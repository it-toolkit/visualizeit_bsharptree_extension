import 'package:visualizeit_bsharptree_extension/exception/element_insertion_exception.dart';
import 'package:visualizeit_bsharptree_extension/exception/element_not_found_exception.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_index_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_sequential_node.dart';

class BSharpTree<T extends Comparable<T>> {
  
  BSharpNode<T>? _rootNode;
  final int maxCapacity;
  int nodesQuantity = 0;

  BSharpTree(this.maxCapacity);
  //Creacion requiere capacidad min y max en nodos internos y en nodos hoja

  //Insercion con validacion de unicidad, algoritmo de sobreflujo y todos los nodos con al menos 2/3 de 
  // ocupacion de su capacidad

  //Supresion con algoritmo de subflujo

  //Busqueda (aproximada) (Para obtener el primer registro del archivo puede usarse la búsqueda con un identificador nulo)

  //Siguiente registro

  //Listar el arbol inorder

  int get _rootMaxCapacity => (4 * maxCapacity) ~/ 3;
  int get _minCapacity => (2 * maxCapacity) ~/ 3;
  int get depth => _rootNode?.level ?? 0;

  void insert(T value){
    print("insertando value: $value");
    if(_rootNode == null){
      _rootNode = BSharpSequentialNode(nodesQuantity, 0, value);
      nodesQuantity++;
      return;
    }

    if(_rootNode!.isLevelZero){ //el unico nodo del arbol es la raiz
      var node = _rootNode as BSharpSequentialNode<T>;
      node.addToNode(value);
      if(_isRootOverflowed(node)){ //Si se supera la maxima capacidad de la raiz
        print("spliteando la raíz");
        var rightNode=BSharpSequentialNode.createNode(nodesQuantity++, 0, node.values.sublist(node.length()~/2));
        print("creando nodo: ${rightNode.id}");
        node.values=node.values.sublist(0,node.length()~/2);
        node.nextNode = rightNode;
        //Crear el nuevo nodo con la key más chica del derecho
        var newRoot = BSharpIndexNode<T>(nodesQuantity++, 1, rightNode.values.first, node, rightNode);
        newRoot.fixFamilyRelations();
        print("creando nodo: ${newRoot.id}");
        _rootNode = newRoot;       
      }
    } else {
      insertRecursively(_rootNode, null,  value);
    }

  }

  void remove(T value){
    print("eliminando value: $value");
    if(_rootNode!=null){
      _removeRecursively(_rootNode!, value);
    }
  }

  void traverse(){
    if(_rootNode!=null){
      //Encontramos el nodo hoja de menores valores (el de mas a la izquierda)
      var node = _rootNode!;
      while (!node.isLevelZero){
        node = (node as BSharpIndexNode<T>).leftNode;
      }
      //Recorremos los nodos hoja en forma secuencial
      BSharpSequentialNode<T>? traverseNode = node as BSharpSequentialNode<T>;
      while (traverseNode!=null){
        print("${traverseNode.id}:${traverseNode.values}");
        traverseNode = traverseNode.nextNode;
      }
    } else {
      print("no values to show");
    }
  }
  
