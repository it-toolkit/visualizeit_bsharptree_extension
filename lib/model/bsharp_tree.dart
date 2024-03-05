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
      if(node.length()  > _rootMaxCapacity){ //Si se supera la maxima capacidad de la raiz
        print("spliteando la raíz");
        var rightNode=BSharpSequentialNode.createNode(nodesQuantity++, 0, node.values.sublist(node.length()~/2));
        node.values=node.values.sublist(0,node.length()~/2);
        node.nextNode = rightNode;
        //Crear el nuevo nodo con la key más chica del derecho
        var bSharpIndexNode = BSharpIndexNode<T>(nodesQuantity++, 1, rightNode.values.first, node, rightNode);
        _rootNode = bSharpIndexNode;
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
      var parentIndexRecord = parent?.findIndexRecordFor(node.firstKey());
      node.addToNode(value);
      if(node.length() > maxCapacity){ //Si se supera la maxima capacidad del nodo
        print("Supera la capacidad del nodo al insertar value: $value");
        if(parent != null){ //TODO creo que parent nunca es null acá porque se eliminó esa posibilidad antes
          
          var hasBalancedWithSibling = false;

          var rightSiblingRecord = parent.findRightSiblingOf(current.firstKey());
          var rightSiblingNode = rightSiblingRecord != null ? rightSiblingRecord.rightNode as BSharpSequentialNode<T> : null;
          if (rightSiblingNode!=null && rightSiblingNode.length() < maxCapacity){ //Balancea si existe hermano derecho y no está lleno
            print("balanceando con hermano derecho");
            balanceSequentialNodes(node,rightSiblingNode, rightSiblingRecord);
            hasBalancedWithSibling = true;
          }
                    
          var leftSiblingRecord = parent.findLeftSiblingOf(current.firstKey()); //Buscamos al hermano izquierdo
          var leftSiblingNode = (leftSiblingRecord != null ? leftSiblingRecord.rightNode : parent.leftNode) as BSharpSequentialNode<T>;
          if (!hasBalancedWithSibling && leftSiblingNode.length() < maxCapacity){ //Si el hermano izquierdo no está lleno
            print("balanceando con hermano izquierdo");
            balanceSequentialNodes(leftSiblingNode, node, parentIndexRecord); //leftSiblingRecord deberia ir?
            hasBalancedWithSibling = true;
          }

          if(hasBalancedWithSibling){
            return null;
          }
          // Si llegué acá no pude rebalancear con ninguno de los hermanos porque estan completos, tengo que unir
          // ambos nodos, crear uno nuevo en el medio y repartir las claves en 3
          if (rightSiblingNode!=null){
            print("fusionando a derecha");
            return fuseSequentialNodes(node, rightSiblingNode, rightSiblingRecord);
          } else {
            print("fusionando a izquierda");
            return fuseSequentialNodes(leftSiblingNode, node, parentIndexRecord);
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
        if(node.length() > maxCapacity){ //Se supera la maxima capacidad del nodo
          print("la promoción hace desbordar el nodo indice");
          if(parent!=null){
            //Intento rotar una clave al hermano derecho
            var biggestRecordFromLeft = node.rightNodes.last;
            var rightSiblingRecord = parent.findRightSiblingOf(current.firstKey());
            var rightSiblingNode = rightSiblingRecord != null ? rightSiblingRecord.rightNode as BSharpIndexNode<T> : null;
            if (rightSiblingNode!=null && rightSiblingNode.length() < maxCapacity){ //Si el hermano derecho no está lleno
              print("balanceando index node con hermano derecho");
              var newIndexRecord = IndexRecord(rightSiblingRecord!.key, rightSiblingNode.leftNode);
              rightSiblingNode.addIndexRecordToNode(newIndexRecord);
              rightSiblingNode.leftNode=biggestRecordFromLeft.rightNode;
              rightSiblingRecord.key = biggestRecordFromLeft.key;
              return null;
            }
            //TODO: Intento rotar una clave al hermano izquierdo
            //TODO: no puedo rotar ni a izq ni a derecha, tengo que juntar las claves y dividir el nodo en 3
          } else {
            //current es la raiz y tengo que dividirla en dos
            if(node.length() > _rootMaxCapacity){ //Si se supera la maxima capacidad de la raiz
              print("el nodo indice es la raíz, hay que realizar un spliteo del nodo raíz");
              var recordToPromote = node.rightNodes.elementAt(node.length()~/2);
              var rightNode=BSharpIndexNode<T>.createNode(nodesQuantity++, node.level, recordToPromote.rightNode, node.rightNodes.sublist((node.length()~/2)+1));
              node.rightNodes=node.rightNodes.sublist(0,node.length()~/2);
              //Crear el nuevo nodo con la key más chica del derecho
              var bSharpIndexNode = BSharpIndexNode<T>(nodesQuantity++, node.level+1, recordToPromote.key, node, rightNode);
              _rootNode = bSharpIndexNode;
            }
          }
        }
      }
      return null;

    }
    return null;
  }

  IndexRecord<T> fuseSequentialNodes(BSharpSequentialNode<T> node, BSharpSequentialNode<T> siblingNode, IndexRecord<T>? siblingRecord) {
    var allKeys = node.values + siblingNode.values;
    allKeys.sort();
    node.values = allKeys.sublist(0, allKeys.length~/3);
    var newNode = BSharpSequentialNode<T>.createNode(nodesQuantity++, 0, allKeys.sublist(allKeys.length~/3, (allKeys.length*2)~/3));
    node.nextNode = newNode;
    newNode.nextNode = siblingNode;
    siblingNode.values = allKeys.sublist((allKeys.length*2)~/3);
    if(siblingRecord != null) {
      siblingRecord.key = siblingNode.firstKey();
    }
    return IndexRecord(newNode.firstKey(), newNode);
  }

  void balanceSequentialNodes(BSharpSequentialNode<T> node, BSharpSequentialNode<T> siblingNode, IndexRecord<T>? siblingRecord) {
    var allKeys = node.values + siblingNode.values;
    allKeys.sort();
    node.values = allKeys.sublist(0, allKeys.length~/2);
    siblingNode.values = allKeys.sublist(allKeys.length~/2);
    if(siblingRecord != null) {
      siblingRecord.key = siblingNode.firstKey();
    }
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

