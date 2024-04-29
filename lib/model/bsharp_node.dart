import 'package:flutter/material.dart';

abstract class BSharpNode<T extends Comparable<T>> with ChangeNotifier {
  int id;
  int level;
  BSharpNode<T>? leftSibling;
  BSharpNode<T>? rightSibling;
  BSharpNode<T>? parent;

  bool get isLevelZero => level == 0;

  BSharpNode(this.id, this.level);
  int length();
  T firstKey();
}
