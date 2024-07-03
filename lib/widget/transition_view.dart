import 'package:flutter/material.dart';

abstract class TransitionView {
  String getTextForWidget();
  Color getTextColorForWidget();
  Color getBoxBorderColorForWidget();
}

mixin NodeCreationView implements TransitionView {
  @override
  Color getBoxBorderColorForWidget() => Colors.black;

  @override
  Color getTextColorForWidget() => Colors.green;

  @override
  String getTextForWidget() => "Created";
}

mixin NodeReuseView implements TransitionView {
  @override
  Color getBoxBorderColorForWidget() => Colors.black;

  @override
  Color getTextColorForWidget() => Colors.green;

  @override
  String getTextForWidget() => "Reused";
}

mixin NodeReadView implements TransitionView {
  @override
  Color getBoxBorderColorForWidget() => Colors.blue;

  @override
  Color getTextColorForWidget() => Colors.brown;

  @override
  String getTextForWidget() => "Read";
}

mixin NodeWrittenView implements TransitionView {
  @override
  Color getBoxBorderColorForWidget() => Colors.blue;

  @override
  Color getTextColorForWidget() => Colors.green;

  @override
  String getTextForWidget() => "Written";
}

mixin NodeOverflowView implements TransitionView {
  @override
  Color getBoxBorderColorForWidget() => Colors.red;

  @override
  Color getTextColorForWidget() => Colors.red;

  @override
  String getTextForWidget() => "Overflow";
}

mixin NodeUnderflowView implements TransitionView {
  @override
  Color getBoxBorderColorForWidget() => Colors.red;

  @override
  Color getTextColorForWidget() => Colors.red;

  @override
  String getTextForWidget() => "Underflow";
}

mixin NodeBalancingView implements TransitionView {
  @override
  Color getBoxBorderColorForWidget() => Colors.blue;

  @override
  Color getTextColorForWidget() => Colors.blue;

  @override
  String getTextForWidget() => "Balancing";
}

mixin NodeSplitView implements TransitionView {
  @override
  Color getBoxBorderColorForWidget() => Colors.blue;

  @override
  Color getTextColorForWidget() => Colors.blue;

  @override
  String getTextForWidget() => "Splitting";
}

mixin NodeFusionView implements TransitionView {
  @override
  Color getBoxBorderColorForWidget() => Colors.blue;

  @override
  Color getTextColorForWidget() => Colors.blue;

  @override
  String getTextForWidget() => "Fusing";
}

mixin NodeReleaseView implements TransitionView {
  @override
  Color getBoxBorderColorForWidget() => Colors.red;

  @override
  Color getTextColorForWidget() => Colors.red;

  @override
  String getTextForWidget() => "Releasing";
}

mixin NodeFoundView implements TransitionView {
  @override
  Color getBoxBorderColorForWidget() => Colors.green;

  @override
  Color getTextColorForWidget() => Colors.green;

  @override
  String getTextForWidget() => "Found";
}
