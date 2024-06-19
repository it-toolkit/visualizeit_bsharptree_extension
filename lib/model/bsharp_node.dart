abstract class BSharpNode<T extends Comparable<T>> {
  final String id;
  int level;
  int maxCapacity;
  BSharpNode<T>? leftSibling;
  BSharpNode<T>? rightSibling;
  BSharpNode<T>? parent;

  bool get isLevelZero => level == 0;
  int get _minCapacity => (2 * maxCapacity) ~/ 3;
  bool isOverflowed() => length() > maxCapacity;
  bool hasCapacityLeft() => length() < maxCapacity;

  bool isUnderflowed() => length() < _minCapacity;
  bool isOverMinCapacity() => length() > _minCapacity;

  bool isAtMaxCapacity() => length() == maxCapacity;

  BSharpNode(this.id, this.level, this.maxCapacity);
  int length();
  T? firstKey();
}
