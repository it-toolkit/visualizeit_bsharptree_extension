import 'package:flutter/material.dart';
import 'package:visualizeit_bsharptree_extension/exception/element_insertion_exception.dart';
import 'package:visualizeit_bsharptree_extension/exception/element_not_found_exception.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_index_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_sequential_node.dart';
import 'package:visualizeit_bsharptree_extension/model/transitions/bsharp_tree_transition.dart';

class BSharpTree<T extends Comparable<T>> with ChangeNotifier {
  BSharpNode<T>? _rootNode;
  final int maxCapacity;
  int nodesQuantity = 0;
  List<BSharpTreeTransition> transitions = [];

  BSharpTree(this.maxCapacity);

  int get _rootMaxCapacity => (4 * maxCapacity) ~/ 3;
  int get _minCapacity => (2 * maxCapacity) ~/ 3;
  int get depth => _rootNode?.level ?? 0;

  bool _isNodeOverflowed(BSharpNode<T> node) => node.length() > maxCapacity;
  bool _hasCapacityLeft(BSharpNode<T>? node) =>
      node != null && node.length() < maxCapacity;

  bool isNodeUnderflowed(BSharpNode<T> node) => node.length() < _minCapacity;
  bool isOverMinCapacity(BSharpNode<T>? node) =>
      node != null && node.length() > _minCapacity;

  bool _isRootOverflowed(BSharpNode node) => node.length() > _rootMaxCapacity;
  bool isRoot(BSharpNode<T> node) => node.id == _rootNode?.id;

  /// Inserts a new [value] in the B# tree
  ///
  /// [value] must be of a type [T] that implements [Comparable]
  /// If the tree is empty, creates the root node and then inserts [value]
  /// If the value is already on the tree, it throws an [ElementInsertionException]
  ///
  /// May cause the B# tree to split nodes or grow on height or width
  void insert(T value) {
    print("insertando value: $value");
    if (_rootNode == null) {
      _rootNode = BSharpSequentialNode(nodesQuantity, 0, value);
      notifyListeners();
      nodesQuantity++;
      return;
    }

    //el unico nodo del arbol es la raiz
    if (_rootNode!.isLevelZero) {
      var node = _rootNode as BSharpSequentialNode<T>;
      node.addToNode(value);
      node.notifyListeners();

      //Si se supera la maxima capacidad de la raiz
      if (_isRootOverflowed(node)) {
        transitions.add(NodeOverflow(node.id.toString()));
        transitions.add(NodeSplit(node.id.toString()));

        var rightNode = BSharpSequentialNode.createNode(
            nodesQuantity++, 0, node.values.sublist(node.length() ~/ 2));

        transitions.add(NodeCreation(rightNode.id.toString()));

        node.values = node.values.sublist(0, node.length() ~/ 2);
        node.nextNode = rightNode;
        //Crear el nuevo nodo con la key más chica del derecho
        var newRoot = BSharpIndexNode<T>(
            nodesQuantity++, 1, rightNode.values.first, node, rightNode);
        newRoot.fixFamilyRelations();
        transitions.add(NodeCreation(newRoot.id.toString()));

        _rootNode = newRoot;
      }
    } else {
      _insertRecursively(_rootNode, null, value);
    }
  }

