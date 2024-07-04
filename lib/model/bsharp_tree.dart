import 'package:visualizeit_bsharptree_extension/exception/element_insertion_exception.dart';
import 'package:visualizeit_bsharptree_extension/exception/element_not_found_exception.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_transition.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_index_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_sequential_node.dart';
import 'package:visualizeit_bsharptree_extension/model/observable.dart';
import 'package:visualizeit_extensions/logging.dart';

final logger = Logger("extension.bsharptree.model");

class BSharpTree<T extends Comparable<T>> extends Observable {
  BSharpNode<T>? _rootNode;
  final int maxCapacity;
  int nodesQuantity = 0;
  int lastNodeId = 0;
  bool keysAreAutoincremental = false;
  T? lastKeyAddedToTree;

  final logger = Logger("extension.bsharptree.model");

  List<String> freeNodesIds = [];

  BSharpTree(this.maxCapacity, {this.keysAreAutoincremental = false});

  BSharpTree._copy(
      this._rootNode,
      this.maxCapacity,
      this.nodesQuantity,
      this.freeNodesIds,
      this.lastNodeId,
      this.keysAreAutoincremental,
      this.lastKeyAddedToTree);

  int get rootMaxCapacity => (4 * maxCapacity) ~/ 3;
  int get depth => _rootNode?.level ?? 0;

  bool isRoot(BSharpNode<T> node) => node.id == _rootNode?.id;

  /// Returns a map with the level as a key, and all of the nodes of the tree in that level
  /// as value
  Map<int, List<BSharpNode<T>>> getAllNodesByLevel() {
    Map<int, List<BSharpNode<T>>> allNodesMap = {};
    if (_rootNode != null) {
      _addNodesByLevelRecursively(allNodesMap, _rootNode!);
    } else {
      allNodesMap = {0: List.empty()};
    }

    return allNodesMap;
  }

  void _addNodesByLevelRecursively(
      Map<int, List<BSharpNode<T>>> nodesMap, BSharpNode<T> current) {
    List<BSharpNode<T>>? nodesList = nodesMap[current.level];
    if (nodesList != null) {
      nodesList.add(current);
    } else {
      nodesMap.putIfAbsent(current.level, () => [current]);
    }
    if (!current.isLevelZero) {
      var node = current as BSharpIndexNode<T>;
      _addNodesByLevelRecursively(nodesMap, node.leftNode);
      for (var indexRecord in node.rightNodes) {
        _addNodesByLevelRecursively(nodesMap, indexRecord.rightNode);
      }
    }
  }

  /// Travels the tree recursively, trying to find the sequential node in which a [value]
  /// should be found, then applies the function of the [modifier] to that node.
  /// 
  /// If that modification results in an index record to be updated, then it also applies a
  /// function from the [modifier] to that node.
  IndexRecord? _searchTreeAndModify(
      BSharpNode<T> current, T value, NodeManager<T> modifier) {
    notifyObservers(NodeRead(targetId: current.id));
    //Base case of the recursion
    if (current.isLevelZero) {
      var sequentialNode = current as BSharpSequentialNode<T>;
      return modifier.applyFunctionToSequentialNode(sequentialNode);
    } else {
      var indexNode = current as BSharpIndexNode<T>;
      var nextNodeForRecursion = indexNode.findNextNodeForKey(value);
      var result = _searchTreeAndModify(nextNodeForRecursion, value, modifier);
      if (result != null) {
        return modifier.applyFunctionToIndexNode(indexNode, result);
      }
      return _releaseIndexNodeIfEmpty(indexNode);
    }
  }

  /// Tries to find a [value] in the B# tree and returns the node id
  ///
  /// if [value] is not on the tree, returns the node where it should be
  String find(T value) {
    var modifier = NodeValueFinder<T>(value, _getNodeId);
    if (_rootNode != null) {
      _searchTreeAndModify(_rootNode!, value, modifier);
    }
    return modifier.result!;
  }

  String _getNodeId(BSharpNode node) {
    notifyObservers(NodeFound(targetId: node.id));
    return node.id;
  }

  /// Inserts a new [value] in the B# tree
  ///
  /// [value] must be of a type [T] that implements [Comparable]
  /// If the tree is empty, creates the root node and then inserts [value]
  /// If the value is already on the tree, it throws an [ElementInsertionException]
  ///
  /// May cause the B# tree to split nodes or grow on height or width
  void insert(T value) {
    logger.debug(() => "insertando value: $value");
    if (keysAreAutoincremental) {
      if (lastKeyAddedToTree != null &&
          lastKeyAddedToTree!.compareTo(value) > 0) {
        throw ElementInsertionException(
            "cant insert the value $value, it's smaller than the last value added to the tree");
      }
    }
    if (_rootNode == null) {
      _rootNode = _buildRootSequentialNode([value]);
      nodesQuantity = 2;
      lastNodeId = 1;
      notifyObservers(
          NodeWritten(targetId: _rootNode!.id, transitionTree: this));
    } else {
      NodeModifier<T> modifier = _buildNodeValueInserter(value);
      _searchTreeAndModify(_rootNode!, value, modifier);
    }
    logger.debug(() => _printTree());
    lastKeyAddedToTree = value;
  }

  NodeModifier<T> _buildNodeValueInserter(value) {
    NodeModifier<T> nodeModifier;
    if (keysAreAutoincremental) {
      nodeModifier = NodeValueInserter<T>(
          value,
          _addValueToSequentialNode,
          _addIndexRecordToNode,
          isRoot,
          _manageOverflowOnRootSequentialNode,
          _manageOverflowOnSequentialNodeWithAutoincrementalValues,
          _manageOverflowOnRootIndexNodeWithAutoIncrementalValues,
          _manageOverflowOnIndexNodeWithAutoIncrementalValues);
    } else {
      nodeModifier = NodeValueInserter<T>(
          value,
          _addValueToSequentialNode,
          _addIndexRecordToNode,
          isRoot,
          _manageOverflowOnRootSequentialNode,
          _manageOverflowOnSequentialNode,
          _manageOverflowOnRootIndexNode,
          _manageOverflowOnIndexNode);
    }
    return nodeModifier;
  }

  void _addValueToSequentialNode(BSharpSequentialNode<T> node, T value) {
    node.addToNode(value);
    notifyObservers(
        NodeWritten(targetId: node.id, transitionTree: this.clone()));
  }

  void _addIndexRecordToNode(
      BSharpIndexNode<T> node, IndexRecord<T> indexRecord) {
    logger.debug(() =>
        "insertando key promocionada: ${indexRecord.key} en nodo ${node.id}");
    node.addIndexRecordToNode(indexRecord);
    node.fixFamilyRelations();
    notifyObservers(
        NodeWritten(targetId: node.id, transitionTree: this.clone()));
  }

