import 'package:visualizeit_bsharptree_extension/model/bsharp_node.dart';
import 'package:collection/collection.dart';

class BSharpIndexNode<T extends Comparable<T>> extends BSharpNode<T> {
  BSharpNode<T> leftNode;
  List<IndexRecord<T>> rightNodes = List.empty(growable: true);

  BSharpIndexNode(super.id, super.level, super.maxCapacity, T value,
      this.leftNode, BSharpNode<T> rightNode) {
    rightNodes.add(IndexRecord<T>(value, rightNode));
  }
  BSharpIndexNode.createNode(
      super.id, super.level, super.maxCapacity, this.leftNode, this.rightNodes);

  /// Takes all of the nodes children and fixes their sibling relationship
  void fixFamilyRelations() {
    var allChildrenNodes = _getAllChildrenNodes();

    for (var i = 0; i < allChildrenNodes.length; i++) {
      var node = allChildrenNodes.elementAt(i);
      var rightSibling = i + 1 < allChildrenNodes.length
          ? allChildrenNodes.elementAt(i + 1)
          : null;
      var leftSibling = i - 1 >= 0 ? allChildrenNodes.elementAt(i - 1) : null;
      node.parent = this;
      node.leftSibling = leftSibling;
      node.rightSibling = rightSibling;
    }
  }

  List<BSharpNode<T>> _getAllChildrenNodes() {
    List<BSharpNode<T>> allNodes = List.empty(growable: true);
    allNodes.add(leftNode);
    allNodes.addAll(rightNodes.map((e) => e.rightNode));
    return allNodes;
  }

  @override
  int length() => rightNodes.length;

  void addIndexRecordToNode(IndexRecord<T> newRecord) {
    rightNodes.add(newRecord);
    rightNodes.sort((a, b) => a.key.compareTo(b.key));
  }

  @override
  T? firstKey() {
    return rightNodes.isNotEmpty ? rightNodes.first.key : null;
  }

  IndexRecord<T>? findIndexRecordById(String id) {
    return rightNodes
        .singleWhereOrNull((indexRecord) => indexRecord.rightNode.id == id);
  }

  BSharpIndexNode<T>? getLeftSibling() => super.leftSibling != null
      ? super.leftSibling as BSharpIndexNode<T>
      : null;
  BSharpIndexNode<T>? getRightSibling() => super.rightSibling != null
      ? super.rightSibling as BSharpIndexNode<T>
      : null;
  BSharpIndexNode<T>? getParent() =>
      super.parent != null ? super.parent as BSharpIndexNode<T> : null;

  BSharpNode<T> findNextNodeForKey(T keyToFind) {
    if (firstKey() == null || keyToFind.compareTo(firstKey()!) < 0) {
      //Si es menor al primer nodo derecho, tomo el izquierdo
      return leftNode;
    } else {
      var potentialIndexRecord = rightNodes
          .lastWhere((element) => element.key.compareTo(keyToFind) <= 0);
      return potentialIndexRecord.rightNode;
    }
  }

  BSharpIndexNode<T> copyWith(
      {required BSharpNode<T> leftNode,
      required List<IndexRecord<T>> rightNodes}) {
    return BSharpIndexNode.createNode(
        id, level, maxCapacity, leftNode, rightNodes);
  }
}

class IndexRecord<T extends Comparable<T>> {
  T key;
  BSharpNode<T> rightNode;

  IndexRecord(this.key, this.rightNode);

  @override
  String toString() {
    return "($key)${rightNode.id}";
  }
}
