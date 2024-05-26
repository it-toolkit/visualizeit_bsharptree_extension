import 'package:visualizeit_bsharptree_extension/exception/element_insertion_exception.dart';
import 'package:visualizeit_bsharptree_extension/exception/element_not_found_exception.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_transition.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_index_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_sequential_node.dart';
import 'package:visualizeit_extensions/logging.dart';

class BSharpTree<T extends Comparable<T>> {
  BSharpNode<T>? _rootNode;
  final int maxCapacity;
  int nodesQuantity = 0;
  int lastNodeId = 0;

  List<BSharpTreeTransition> transitions = [];

  final logger = Logger("extension.bsharptree.model");

  List<String> freeNodesIds = [];

  BSharpTree(this.maxCapacity);

  BSharpTree._copy(this._rootNode, this.maxCapacity, this.nodesQuantity,
      this.freeNodesIds, this.lastNodeId);

  int get _rootMaxCapacity => (4 * maxCapacity) ~/ 3;
  int get depth => _rootNode?.level ?? 0;

  bool isRoot(BSharpNode<T> node) => node.id == _rootNode?.id;
  List<BSharpTreeTransition> getTransitions() => transitions;

  /// Inserts a new [value] in the B# tree
  ///
  /// [value] must be of a type [T] that implements [Comparable]
  /// If the tree is empty, creates the root node and then inserts [value]
  /// If the value is already on the tree, it throws an [ElementInsertionException]
  ///
  /// May cause the B# tree to split nodes or grow on height or width
  void insert(T value) {
    transitions = [];
    logger.debug(() => "insertando value: $value");
    if (_rootNode == null) {
      _rootNode = _buildRootSequentialNode([value]);
      nodesQuantity = 2;
      lastNodeId = 1;
      transitions
          .add(NodeWritten(targetId: _rootNode!.id, transitionTree: this));
    } else {
      if (_rootNode!.isLevelZero) {
        //el unico nodo del arbol es la raiz
        var node = _rootNode as BSharpSequentialNode<T>;
        node.addToNode(value);
        transitions.addAll([
          NodeRead(targetId: node.id),
          NodeWritten(targetId: _rootNode!.id, transitionTree: this.clone())
        ]);
        if (node.isOverflowed()) {
          //Si se supera la maxima capacidad de la raiz
          transitions.add(
              NodeOverflow(targetId: node.id, transitionTree: this.clone()));
          var leftNode = _buildSequentialNode(node.getFirstHalfOfValues());
          var rightNode = _buildSequentialNode(node.getLastHalfOfValues());
          leftNode.nextNode = rightNode;
          //Crear el nuevo nodo indice raiz que va a reemplazar al nodo secuencia
          var newRoot = _buildRootIndexNode(
              leftNode, [IndexRecord(rightNode.values.first, rightNode)], 1,
              isReplacingRoot: true);

          newRoot.fixFamilyRelations();
          _rootNode = newRoot;
          transitions.addAll([
            NodeWritten(targetId: leftNode.id, transitionTree: this),
            NodeWritten(targetId: rightNode.id),
            NodeWritten(targetId: newRoot.id, transitionTree: this)
          ]);
        }
      } else {
        _insertRecursively(_rootNode, null, value);
      }
    }

    logger.debug(() => _printTree());
  }

  /// Removes a [value] from the B# tree, if it can be found
  ///
  /// [value] must be of a type [T] that implements [Comparable]
  /// If the value is not found on the tree, it throws an [ElementNotFoundException]
  ///
  /// May cause the tree to fuse nodes and shrink in height or width
  void remove(T value) {
    transitions = [];
    logger.debug(() => "eliminando value: $value");
    if (_rootNode != null) {
      _removeRecursively(_rootNode!, value);
    }
    logger.debug(() => _printTree());
  }

