import 'package:visualizeit_bsharptree_extension/model/bsharp_node.dart';
import 'package:collection/collection.dart';

class BSharpIndexNode<T extends Comparable<T>> extends BSharpNode<T> {
  BSharpNode<T> leftNode;
  List<IndexRecord<T>> rightNodes = List.empty(growable: true); //Tiene sentido que esto tenga una lista?

  BSharpIndexNode(super.id, super.level, T value, this.leftNode, BSharpNode<T> rightNode){
    rightNodes.add(IndexRecord<T>(value, rightNode));
  }
  
  @override
  int length() => rightNodes.length;
  
  @override
  (BSharpNode<T>, BSharpNode<T>) splitNode() {
    // TODO: implement splitNode
    throw UnimplementedError();
  }

  @override
  void addToNode(T value) {
    // TODO: implement addNode
    throw UnimplementedError();
  }
  
  @override
  T firstKey() {
    return rightNodes.first.key;
  }

  IndexRecord<T>? getIndexRecordFor(T keyToFind){
    return rightNodes.singleWhere((indexRecord) => indexRecord.key == keyToFind);
  }

  //Encuentra el hermano derecho a una clave
  IndexRecord<T>? findRightSiblingOf(T keyToFind) {
    return rightNodes.firstWhereOrNull((element) => element.key.compareTo(keyToFind)>0);
  }

  


  //Encuentra el hermano izquierdo, si está en la lista de rightNodes
  IndexRecord<T>? findLeftSiblingOf(T keyToFind) {
    var rightNode = rightNodes.firstWhereOrNull((element) => element.key.compareTo(keyToFind)<0);
  }

  
}

class IndexRecord<T extends Comparable<T>> {
  T key;
  BSharpNode<T> rightNode;

  IndexRecord(this.key, this.rightNode);
}