  IndexRecord<T>? _manageOverflowOnRootSequentialNode(
      BSharpSequentialNode<T> node) {
    notifyObservers(
        NodeOverflow(targetId: node.id, transitionTree: this.clone()));
    BSharpSequentialNode<T> leftNode;
    BSharpSequentialNode<T> rightNode;

    (leftNode, rightNode) = _splitRootNodesInTwo(node);

    leftNode.nextNode = rightNode;
    //Crear el nuevo nodo indice raiz que va a reemplazar al nodo secuencia
    var newRoot = _buildRootIndexNode(
        leftNode, [IndexRecord(rightNode.values.first, rightNode)], 1,
        isReplacingRoot: true);

    newRoot.fixFamilyRelations();
    _rootNode = newRoot;
    notifyObservers(NodeWritten(targetId: leftNode.id, transitionTree: this));
    notifyObservers(NodeWritten(targetId: rightNode.id));
    notifyObservers(NodeWritten(targetId: newRoot.id, transitionTree: this));
    return null;
  }

  IndexRecord<T>? _manageOverflowOnSequentialNode(
      BSharpSequentialNode<T> node) {
    notifyObservers(
        NodeOverflow(targetId: node.id, transitionTree: this.clone()));
    IndexRecord<T>? indexRecord;
    var hasBalancedWithSibling = _tryToBalanceSequentialNodesWithSibling(node);

    if (!hasBalancedWithSibling) {
      // Si llegué acá no pude rebalancear con ninguno de los hermanos porque estan completos, tengo que unir
      // ambos nodos, crear uno nuevo en el medio y repartir las claves en 3
      indexRecord = _splitSequentialNodeWithAnySibling(node);
    }
    return indexRecord;
  }

  IndexRecord<T>? _manageOverflowOnSequentialNodeWithAutoincrementalValues(
      BSharpSequentialNode<T> node) {
    notifyObservers(
        NodeOverflow(targetId: node.id, transitionTree: this.clone()));
    var lastValue = node.values.removeLast();
    var newNode = _buildSequentialNode([lastValue]);
    node.nextNode = newNode;
    notifyObservers(
        NodeWritten(targetId: newNode.id, transitionTree: this.clone()));
    return IndexRecord(newNode.firstKey()!, newNode);
  }

  IndexRecord<T>? _manageOverflowOnRootIndexNodeWithAutoIncrementalValues(
      BSharpIndexNode<T> node) {
    var recordToPromote = node.rightNodes.elementAt(maxCapacity);

    var newLeftNode = _buildIndexNode(
        node.leftNode, node.rightNodes.sublist(0, maxCapacity), node.level);
    var newRightNode = _buildIndexNode(recordToPromote.rightNode,
        node.rightNodes.sublist(maxCapacity + 1), node.level);

    node.leftNode = newLeftNode;
    node.rightNodes = [IndexRecord(recordToPromote.key, newRightNode)];
    node.level += 1;

    newLeftNode.fixFamilyRelations();
    newRightNode.fixFamilyRelations();
    node.fixFamilyRelations();

    notifyObservers(NodeWritten(targetId: newLeftNode.id));
    notifyObservers(NodeWritten(targetId: newRightNode.id));
    notifyObservers(
        NodeWritten(targetId: node.id, transitionTree: this.clone()));
    return null;
  }

  IndexRecord<T>? _manageOverflowOnIndexNodeWithAutoIncrementalValues(
      BSharpIndexNode<T> node) {
    var lastIndexRecord = node.rightNodes.removeLast();
    var newNode = _buildIndexNode(lastIndexRecord.rightNode, [], node.level);

    node.fixFamilyRelations();
    newNode.fixFamilyRelations();
    notifyObservers(NodeWritten(targetId: newNode.id));
    notifyObservers(
        NodeWritten(targetId: node.id, transitionTree: this.clone()));

    return IndexRecord(lastIndexRecord.key, newNode);
  }

  IndexRecord<T>? _manageOverflowOnRootIndexNode(BSharpIndexNode<T> node) {
    notifyObservers(
        NodeOverflow(targetId: node.id, transitionTree: this.clone()));
    //current es la raiz y tengo que dividirla en dos
    _splitIndexRootNode(node);
    return null;
  }

  IndexRecord<T>? _manageOverflowOnIndexNode(BSharpIndexNode<T> node) {
    notifyObservers(
        NodeOverflow(targetId: node.id, transitionTree: this.clone()));
    IndexRecord<T>? indexRecord;
    var hasBalancedWithSibling =
        _tryToBalanceOverflowedIndexNodeWithSiblings(node);
    if (!hasBalancedWithSibling) {
      //no puedo rotar ni a izq ni a derecha, tengo que juntar las claves y dividir el nodo en 3
      indexRecord = _splitSiblingIndexNodeWithAnySibling(node);
    }
    return indexRecord;
  }

  /// Removes a [value] from the B# tree, if it can be found
  ///
  /// [value] must be of a type [T] that implements [Comparable]
  /// If the value is not found on the tree, it throws an [ElementNotFoundException]
  ///
  /// May cause the tree to fuse nodes and shrink in height or width
  void remove(T value) {
    logger.debug(() => "eliminando value: $value");
    if (_rootNode != null) {
      var modifier = _buildNodeValueRemover(value);
      _searchTreeAndModify(_rootNode!, value, modifier);
    }
    logger.debug(() => _printTree());
  }

  NodeModifier<T> _buildNodeValueRemover(T value) {
    NodeModifier<T> nodeModifier;
    if (keysAreAutoincremental) {
      nodeModifier = NodeValueRemover<T>(
          value,
          _removeValueFromSequentialNode,
          _removeIndexRecordFromNode,
          isRoot,
          (node) => null,
          _manageUnderflowOnSequentialNodeWithAutoincrementalValues,
          _manageUnderflowOnRootIndexNode,
          _manageUnderflowOnIndexNodeWithAutoincrementalValues);
    } else {
      nodeModifier = NodeValueRemover<T>(
          value,
          _removeValueFromSequentialNode,
          _removeIndexRecordFromNode,
          isRoot,
          (node) => null,
          _manageUnderflowOnSequentialNode,
          _manageUnderflowOnRootIndexNode,
          _manageUnderflowOnIndexNode);
    }

    return nodeModifier;
  }

  void _removeValueFromSequentialNode(BSharpSequentialNode<T> node, T value) {
    logger.debug(() =>
        "el valor a remover '$value' se encontró en el nodo con id: ${node.id}");
    node.removeValue(value);
    notifyObservers(
        NodeWritten(targetId: node.id, transitionTree: this.clone()));
  }

  void _removeIndexRecordFromNode(
      BSharpIndexNode<T> node, IndexRecord<T> indexRecordToUpdate) {
    logger.debug(() =>
        "index record a remover con id de rightNode: ${indexRecordToUpdate.rightNode.id}");
    node.rightNodes.removeWhere((indexRecord) =>
        indexRecord.rightNode.id == indexRecordToUpdate.rightNode.id);
    node.fixFamilyRelations();
    notifyObservers(
        NodeWritten(targetId: node.id, transitionTree: this.clone()));
  }