  /// Prints every sequential node, with their values
  ///
  /// It traverse all the tree until it founds the smallest value, then uses the pointers to the next node to
  /// print every node id and values
  void traverse() {
    if (_rootNode != null) {
      //Encontramos el nodo hoja de menores valores (el de mas a la izquierda)
      var node = _rootNode!;
      while (!node.isLevelZero) {
        node = (node as BSharpIndexNode<T>).leftNode;
      }
      //Recorremos los nodos hoja en forma secuencial
      BSharpSequentialNode<T>? traverseNode = node as BSharpSequentialNode<T>;
      while (traverseNode != null) {
        print("${traverseNode.id}:${traverseNode.values}");
        traverseNode = traverseNode.nextNode;
      }
    } else {
      print("no values to show");
    }
  }

  Map<int, List<BSharpNode<T>>> getAllNodesByLevel() {
    Map<int, List<BSharpNode<T>>> allNodesMap = {};
    if (_rootNode != null) {
      addNodesByLevelRecursively(allNodesMap, _rootNode!);
    } else {
      allNodesMap = {0: List.empty()};
    }

    return allNodesMap;
  }

  void addNodesByLevelRecursively(
      Map<int, List<BSharpNode<T>>> nodesMap, BSharpNode<T> current) {
    List<BSharpNode<T>>? nodesList = nodesMap[current.level];
    if (nodesList != null) {
      nodesList.add(current);
    } else {
      nodesMap.putIfAbsent(current.level, () => [current]);
    }
    if (!current.isLevelZero) {
      var node = current as BSharpIndexNode<T>;
      addNodesByLevelRecursively(nodesMap, node.leftNode);
      for (var indexRecord in node.rightNodes) {
        addNodesByLevelRecursively(nodesMap, indexRecord.rightNode);
      }
    }
  }

  /// Inserts recursively a [value] in the B# tree
  ///
  /// Using the root node as the starting point, finds recursively the correct sequential node to insert the value,
  /// then goes back to update every node necesary in the recursion
  /// If the value is already on the sequential node, it throws a [ElementInsertionException]
  IndexRecord<T>? _insertRecursively(
      BSharpNode<T>? current, BSharpIndexNode<T>? parent, T value) {
    if (current != null && current.isLevelZero) {
      // Encontré el nodo secuencial donde deberia insertar
      var node = current as BSharpSequentialNode<T>;
      transitions.add(NodeRead(targetId: node.id));
      logger.debug(() => "nodo ${node.id} es donde se va a insertar el valor");
      if (node.isValueOnNode(value)) {
        logger.error(
            () => "el valor $value ya se encuentra en el nodo ${node.id}");
        throw ElementInsertionException(
            "cant insert the value $value, it's already on the tree");
      }
      node.addToNode(value);
      transitions
          .add(NodeWritten(targetId: node.id, transitionTree: this.clone()));
      if (node.isOverflowed()) {
        //Si se supera la maxima capacidad del nodo
        transitions
            .add(NodeOverflow(targetId: node.id, transitionTree: this.clone()));

        var hasBalancedWithSibling =
            _tryToBalanceSequentialNodesWithSibling(node);

        if (!hasBalancedWithSibling) {
          // Si llegué acá no pude rebalancear con ninguno de los hermanos porque estan completos, tengo que unir
          // ambos nodos, crear uno nuevo en el medio y repartir las claves en 3
          return _splitSequentialNodeWithAnySibling(node);
        }
      }
    } else {
      var node = current as BSharpIndexNode<T>;
      transitions.add(NodeRead(targetId: node.id));
      var nextNode = node.findNextNodeForKey(value);
      IndexRecord<T>? promotedKey =
          _insertRecursively(nextNode, current, value);
      //Intento agregar la key en el nodo
      if (promotedKey != null) {
        logger.debug(() =>
            "insertando key promocionada: ${promotedKey.key} en nodo ${node.id}");
        node.addIndexRecordToNode(promotedKey);
        node.fixFamilyRelations();
        transitions
            .add(NodeWritten(targetId: node.id, transitionTree: this.clone()));
        if (node.isOverflowed()) {
          if (!isRoot(node)) {
            transitions.add(
                NodeOverflow(targetId: node.id, transitionTree: this.clone()));
            var hasBalancedWithSibling =
                _tryToBalanceOverflowedIndexNodeWithSiblings(node);
            if (!hasBalancedWithSibling) {
              //no puedo rotar ni a izq ni a derecha, tengo que juntar las claves y dividir el nodo en 3
              return _splitSiblingIndexNodeWithAnySibling(node);
            }
          } else {
            //current es la raiz y tengo que dividirla en dos
            transitions.add(
                NodeOverflow(targetId: node.id, transitionTree: this.clone()));
            //Si se supera la maxima capacidad de la raiz
            _splitIndexRootNode(node);
          }
        }
      }
    }
    return null;
  }

