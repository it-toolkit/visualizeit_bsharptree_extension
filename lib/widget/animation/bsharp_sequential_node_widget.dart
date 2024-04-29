import 'dart:math';

import 'package:flutter/material.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_sequential_node.dart';
import 'package:visualizeit_bsharptree_extension/widget/component.dart';
import 'package:widget_arrows/widget_arrows.dart';

class BSharpSequentialNodeWidget extends StatefulWidget {
  final BSharpSequentialNode node;
  const BSharpSequentialNodeWidget(this.node, {super.key});

  @override
  State<BSharpSequentialNodeWidget> createState() =>
      _BSharpSequentialNodeWidgetState();
}

class _BSharpSequentialNodeWidgetState extends State<BSharpSequentialNodeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggeredController;
  late Animation _boxWithGrow;
  late Animation _valueOpacity;
  /*late Interval widthInterval;
  late Interval opacityInterval;*/

  @override
  void initState() {
    super.initState();

    /*widthInterval = const Interval(
      0.125,
      0.250,
      curve: Curves.ease,
    );
    opacityInterval = const Interval(
      0.260,
      0.300,
      curve: Curves.ease,
    );*/
    _staggeredController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _staggeredController.forward();
    _staggeredController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _staggeredController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _boxWithGrow = Tween(
            begin: max(50, 20 + (widget.node.length() - 1) * 35),
            end: max(50, 20 + (widget.node.length()) * 35))
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.0, 0.50, curve: Curves.easeOut)));
    _valueOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));
    var components = buildComponents();
    return ArrowElement(
        id: widget.node.id.toString(),
        child: Container(
            width: _boxWithGrow.value,
            height: 65,
            decoration: BoxDecoration(
                border: Border.all(),
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                boxShadow: const [
                  BoxShadow(blurRadius: 10),
                ]),
            child: Column(
              children: <Widget>[
                // Create all of the colored boxes in the colors map.
                for (final Component component in components)
                  Container(
                    child: component.widget,
                  ),
              ],
            )));
  }

  /*@override
  Widget build(BuildContext context) {
    return ArrowElement(
        id: widget.node.id.toString(),
        child:
            AnimatedBuilder(animation: widget.node, builder: buildContainer));
  }*/

  /*Widget buildContainer(BuildContext context, Widget? child) {
    var components = buildComponents();
    return AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: max(50, 20 + widget.node.length() * 35),
        height: 65,
        decoration: BoxDecoration(
            border: Border.all(),
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            boxShadow: const [
              BoxShadow(blurRadius: 10),
            ]),
        child: Column(
          children: <Widget>[
            // Create all of the colored boxes in the colors map.
            for (final Component component in components)
              Container(
                child: component.widget,
              ),
          ],
        ));
  }*/

  /*Widget buildContainer(BuildContext context, Widget? child) {
    var components = buildComponents();
    return AnimatedBuilder(
      animation: _staggeredController,
      builder: (context, child) {
        final animationPercent = Curves.elasticOut
            .transform(widthInterval.transform(_staggeredController.value));
        final double width = animationPercent.clamp(
            max(50, 20 + (widget.node.length() - 1) * 35),
            max(50, 20 + widget.node.length() * 35));
        return Container(
            width: width,
            height: 65,
            decoration: BoxDecoration(
                border: Border.all(),
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                boxShadow: const [
                  BoxShadow(blurRadius: 10),
                ]),
            child: Column(
              children: <Widget>[
                // Create all of the colored boxes in the colors map.
                for (final Component component in components)
                  Container(
                    child: component.widget,
                  ),
              ],
            ));
      },
    );
  }*/

  List<Component> buildComponents() {
    final valueNodes = <Widget>[];
    String nodeId = widget.node.id.toString();
    valueNodes.add(const Spacer());
    for (var value in widget.node.values) {
      valueNodes.addAll([
        _boxContainer(value.toString()),
      ]);
    }
    valueNodes.add(const Spacer());
    return <Component>[
      Component(
        "node-$nodeId",
        Alignment.topCenter,
        SizedBox(
          width: 30,
          height: 20,
          child: FittedBox(
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
              child: Text("Id: $nodeId",
                  style: const TextStyle(
                      color: Colors.black, decoration: TextDecoration.none))),
        ),
      ),
      Component(
        "values-$nodeId",
        const Alignment(0, 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: valueNodes,
        ),
      ),
    ];
  }

  static Widget _boxContainer(String text,
      {double margin = 0.0, Color color = Colors.cyan}) {
    return Container(
      width: 35.0,
      height: 40.0,
      margin: EdgeInsets.all(margin),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(),
        color: color,
      ),
      alignment: Alignment.center,
      child: FittedBox(
          fit: BoxFit.fitWidth,
          child: Text(text,
              style: const TextStyle(
                decoration: TextDecoration.none,
              ))),
    );
  }
}