  IndexRecord<T>? _manageUnderflowOnSequentialNodeWithAutoincrementalValues(
      BSharpSequentialNode<T> node) {
    var isTheLastBranch = node.getParent()!.rightSibling == null;
    IndexRecord<T>? indexRecordToUpdate;
    if (isTheLastBranch) {
      if (node.values.isEmpty) {
        var parentNode = node.getParent()!;
        indexRecordToUpdate = parentNode.findIndexRecordById(node.id);
        _release(node);
        notifyObservers(
            NodeRelease(targetId: node.id, transitionTree: this.clone()));
      }
    } else {
      indexRecordToUpdate = _manageUnderflowOnSequentialNode(node);
    }
    return indexRecordToUpdate;
  }

  IndexRecord<T>? _manageUnderflowOnIndexNodeWithAutoincrementalValues(
      BSharpIndexNode<T> node) {
    IndexRecord<T>? indexRecordToUpdate;
    var isTheLastBranch = node.rightSibling == null;
    if (isTheLastBranch) {
      indexRecordToUpdate = _releaseIndexNodeIfEmpty(node);
    } else {
      indexRecordToUpdate = _manageUnderflowOnIndexNode(node);
    }
    return indexRecordToUpdate;
  }

  IndexRecord<T>? _manageUnderflowOnSequentialNode(
      BSharpSequentialNode<T> node) {
    notifyObservers(
        NodeUnderflow(targetId: node.id, transitionTree: this.clone()));
    var hasBalancedWithSibling =
        _tryToBalanceUnderflowedSequentialNodeWithSiblings(node);
    IndexRecord<T>? indexRecordToUpdate;
    if (!hasBalancedWithSibling) {
      // Si llegué acá no pude rebalancear con ninguno de los hermanos porque estan completos, tengo que unir
      // ambos nodos
      indexRecordToUpdate = _fuseSequentialNodeWithAnySibling(node);
    }
    return indexRecordToUpdate;
  }

  IndexRecord<T>? _manageUnderflowOnRootIndexNode(BSharpIndexNode<T> node) {
    if (node.parent == null && node.length() == 0) {
      BSharpNode<T> leftChild = node.leftNode;
      if (node.leftNode.isLevelZero) {
        //Hay que convertir el nodo raiz de un index node a un sequential node
        leftChild = leftChild as BSharpSequentialNode<T>;
        _rootNode =
            _buildRootSequentialNode(leftChild.values, isReplacingRoot: true);
      } else {
        leftChild = leftChild as BSharpIndexNode<T>;
        node.leftNode = leftChild.leftNode;
        node.rightNodes = leftChild.rightNodes;
        node.level = node.level - 1;
        node.fixFamilyRelations();
      }
      _release(leftChild);
      notifyObservers(NodeRelease(targetId: leftChild.id));
      notifyObservers(NodeWritten(targetId: node.id, transitionTree: this.clone()));
    } else {
      node.fixFamilyRelations();
    }

    return null;
  }

  IndexRecord<T>? _manageUnderflowOnIndexNode(BSharpIndexNode<T> node) {
    IndexRecord<T>? indexRecordToUpdate;
    notifyObservers(
        NodeUnderflow(targetId: node.id, transitionTree: this.clone()));
    var hasBalancedWithSibling =
        _tryToBalanceUnderflowedIndexNodeWithSiblings(node);
    if (!hasBalancedWithSibling) {
      indexRecordToUpdate = _fuseIndexNodesWithAnySibling(node);
    }
    return indexRecordToUpdate;
  }

  /// Splits the root [node] (when it's an index node)
  ///
  /// This method is called when the root is over its max capacity
  /// It takes all the root childrens and creates a new sibling and a new root node. Then it distributes the children between
  /// the new sibling and the former root node.
  void _splitIndexRootNode(BSharpIndexNode<T> node) {
    var recordToPromote = node.rightNodes.elementAt(node.length() ~/ 2);

    var newLeftNode = _buildIndexNode(node.leftNode,
        node.rightNodes.sublist(0, node.length() ~/ 2), node.level);
    var newRightNode = _buildIndexNode(recordToPromote.rightNode,
        node.rightNodes.sublist((node.length() ~/ 2) + 1), node.level);

    node.leftNode = newLeftNode;
    node.rightNodes = [IndexRecord(recordToPromote.key, newRightNode)];
    node.level += 1;

    newLeftNode.fixFamilyRelations();
    newRightNode.fixFamilyRelations();
    node.fixFamilyRelations();

    notifyObservers(NodeWritten(targetId: newLeftNode.id));
    notifyObservers(NodeWritten(targetId: newRightNode.id));
    notifyObservers(
        NodeWritten(targetId: node.id, transitionTree: this.clone()));
  }

  /// Balances index nodes, taking a node (and its children) from the right sibling and 
  /// adding a node on the left sibling
  ///
  /// Using the [parent] key and the [rightSiblingNode] left children creates a new [IndexRecord]
  /// to add to the left sibling then removes the first [IndexRecord] of the right sibling, to use 
  /// its node as the new left children of the node.
  /// Lastly, updates the right sibling index record with the new smallest key.
  void _balanceIndexNodesRightToLeft(BSharpIndexNode<T> leftSiblingNode,
      BSharpIndexNode<T> rightSiblingNode, BSharpIndexNode<T> parent) {
    var rightSiblingRecord = parent.findIndexRecordById(rightSiblingNode.id);
    var smallestRecordFromRight = rightSiblingNode.rightNodes.removeAt(0);

    var newIndexRecord =
        IndexRecord(rightSiblingRecord!.key, rightSiblingNode.leftNode);
    leftSiblingNode.addIndexRecordToNode(newIndexRecord);
    rightSiblingNode.leftNode = smallestRecordFromRight.rightNode;
    rightSiblingRecord.key = smallestRecordFromRight.key;

    leftSiblingNode.fixFamilyRelations();
    rightSiblingNode.fixFamilyRelations();

    notifyObservers(NodeBalancing(
        targetId: leftSiblingNode.id,
        firstOptionalTargetId: rightSiblingNode.id,
        transitionTree: this.clone()));
    notifyObservers(NodeWritten(targetId: leftSiblingNode.id));
    notifyObservers(NodeWritten(
        targetId: rightSiblingNode.id, transitionTree: this.clone()));
  }