  /// Removes recursively a [value] in the B# tree
  ///
  /// Using the root node as the starting point, finds recursively the correct sequential node to remove the value,
  /// then goes back to update every node necesary in the recursion
  /// If the value is not on the sequential node, it throws a [ElementNotFoundException]
  IndexRecord<T>? _removeRecursively(BSharpNode<T> current, T value) {
    if (current.isLevelZero) {
      var node = current as BSharpSequentialNode<T>;
      transitions.add(NodeRead(targetId: node.id));
      if (node.values.contains(value)) {
        logger.debug(() =>
            "el valor a remover '$value' se encontró en el nodo con id: ${node.id}");
        node.removeValue(value);
        transitions
            .add(NodeWritten(targetId: node.id, transitionTree: this.clone()));
        if (!isRoot(node) && node.isUnderflowed()) {
          transitions.add(
              NodeUnderflow(targetId: node.id, transitionTree: this.clone()));
          var hasBalancedWithSibling =
              _tryToBalanceUnderflowedSequentialNodeWithSiblings(node);

          if (!hasBalancedWithSibling) {
            // Si llegué acá no pude rebalancear con ninguno de los hermanos porque estan completos, tengo que unir
            // ambos nodos
            return _fuseSequentialNodeWithAnySibling(node);
          }
        }
      } else {
        throw ElementNotFoundException("Element $value not found in the tree");
      }
    } else {
      var node = current as BSharpIndexNode<T>;
      transitions.add(NodeRead(targetId: node.id));
      BSharpNode<T> nextNode = node.findNextNodeForKey(value);
      IndexRecord<T>? indexRecordToUpdate = _removeRecursively(nextNode, value);

      if (indexRecordToUpdate != null) {
        logger.debug(() =>
            "index record a remover con id de rightNode: ${indexRecordToUpdate.rightNode.id}");
        node.rightNodes.removeWhere((indexRecord) =>
            indexRecord.rightNode.id == indexRecordToUpdate.rightNode.id);
        if (node.parent != null && node.isUnderflowed()) {
          transitions.add(
              NodeWritten(targetId: node.id, transitionTree: this.clone()));
          transitions.add(
              NodeUnderflow(targetId: node.id, transitionTree: this.clone()));
          var hasBalancedWithSibling =
              _tryToBalanceUnderflowedIndexNodeWithSiblings(node);
          if (!hasBalancedWithSibling) {
            return _fuseIndexNodesWithAnySibling(node);
          }
        } else {
          if (node.parent == null && node.length() == 0) {
            BSharpNode<T> leftChild = node.leftNode;
            if (node.leftNode.isLevelZero) {
              //Hay que convertir el nodo raiz de un index node a un sequential node
              leftChild = leftChild as BSharpSequentialNode<T>;
              _rootNode = _buildRootSequentialNode(leftChild.values,
                  isReplacingRoot: true);
            } else {
              leftChild = leftChild as BSharpIndexNode<T>;
              node.leftNode = leftChild.leftNode;
              node.rightNodes = leftChild.rightNodes;
              node.level = node.level - 1;
              node.fixFamilyRelations();
            }
            _release(leftChild);
            transitions.add(NodeRelease(targetId: leftChild.id));
          } else {
            node.fixFamilyRelations();
          }

          transitions.add(NodeWritten(targetId: node.id, transitionTree: this));
        }
      }
    }
    return null;
  }

  String find(T value) {
    transitions = [];
    var modifier = NodeSearcher<String, T>(getNodeId);
    if (_rootNode != null) {
      _searchTreeAndApplyFunctionToNode(_rootNode!, value, modifier);
    }
    return modifier.result!;
  }

