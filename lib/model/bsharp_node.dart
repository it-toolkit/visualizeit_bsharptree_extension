abstract class BSharpNode<T extends Comparable<T>>{
  int id;
  int level;
  
  bool get isLevelZero => level == 0;
 
  BSharpNode(this.id, this.level);
  void addToNode(T value);
  int length();
  (BSharpNode<T>, BSharpNode<T>) splitNode();
  T firstKey();
}