  /// Balances index nodes, taking a node (and its children) from the left sibling and adding a node on the right sibling
  ///
  /// Using the [parent] key and the [rightSiblingNode] left children creates a new [IndexRecord] to add to the right sibling
  /// then removes the last [IndexRecord] of the left sibling, to use its node as the new left children of the node.
  /// /// Lastly, updates the right sibling index record with the new smallest key.
  void _balanceIndexNodesLeftToRight(BSharpIndexNode<T> leftSiblingNode,
      BSharpIndexNode<T> rightSiblingNode, BSharpIndexNode<T> parent) {
    var rightSiblingRecord = parent.findIndexRecordById(rightSiblingNode.id);
    var biggestRecordFromLeft = leftSiblingNode.rightNodes.removeLast();

    var newIndexRecord =
        IndexRecord(rightSiblingRecord!.key, rightSiblingNode.leftNode);
    rightSiblingNode.addIndexRecordToNode(newIndexRecord);
    rightSiblingNode.leftNode = biggestRecordFromLeft.rightNode;
    rightSiblingRecord.key = biggestRecordFromLeft.key;

    leftSiblingNode.fixFamilyRelations();
    rightSiblingNode.fixFamilyRelations();

    notifyObservers(NodeBalancing(
        targetId: leftSiblingNode.id,
        firstOptionalTargetId: rightSiblingNode.id,
        transitionTree: this.clone()));
    notifyObservers(NodeWritten(targetId: leftSiblingNode.id));
    notifyObservers(NodeWritten(
        targetId: rightSiblingNode.id, transitionTree: this.clone()));
  }

  /// Taking all the index records of an index [node] and its [siblingNode], and adding the [IndexRecord] of the siblingNode,
  /// splits these index records in 3 nodes, adding a new node in the middle of [node] and [siblingNode], and promotes
  /// a new [IndexRecord] to be added to the parent node
  IndexRecord<T> _splitSiblingIndexNodes(BSharpIndexNode<T> node,
      BSharpIndexNode<T> siblingNode, BSharpIndexNode<T> parent) {
    notifyObservers(
        NodeSplit(targetId: node.id, firstOptionalTargetId: siblingNode.id));

    var siblingRecord = parent.findIndexRecordById(siblingNode.id);
    var allIndexRecords = node.rightNodes;
    var parentIndexRecord =
        IndexRecord(siblingRecord!.key, siblingNode.leftNode);
    allIndexRecords.add(parentIndexRecord);
    allIndexRecords.addAll(siblingNode.rightNodes);
    allIndexRecords.sort((a, b) => a.key.compareTo(b.key));
    node.rightNodes = allIndexRecords.sublist(0, allIndexRecords.length ~/ 3);

    var firstPromotedIndexRecord =
        allIndexRecords.elementAt(allIndexRecords.length ~/ 3);
    siblingNode.leftNode = firstPromotedIndexRecord.rightNode;
    siblingNode.rightNodes = allIndexRecords.sublist(
        (allIndexRecords.length ~/ 3) + 1, (allIndexRecords.length * 2) ~/ 3);
    siblingRecord.key = firstPromotedIndexRecord.key;

    var secondPromotedIndexRecord =
        allIndexRecords.elementAt((allIndexRecords.length * 2) ~/ 3);

    var newNode = _buildIndexNode(
        secondPromotedIndexRecord.rightNode,
        allIndexRecords.sublist(((allIndexRecords.length * 2) ~/ 3) + 1),
        node.level);

    node.fixFamilyRelations();
    siblingNode.fixFamilyRelations();
    newNode.fixFamilyRelations();

    notifyObservers(NodeWritten(targetId: newNode.id));
    notifyObservers(NodeWritten(targetId: node.id));
    notifyObservers(
        NodeWritten(targetId: siblingNode.id, transitionTree: this.clone()));

    return IndexRecord(secondPromotedIndexRecord.key, newNode);
  }

  /// Balances sequential nodes, taking all the keys from a [node] and its [siblingNode] and
  /// redistributing half of the keys on each node
  ///
  /// Lastly, updates the [siblingNode] index record with the new smallest key.
  void _balanceSequentialNodeWithSibling(
      BSharpSequentialNode<T> node, BSharpSequentialNode<T> siblingNode) {
    var siblingRecord = node.getParent()!.findIndexRecordById(siblingNode.id);
    var allKeys = node.values + siblingNode.values;
    allKeys.sort();
    node.values = allKeys.sublist(0, allKeys.length ~/ 2);
    siblingNode.values = allKeys.sublist(allKeys.length ~/ 2);
    if (siblingRecord != null) {
      siblingRecord.key = siblingNode.firstKey()!;
    }

    notifyObservers(NodeBalancing(
        targetId: node.id,
        firstOptionalTargetId: siblingNode.id,
        transitionTree: this));
    notifyObservers(NodeWritten(targetId: node.id));
    notifyObservers(
        NodeWritten(targetId: siblingNode.id, transitionTree: this.clone()));
  }

  /// Taking all the keys records of a sequential [node] and its [siblingNode], splits the keys in 3 nodes,
  /// adding a new node in the middle of [node] and [siblingNode], and promotes a new [IndexRecord] to be added
  /// to the parent node
  IndexRecord<T> _splitSiblingSequentialNodes(BSharpSequentialNode<T> node,
      BSharpSequentialNode<T> siblingNode, BSharpIndexNode<T> parentNode) {
    notifyObservers(
        NodeSplit(targetId: node.id, firstOptionalTargetId: siblingNode.id));

    var siblingRecord = parentNode.findIndexRecordById(siblingNode.id);
    var allKeys = node.values + siblingNode.values;
    allKeys.sort();
    node.values = allKeys.sublist(0, allKeys.length ~/ 3);

    var newNode = _buildSequentialNode(
        allKeys.sublist(allKeys.length ~/ 3, (allKeys.length * 2) ~/ 3));

    newNode.nextNode = siblingNode;
    node.nextNode = newNode;

    siblingNode.values = allKeys.sublist((allKeys.length * 2) ~/ 3);
    if (siblingRecord != null) {
      siblingRecord.key = siblingNode.firstKey()!;
    }

    notifyObservers(NodeWritten(
        targetId: newNode.id,
        transitionTree: this
            .clone()));
    return IndexRecord(newNode.firstKey()!, newNode);
  }

  /// Prints all the nodes info from the tree, starting from the root
  String _printTree() {
    if (_rootNode != null) {
      var depth = 0;
      var buffer = StringBuffer();
      _printNode(_rootNode!, depth, buffer);
      return buffer.toString();
    }
    return "";
  }

  /// Prints a single node info and recursively calls itself to print all the children's node info
  void _printNode(BSharpNode<T> node, int depth, StringBuffer buffer) {
    String padding = "${"--" * depth}>";
    String nodeId = node.id.padRight(2);
    if (!node.isLevelZero) {
      var indexNode = node as BSharpIndexNode<T>;
      buffer.writeln(
          "$padding$nodeId: ${indexNode.leftNode.id}|${indexNode.rightNodes} - parent: ${indexNode.getParent()?.id}, leftSibling: ${indexNode.getLeftSibling()?.id}, rightSibling: ${indexNode.getRightSibling()?.id}");
      _printNode(indexNode.leftNode, ++depth, buffer);
      for (var e in indexNode.rightNodes) {
        _printNode(e.rightNode, depth, buffer);
      }
    } else {
      var sequentialNode = node as BSharpSequentialNode<T>;
      buffer.writeln(
          "$padding$nodeId: ${sequentialNode.values} - parent: ${node.getParent()?.id}, leftSibling: ${node.getLeftSibling()?.id}, rightSibling: ${node.getRightSibling()?.id}");
    }
  }