  void _searchTreeAndApplyFunctionToNode(
      BSharpNode<T> current, T value, NodeModifier modifier) {
    transitions.add(NodeRead(targetId: current.id));
    //Base case of the recursion
    if (current.isLevelZero) {
      var sequentialNode = current as BSharpSequentialNode<T>;
      modifier.applyFunctionToNode(sequentialNode);
    } else {
      var indexNode = current as BSharpIndexNode<T>;
      var nextNodeForRecursion = indexNode.findNextNodeForKey(value);
      _searchTreeAndApplyFunctionToNode(nextNodeForRecursion, value, modifier);
    }
  }

  String getNodeId(BSharpNode node) {
    transitions.add(NodeFound(targetId: node.id));
    return node.id;
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

    //Seteamos el nuevo nodo como la raiz
    transitions.addAll([
      NodeWritten(targetId: newLeftNode.id),
      NodeWritten(targetId: newRightNode.id),
      NodeWritten(
          targetId: node.id,
          transitionTree: this.clone()) //TODO ver si va esto aca
    ]);
  }

  /// Balances index nodes, taking a node (and its children) from the right sibling and adding a node on the left sibling
  ///
  /// Using the [parent] key and the [rightSiblingNode] left children creates a new [IndexRecord] to add to the left sibling
  /// then removes the first [IndexRecord] of the right sibling, to use its node as the new left children of the node.
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
    transitions.addAll([
      NodeBalancing(
          targetId: leftSiblingNode.id,
          firstOptionalTargetId: rightSiblingNode.id,
          transitionTree: this.clone()),
      NodeWritten(targetId: leftSiblingNode.id),
      NodeWritten(targetId: rightSiblingNode.id, transitionTree: this.clone())
    ]);
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