  IndexRecord<T>? insertRecursively(BSharpNode<T>? current, BSharpIndexNode<T>? parent, T value) {
    if(current!=null && current.isLevelZero){ // Encontré el nodo secuencial donde deberia insertar
      var node = current as BSharpSequentialNode<T>;
      if(node.isValueOnNode(value)){
        throw ElementInsertionException("cant insert the value $value, it's already on the tree");
      }
      node.addToNode(value);
      if(_isNodeOverflowed(node)){ //Si se supera la maxima capacidad del nodo
        print("Supera la capacidad del nodo al insertar value: $value");
        if(parent != null){ //TODO creo que parent nunca es null acá porque se eliminó esa posibilidad antes
          
          var hasBalancedWithSibling = false;

          var rightSiblingNode = node.getRightSibling();
          if(_hasCapacityLeft(rightSiblingNode)){
            print("balanceando con hermano derecho");
            balanceSequentialNodeWithSibling(node,rightSiblingNode!, parent);
            hasBalancedWithSibling = true;
          }
                    
          var leftSiblingNode = node.getLeftSibling();
          if (!hasBalancedWithSibling && _hasCapacityLeft(leftSiblingNode)){
            print("balanceando con hermano izquierdo");
            balanceSequentialNodeWithSibling(leftSiblingNode!, node, parent);
            hasBalancedWithSibling = true;
          }

          if(hasBalancedWithSibling){
            return null;
          }
          // Si llegué acá no pude rebalancear con ninguno de los hermanos porque estan completos, tengo que unir
          // ambos nodos, crear uno nuevo en el medio y repartir las claves en 3
          if (rightSiblingNode!=null){
            print("fusionando a derecha");
            return fuseAndSplitSiblingSequentialNodes(node, rightSiblingNode, parent);
          } else {
            print("fusionando a izquierda");
            return fuseAndSplitSiblingSequentialNodes(leftSiblingNode!, node, parent);
          }
        }
      }
    } else {
      var node = current as BSharpIndexNode<T>;
      IndexRecord<T>? promotedKey;
      if(value.compareTo(node.firstKey())<0) {
        //Si es menor al primer nodo derecho, tomo el izquierdo
        promotedKey = insertRecursively(node.leftNode, current, value);
      } else {
        var indexRecord = node.rightNodes.lastWhere((element) => element.key.compareTo(value)<=0);
        promotedKey = insertRecursively(indexRecord.rightNode, current, value);
      }
      //Intento agregar la key en el nodo
      if(promotedKey!=null){
        print("key promocionada: ${promotedKey.key}");
        node.addIndexRecordToNode(promotedKey);
        node.fixFamilyRelations();
        if(_isNodeOverflowed(node)){ //Se supera la maxima capacidad del nodo
          print("la promoción hace desbordar el nodo indice");
          if(parent!=null){
            //Intento rotar una clave al hermano derecho
            var rightSiblingNode = node.getRightSibling();
            if (_hasCapacityLeft(rightSiblingNode)){ //Si el hermano derecho no está lleno
              print("balanceando index node ${node.id} con hermano derecho ${rightSiblingNode!.id}");
              balanceIndexNodeRight(node, rightSiblingNode, parent);
              return null;
            }
            //Intento rotar una clave al hermano izquierdo
            
            var leftSiblingNode = node.getLeftSibling();
            if (_hasCapacityLeft(leftSiblingNode)){
              print("balanceando index node ${node.id} con hermano izquierdo ${leftSiblingNode!.id}");
              balanceIndexNodeLeft(leftSiblingNode, node, parent);
              return null;
            }
            //no puedo rotar ni a izq ni a derecha, tengo que juntar las claves y dividir el nodo en 3
            if(rightSiblingNode!=null){
              print("fusionando index node a derecha");
              return fuseAndSplitSiblingIndexNodes(node, rightSiblingNode, parent);
            } else {
              print("fusionando index node a izquierda");
              return fuseAndSplitSiblingIndexNodes(leftSiblingNode!, node, parent);
            }
          } else {
            //current es la raiz y tengo que dividirla en dos
            if(_isRootOverflowed(node)){ //Si se supera la maxima capacidad de la raiz
              print("el nodo indice es la raíz, hay que realizar un spliteo del nodo raíz");
              splitIndexRootNode(node);
              return null;
            }
          }
        }
      }
      return null;

    }
    return null;
  }

  void splitIndexRootNode(BSharpIndexNode<T> node) {
    var recordToPromote = node.rightNodes.elementAt(node.length()~/2);
    var newSiblingNode=BSharpIndexNode<T>.createNode(nodesQuantity++, node.level, recordToPromote.rightNode, node.rightNodes.sublist((node.length()~/2)+1));
    print("creando nodo: ${newSiblingNode.id}");
    node.rightNodes=node.rightNodes.sublist(0,node.length()~/2);
    
    //Crear el nuevo nodo con la key más chica del derecho
    var bSharpIndexNode = BSharpIndexNode<T>(nodesQuantity++, node.level+1, recordToPromote.key, node, newSiblingNode);
    print("creando nodo: ${bSharpIndexNode.id}");

    newSiblingNode.fixFamilyRelations();
    node.fixFamilyRelations();
    bSharpIndexNode.fixFamilyRelations();

    //Seteamos el nuevo nodo como la raiz
    _rootNode = bSharpIndexNode;
  }

  bool _isNodeOverflowed(BSharpNode<T> node) => node.length() > maxCapacity;
  bool _hasCapacityLeft(BSharpNode<T>? node) => node!=null && node.length() < maxCapacity;
  bool _isRootOverflowed(BSharpNode node) => node.length()  > _rootMaxCapacity;