  /// Fuses the keys of a sequential [node] and its [siblingNode], and sets all the keys in the [node]
  ///
  /// Returns the [IndexRecord] of the [siblingNode] to be removed from the parent node
  IndexRecord<T>? _fuseSiblingSequentialNodes(BSharpSequentialNode<T> node,
      BSharpSequentialNode<T> siblingNode, BSharpIndexNode<T> parent) {
    var siblingRecord = parent.findIndexRecordById(siblingNode.id);
    var nodeRecord = parent.findIndexRecordById(node.id);
    var allKeys = node.values + siblingNode.values;
    allKeys.sort();

    node.values = allKeys;
    node.nextNode = siblingNode.nextNode;
    if (nodeRecord != null) {
      nodeRecord.key = node.firstKey()!;
    }

    _release(siblingNode);

    notifyObservers(
        NodeFusion(targetId: node.id, firstOptionalTargetId: siblingNode.id));
    notifyObservers(NodeWritten(targetId: node.id));
    notifyObservers(
        NodeRelease(targetId: siblingNode.id, transitionTree: this.clone()));

    return siblingRecord;
  }

  /// Fuses the index records of an index [node] and its [siblingNode], and sets all these index records in the [node]
  ///
  /// Returns the [IndexRecord] of the [siblingNode] to be removed from the parent node
  IndexRecord<T>? _fuseSiblingIndexNodes(BSharpIndexNode<T> node,
      BSharpIndexNode<T> siblingNode, BSharpIndexNode<T> parent) {
    var siblingRecord = parent.findIndexRecordById(siblingNode.id);

    var newIndexRecord = IndexRecord(siblingRecord!.key, siblingNode.leftNode);

    node.addIndexRecordToNode(newIndexRecord);
    for (var nodeToMove in siblingNode.rightNodes) {
      node.addIndexRecordToNode(nodeToMove);
    }
    node.fixFamilyRelations();

    _release(siblingNode);

    notifyObservers(
        NodeFusion(targetId: node.id, firstOptionalTargetId: siblingNode.id));
    notifyObservers(NodeWritten(targetId: node.id));
    notifyObservers(NodeRelease(targetId: siblingNode.id));

    return siblingRecord;
  }

  /// Inserts a [listOfValues] into the tree, one by one
  void insertAll(List<T> listOfValues) {
    logger.debug(() => "values to insert: $listOfValues");
    for (var value in listOfValues) {
      insert(value);
    }
  }

  /// Fuse a sequential [node] with its adjacent siblings, splitting the values between the two of them and freeing the node.
  /// If [node] doesn't have a right sibling, it tries to fuse with its left sibling and the left sibling of the left sibling.
  /// If [node] doesn't have a left sibling, it tries to fuse with his right sibling, and the right sibling of the right sibling.
  /// If all of the above fails, it means that the node only has one sibling, and fuses with it
  IndexRecord<T>? _fuseSequentialNodeWithAnySibling(
      BSharpSequentialNode<T> node) {
    var rightSiblingNode = node.getRightSibling();
    var leftSiblingNode = node.getLeftSibling();

    IndexRecord<T>? indexRecordToUpdate;

    if (rightSiblingNode != null && leftSiblingNode != null) {
      indexRecordToUpdate = _fuseSequentialNodeWithTwoSiblings(
          node, leftSiblingNode, rightSiblingNode);
      leftSiblingNode.nextNode = rightSiblingNode;
      return indexRecordToUpdate;
    }

    // The node is the leftmost node, so you have to fuse with his right sibling, and the right sibling of the right sibling
    if (leftSiblingNode == null &&
        rightSiblingNode != null &&
        rightSiblingNode.getRightSibling() != null) {
      return _fuseSequentialNodeWithTwoSiblings(
          rightSiblingNode, node, rightSiblingNode.getRightSibling()!);
    }

    // The node is the rightmost node, so you have to fuse with his left sibling, and the left sibling of the left sibling
    if (rightSiblingNode == null &&
        leftSiblingNode != null &&
        leftSiblingNode.getLeftSibling() != null) {
      indexRecordToUpdate = _fuseSequentialNodeWithTwoSiblings(
          node, leftSiblingNode.getLeftSibling()!, leftSiblingNode);
      leftSiblingNode.nextNode = null;
      return indexRecordToUpdate;
    }

    if (node.getRightSibling() != null) {
      return _fuseSiblingSequentialNodes(
          node, node.getRightSibling()!, node.getParent()!);
    } else {
      return _fuseSiblingSequentialNodes(
          node.getLeftSibling()!, node, node.getParent()!);
    }
  }

  IndexRecord<T>? _fuseSequentialNodeWithTwoSiblings(
      BSharpSequentialNode<T> node,
      BSharpSequentialNode<T> leftSiblingNode,
      BSharpSequentialNode<T> rightSiblingNode) {
    var leftSiblingRecord =
        node.getParent()!.findIndexRecordById(leftSiblingNode.id);
    var rightSiblingRecord =
        node.getParent()!.findIndexRecordById(rightSiblingNode.id);
    var nodeRecord = node.getParent()!.findIndexRecordById(node.id);
    var allKeys =
        node.values + leftSiblingNode.values + rightSiblingNode.values;
    allKeys.sort();

    leftSiblingNode.values = allKeys.sublist(0, allKeys.length ~/ 2);
    rightSiblingNode.values = allKeys.sublist(allKeys.length ~/ 2);
    leftSiblingNode.nextNode = rightSiblingNode;

    if (leftSiblingRecord != null) {
      leftSiblingRecord.key = leftSiblingNode.firstKey()!;
    }

    if (rightSiblingRecord != null) {
      rightSiblingRecord.key = rightSiblingNode.firstKey()!;
    }

    notifyObservers(NodeFusion(
        targetId: node.id,
        firstOptionalTargetId: leftSiblingNode.id,
        secondOptionalTargetId: rightSiblingNode.id));
    notifyObservers(NodeWritten(targetId: leftSiblingNode.id));
    notifyObservers(NodeWritten(targetId: rightSiblingNode.id));

    _release(node);

    notifyObservers(
        NodeRelease(targetId: node.id, transitionTree: this.clone()));

    return nodeRecord;
  }

