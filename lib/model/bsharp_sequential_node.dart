import 'package:visualizeit_bsharptree_extension/model/bsharp_node.dart';

class BSharpSequentialNode<T extends Comparable<T>> extends BSharpNode<T>{
  List<T> values = <T>[];
  //BSharpNode? rightNode;
  BSharpSequentialNode<T>? nextNode;

  @override
  int length() => values.length;

  BSharpSequentialNode(super.id, super.level, T value){
    values.add(value);
  }

  BSharpSequentialNode.createNode(super.id, super.level, this.values);
  
  @override
  void addToNode(T value){
    values.add(value);
    values.sort();
  }

  (BSharpSequentialNode<T>, BSharpSequentialNode<T>) splitNode() {
      //Mejora: remover los ultimos de la lista de valores y pasarlo a un nuevo nodo y devolver ambos
      var leftNode=BSharpSequentialNode.createNode(1, level, values.sublist(0, length()~/2));
      var rightNode=BSharpSequentialNode.createNode(2, level, values.sublist(length()~/2));
      rightNode.nextNode = this.nextNode;
      leftNode.nextNode = rightNode;
      return (leftNode, rightNode);
  }
  
  @override
  T firstKey() => values.first;
}