  void balanceIndexNodeLeft(BSharpIndexNode<T> leftSiblingNode, BSharpIndexNode<T> node, BSharpIndexNode<T> parent) {
    var leftSiblingRecord = parent.findLeftSiblingOf(node.firstKey()); //Buscamos al hermano izquierdo
    var smallestRecordFromRight = node.rightNodes.removeAt(0);

    var newIndexRecord = IndexRecord(leftSiblingRecord!.key, node.leftNode);
    leftSiblingNode.addIndexRecordToNode(newIndexRecord);
    node.leftNode = smallestRecordFromRight.rightNode;
    leftSiblingRecord.key = smallestRecordFromRight.key;

    leftSiblingNode.fixFamilyRelations();
    node.fixFamilyRelations();
  }

  void balanceIndexNodeRight(BSharpIndexNode<T> node, BSharpIndexNode<T> rightSiblingNode, BSharpIndexNode<T> parent) {
    var rightSiblingRecord = parent.findRightSiblingOf(node.firstKey());
    var biggestRecordFromLeft = node.rightNodes.removeLast();

    var newIndexRecord = IndexRecord(rightSiblingRecord!.key, rightSiblingNode.leftNode);
    rightSiblingNode.addIndexRecordToNode(newIndexRecord);
    rightSiblingNode.leftNode=biggestRecordFromLeft.rightNode;
    rightSiblingRecord.key = biggestRecordFromLeft.key;
    
    node.fixFamilyRelations();
    rightSiblingNode.fixFamilyRelations();
  }

  IndexRecord<T> fuseAndSplitSiblingIndexNodes(BSharpIndexNode<T> node, BSharpIndexNode<T> siblingNode, BSharpIndexNode<T> parent){
    var siblingRecord = parent.findIndexRecordById(siblingNode.id);
    var allIndexRecords = node.rightNodes;
    var parentIndexRecord = IndexRecord(siblingRecord!.key, siblingNode.leftNode); //TODO Hay un caso en elque siblingRecord == null?
    allIndexRecords.add(parentIndexRecord);
    allIndexRecords.addAll(siblingNode.rightNodes);
    allIndexRecords.sort((a, b) => a.key.compareTo(b.key));
    node.rightNodes = allIndexRecords.sublist(0, allIndexRecords.length~/3);

    var firstPromotedIndexRecord = allIndexRecords.elementAt(allIndexRecords.length~/3);
    siblingNode.leftNode = firstPromotedIndexRecord.rightNode;
    siblingNode.rightNodes = allIndexRecords.sublist((allIndexRecords.length~/3)+1, (allIndexRecords.length*2)~/3);
    siblingRecord.key = firstPromotedIndexRecord.key;

    var secondPromotedIndexRecord = allIndexRecords.elementAt((allIndexRecords.length*2)~/3);    

    var newNode = BSharpIndexNode<T>.createNode(nodesQuantity++, node.level, secondPromotedIndexRecord.rightNode, allIndexRecords.sublist(((allIndexRecords.length*2)~/3)+1));
    print("creando nodo: ${newNode.id}");

    node.fixFamilyRelations();
    siblingNode.fixFamilyRelations();
    newNode.fixFamilyRelations();
    
    return IndexRecord(secondPromotedIndexRecord.key, newNode);
  }

  void balanceSequentialNodeWithSibling(BSharpSequentialNode<T> node, BSharpSequentialNode<T> siblingNode, BSharpIndexNode<T> parentNode) {
    var siblingRecord = parentNode.findIndexRecordById(siblingNode.id);
    var allKeys = node.values + siblingNode.values;
    allKeys.sort();
    node.values = allKeys.sublist(0, allKeys.length~/2);
    siblingNode.values = allKeys.sublist(allKeys.length~/2);
    if(siblingRecord != null) {
      siblingRecord.key = siblingNode.firstKey();
    }
  }

  IndexRecord<T> fuseAndSplitSiblingSequentialNodes(BSharpSequentialNode<T> node, BSharpSequentialNode<T> siblingNode, BSharpIndexNode<T> parentNode) {
    var siblingRecord = parentNode.findIndexRecordById(siblingNode.id);
    var allKeys = node.values + siblingNode.values;
    allKeys.sort();
    node.values = allKeys.sublist(0, allKeys.length~/3);
    
    var newNode = BSharpSequentialNode<T>.createNode(nodesQuantity++, 0, allKeys.sublist(allKeys.length~/3, (allKeys.length*2)~/3));
    print("creando nodo: ${newNode.id}");
    newNode.nextNode = siblingNode;
    node.nextNode = newNode;
    
    siblingNode.values = allKeys.sublist((allKeys.length*2)~/3);
    if(siblingRecord != null) {
      siblingRecord.key = siblingNode.firstKey();
    }
    return IndexRecord(newNode.firstKey(), newNode);
  }