  /// Tries to balance a sequential [node] with its right sibling, using the [capacityCheckFunction].
  /// If its unable to do it, then tries the same with the left sibling.
  /// If it was able to balance with any of the siblings, returns true. Otherwise, returns false.
  bool _tryToBalanceSequentialNodesWithSibling(BSharpSequentialNode<T> node) {
    var rightSiblingNode = node.getRightSibling();

    if (rightSiblingNode != null) {
      notifyObservers(NodeRead(targetId: rightSiblingNode.id));
      //Se intenta balancear con el hermano derecho
      if (rightSiblingNode.hasCapacityLeft()) {
        _balanceSequentialNodeWithSibling(node, rightSiblingNode);
        return true;
      }
    }
    logger.debug(() => "no se pudo balancear con hermano derecho");

    var leftSiblingNode =
        node.getLeftSibling(); //Se intenta balancear con el hermano izquierdo
    if (leftSiblingNode != null) {
      notifyObservers(NodeRead(targetId: leftSiblingNode.id));
      if (leftSiblingNode.hasCapacityLeft()) {
        _balanceSequentialNodeWithSibling(leftSiblingNode, node);
        return true;
      }
    }
    logger.debug(() => "no se pudo balancear con hermano izquierdo");
    return false;
  }

  /// Tries to balance an underflowed index [node] with its right sibling, if it's over its minimum capacity.
  /// If its unable to do it, then tries the same with the left sibling.
  /// If it was able to balance with any of the siblings, returns true. Otherwise, returns false.
  bool _tryToBalanceUnderflowedIndexNodeWithSiblings(BSharpIndexNode<T> node) {
    var rightSiblingNode = node.getRightSibling();
    if (rightSiblingNode != null) {
      notifyObservers(NodeRead(targetId: rightSiblingNode.id));
      if (rightSiblingNode.isOverMinCapacity()) {
        _balanceIndexNodesRightToLeft(
            node, rightSiblingNode, node.getParent()!);
        return true;
      }
    }
    logger.debug(() => "no se pudo balancear con hermano derecho");

    var leftSiblingNode = node.getLeftSibling();

    if (leftSiblingNode != null) {
      notifyObservers(NodeRead(targetId: leftSiblingNode.id));
      if (leftSiblingNode.isOverMinCapacity()) {
        _balanceIndexNodesLeftToRight(leftSiblingNode, node, node.getParent()!);
        return true;
      }
    }
    logger.debug(() => "no se pudo balancear con hermano izquierdo");
    return false;
  }

  /// Tries to balance an overflowed index [node] with its right sibling, if it's over it has enough capacity.
  /// If its unable to do it, then tries the same with the left sibling.
  /// If it was able to balance with any of the siblings, returns true. Otherwise, returns false.
  bool _tryToBalanceOverflowedIndexNodeWithSiblings(BSharpIndexNode<T> node) {
    var rightSiblingNode = node.getRightSibling();
    if (rightSiblingNode != null) {
      notifyObservers(NodeRead(targetId: rightSiblingNode.id));
      if (rightSiblingNode.hasCapacityLeft()) {
        _balanceIndexNodesLeftToRight(
            node, rightSiblingNode, node.getParent()!);
        return true;
      }
    }
    logger.debug(() => "no se pudo balancear con hermano derecho");

    var leftSiblingNode = node.getLeftSibling();
    if (leftSiblingNode != null) {
      notifyObservers(NodeRead(targetId: leftSiblingNode.id));
      if (leftSiblingNode.hasCapacityLeft()) {
        _balanceIndexNodesRightToLeft(leftSiblingNode, node, node.getParent()!);
        return true;
      }
    }
    logger.debug(() => "no se pudo balancear con hermano izquierdo");
    return false;
  }

  /// Fuse an index [node] with its right sibling, if it exists.
  /// If it doesn't exist, fuses the left sibling with the [node]
  IndexRecord<T>? _fuseIndexNodesWithAnySibling(BSharpIndexNode<T> node) {
    if (node.getRightSibling() != null) {
      return _fuseSiblingIndexNodes(
          node, node.getRightSibling()!, node.getParent()!);
    } else {
      return _fuseSiblingIndexNodes(
          node.getLeftSibling()!, node, node.getParent()!);
    }
  }

  /// Splits a sequential [node] with its right sibling, if it exists.
  /// If it doesn't exist, splits the left sibling with the [node]
  IndexRecord<T>? _splitSequentialNodeWithAnySibling(
      BSharpSequentialNode<T> node) {
    if (node.getRightSibling() != null) {
      return _splitSiblingSequentialNodes(
          node, node.getRightSibling()!, node.getParent()!);
    } else {
      return _splitSiblingSequentialNodes(
          node.getLeftSibling()!, node, node.getParent()!);
    }
  }

  /// Splits an index [node] with its right sibling, if it exists.
  /// If it doesn't exist, splits the left sibling with the [node]
  IndexRecord<T>? _splitSiblingIndexNodeWithAnySibling(
      BSharpIndexNode<T> node) {
    var rightSiblingNode = node.getRightSibling();
    if (rightSiblingNode != null) {
      return _splitSiblingIndexNodes(node, rightSiblingNode, node.getParent()!);
    } else {
      var leftSiblingNode = node.getLeftSibling();
      return _splitSiblingIndexNodes(leftSiblingNode!, node, node.getParent()!);
    }
  }

  /// Balances sequential nodes, taking all the keys from a [node] and its [siblingNode] and
  /// redistributing half of the keys on each node
  ///
  /// Lastly, updates the [siblingNode] index record with the new smallest key.
  void _balanceSequentialNodeWithTwoSiblings(
      BSharpSequentialNode<T> leftSiblingNode,
      BSharpSequentialNode<T> centerSiblingNode,
      BSharpSequentialNode<T> rightSiblingNode) {
    var centerSiblingRecord = centerSiblingNode
        .getParent()!
        .findIndexRecordById(centerSiblingNode.id);
    var rightSiblingRecord =
        rightSiblingNode.getParent()!.findIndexRecordById(rightSiblingNode.id);
    var allKeys = leftSiblingNode.values +
        centerSiblingNode.values +
        rightSiblingNode.values;
    allKeys.sort();
    leftSiblingNode.values = allKeys.sublist(0, allKeys.length ~/ 3);
    centerSiblingNode.values =
        allKeys.sublist(allKeys.length ~/ 3, (allKeys.length * 2) ~/ 3);
    rightSiblingNode.values = allKeys.sublist((allKeys.length * 2) ~/ 3);

    if (centerSiblingRecord != null) {
      centerSiblingRecord.key = centerSiblingNode.firstKey()!;
    }

    if (rightSiblingRecord != null) {
      rightSiblingRecord.key = rightSiblingNode.firstKey()!;
    }

    notifyObservers(NodeBalancing(
        targetId: leftSiblingNode.id,
        firstOptionalTargetId: centerSiblingNode.id,
        secondOptionalTargetId: rightSiblingNode.id,
        transitionTree: this.clone()));
    notifyObservers(NodeWritten(targetId: leftSiblingNode.id));
    notifyObservers(NodeWritten(targetId: centerSiblingNode.id));
    notifyObservers(NodeWritten(
        targetId: rightSiblingNode.id, transitionTree: this.clone()));
  }

