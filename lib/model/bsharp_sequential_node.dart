import 'package:visualizeit_bsharptree_extension/model/bsharp_index_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_node.dart';

class BSharpSequentialNode<T extends Comparable<T>> extends BSharpNode<T> {
  List<T> values = <T>[];
  BSharpSequentialNode<T>? nextNode;

  @override
  int length() => values.length;

  BSharpSequentialNode(super.id, super.level, super.maxCapacity, T value) {
    values.add(value);
  }

  BSharpSequentialNode.createNode(
      super.id, super.level, super.maxCapacity, this.values);

  void addToNode(T value) {
    values.add(value);
    values.sort();
  }

  List<T> getFirstHalfOfValues() => values.sublist(0, length() ~/ 2);
  List<T> getLastHalfOfValues() => values.sublist(length() ~/ 2);

  @override
  T? firstKey() => values.isNotEmpty ? values.first : null;

  BSharpSequentialNode<T>? getLeftSibling() => super.leftSibling != null
      ? super.leftSibling as BSharpSequentialNode<T>
      : null;
  BSharpSequentialNode<T>? getRightSibling() => super.rightSibling != null
      ? super.rightSibling as BSharpSequentialNode<T>
      : null;
  BSharpIndexNode<T>? getParent() =>
      super.parent != null ? super.parent as BSharpIndexNode<T> : null;

  void removeValue(T value) {
    this.values.remove(value);
    BSharpIndexNode<T>? parentNode = getParent();
    if (parentNode != null) {
      //No es el nodo raiz
      IndexRecord<T>? nodeIndexRecord = parentNode.findIndexRecordById(id);
      //Se actualiza la key del index record
      if (nodeIndexRecord != null && length() > 0) {
        nodeIndexRecord.key = nodeIndexRecord.rightNode.firstKey()!; //TODO asegurarse que el ! este correcto acá
      }
    }
  }

  bool isValueOnNode(T valueToFind) {
    return values.contains(valueToFind);
  }

  BSharpSequentialNode<T> copy() {
    return BSharpSequentialNode.createNode(
        id, level, maxCapacity, List.of(values));
  }
}
