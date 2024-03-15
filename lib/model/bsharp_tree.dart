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
        node.values=node.values.sublist(0,node.length()~/2);
        node.nextNode = rightNode;
        node.rightSibling = rightNode;
        rightNode.leftSibling = node;
        //Crear el nuevo nodo con la key más chica del derecho
        var newRoot = BSharpIndexNode<T>(nodesQuantity++, 1, rightNode.values.first, node, rightNode);
        node.parent = newRoot;
        rightNode.parent = newRoot;
        _rootNode = newRoot;
      }
    } else {
      insertRecursively(_rootNode, null,  value);
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

          var rightSiblingNode = node.rightSibling;
          if(_hasCapacityLeft(rightSiblingNode)){
            print("balanceando con hermano derecho");
            balanceSequentialNodeWithSibling(node,rightSiblingNode!, parent);
            hasBalancedWithSibling = true;
          }
                    
          var leftSiblingNode = node.leftSibling;
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
            return fuseSiblingSequentialNodes(node, rightSiblingNode, parent);
          } else {
            print("fusionando a izquierda");
            return fuseSiblingSequentialNodes(leftSiblingNode!, node, parent);
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
            var rightSiblingNode = node.rightSibling;
            if (_hasCapacityLeft(rightSiblingNode)){ //Si el hermano derecho no está lleno
              print("balanceando index node con hermano derecho");
              var biggestRecordFromLeft = node.rightNodes.removeLast();
              balanceIndexNodeRight(rightSiblingRecord, rightSiblingNode!, biggestRecordFromLeft);
              return null;
            }
            //Intento rotar una clave al hermano izquierdo
            var leftSiblingRecord = parent.findLeftSiblingOf(node.firstKey()); //Buscamos al hermano izquierdo
            var leftSiblingNode = node.leftSibling;
            if (_hasCapacityLeft(leftSiblingNode)){
              print("balanceando index node con hermano izquierdo");
              var smallestRecordFromRight = node.rightNodes.removeAt(0);
              balanceIndexNodeLeft(leftSiblingRecord, node, leftSiblingNode!, smallestRecordFromRight);
              return null;
            }
            //no puedo rotar ni a izq ni a derecha, tengo que juntar las claves y dividir el nodo en 3
            if(rightSiblingRecord!=null && rightSiblingNode!=null ){
              print("fusionando index node a derecha");
              return fuseSiblingIndexNodes(node, rightSiblingNode, parent);
              //return fuseIndexNodes(rightSiblingRecord, rightSiblingNode, node);
            } else {
              print("fusionando index node a izquierda");
              return fuseSiblingIndexNodes(leftSiblingNode!, node, parent);
            }
          } else {
            //current es la raiz y tengo que dividirla en dos
            if(_isRootOverflowed(node)){ //Si se supera la maxima capacidad de la raiz
              print("el nodo indice es la raíz, hay que realizar un spliteo del nodo raíz");
              var recordToPromote = node.rightNodes.elementAt(node.length()~/2);
              var rightNode=BSharpIndexNode<T>.createNode(nodesQuantity++, node.level, recordToPromote.rightNode, node.rightNodes.sublist((node.length()~/2)+1));
              node.rightSibling = rightNode;
              rightNode.leftSibling = node;
              node.rightNodes=node.rightNodes.sublist(0,node.length()~/2);
              // Cortamos la relación de hermanos
              var lastNodeOnLeft = node.rightNodes.last.rightNode;
              lastNodeOnLeft.rightSibling = null;
              var firstNodeOnRight = rightNode.leftNode;
              firstNodeOnRight.leftSibling = null;
              //Crear el nuevo nodo con la key más chica del derecho
              var bSharpIndexNode = BSharpIndexNode<T>(nodesQuantity++, node.level+1, recordToPromote.key, node, rightNode);
              rightNode.parent = bSharpIndexNode;
              _rootNode = bSharpIndexNode;
            }
          }
        }
      }
      return null;

    }
    return null;
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

  IndexRecord<T> fuseSiblingIndexNodes(BSharpIndexNode<T> node, BSharpIndexNode<T> siblingNode, BSharpIndexNode<T> parent){
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

  IndexRecord<T> fuseSiblingSequentialNodes(BSharpSequentialNode<T> node, BSharpSequentialNode<T> siblingNode, BSharpIndexNode<T> parentNode) {
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
      printNode(_rootNode!);
    }
  }

  void printNode(BSharpNode<T> node){
    if(!node.isLevelZero){
      var indexNode = node as BSharpIndexNode<T>;
      print("${indexNode.id}: ${indexNode.leftNode.id}|${indexNode.rightNodes}");
      printNode(indexNode.leftNode);
      for (var e in indexNode.rightNodes) {
        printNode(e.rightNode);
      }
    } else {
      var sequentialNode = node as BSharpSequentialNode<T>;
      print("${sequentialNode.id}: ${sequentialNode.values}");
    }
  }
  
  
}