  bool _tryToBalanceUnderflowedSequentialNodeWithSiblings(
      BSharpSequentialNode<T> node) {
    // si el nodo no tiene hermano derecho, tengo que tratar de balancear con su hermano izquierdo
    // y el izquierdo del izquierdo, si existe

    var rightSiblingNode = node.getRightSibling();
    if (rightSiblingNode != null) {
      notifyObservers(NodeRead(targetId: rightSiblingNode.id));
      if (rightSiblingNode.isOverMinCapacity()) {
        //Se intenta balancear con el hermano derecho
        _balanceSequentialNodeWithSibling(node, rightSiblingNode);
        return true;
      }
    }
    logger.debug(() => "no se pudo balancear con hermano derecho");

    var leftSiblingNode =
        node.getLeftSibling(); //Se intenta balancear con el hermano izquierdo
    if (leftSiblingNode != null) {
      notifyObservers(NodeRead(targetId: leftSiblingNode.id));
      if (leftSiblingNode.isOverMinCapacity()) {
        _balanceSequentialNodeWithSibling(leftSiblingNode, node);
        return true;
      }
    }

    logger.debug(() => "no se pudo balancear con hermano izquierdo");

    //Se trata de balancear entre los hermanos izquierdos (si existen)
    if (rightSiblingNode == null &&
        leftSiblingNode != null &&
        leftSiblingNode.getLeftSibling() != null) {
      var leftLeftSibling = leftSiblingNode.getLeftSibling()!;

      notifyObservers(NodeRead(targetId: leftLeftSibling.id));
      if (leftLeftSibling.isOverMinCapacity()) {
        _balanceSequentialNodeWithTwoSiblings(
            leftLeftSibling, leftSiblingNode, node);
        return true;
      }
      logger.debug(
          () => "no se pudo balancear con hermano izquierdo del izquierdo");
    }

    //Se trata de balancear entre los hermanos derechos (si existen)
    if (leftSiblingNode == null &&
        rightSiblingNode != null &&
        rightSiblingNode.getRightSibling() != null) {
      var rightRightSibling = rightSiblingNode.getRightSibling()!;

      notifyObservers(NodeRead(targetId: rightRightSibling.id));
      if (rightRightSibling.isOverMinCapacity()) {
        _balanceSequentialNodeWithTwoSiblings(
            node, rightSiblingNode, rightRightSibling);
        return true;
      }
      logger
          .debug(() => "no se pudo balancear con hermano derecho del derecho");
    }

    return false;
  }

  /// Clones a B# Tree, copying all the info of its nodes and their relationship with each other
  BSharpTree<T> clone() {
    BSharpNode<T>? rootNode;
    if (_rootNode != null) {
      rootNode = _cloneRecursively(_rootNode!);
    }

    return BSharpTree<T>._copy(
        rootNode,
        maxCapacity,
        nodesQuantity,
        List.of(freeNodesIds),
        lastNodeId,
        keysAreAutoincremental,
        lastKeyAddedToTree);
  }

  BSharpNode<T> _cloneRecursively(BSharpNode<T> node) {
    if (!node.isLevelZero) {
      var indexNode = node as BSharpIndexNode<T>;

      var leftNode = _cloneRecursively(indexNode.leftNode);
      var rightNodes = indexNode.rightNodes
          .map((indexRecord) => IndexRecord(
              indexRecord.key, _cloneRecursively(indexRecord.rightNode)))
          .toList();
      var indexNodeCopy =
          indexNode.copyWith(leftNode: leftNode, rightNodes: rightNodes);
      indexNodeCopy.fixFamilyRelations();
      return indexNodeCopy;
    } else {
      var sequentialNode = node as BSharpSequentialNode<T>;
      return sequentialNode.copy();
    }
  }

  /// Returns a new sequential node, with a new node id or reusing a free node
  BSharpSequentialNode<T> _buildSequentialNode(List<T> values,
      {String? givenNodeId, int? givenCapacity, bool isReplacingRoot = false}) {
    var nodeId = "";
    var hasReused = false;

    //Si no me llega un nodeId hay que obtenerlo, reusando uno o creando uno nuevo
    if (givenNodeId == null) {
      (nodeId, hasReused) = _getNextNodeIdWithReuse();
    } else {
      nodeId = givenNodeId;
    }

    var node = BSharpSequentialNode.createNode(
        nodeId, 0, givenCapacity ?? maxCapacity, values);

    // Si no se está reemplazando la raiz, es un nuevo nodo hoja que hay que agregar al arbol
    if (!isReplacingRoot) {
      nodesQuantity++;
      notifyObservers(hasReused
          ? NodeReuse(targetId: nodeId)
          : NodeCreation(targetId: nodeId));
    }
    return node;
  }

  BSharpSequentialNode<T> _buildRootSequentialNode(List<T> values,
      {bool isReplacingRoot = false}) {
    return _buildSequentialNode(values,
        givenCapacity: rootMaxCapacity,
        givenNodeId: "0-1",
        isReplacingRoot: isReplacingRoot);
  }

  /// Returns a new index node, with a new node id or reusing a free node
  BSharpIndexNode<T> _buildIndexNode(
      BSharpNode<T> leftNode, List<IndexRecord<T>> rightNodes, int level,
      {String? givenNodeId, int? givenCapacity, bool isReplacingRoot = false}) {
    var nodeId = "";
    var hasReused = false;

    //Si no me llega un nodeId hay que obtenerlo, reusando uno o creando uno nuevo
    if (givenNodeId == null) {
      (nodeId, hasReused) = _getNextNodeIdWithReuse();
    } else {
      nodeId = givenNodeId;
    }

    var node = BSharpIndexNode.createNode(
        nodeId, level, givenCapacity ?? maxCapacity, leftNode, rightNodes);

    if (!isReplacingRoot) {
      nodesQuantity++;
      notifyObservers(hasReused
          ? NodeReuse(targetId: nodeId)
          : NodeCreation(targetId: nodeId));
    }
    return node;
  }

  BSharpIndexNode<T> _buildRootIndexNode(
      BSharpNode<T> leftNode, List<IndexRecord<T>> rightNodes, int level,
      {bool isReplacingRoot = false}) {
    return _buildIndexNode(leftNode, rightNodes, level,
        givenNodeId: "0-1",
        givenCapacity: rootMaxCapacity,
        isReplacingRoot: isReplacingRoot);
  }

  (String, bool) _getNextNodeIdWithReuse() {
    if (freeNodesIds.isNotEmpty) {
      return (freeNodesIds.removeAt(0), true);
    } else {
      lastNodeId++;
      return (lastNodeId.toString(), false);
    }
  }

  ///Releases a node, adding its id to the free node list
  void _release(BSharpNode<T> node) {
    freeNodesIds.add(node.id);
    nodesQuantity--;
  }

  ///Splits the values of a node in two new nodes
  ///
  ///If the tree has autoincremental keys, it fills the first node to maximum capacity,
  ///leaving the rest of the values in the second node.
  (BSharpSequentialNode<T>, BSharpSequentialNode<T>) _splitRootNodesInTwo(
      BSharpSequentialNode<T> node) {
    if (keysAreAutoincremental) {
      return (
        _buildSequentialNode(node.values.sublist(0, maxCapacity)),
        _buildSequentialNode(node.values.sublist(maxCapacity))
      );
    } else {
      return (
        _buildSequentialNode(node.getFirstHalfOfValues()),
        _buildSequentialNode(node.getLastHalfOfValues())
      );
    }
  }