  void printTree(){
    if(_rootNode!=null){
      var depth = 0;
      _printNode(_rootNode!, depth);
    }
  }

  void _printNode(BSharpNode<T> node, int depth){
    String padding = "${"--" * depth}>";
    String nodeId = "${node.id}".padRight(2);
    if(!node.isLevelZero){
      var indexNode = node as BSharpIndexNode<T>;
      print("$padding$nodeId: ${indexNode.leftNode.id}|${indexNode.rightNodes} - parent: ${indexNode.getParent()?.id}, leftSibling: ${indexNode.getLeftSibling()?.id}, rightSibling: ${indexNode.getRightSibling()?.id}");
      _printNode(indexNode.leftNode, ++depth);
      for (var e in indexNode.rightNodes) {
        _printNode(e.rightNode, depth);
      }
    } else {
      var sequentialNode = node as BSharpSequentialNode<T>;
      print("$padding$nodeId: ${sequentialNode.values} - parent: ${node.getParent()?.id}, leftSibling: ${node.getLeftSibling()?.id}, rightSibling: ${node.getRightSibling()?.id}");
    }
  }

  IndexRecord<T>? _removeRecursively(BSharpNode<T> current, T value){
    if(current.isLevelZero){
      var node = current as BSharpSequentialNode<T>;
      if(node.values.contains(value)){
        print("el valor a remover '$value' se encontró en el nodo con id: ${node.id}");
        node.removeValue(value);
        if(!isRoot(node) && isNodeUnderflowed(node)){
          print("el nodo tiene menos valores que la capacidad minima");
          
          var hasBalancedWithSibling = tryToBalanceSequentialNodesWithSiblingsOnRemoval(node);
          
          if(!hasBalancedWithSibling){
            // Si llegué acá no pude rebalancear con ninguno de los hermanos porque estan completos, tengo que unir
            // ambos nodos
            return fuseSequentialNodeWithAnySibling(node);
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        throw ElementNotFoundException("Element $value not found in the tree");
      }
    } else {
      var node = current as BSharpIndexNode<T>;
      IndexRecord<T>? indexRecordToUpdate;
      if(value.compareTo(node.firstKey())<0) {
        //Si es menor al primer nodo derecho, tomo el izquierdo
        indexRecordToUpdate = _removeRecursively(node.leftNode, value);
      } else {
        var potentialIndexRecord = node.rightNodes.lastWhere((element) => element.key.compareTo(value)<=0);
        indexRecordToUpdate = _removeRecursively(potentialIndexRecord.rightNode, value);
      }
      if(indexRecordToUpdate!=null){
        print("index record a remover con id de rightNode: ${indexRecordToUpdate.rightNode.id}");
        node.rightNodes.removeWhere((indexRecord) => indexRecord.rightNode.id == indexRecordToUpdate!.rightNode.id);

        if(node.parent != null && isNodeUnderflowed(node)){
          var hasBalancedWithSibling = false;
          var rightSiblingNode = node.getRightSibling();
          if(isOverMinCapacity(rightSiblingNode)){
            print("balanceando index node con hermano derecho");
            balanceIndexNodeWithRightSibling(node, rightSiblingNode!, node.getParent()!);
            hasBalancedWithSibling = true;
          }

          var leftSiblingNode = node.getLeftSibling();
          if(!hasBalancedWithSibling && isOverMinCapacity(leftSiblingNode)){
            print("balanceando index node con hermano izquierdo");
            balanceIndexNodeWithLeftSibling(leftSiblingNode!, node, node.getParent()!);
            hasBalancedWithSibling = true;
          }
          if(hasBalancedWithSibling){
            return null;
          } else {
            if(rightSiblingNode!=null){
              print("fusionando index node con hermano derecho");
              return fuseSiblingIndexNodes(node, rightSiblingNode, node.getParent()!);
            } else {
              print("fusionando index node con hermano izquierdo");
              return fuseSiblingIndexNodes(leftSiblingNode!, node, node.getParent()!);
            }
          }
        } else {
          if(node.parent == null && node.length() == 0){
            _rootNode = node.leftNode;
            _rootNode!.parent = null;
            _rootNode!.leftSibling = null;
            _rootNode!.rightSibling = null;
          } else {
            node.fixFamilyRelations();
          }
          return null;
        }
      } else {
        return null;
      }
    }
  }
  
  bool isNodeUnderflowed(BSharpNode<T> node) => node.length() < _minCapacity;
  
  bool isOverMinCapacity(BSharpNode<T>? node) => node != null && node.length() > _minCapacity;

  bool tryToBalanceSequentialNodesWithSiblingsOnRemoval(BSharpSequentialNode<T> node){
    var rightSiblingNode = node.getRightSibling();
    if(isOverMinCapacity(rightSiblingNode)){ //Se intenta balancear con el hermano derecho
      print("balanceando sequential node ${node.id} con hermano derecho ${rightSiblingNode!.id}");
      balanceSequentialNodeWithSibling(node, rightSiblingNode, node.getParent()!);
      return true;
    }

    var leftSiblingNode = node.getLeftSibling(); //Se intenta balancear con el hermano izquierdo
    if(isOverMinCapacity(leftSiblingNode)){
      print("balanceando sequential node ${node.id} con hermano izquierdo ${leftSiblingNode!.id}");
      balanceSequentialNodeWithSibling(leftSiblingNode, node, node.getParent()!);
      return true;
    }
    return false;
  }
  
  IndexRecord<T>? fuseSiblingSequentialNodes(BSharpSequentialNode<T> node, BSharpSequentialNode<T> siblingNode, BSharpIndexNode<T> parent) {
    print("fusionando nodos con ids: ${node.id} y ${siblingNode.id}");
    var siblingRecord = parent.findIndexRecordById(siblingNode.id);
    var nodeRecord = parent.findIndexRecordById(node.id);
    var allKeys = node.values + siblingNode.values;
    allKeys.sort();

    node.values = allKeys;
    node.nextNode = siblingNode.nextNode;
    if(nodeRecord != null){
      nodeRecord.key = node.firstKey();
    }
    
    return siblingRecord;
  }
  
  void balanceIndexNodeWithRightSibling(BSharpIndexNode<T> node, BSharpIndexNode<T> rightSiblingNode, BSharpIndexNode<T> parent) {
    print("balanceando index nodes con ids: ${node.id} y ${rightSiblingNode.id}");
    var siblingRecord = parent.findIndexRecordById(rightSiblingNode.id);
        
    var newIndexRecord = IndexRecord(siblingRecord!.key, rightSiblingNode.leftNode);
    node.addIndexRecordToNode(newIndexRecord);

    siblingRecord.key = rightSiblingNode.firstKey();
    
    var removedIndexRecord = rightSiblingNode.rightNodes.removeAt(0);
    rightSiblingNode.leftNode = removedIndexRecord.rightNode;
    
    node.fixFamilyRelations();
    rightSiblingNode.fixFamilyRelations();
  }

  void balanceIndexNodeWithLeftSibling(BSharpIndexNode<T> leftSiblingNode, BSharpIndexNode<T> node, BSharpIndexNode<T> parent) {
    print("balanceando ${node.id} con su hermano izquierdo: ${leftSiblingNode.id}");
    var nodeRecord = parent.findIndexRecordById(node.id);
    var newIndexRecord = IndexRecord(nodeRecord!.key, node.leftNode);
    
    node.addIndexRecordToNode(newIndexRecord);
    var greatestRecordFromLeft = leftSiblingNode.rightNodes.removeLast();
    nodeRecord.key = greatestRecordFromLeft.key;
    node.leftNode = greatestRecordFromLeft.rightNode;

    leftSiblingNode.fixFamilyRelations();
    node.fixFamilyRelations();
  }
  
  IndexRecord<T>? fuseSiblingIndexNodes(BSharpIndexNode<T> node, BSharpIndexNode<T> siblingNode, BSharpIndexNode<T> parent) {
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

  void insertAll(List<T> listOfValues) {
    print("values to insert: $listOfValues");
    for (var value in listOfValues) {
      insert(value);
    }
  }
  
  bool isRoot(BSharpNode<T> node) {
    return node.id == _rootNode?.id;
  }
  
  IndexRecord<T>? fuseSequentialNodeWithAnySibling(BSharpSequentialNode<T> node) {
    if(node.getRightSibling() != null){
      print("fusionando sequential node con hermano derecho");
      return fuseSiblingSequentialNodes(node, node.getRightSibling()!, node.getParent()!);
    } else {
      print("fusionando sequential node con hermano izquierdo");
      return fuseSiblingSequentialNodes(node.getLeftSibling()!, node, node.getParent()!);
    }
  }
  
  
}