  /// Removes a [value] from the B# tree, if it can be found
  ///
  /// [value] must be of a type [T] that implements [Comparable]
  /// If the value is not found on the tree, it throws an [ElementNotFoundException]
  ///
  /// May cause the tree to fuse nodes and shrink in height or width
  void remove(T value) {
    print("eliminando value: $value");
    if (_rootNode != null) {
      _removeRecursively(_rootNode!, value);
    }
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
      //allNodesMap.putIfAbsent(_rootNode!.level, () => [_rootNode!]);
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
    //nodesMap.putIfAbsent(current.level, () => nodesMap[current.level] = );
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
      if (node.isValueOnNode(value)) {
        throw ElementInsertionException(
            "cant insert the value $value, it's already on the tree");
      }
      node.addToNode(value);
      if (_isNodeOverflowed(node)) {
        transitions.add(NodeOverflow(node.id.toString()));
        //Si se supera la maxima capacidad del nodo
        print("Supera la capacidad del nodo al insertar value: $value");
        if (parent != null) {
          //TODO creo que parent nunca es null acá porque se eliminó esa posibilidad antes

          var hasBalancedWithSibling =
              _tryToBalanceSequentialNodesWithSibling(node, _hasCapacityLeft);

          if (!hasBalancedWithSibling) {
            // Si llegué acá no pude rebalancear con ninguno de los hermanos porque estan completos, tengo que unir
            // ambos nodos, crear uno nuevo en el medio y repartir las claves en 3
            return _splitSequentialNodeWithAnySibling(node);
          }
        }
      }
    } else {
      var node = current as BSharpIndexNode<T>;
      var nextNode = node.findNextNodeForKey(value);
      IndexRecord<T>? promotedKey =
          _insertRecursively(nextNode, current, value);
      //Intento agregar la key en el nodo
      if (promotedKey != null) {
        print("key promocionada: ${promotedKey.key}");
        node.addIndexRecordToNode(promotedKey);
        node.fixFamilyRelations();
        if (_isNodeOverflowed(node)) {
          //Se supera la maxima capacidad del nodo
          print("la promoción hace desbordar el nodo indice");

          if (!isRoot(node)) {
            var hasBalancedWithSibling =
                _tryToBalanceOverflowedIndexNodeWithSiblings(node);
            if (!hasBalancedWithSibling) {
              //no puedo rotar ni a izq ni a derecha, tengo que juntar las claves y dividir el nodo en 3
              return _splitSiblingIndexNodeWithAnySibling(node);
            }
          } else {
            //current es la raiz y tengo que dividirla en dos
            if (_isRootOverflowed(node)) {
              //Si se supera la maxima capacidad de la raiz
              print(
                  "el nodo indice es la raíz, hay que realizar un spliteo del nodo raíz");
              _splitIndexRootNode(node);
            }
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
      if (node.values.contains(value)) {
        print(
            "el valor a remover '$value' se encontró en el nodo con id: ${node.id}");
        node.removeValue(value);
        if (!isRoot(node) && isNodeUnderflowed(node)) {
          print("el nodo tiene menos valores que la capacidad minima");

          //var hasBalancedWithSibling = _tryToBalanceSequentialNodesWithSibling(node, isOverMinCapacity);

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
      BSharpNode<T> nextNode = node.findNextNodeForKey(value);
      IndexRecord<T>? indexRecordToUpdate = _removeRecursively(nextNode, value);

      if (indexRecordToUpdate != null) {
        print(
            "index record a remover con id de rightNode: ${indexRecordToUpdate.rightNode.id}");
        node.rightNodes.removeWhere((indexRecord) =>
            indexRecord.rightNode.id == indexRecordToUpdate.rightNode.id);

        if (node.parent != null && isNodeUnderflowed(node)) {
          var hasBalancedWithSibling =
              _tryToBalanceUnderflowedIndexNodeWithSiblings(node);
          if (!hasBalancedWithSibling) {
            return _fuseIndexNodesWithAnySibling(node);
          }
        } else {
          if (node.parent == null && node.length() == 0) {
            _rootNode = node.leftNode;
            _rootNode!.parent = null;
            _rootNode!.leftSibling = null;
            _rootNode!.rightSibling = null;
          } else {
            node.fixFamilyRelations();
          }
        }
      }
    }
    return null;
  }

  /// Splits the root [node] (when it's an index node)
  ///
  /// This method is called when the root is over its max capacity
  /// It takes all the root childrens and creates a new sibling and a new root node. Then it distributes the children between
  /// the new sibling and the former root node.
  void _splitIndexRootNode(BSharpIndexNode<T> node) {
    var recordToPromote = node.rightNodes.elementAt(node.length() ~/ 2);
    var newSiblingNode = BSharpIndexNode<T>.createNode(
        nodesQuantity++,
        node.level,
        recordToPromote.rightNode,
        node.rightNodes.sublist((node.length() ~/ 2) + 1));
    print("creando nodo: ${newSiblingNode.id}");
    node.rightNodes = node.rightNodes.sublist(0, node.length() ~/ 2);

    //Crear el nuevo nodo con la key más chica del derecho
    var bSharpIndexNode = BSharpIndexNode<T>(nodesQuantity++, node.level + 1,
        recordToPromote.key, node, newSiblingNode);
    print("creando nodo: ${bSharpIndexNode.id}");

    newSiblingNode.fixFamilyRelations();
    node.fixFamilyRelations();
    bSharpIndexNode.fixFamilyRelations();

    //Seteamos el nuevo nodo como la raiz
    _rootNode = bSharpIndexNode;
  }

  /// Balances index nodes, taking a node (and its children) from the right sibling and adding a node on the left sibling
  ///
  /// Using the [parent] key and the [rightSiblingNode] left children creates a new [IndexRecord] to add to the left sibling
  /// then removes the first [IndexRecord] of the right sibling, to use its node as the new left children of the node.
  /// Lastly, updates the right sibling index record with the new smallest key.
  void _balanceIndexNodesRightToLeft(BSharpIndexNode<T> leftSiblingNode,
      BSharpIndexNode<T> rightSiblingNode, BSharpIndexNode<T> parent) {
    print(
        "balanceando index nodes de derecha a izquierda con ids: ${leftSiblingNode.id} y ${rightSiblingNode.id}");
    var rightSiblingRecord = parent.findIndexRecordById(rightSiblingNode.id);
    var smallestRecordFromRight = rightSiblingNode.rightNodes.removeAt(0);

    var newIndexRecord =
        IndexRecord(rightSiblingRecord!.key, rightSiblingNode.leftNode);
    leftSiblingNode.addIndexRecordToNode(newIndexRecord);
    rightSiblingNode.leftNode = smallestRecordFromRight.rightNode;
    rightSiblingRecord.key = smallestRecordFromRight.key;

    leftSiblingNode.fixFamilyRelations();
    rightSiblingNode.fixFamilyRelations();
  }

  /// Balances index nodes, taking a node (and its children) from the left sibling and adding a node on the right sibling
  ///
  /// Using the [parent] key and the [rightSiblingNode] left children creates a new [IndexRecord] to add to the right sibling
  /// then removes the last [IndexRecord] of the left sibling, to use its node as the new left children of the node.
  /// /// Lastly, updates the right sibling index record with the new smallest key.
  void _balanceIndexNodesLeftToRight(BSharpIndexNode<T> leftSiblingNode,
      BSharpIndexNode<T> rightSiblingNode, BSharpIndexNode<T> parent) {
    print(
        "balanceando index nodes de izq a derecha con ids: ${leftSiblingNode.id} y ${rightSiblingNode.id}");
    var rightSiblingRecord = parent.findIndexRecordById(rightSiblingNode.id);
    var biggestRecordFromLeft = leftSiblingNode.rightNodes.removeLast();

    var newIndexRecord =
        IndexRecord(rightSiblingRecord!.key, rightSiblingNode.leftNode);
    rightSiblingNode.addIndexRecordToNode(newIndexRecord);
    rightSiblingNode.leftNode = biggestRecordFromLeft.rightNode;
    rightSiblingRecord.key = biggestRecordFromLeft.key;

    leftSiblingNode.fixFamilyRelations();
    rightSiblingNode.fixFamilyRelations();
  }

  /// Taking all the index records of an index [node] and its [siblingNode], and adding the [IndexRecord] of the siblingNode,
  /// splits these index records in 3 nodes, adding a new node in the middle of [node] and [siblingNode], and promotes
  /// a new [IndexRecord] to be added to the parent node
  IndexRecord<T> _splitSiblingIndexNodes(BSharpIndexNode<T> node,
      BSharpIndexNode<T> siblingNode, BSharpIndexNode<T> parent) {
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

    var newNode = BSharpIndexNode<T>.createNode(
        nodesQuantity++,
        node.level,
        secondPromotedIndexRecord.rightNode,
        allIndexRecords.sublist(((allIndexRecords.length * 2) ~/ 3) + 1));
    print("creando nodo: ${newNode.id}");

    node.fixFamilyRelations();
    siblingNode.fixFamilyRelations();
    newNode.fixFamilyRelations();

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
  }

  /// Taking all the keys records of a sequential [node] and its [siblingNode], splits the keys in 3 nodes,
  /// adding a new node in the middle of [node] and [siblingNode], and promotes a new [IndexRecord] to be added
  /// to the parent node
  IndexRecord<T> _splitSiblingSequentialNodes(BSharpSequentialNode<T> node,
      BSharpSequentialNode<T> siblingNode, BSharpIndexNode<T> parentNode) {
    transitions.add(NodeSplit(node.id.toString()));
    var siblingRecord = parentNode.findIndexRecordById(siblingNode.id);
    var allKeys = node.values + siblingNode.values;
    allKeys.sort();
    node.values = allKeys.sublist(0, allKeys.length ~/ 3);

    var newNode = BSharpSequentialNode<T>.createNode(nodesQuantity++, 0,
        allKeys.sublist(allKeys.length ~/ 3, (allKeys.length * 2) ~/ 3));
    transitions.add(NodeCreation(newNode.id.toString()));
    newNode.nextNode = siblingNode;
    node.nextNode = newNode;

    siblingNode.values = allKeys.sublist((allKeys.length * 2) ~/ 3);
    if (siblingRecord != null) {
      siblingRecord.key = siblingNode.firstKey();
    }
    return IndexRecord(newNode.firstKey(), newNode);
  }

  /// Prints all the nodes info from the tree, starting from the root
  void printTree() {
    if (_rootNode != null) {
      var depth = 0;
      _printNode(_rootNode!, depth);
    }
  }

  /// Prints a single node info and recursively calls itself to print all the children's node info
  void _printNode(BSharpNode<T> node, int depth) {
    String padding = "${"--" * depth}>";
    String nodeId = "${node.id}".padRight(2);
    if (!node.isLevelZero) {
      var indexNode = node as BSharpIndexNode<T>;
      print(
          "$padding$nodeId: ${indexNode.leftNode.id}|${indexNode.rightNodes} - parent: ${indexNode.getParent()?.id}, leftSibling: ${indexNode.getLeftSibling()?.id}, rightSibling: ${indexNode.getRightSibling()?.id}");
      _printNode(indexNode.leftNode, ++depth);
      for (var e in indexNode.rightNodes) {
        _printNode(e.rightNode, depth);
      }
    } else {
      var sequentialNode = node as BSharpSequentialNode<T>;
      print(
          "$padding$nodeId: ${sequentialNode.values} - parent: ${node.getParent()?.id}, leftSibling: ${node.getLeftSibling()?.id}, rightSibling: ${node.getRightSibling()?.id}");
    }
  }

  /// Fuses the keys of a sequential [node] and its [siblingNode], and sets all the keys in the [node]
  ///
  /// Returns the [IndexRecord] of the [siblingNode] to be removed from the parent node
  IndexRecord<T>? _fuseSiblingSequentialNodes(BSharpSequentialNode<T> node,
      BSharpSequentialNode<T> siblingNode, BSharpIndexNode<T> parent) {
    print("fusionando nodos con ids: ${node.id} y ${siblingNode.id}");
    var siblingRecord = parent.findIndexRecordById(siblingNode.id);
    var nodeRecord = parent.findIndexRecordById(node.id);
    var allKeys = node.values + siblingNode.values;
    allKeys.sort();

    node.values = allKeys;
    node.nextNode = siblingNode.nextNode;
    if (nodeRecord != null) {
      nodeRecord.key = node.firstKey();
    }

    return siblingRecord;
  }

  /// Fuses the index records of an index [node] and its [siblingNode], and sets all these index records in the [node]
  ///
  /// Returns the [IndexRecord] of the [siblingNode] to be removed from the parent node
  IndexRecord<T>? _fuseSiblingIndexNodes(BSharpIndexNode<T> node,
      BSharpIndexNode<T> siblingNode, BSharpIndexNode<T> parent) {
    print("fusionando index nodes con ids: ${node.id} y ${siblingNode.id}");
    var siblingRecord = parent.findIndexRecordById(siblingNode.id);

    var newIndexRecord = IndexRecord(siblingRecord!.key, siblingNode.leftNode);

    node.addIndexRecordToNode(newIndexRecord);
    for (var nodeToMove in siblingNode.rightNodes) {
      node.addIndexRecordToNode(nodeToMove);
    }
    node.fixFamilyRelations();

    return siblingRecord;
  }

  /// Inserts a [listOfValues] into the tree, one by one
  void insertAll(List<T> listOfValues) {
    print("values to insert: $listOfValues");
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
      print("fusionando node con hermanos derechos e izquierdo");
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
          node, rightSiblingNode, rightSiblingNode.getRightSibling()!);
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

    print("fusionando sequential node con hermano izquierdo");
    return _fuseSiblingSequentialNodes(
        node.getLeftSibling()!, node, node.getParent()!);
  }

  IndexRecord<T>? _fuseSequentialNodeWithTwoSiblings(
      BSharpSequentialNode<T> node,
      BSharpSequentialNode<T> leftSiblingNode,
      BSharpSequentialNode<T> rightSiblingNode) {
    print(
        "fusionando nodos con id: ${node.id} con sus hermanos ${leftSiblingNode.id} y ${rightSiblingNode.id}");
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
      leftSiblingRecord.key = node.firstKey();
    }

    if (rightSiblingRecord != null) {
      rightSiblingRecord.key = node.firstKey();
    }

    return nodeRecord;
  }

  /// Tries to balance a sequential [node] with its right sibling, using the [capacityCheckFunction].
  /// If its unable to do it, then tries the same with the left sibling.
  /// If it was able to balance with any of the siblings, returns true. Otherwise, returns false.
  bool _tryToBalanceSequentialNodesWithSibling(BSharpSequentialNode<T> node,
      bool Function(BSharpNode<T>? node) capacityCheckFunction) {
    var rightSiblingNode = node.getRightSibling();
    if (capacityCheckFunction(rightSiblingNode)) {
      //Se intenta balancear con el hermano derecho
      /*print(
          "balanceando sequential node ${node.id} con hermano derecho ${rightSiblingNode!.id}");*/
      transitions.add(
          NodeBalancing(node.id.toString(), rightSiblingNode!.id.toString()));
      _balanceSequentialNodeWithSibling(node, rightSiblingNode);
      return true;
    }

    var leftSiblingNode =
        node.getLeftSibling(); //Se intenta balancear con el hermano izquierdo
    if (capacityCheckFunction(leftSiblingNode)) {
      transitions.add(
          NodeBalancing(node.id.toString(), leftSiblingNode!.id.toString()));
      _balanceSequentialNodeWithSibling(leftSiblingNode, node);
      return true;
    }
    return false;
  }

  /// Tries to balance an underflowed index [node] with its right sibling, if it's over its minimum capacity.
  /// If its unable to do it, then tries the same with the left sibling.
  /// If it was able to balance with any of the siblings, returns true. Otherwise, returns false.
  bool _tryToBalanceUnderflowedIndexNodeWithSiblings(BSharpIndexNode<T> node) {
    var rightSiblingNode = node.getRightSibling();
    if (isOverMinCapacity(rightSiblingNode)) {
      print("balanceando index node con hermano derecho");
      _balanceIndexNodesRightToLeft(node, rightSiblingNode!, node.getParent()!);
      return true;
    }

    var leftSiblingNode = node.getLeftSibling();
    if (isOverMinCapacity(leftSiblingNode)) {
      print("balanceando index node con hermano izquierdo");
      _balanceIndexNodesLeftToRight(leftSiblingNode!, node, node.getParent()!);
      return true;
    }
    return false;
  }

  /// Tries to balance an overflowed index [node] with its right sibling, if it's over it has enough capacity.
  /// If its unable to do it, then tries the same with the left sibling.
  /// If it was able to balance with any of the siblings, returns true. Otherwise, returns false.
  bool _tryToBalanceOverflowedIndexNodeWithSiblings(BSharpIndexNode<T> node) {
    var rightSiblingNode = node.getRightSibling();
    if (_hasCapacityLeft(rightSiblingNode)) {
      print("balanceando index node con hermano derecho");
      _balanceIndexNodesLeftToRight(node, rightSiblingNode!, node.getParent()!);
      return true;
    }

    var leftSiblingNode = node.getLeftSibling();
    if (_hasCapacityLeft(leftSiblingNode)) {
      print("balanceando index node con hermano izquierdo");
      _balanceIndexNodesRightToLeft(leftSiblingNode!, node, node.getParent()!);
      return true;
    }
    return false;
  }

  /// Fuse an index [node] with its right sibling, if it exists.
  /// If it doesn't exist, fuses the left sibling with the [node]
  IndexRecord<T>? _fuseIndexNodesWithAnySibling(BSharpIndexNode<T> node) {
    if (node.getRightSibling() != null) {
      print("fusionando index node con hermano derecho");
      return _fuseSiblingIndexNodes(
          node, node.getRightSibling()!, node.getParent()!);
    } else {
      print("fusionando index node con hermano izquierdo");
      return _fuseSiblingIndexNodes(
          node.getLeftSibling()!, node, node.getParent()!);
    }
  }

  /// Splits a sequential [node] with its right sibling, if it exists.
  /// If it doesn't exist, splits the left sibling with the [node]
  IndexRecord<T>? _splitSequentialNodeWithAnySibling(
      BSharpSequentialNode<T> node) {
    if (node.getRightSibling() != null) {
      //print("fusionando a derecha");

      return _splitSiblingSequentialNodes(
          node, node.getRightSibling()!, node.getParent()!);
    } else {
      print("fusionando a izquierda");
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
      print(
          "fusionando index node ${node.id} con hermano derecho ${rightSiblingNode.id}");
      return _splitSiblingIndexNodes(node, rightSiblingNode, node.getParent()!);
    } else {
      var leftSiblingNode = node.getLeftSibling();
      print(
          "fusionando index node ${node.id} con hermano izquierdo ${leftSiblingNode!.id}");
      return _splitSiblingIndexNodes(leftSiblingNode, node, node.getParent()!);
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
  }

  bool _tryToBalanceUnderflowedSequentialNodeWithSiblings(
      BSharpSequentialNode<T> node) {
    // si el nodo no tiene hermano derecho, tengo que tratar de balancear con su hermano izquierdo
    // y el izquierdo del izquierdo, si existe

    var rightSiblingNode = node.getRightSibling();
    if (isOverMinCapacity(rightSiblingNode)) {
      //Se intenta balancear con el hermano derecho
      print(
          "balanceando sequential node ${node.id} con hermano derecho ${rightSiblingNode!.id}");
      _balanceSequentialNodeWithSibling(node, rightSiblingNode);
      return true;
    }

    var leftSiblingNode =
        node.getLeftSibling(); //Se intenta balancear con el hermano izquierdo
    if (isOverMinCapacity(leftSiblingNode)) {
      print(
          "balanceando sequential node ${node.id} con hermano izquierdo ${leftSiblingNode!.id}");
      _balanceSequentialNodeWithSibling(leftSiblingNode, node);
      return true;
    }

    //Se trata de balancear entre los hermanos izquierdos (si existen)
    if (rightSiblingNode == null &&
        leftSiblingNode != null &&
        isOverMinCapacity(leftSiblingNode.getLeftSibling())) {
      print(
          "balanceando sequential node ${node.id} con sus hermanos izquierdos ${leftSiblingNode.id} y ${leftSiblingNode.getLeftSibling()!.id}");
      _balanceSequentialNodeWithTwoSiblings(
          leftSiblingNode.getLeftSibling()!, leftSiblingNode, node);
      return true;
    }

    //Se trata de balancear entre los hermanos derechos (si existen)
    if (leftSiblingNode == null &&
        rightSiblingNode != null &&
        isOverMinCapacity(rightSiblingNode.getRightSibling())) {
      print(
          "balanceando sequential node ${node.id} con sus hermanos derechos ${rightSiblingNode.id} y ${rightSiblingNode.getRightSibling()!.id}");
      _balanceSequentialNodeWithTwoSiblings(
          node, rightSiblingNode, rightSiblingNode.getRightSibling()!);
      return true;
    }

    return false;
  }
}
