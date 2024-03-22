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
        node.rightSibling = rightNode;
        rightNode.leftSibling = node;
        //Crear el nuevo nodo con la key más chica del derecho
        var newRoot = BSharpIndexNode<T>(nodesQuantity++, 1, rightNode.values.first, node, rightNode);
        print("creando nodo: ${newRoot.id}");
        node.parent = newRoot;
        rightNode.parent = newRoot;
        _rootNode = newRoot;
      }
    } else {
      insertRecursively(_rootNode, null,  value);
    }

  }

  void remove(T value){
    if(_rootNode!=null){
      removeRecursively(_rootNode!, value);
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
                    
          var leftSiblingNode = node.getleftSibling();
          if (!hasBalancedWithSibling && _hasCapacityLeft(leftSiblingNode)){
            print("balanceando con hermano izquierdo");
            balanceSequentialNodeWithSibling(leftSiblingNode!, node, parent); //leftSiblingRecord deberia ir?
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
        var indexRecord = node.rightNodes.lastWhere((element) => element.key.compareTo(value)<0);
        promotedKey = insertRecursively(indexRecord.rightNode, current, value);
      }
      //Intento agregar la key en el nodo
      if(promotedKey!=null){
        print("key promocionada: ${promotedKey.key}");
        node.addIndexRecordToNode(promotedKey);
        if(_isNodeOverflowed(node)){ //Se supera la maxima capacidad del nodo
          print("la promoción hace desbordar el nodo indice");
          if(parent!=null){
            //Intento rotar una clave al hermano derecho
            var rightSiblingRecord = parent.findRightSiblingOf(node.firstKey());
            var rightSiblingNode = node.getRightSibling();
            if (_hasCapacityLeft(rightSiblingNode)){ //Si el hermano derecho no está lleno
              print("balanceando index node con hermano derecho");
              var biggestRecordFromLeft = node.rightNodes.removeLast();
              balanceIndexNodeRight(rightSiblingRecord, rightSiblingNode!, biggestRecordFromLeft);
              return null;
            }
            //Intento rotar una clave al hermano izquierdo
            var leftSiblingRecord = parent.findLeftSiblingOf(node.firstKey()); //Buscamos al hermano izquierdo
            var leftSiblingNode = node.getLeftSibling();
            if (_hasCapacityLeft(leftSiblingNode)){
              print("balanceando index node con hermano izquierdo");
              var smallestRecordFromRight = node.rightNodes.removeAt(0);
              balanceIndexNodeLeft(leftSiblingRecord, node, leftSiblingNode!, smallestRecordFromRight);
              return null;
            }
            //no puedo rotar ni a izq ni a derecha, tengo que juntar las claves y dividir el nodo en 3
            if(rightSiblingRecord!=null && rightSiblingNode!=null ){
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
    node.rightSibling = newSiblingNode;
    newSiblingNode.leftSibling = node;
    node.rightNodes=node.rightNodes.sublist(0,node.length()~/2);
    //Actualizamos el padre de los nodos 
    newSiblingNode.leftNode.parent = newSiblingNode;
    //rightNode.rightNodes.map((e) => e.rightNode.parent = rightNode);
    for (var node in newSiblingNode.rightNodes){
      node.rightNode.parent = newSiblingNode;
    }
    // Cortamos la relación de hermanos
    var lastNodeOnLeft = node.rightNodes.last.rightNode; 
    lastNodeOnLeft.rightSibling = null;
    var firstNodeOnRight = newSiblingNode.leftNode;
    firstNodeOnRight.leftSibling = null;
    //Crear el nuevo nodo con la key más chica del derecho
    var bSharpIndexNode = BSharpIndexNode<T>(nodesQuantity++, node.level+1, recordToPromote.key, node, newSiblingNode);
    print("creando nodo: ${bSharpIndexNode.id}");
    newSiblingNode.parent = bSharpIndexNode;
    node.parent = bSharpIndexNode;
    _rootNode = bSharpIndexNode;
  }

  bool _isNodeOverflowed(BSharpNode<T> node) => node.length() > maxCapacity;
  bool _hasCapacityLeft(BSharpNode<T>? node) => node!=null && node.length() < maxCapacity;
  bool _isRootOverflowed(BSharpNode node) => node.length()  > _rootMaxCapacity;


  void balanceIndexNodeLeft(IndexRecord<T>? leftSiblingRecord, BSharpIndexNode<T> node, BSharpIndexNode<T> leftSiblingNode, IndexRecord<T> smallestRecordFromRight) {
    var newIndexRecord = IndexRecord(leftSiblingRecord!.key, node.leftNode);
    leftSiblingNode.addIndexRecordToNode(newIndexRecord);
    node.leftNode = smallestRecordFromRight.rightNode;
    leftSiblingRecord.key = smallestRecordFromRight.key;
  }

  void balanceIndexNodeRight(IndexRecord<T>? rightSiblingRecord, BSharpIndexNode<T> rightSiblingNode, IndexRecord<T> biggestRecordFromLeft) {
    var newIndexRecord = IndexRecord(rightSiblingRecord!.key, rightSiblingNode.leftNode);
    rightSiblingNode.addIndexRecordToNode(newIndexRecord);
    rightSiblingNode.leftNode=biggestRecordFromLeft.rightNode;
    rightSiblingRecord.key = biggestRecordFromLeft.key;
  }

  IndexRecord<T> fuseAndSplitSiblingIndexNodes(BSharpIndexNode<T> node, BSharpIndexNode<T> siblingNode, BSharpIndexNode<T> parent){
    var siblingRecord = parent.findIndexRecordById(siblingNode.id);
    var allIndexRecords = node.rightNodes;
    var parentIndexRecord = IndexRecord(siblingRecord!.key, siblingNode.leftNode); //TODO Hay un caso en elque siblingRecord == null?
    allIndexRecords.add(parentIndexRecord);
    allIndexRecords.addAll(siblingNode.rightNodes);
    allIndexRecords.sort((a, b) => a.key.compareTo(b.key));
    node.rightNodes = allIndexRecords.sublist(0, allIndexRecords.length~/3);
    node.rightNodes.last.rightNode.rightSibling = null;

    var firstPromotedIndexRecord = allIndexRecords.elementAt(allIndexRecords.length~/3);
    siblingNode.leftNode = firstPromotedIndexRecord.rightNode;
    siblingNode.leftNode.leftSibling = null;
    siblingNode.rightNodes = allIndexRecords.sublist((allIndexRecords.length~/3)+1, (allIndexRecords.length*2)~/3);
    siblingRecord.key = firstPromotedIndexRecord.key;

    var secondPromotedIndexRecord = allIndexRecords.elementAt((allIndexRecords.length*2)~/3);    

    var newNode = BSharpIndexNode<T>.createNode(nodesQuantity++, node.level, secondPromotedIndexRecord.rightNode, allIndexRecords.sublist(((allIndexRecords.length*2)~/3)+1));
    print("creando nodo: ${newNode.id}");
    newNode.leftSibling = siblingNode;
    newNode.parent = parent;
    siblingNode.rightSibling = newNode;
    
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
    newNode.leftSibling = node;
    newNode.rightSibling = siblingNode;
    newNode.parent = parentNode;
    newNode.nextNode = siblingNode;

    node.rightSibling = newNode;
    node.nextNode = newNode;
    
    siblingNode.values = allKeys.sublist((allKeys.length*2)~/3);
    siblingNode.leftSibling = newNode;
    if(siblingRecord != null) {
      siblingRecord.key = siblingNode.firstKey();
    }
    return IndexRecord(newNode.firstKey(), newNode);
  }

  void printTree(){
    if(_rootNode!=null){
      _printNode(_rootNode!);
    }
  }

  void _printNode(BSharpNode<T> node){
    if(!node.isLevelZero){
      var indexNode = node as BSharpIndexNode<T>;
      print("${indexNode.id}: ${indexNode.leftNode.id}|${indexNode.rightNodes}");
      _printNode(indexNode.leftNode);
      for (var e in indexNode.rightNodes) {
        _printNode(e.rightNode);
      }
    } else {
      var sequentialNode = node as BSharpSequentialNode<T>;
      print("${sequentialNode.id}: ${sequentialNode.values}");
    }
  }

  IndexRecord<T>? removeRecursively(BSharpNode<T> current, T value){
    if(current.isLevelZero){
      var node = current as BSharpSequentialNode<T>;
      if(node.values.contains(value)){
        print("el valor a remover '$value' se encontró en el nodo con id: ${node.id}");
        node.values.remove(value);
        if(node.parent != null){ //No es el nodo raiz
          var nodeIndexRecord = node.getParent()!.findIndexRecordById(node.id);
          if(nodeIndexRecord!=null && node.values.isNotEmpty){
            nodeIndexRecord.key = nodeIndexRecord.rightNode.firstKey();
          }
          
          if(isNodeUnderflowed(node)){ 
            print("el nodo tiene menos valores que la capacidad minima");
            var rightSiblingNode = node.getRightSibling();
            var hasBalancedWithSibling = false;
            if(isOverMinCapacity(rightSiblingNode)){ //Se intenta balancear con el hermano derecho
              print("balanceando sequential node con hermano derecho");
              balanceSequentialNodeWithSibling(node, rightSiblingNode!, node.getParent()!);
              hasBalancedWithSibling = true;
            }

            var leftSiblingNode = node.getleftSibling(); //Se intenta balancear con el hermano izquierdo
            if(!hasBalancedWithSibling && isOverMinCapacity(leftSiblingNode)){
              print("balanceando sequential node con hermano izquierdo");
              balanceSequentialNodeWithSibling(leftSiblingNode!, node, node.getParent()!);
              hasBalancedWithSibling = true;
            }

            if(hasBalancedWithSibling){
              return null;
            } else {
              // Si llegué acá no pude rebalancear con ninguno de los hermanos porque estan completos, tengo que unir
              // ambos nodos
              if(rightSiblingNode!=null){
                print("fusionando sequential node con hermano derecho");
                return fuseSiblingSequentialNodes(node, rightSiblingNode, node.getParent()!);
              } else {
                print("fusionando sequential node con hermano izquierdo");
                return fuseSiblingSequentialNodes(leftSiblingNode!, node, node.getParent()!);
              }
            }
          }
        }
      } else {
        //TODO Ver que hacemos si no encontramos el value
      }
    } else {
      var node = current as BSharpIndexNode<T>;
      IndexRecord<T>? indexRecordToUpdate;
      if(value.compareTo(node.firstKey())<0) {
        //Si es menor al primer nodo derecho, tomo el izquierdo
        indexRecordToUpdate = removeRecursively(node.leftNode, value);
      } else {
        var potentialIndexRecord = node.rightNodes.lastWhere((element) => element.key.compareTo(value)<=0);
        indexRecordToUpdate = removeRecursively(potentialIndexRecord.rightNode, value);
      }
      if(indexRecordToUpdate!=null){
        print("valor a remover en nodo index: ${indexRecordToUpdate.key}");
        node.rightNodes.removeWhere((element) => element.key == indexRecordToUpdate!.key);
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
  
  IndexRecord<T>? fuseSiblingSequentialNodes(BSharpSequentialNode<T> node, BSharpSequentialNode<T> siblingNode, BSharpIndexNode<T> parent) {
    print("fusionando nodos con ids: ${node.id} y ${siblingNode.id}");
    var siblingRecord = parent.findIndexRecordById(siblingNode.id);
    var nodeRecord = parent.findIndexRecordById(node.id);
    var allKeys = node.values + siblingNode.values;
    allKeys.sort();

    node.values = allKeys;
    node.rightSibling = siblingNode.getRightSibling();
    node.nextNode = siblingNode.nextNode;
    if(nodeRecord != null){
      nodeRecord.key = node.firstKey();
    }
    
    return siblingRecord;
  }
  
  void balanceIndexNodeWithRightSibling(BSharpIndexNode<T> node, BSharpIndexNode<T> rightSiblingNode, BSharpIndexNode<T> parent) {
    print("balanceando index nodes con ids: ${node.id} y ${rightSiblingNode.id}");
    var siblingRecord = parent.findIndexRecordById(rightSiblingNode.id);
    var nodeRecord = parent.findIndexRecordById(node.id);
    
    var newIndexRecord = IndexRecord(siblingRecord!.key, rightSiblingNode.leftNode);
    node.addIndexRecordToNode(newIndexRecord);
    var leftChildren = node.findLeftSiblingById(newIndexRecord.rightNode.id);
    leftChildren.rightSibling = newIndexRecord.rightNode;
    newIndexRecord.rightNode.leftSibling = leftChildren;
    var rightChildren = node.findRightSiblingOf(newIndexRecord.key);
    newIndexRecord.rightNode.rightSibling = rightChildren?.rightNode;

    siblingRecord.key = rightSiblingNode.rightNodes.first.key;
    var removedIndexRecord = rightSiblingNode.rightNodes.removeAt(0);
    rightSiblingNode.leftNode = removedIndexRecord.rightNode;
  }

  void balanceIndexNodeWithLeftSibling(BSharpIndexNode<T> leftSiblingNode, BSharpIndexNode<T> node, BSharpIndexNode<T> parent) {
    print("balanceando ${node.id} con su hermano izquierdo: ${leftSiblingNode.id}");
    var nodeRecord = parent.findIndexRecordById(node.id);
    //var nodeRecord = parent.findIndexRecordById(leftSiblingNode.id);
    
    var newIndexRecord = IndexRecord(nodeRecord!.key, node.leftNode);
    
    var smallesRecordFromRight = node.rightNodes.firstOrNull;
    if(smallesRecordFromRight != null){
      newIndexRecord.rightNode.rightSibling = smallesRecordFromRight.rightNode;
    } else {
      newIndexRecord.rightNode.rightSibling = null;
    }
    
    node.addIndexRecordToNode(newIndexRecord);
    var greatestRecordFromLeft = leftSiblingNode.rightNodes.removeLast();
    nodeRecord.key = greatestRecordFromLeft.key;
    node.leftNode = greatestRecordFromLeft.rightNode;
    node.leftNode.leftSibling = null;
    newIndexRecord.rightNode.leftSibling = node.leftNode;

    node.leftNode.parent = node;
  }
  
  IndexRecord<T>? fuseSiblingIndexNodes(BSharpIndexNode<T> node, BSharpIndexNode<T> siblingNode, BSharpIndexNode<T> parent) {
    print("fusionando index nodes con ids: ${node.id} y ${siblingNode.id}");
    var siblingRecord = parent.findIndexRecordById(siblingNode.id);

    var newIndexRecord = IndexRecord(siblingRecord!.key, siblingNode.leftNode);

    BSharpNode<T> lastNodeOnLeft;
    if(node.rightNodes.isNotEmpty){
      lastNodeOnLeft = node.rightNodes.last.rightNode;
    } else {
      lastNodeOnLeft = node.leftNode;
    }
    lastNodeOnLeft.rightSibling = newIndexRecord.rightNode;
    newIndexRecord.rightNode.leftSibling = lastNodeOnLeft;
    newIndexRecord.rightNode.parent = node;

    if(siblingNode.rightNodes.isNotEmpty){
      newIndexRecord.rightNode.rightSibling = siblingNode.rightNodes.first.rightNode;
      siblingNode.rightNodes.first.rightNode.leftSibling = newIndexRecord.rightNode;
    }    

    node.addIndexRecordToNode(newIndexRecord);
    for (var nodeToMove in siblingNode.rightNodes) {
      nodeToMove.rightNode.parent = node;
      node.addIndexRecordToNode(nodeToMove);
    }
    node.rightSibling = siblingNode.getRightSibling();

    return siblingRecord;
  }
  
  
}