  IndexRecord<T>? _releaseIndexNodeIfEmpty(BSharpIndexNode<T> indexNode) {
    IndexRecord<T>? result;
    if (indexNode.leftNode.length() == 0 && indexNode.rightNodes.isEmpty) {
      result = indexNode.getParent()!.findIndexRecordById(indexNode.id);
      _release(indexNode);
    }
    indexNode.fixFamilyRelations();
    return result;
  }
}

/// A class that represents an object that manages a node
///
/// It receives a [value] that will be used in any operation over a node, which may be a modification
/// or finding the node in which this value should be.
/// It also receives a [functionToApplyToSequentialNode] to be defined when extending
/// and an optional [functionToApplyToIndexNode] that has a default behavior.
abstract class NodeManager<T extends Comparable<T>> {
  final T value;
  final Function functionToApplyToSequentialNode;
  final Function? functionToApplyToIndexNode;

  NodeManager(this.value, this.functionToApplyToSequentialNode,
      [this.functionToApplyToIndexNode]);
  IndexRecord? applyFunctionToSequentialNode(BSharpSequentialNode<T> node);
  IndexRecord? applyFunctionToIndexNode(
      BSharpIndexNode<T> node, IndexRecord recordToUpdate) {
    IndexRecord? result;
    if (functionToApplyToIndexNode != null) {
      functionToApplyToIndexNode!(node, recordToUpdate);
    }

    return result;
  }
}

/// A class that represents an object that modifies a node
///
/// It applies a function to a sequential or index node, if the node is unbalanced (meaning it's in an
/// underflow or an overflow) after modifiying it, checks if the node is a root and manages this 
/// unbalance.
/// 
/// This class receives several functions on its creation that will be applied on a node modification
/// [isRoot] is used to evaluate if the node is the root of the tree
/// [manageUnbalanceOnSequentialRootNode] will be called if the change in the node produces an unbalance 
/// in a sequential node, that is a root too
/// [manageUnbalanceOnSequentialNode] will be called if the change in the node produces an unbalance 
/// in a sequential node
/// [manageUnbalanceOnIndexRootNode] will be called if the change in the node produces an unbalance 
/// in an index node, that is a root too
/// [manageUnbalanceOnIndexNode] will be called if the change in the node produces an unbalance 
/// in an index node
abstract class NodeModifier<T extends Comparable<T>> extends NodeManager<T> {
  final bool Function(BSharpNode<T>) isRoot;
  final IndexRecord<T>? Function(BSharpSequentialNode<T> node)
      manageUnbalanceOnSequentialRootNode;
  final IndexRecord<T>? Function(BSharpSequentialNode<T> node)
      manageUnbalanceOnSequentialNode;
  final IndexRecord<T>? Function(BSharpIndexNode<T> node)
      manageUnbalanceOnIndexRootNode;
  final IndexRecord<T>? Function(BSharpIndexNode<T> node)
      manageUnbalanceOnIndexNode;

  NodeModifier(
      super.value,
      super.functionToApplyToSequentialNode,
      super.functionToApplyToIndexNode,
      this.isRoot,
      this.manageUnbalanceOnSequentialRootNode,
      this.manageUnbalanceOnSequentialNode,
      this.manageUnbalanceOnIndexRootNode,
      this.manageUnbalanceOnIndexNode);

  @override
  IndexRecord<T>? applyFunctionToSequentialNode(BSharpSequentialNode<T> node) {
    manageValueFoundInNode(node);
    functionToApplyToSequentialNode(node, value);
    IndexRecord<T>? result;
    if (isUnbalanced(node)) {
      if (isRoot(node)) {
        result = manageUnbalanceOnSequentialRootNode(node);
      } else {
        result = manageUnbalanceOnSequentialNode(node);
      }
    }
    return result;
  }

  @override
  IndexRecord<T>? applyFunctionToIndexNode(
      BSharpIndexNode<T> node, IndexRecord recordToUpdate) {
    IndexRecord<T>? result;
    if (functionToApplyToIndexNode != null) {
      functionToApplyToIndexNode!(node, recordToUpdate);

      if (isUnbalanced(node)) {
        if (isRoot(node)) {
          result = manageUnbalanceOnIndexRootNode(node);
        } else {
          result = manageUnbalanceOnIndexNode(node);
        }
      }
    }
    return result;
  }

  void manageValueFoundInNode(BSharpSequentialNode<T> node);

  bool isUnbalanced(BSharpNode<T> node);
}

///  A class that extends NodeModifier, with methods used on the insertion of a value in a node
class NodeValueInserter<T extends Comparable<T>> extends NodeModifier<T> {
  NodeValueInserter(
      super.value,
      super.functionToApplyToSequentialNode,
      super.functionToApplyToIndexNode,
      super.isRoot,
      super.manageUnbalanceOnSequentialRootNode,
      super.manageUnbalanceOnSequentialNode,
      super.manageUnbalanceOnIndexRootNode,
      super.manageUnbalanceOnIndexNode);

  @override
  bool isUnbalanced(BSharpNode<T> node) {
    return node.isOverflowed();
  }

  @override
  void manageValueFoundInNode(BSharpSequentialNode<T> node) {
    if (node.isValueOnNode(value)) {
      logger
          .error(() => "el valor $value ya se encuentra en el nodo ${node.id}");
      throw ElementInsertionException(
          "cant insert the value $value, it's already on the tree");
    }
  }
}

///  A class that extends NodeModifier, with methods used on the removal of a value in a node
class NodeValueRemover<T extends Comparable<T>> extends NodeModifier<T> {
  NodeValueRemover(
      super.value,
      super.functionToApplyToSequentialNode,
      super.functionToApplyToIndexNode,
      super.isRoot,
      super.manageUnbalanceOnSequentialRootNode,
      super.manageUnbalanceOnSequentialNode,
      super.manageUnbalanceOnIndexRootNode,
      super.manageUnbalanceOnIndexNode);

  @override
  bool isUnbalanced(BSharpNode<T> node) {
    return node.isUnderflowed();
  }

  @override
  void manageValueFoundInNode(BSharpSequentialNode<T> node) {
    if (!node.isValueOnNode(value)) {
      throw ElementNotFoundException("Element $value not found in the tree");
    }
  }
}

///  A class that extends NodeManager, with methods used to search for a value in a node
class NodeValueFinder<T extends Comparable<T>> extends NodeManager<T> {
  String? result;

  NodeValueFinder(super.value, super.functionToApplyToSequentialNode);

  @override
  IndexRecord<T>? applyFunctionToSequentialNode(BSharpSequentialNode<T> node) {
    result = functionToApplyToSequentialNode(node);
    return null;
  }
}
