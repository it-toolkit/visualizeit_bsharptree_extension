import 'package:visualizeit_bsharptree_extension/model/bsharp_index_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_node.dart';

class BSharpSequentialNode<T extends Comparable<T>> extends BSharpNode<T>{
  List<T> values = <T>[];
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

  @override
  T firstKey() => values.first;

  @override
  BSharpSequentialNode<T>? getleftSibling() => super.leftSibling != null ? super.leftSibling as BSharpSequentialNode<T> : null;

  @override
  BSharpSequentialNode<T>? getRightSibling() => super.rightSibling != null ? super.rightSibling as BSharpSequentialNode<T> : null;

  @override
  BSharpIndexNode<T>? getParent() => super.parent != null ? super.parent as BSharpIndexNode<T> : null;
}