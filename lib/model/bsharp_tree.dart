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
    if(_rootNode == null){
      _rootNode = BSharpSequentialNode(nodesQuantity, 0, value);
      nodesQuantity++;
      return;
    }

    if(_rootNode!.isLevelZero){ //el unico nodo del arbol es la raiz
      var node = _rootNode as BSharpSequentialNode<T>;
      node.addToNode(value);
      if(node.length()  >= _rootMaxCapacity){ //Si se supera la maxima capacidad de la raiz
        var (leftNode, rightNode) = node.splitNode();//Splitear en dos el nodo
        //Crear el nuevo nodo con la key más chica del derecho
        var bSharpIndexNode = BSharpIndexNode<T>(nodesQuantity, 1, rightNode.values.first, leftNode, rightNode);
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
  
  void insertRecursively(BSharpNode<T>? current, BSharpIndexNode<T>? parent, T value) {
    if(current!=null && current.isLevelZero){ // Encontré el nodo secuencial donde deberia insertar
      var node = current as BSharpSequentialNode<T>;
      node.addToNode(value);
      if(node.length() > maxCapacity){ //Si se supera la maxima capacidad del nodo
        if(parent != null){ //TODO creo que parent nunca es null acá porque se eliminó esa posibilidad antes
          var rightSiblingRecord = parent.findRightSiblingOf(current.firstKey());
          var rightSiblingNode = rightSiblingRecord != null ? rightSiblingRecord.rightNode as BSharpSequentialNode<T> : null;
          if (rightSiblingNode!=null && rightSiblingNode.length() < maxCapacity){ //Si el hermano derecho no está lleno
            var allKeys = node.values + rightSiblingNode.values;
            allKeys.sort();
            node.values = allKeys.sublist(0, allKeys.length~/2);
            rightSiblingNode.values = allKeys.sublist(allKeys.length~/2);
            if(rightSiblingRecord != null) {
              rightSiblingRecord.key = rightSiblingNode.firstKey();
            }
            return;
          }
          var leftSiblingRecord = parent.findLeftSiblingOf(current.firstKey()); //Buscamos al hermano izquierdo
          var leftSiblingNode = (leftSiblingRecord != null ? leftSiblingRecord.rightNode : parent.leftNode) as BSharpSequentialNode<T>;
          if (leftSiblingNode.length() < maxCapacity){ //Si el hermano izquierdo no está lleno
            var nodeRecord = parent.getIndexRecordFor(node.firstKey());
            var allKeys = node.values + leftSiblingNode.values;
            allKeys.sort();
            leftSiblingNode.values = allKeys.sublist(0, allKeys.length~/2);
            node.values = allKeys.sublist(allKeys.length~/2);
            //Al rebalancearse a izquierda tengo que actualizar la nueva key en el indexRecord correspondiente
            nodeRecord!.key = node.firstKey(); 
            if(leftSiblingRecord != null) {
              leftSiblingRecord.key = leftSiblingNode.firstKey(); //TODO: Revisar este caso
            }
            return;
          }
          // Si llegué acá no pude rebalancear con ninguno de los hermanos porque estan completos, tengo que unir
          // ambos nodos, crear uno nuevo en el medio y repartir las claves en 3
          if (rightSiblingNode!=null){
            var allKeys = node.values + rightSiblingNode.values;
            allKeys.sort();
            node.values = allKeys.sublist(0, allKeys.length~/3);
            var newNode = BSharpSequentialNode<T>.createNode(nodesQuantity, 0, allKeys.sublist(allKeys.length~/3, (allKeys.length*2)~/3));
            node.nextNode = newNode;
            newNode.nextNode = rightSiblingNode;
            rightSiblingNode.values = allKeys.sublist((allKeys.length*2)~/3);
            if(rightSiblingRecord != null) {
              rightSiblingRecord.key = rightSiblingNode.firstKey();
            }
            
          } else {
            //Alternativa con el hermano izquierdo
          }
        }
      }
    } else {
      var node = current as BSharpIndexNode<T>;
      if(value.compareTo(node.firstKey())<0) {
        //Si es menor al primer nodo derecho, tomo el izquierdo
        insertRecursively(node.leftNode, current, value);
      } else {
        var indexRecord = node.rightNodes.lastWhere((element) => element.key.compareTo(value)<0);
        insertRecursively(indexRecord.rightNode, current, value);
      }
    }
  }
}