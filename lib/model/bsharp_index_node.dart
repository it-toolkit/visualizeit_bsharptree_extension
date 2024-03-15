import 'package:visualizeit_bsharptree_extension/model/bsharp_node.dart';
import 'package:collection/collection.dart';

class BSharpIndexNode<T extends Comparable<T>> extends BSharpNode<T> {
  BSharpNode<T> leftNode;
  //BSharpIndexNode<T>? leftSibling;
  //BSharpIndexNode<T>? rightSibling;
  //BSharpIndexNode<T>? parent;
  List<IndexRecord<T>> rightNodes = List.empty(growable: true);

  BSharpIndexNode(super.id, super.level, T value, this.leftNode, BSharpNode<T> rightNode){
    rightNodes.add(IndexRecord<T>(value, rightNode));
  }
  BSharpIndexNode.createNode(super.id, super.level, this.leftNode, this.rightNodes);
  
  @override
  int length() => rightNodes.length;
  
  @override
  void addToNode(T value) {
    // TODO: implement addNode
    throw UnimplementedError();
  }

  void addIndexRecordToNode(IndexRecord<T> newRecord){
    rightNodes.add(newRecord);
    rightNodes.sort((a, b) => a.key.compareTo(b.key));
  }
  
  @override
  T firstKey() {
    return rightNodes.first.key;
  }

  IndexRecord<T>? findIndexRecordFor(T keyToFind){
    return rightNodes.singleWhereOrNull((indexRecord) => indexRecord.key == keyToFind);
  }

  IndexRecord<T>? findIndexRecordById(int id){
    return rightNodes.singleWhereOrNull((indexRecord) => indexRecord.rightNode.id == id);
  }

  //Encuentra el hermano derecho a una clave
  IndexRecord<T>? findRightSiblingOf(T keyToFind) {
    return rightNodes.firstWhereOrNull((element) => element.key.compareTo(keyToFind)>0);
  }

  //Encuentra el hermano izquierdo, si está en la lista de rightNodes
  IndexRecord<T>? findLeftSiblingOf(T keyToFind) {
    return rightNodes.lastWhereOrNull((element) => element.key.compareTo(keyToFind)<0);
  }

  BSharpNode<T> findLeftSiblingById(int id){
    int siblingPosition = rightNodes.indexWhere((element) => element.rightNode.id == id) - 1;
    if(siblingPosition < 0 ) {
      return leftNode;
    } else {
      return rightNodes.elementAt(siblingPosition).rightNode;
    }
  }

  @override
  BSharpIndexNode<T>? get leftSibling => super.leftSibling != null ? super.leftSibling as BSharpIndexNode<T> : null;

  @override
  BSharpIndexNode<T>? get rightSibling => super.rightSibling != null ? super.rightSibling as BSharpIndexNode<T> : null;

  @override
  BSharpIndexNode<T>? get parent => super.parent != null ? super.parent as BSharpIndexNode<T> : null;
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