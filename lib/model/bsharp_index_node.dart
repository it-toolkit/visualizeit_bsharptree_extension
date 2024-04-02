import 'package:visualizeit_bsharptree_extension/model/bsharp_node.dart';
import 'package:collection/collection.dart';

class BSharpIndexNode<T extends Comparable<T>> extends BSharpNode<T> {
  BSharpNode<T> leftNode;
  List<IndexRecord<T>> rightNodes = List.empty(growable: true);

  BSharpIndexNode(super.id, super.level, T value, this.leftNode, BSharpNode<T> rightNode){
    rightNodes.add(IndexRecord<T>(value, rightNode));
  }
  BSharpIndexNode.createNode(super.id, super.level, this.leftNode, this.rightNodes);

  void fixFamilyRelations(){
    var allChildrenNodes = _getAllChildrenNodes();

    for (var i = 0; i < allChildrenNodes.length; i++) {
      var node = allChildrenNodes.elementAt(i);
      node.parent = this;
      if(i == 0){
        node.leftSibling = null;
        node.rightSibling = allChildrenNodes.elementAt(i+1);
      } else if(i == allChildrenNodes.length - 1) {
        node.rightSibling = null;
        node.leftSibling = allChildrenNodes.elementAt(i-1);
      } else {
        node.rightSibling = allChildrenNodes.elementAt(i+1);
        node.leftSibling = allChildrenNodes.elementAt(i-1);
      }
    }
  }

  List<BSharpNode<T>> _getAllChildrenNodes(){
    List<BSharpNode<T>> allNodes = List.empty(growable: true);
    allNodes.add(leftNode);
    allNodes.addAll(rightNodes.map((e) => e.rightNode));
    return allNodes;
  }
  
  @override
  int length() => rightNodes.length;
  
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

  BSharpIndexNode<T>? getLeftSibling() => super.leftSibling != null ? super.leftSibling as BSharpIndexNode<T> : null;
  BSharpIndexNode<T>? getRightSibling() => super.rightSibling != null ? super.rightSibling as BSharpIndexNode<T> : null;
  BSharpIndexNode<T>? getParent() => super.parent != null ? super.parent as BSharpIndexNode<T> : null;

  BSharpNode<T> findNextNodeForKey(T keyToFind) {
    if(keyToFind.compareTo(firstKey())<0) {
        //Si es menor al primer nodo derecho, tomo el izquierdo
        return leftNode;
      } else {
        var potentialIndexRecord = rightNodes.lastWhere((element) => element.key.compareTo(keyToFind)<=0);
        return potentialIndexRecord.rightNode;
      }
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