    transitions.addAll([
      NodeBalancing(
          targetId: leftSiblingNode.id,
          firstOptionalTargetId: rightSiblingNode.id,
          transitionTree: this.clone()),
      NodeWritten(targetId: leftSiblingNode.id),
      NodeWritten(targetId: rightSiblingNode.id, transitionTree: this.clone())
    ]);
  }

  /// Taking all the index records of an index [node] and its [siblingNode], and adding the [IndexRecord] of the siblingNode,
  /// splits these index records in 3 nodes, adding a new node in the middle of [node] and [siblingNode], and promotes
  /// a new [IndexRecord] to be added to the parent node
  IndexRecord<T> _splitSiblingIndexNodes(BSharpIndexNode<T> node,
      BSharpIndexNode<T> siblingNode, BSharpIndexNode<T> parent) {
    transitions.add(
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

    transitions.addAll([
      NodeWritten(targetId: newNode.id),
      NodeWritten(targetId: node.id),
      NodeWritten(targetId: siblingNode.id, transitionTree: this.clone())
    ]);

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
      siblingRecord.key = siblingNode.firstKey();
    }
    transitions.addAll([
      NodeBalancing(
          targetId: node.id,
          firstOptionalTargetId: siblingNode.id,
          transitionTree: this),
      NodeWritten(targetId: node.id),
      NodeWritten(targetId: siblingNode.id, transitionTree: this.clone())
    ]);
  }

  /// Taking all the keys records of a sequential [node] and its [siblingNode], splits the keys in 3 nodes,
  /// adding a new node in the middle of [node] and [siblingNode], and promotes a new [IndexRecord] to be added
  /// to the parent node
  IndexRecord<T> _splitSiblingSequentialNodes(BSharpSequentialNode<T> node,
      BSharpSequentialNode<T> siblingNode, BSharpIndexNode<T> parentNode) {
    transitions.add(
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
      siblingRecord.key = siblingNode.firstKey();
    }
    transitions.addAll([
      NodeWritten(targetId: newNode.id, transitionTree: this.clone())
    ]); //TODO acá se deberian escribir tambien los otros nodos
    return IndexRecord(newNode.firstKey(), newNode);
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
      nodeRecord.key = node.firstKey();
    }

    _release(siblingNode);

    transitions.addAll([
      NodeFusion(targetId: node.id, firstOptionalTargetId: siblingNode.id),
      NodeWritten(targetId: node.id),
      NodeRelease(targetId: siblingNode.id, transitionTree: this.clone())
    ]);

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

    transitions.addAll([
      NodeFusion(targetId: node.id, firstOptionalTargetId: siblingNode.id),
      NodeWritten(targetId: node.id),
      NodeRelease(targetId: siblingNode.id)
    ]);

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
    leftSiblingNode.nextNode = rightSiblingNode; //TODO chequear los nextNode

    if (leftSiblingRecord != null) {
      leftSiblingRecord.key = leftSiblingNode.firstKey();
    }

    if (rightSiblingRecord != null) {
      rightSiblingRecord.key = rightSiblingNode.firstKey();
    }

    _release(node);

    transitions.addAll([
      NodeFusion(
          targetId: node.id,
          firstOptionalTargetId: leftSiblingNode.id,
          secondOptionalTargetId: rightSiblingNode.id),
      NodeWritten(targetId: leftSiblingNode.id),
      NodeWritten(targetId: rightSiblingNode.id),
      NodeRelease(
          targetId: node.id,
          transitionTree: this.clone()) //TODO CHEQUEAR SI VA ACA
    ]);

    return nodeRecord;
  }

  /// Tries to balance a sequential [node] with its right sibling, using the [capacityCheckFunction].
  /// If its unable to do it, then tries the same with the left sibling.
  /// If it was able to balance with any of the siblings, returns true. Otherwise, returns false.
  bool _tryToBalanceSequentialNodesWithSibling(BSharpSequentialNode<T> node) {
    var rightSiblingNode = node.getRightSibling();

    if (rightSiblingNode != null) {
      transitions.add(NodeRead(targetId: rightSiblingNode.id));
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
      transitions.add(NodeRead(targetId: leftSiblingNode.id));
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
      transitions.add(NodeRead(targetId: rightSiblingNode.id));
      if (rightSiblingNode.isOverMinCapacity()) {
        _balanceIndexNodesRightToLeft(
            node, rightSiblingNode, node.getParent()!);
        return true;
      }
    }
    logger.debug(() => "no se pudo balancear con hermano derecho");

    var leftSiblingNode = node.getLeftSibling();

    if (leftSiblingNode != null) {
      transitions.add(NodeRead(targetId: leftSiblingNode.id));
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
      transitions.add(NodeRead(targetId: rightSiblingNode.id));
      if (rightSiblingNode.hasCapacityLeft()) {
        _balanceIndexNodesLeftToRight(
            node, rightSiblingNode, node.getParent()!);
        return true;
      }
    }
    logger.debug(() => "no se pudo balancear con hermano derecho");

    var leftSiblingNode = node.getLeftSibling();
    if (leftSiblingNode != null) {
      transitions.add(NodeRead(targetId: leftSiblingNode.id));
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
      centerSiblingRecord.key = centerSiblingNode.firstKey();
    }

    if (rightSiblingRecord != null) {
      rightSiblingRecord.key = rightSiblingNode.firstKey();
    }

    transitions.addAll([
      NodeBalancing(
          targetId: leftSiblingNode.id,
          firstOptionalTargetId: centerSiblingNode.id,
          secondOptionalTargetId: rightSiblingNode.id,
          transitionTree: this.clone()),
      NodeWritten(targetId: leftSiblingNode.id),
      NodeWritten(targetId: centerSiblingNode.id),
      NodeWritten(targetId: rightSiblingNode.id, transitionTree: this.clone())
    ]);
  }

  bool _tryToBalanceUnderflowedSequentialNodeWithSiblings(
      BSharpSequentialNode<T> node) {
    // si el nodo no tiene hermano derecho, tengo que tratar de balancear con su hermano izquierdo
    // y el izquierdo del izquierdo, si existe

    var rightSiblingNode = node.getRightSibling();
    if (rightSiblingNode != null) {
      transitions.add(NodeRead(targetId: rightSiblingNode.id));
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
      transitions.add(NodeRead(targetId: leftSiblingNode.id));
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
      transitions.add(NodeRead(targetId: leftLeftSibling.id));
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
      transitions.add(NodeRead(targetId: rightRightSibling.id));
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

  BSharpTree<T> clone() {
    BSharpNode<T>? rootNode;
    if (_rootNode != null) {
      rootNode = _cloneRecursively(_rootNode!);
    }

    return BSharpTree<T>._copy(rootNode, maxCapacity, nodesQuantity,
        List.of(freeNodesIds), lastNodeId);
  }

  BSharpNode<T> _cloneRecursively(BSharpNode<T> node) {
    if (!node.isLevelZero) {
      var indexNode = node as BSharpIndexNode<T>;

      var leftNode = _cloneRecursively(indexNode.leftNode);
      var rightNodes = indexNode.rightNodes
          .map((indexRecord) => IndexRecord(
              indexRecord.key, _cloneRecursively(indexRecord.rightNode)))
          .toList();
      return indexNode.copyWith(leftNode: leftNode, rightNodes: rightNodes);
    } else {
      var sequentialNode = node as BSharpSequentialNode<T>;
      return sequentialNode.copy();
    }
  }

  /*Map toJson() {
    Map rootNodeMap = _rootNode != null ? _rootNode!.toJson() : null;
    return {
      'maxCapacity': maxCapacity,
      'nodesQuantity': nodesQuantity,
      'rootNode': rootNodeMap
    };
  }*/

  BSharpSequentialNode<T> _buildSequentialNode(List<T> values,
      {String? givenNodeId, int? givenCapacity, bool isReplacingRoot = false}) {
    var nodeId = "";
    var hasReused = false;

    //Si no me llega un nodeId hay que obtenerlo, reusando uno o creando uno nuevo
    if (givenNodeId == null) {
      (nodeId, hasReused) = getNextNodeIdWithReuse();
    } else {
      nodeId = givenNodeId;
    }

    var node = BSharpSequentialNode.createNode(
        nodeId, 0, givenCapacity ?? maxCapacity, values);

    // Si no se está reemplazando la raiz, es un nuevo nodo hoja que hay que agregar al arbol
    if (!isReplacingRoot) {
      nodesQuantity++;
      transitions.add(hasReused
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
        givenCapacity: _rootMaxCapacity,
        isReplacingRoot: isReplacingRoot);
  }

  BSharpIndexNode<T> _buildIndexNode(
      BSharpNode<T> leftNode, List<IndexRecord<T>> rightNodes, int level,
      {String? givenNodeId, int? givenCapacity, bool isReplacingRoot = false}) {
    var nodeId = "";
    var hasReused = false;

    //Si no me llega un nodeId hay que obtenerlo, reusando uno o creando uno nuevo
    if (givenNodeId == null) {
      (nodeId, hasReused) = getNextNodeIdWithReuse();
    } else {
      nodeId = givenNodeId;
    }

    var node = BSharpIndexNode.createNode(
        nodeId, level, givenCapacity ?? maxCapacity, leftNode, rightNodes);

    if (!isReplacingRoot) {
      nodesQuantity++;
      transitions.add(hasReused
          ? NodeReuse(targetId: nodeId)
          : NodeCreation(targetId: nodeId));
    }
    return node;
  }

  BSharpSequentialNode<T> _buildRootSequentialNode(List<T> values,
      {bool isReplacingRoot = false}) {
    return _buildSequentialNode(values,
        givenCapacity: _rootMaxCapacity,
        givenNodeId: "0-1",
        isReplacingRoot: isReplacingRoot);
  }

  (String, bool) getNextNodeIdWithReuse() {
    if (freeNodesIds.isNotEmpty) {
      return (freeNodesIds.removeAt(0), true);
    } else {
      lastNodeId++;
      return (lastNodeId.toString(), false);
    }
  }

  void _release(BSharpNode<T> node) {
    freeNodesIds.add(node.id);
    nodesQuantity--;
  }
}

abstract class NodeModifier<S, T extends Comparable<T>> {
  bool changedStructure = false;
  S? result;
  Function functionToApply;

  NodeModifier(this.functionToApply);

  void applyFunctionToNode(BSharpNode<T> node);

  S? getResult() {
    return result;
  }
}

class NodeSearcher<S, T extends Comparable<T>> extends NodeModifier<S, T> {
  NodeSearcher(super.functionToApply);

  @override
  void applyFunctionToNode(BSharpNode<T> node) {
    result = functionToApply(node);
  }
}
