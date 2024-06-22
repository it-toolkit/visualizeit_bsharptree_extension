import 'package:flutter/material.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_transition.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_command.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_node.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_bsharptree_extension/widget/tree_node_widget.dart';
import 'package:widget_arrows/widget_arrows.dart';

class TreeWidget extends StatefulWidget {
  final BSharpTree tree;
  final BSharpTreeTransition? currentTransition;
  final BSharpTreeCommand? commandInExecution;

  const TreeWidget(this.tree, this.currentTransition, this.commandInExecution,
      {super.key});

  @override
  State<TreeWidget> createState() {
    return _TreeWidgetState();
  }
}

class _TreeWidgetState extends State<TreeWidget> {
  Map<int, List<Widget>>? _components;

  _TreeWidgetState();

  @override
  void initState() {
    super.initState();
  }

  Map<int, List<Widget>> createWidgetsFromTree(double screenWidth) {
    return widget.tree
        .getAllNodesByLevel()
        .map((level, listOfNodes) => MapEntry(
            level,
            listOfNodes.map((node) {
              var widthOfLevel =
                  listOfNodes.length * widget.tree.maxCapacity * 65;

              double? scaleFactor = widthOfLevel > screenWidth
                  ? (screenWidth / widthOfLevel)
                  : null;

              return createNodeWithTransition(node, scaleFactor);
            }).toList()));
  }

  TreeNodeWidget createNodeWithTransition(
      BSharpNode<Comparable> node, double? scaleFactor) {
    var nodeTransition = widget.currentTransition != null &&
            widget.currentTransition!.isATarget(node.id)
        ? widget.currentTransition
        : null;
    if (scaleFactor != null) {
      return TreeNodeWidget(
        node,
        nodeTransition,
        scaleFactor: scaleFactor,
      );
    } else {
      return TreeNodeWidget(
        node,
        nodeTransition,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double screenWidth = constraints.maxWidth;
        _components = createWidgetsFromTree(screenWidth);

        final List<Widget> rows = [
          buildCommandInExecutionRow(),
          buildCurrentTransitionRow(),
          buildFreeNodesRow()
        ];

        List<Widget> treeNodeRows = [];
        for (var mapEntry in _components!.entries) {
          List<Widget> children = mapEntry.value.fold(
              [],
              (previousValue, widget) =>
                  previousValue +
                  ([
                    widget,
                  ]));
          treeNodeRows.addAll([
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: children,
            ),
            const Spacer(),
          ]);
        }

        rows.add(Expanded(
            child: Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: treeNodeRows,
          ),
        )));

        rows.add(buildColorReferenceBox());

        return ArrowContainer(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: rows),
        );
      },
    );
  }

  Row buildColorReferenceBox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 165,
          height: 65,
          margin: const EdgeInsets.only(right: 2, bottom: 2),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              boxShadow: const [
                BoxShadow(blurRadius: 5),
              ]),
          child: Column(
            children: [
              buildColorReferenceRow(Colors.cyan, "Node with available space"),
              buildColorReferenceRow(Colors.yellow, "Node at capacity limit"),
              buildColorReferenceRow(Colors.red, "Overflowed node"),
            ],
          ),
        ),
      ],
    );
  }

  Row buildFreeNodesRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 20,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            child: Text(widget.tree.freeNodesIds.isNotEmpty
                ? "Free nodes: ${widget.tree.freeNodesIds}"
                : ""),
          ),
        ),
      ],
    );
  }

  Row buildCurrentTransitionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 180,
          height: 20,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            child: Text(widget.currentTransition != null
                ? widget.currentTransition.toString()
                : ""),
          ),
        ),
        SizedBox(
          width: 180,
          height: 20,
          child: FittedBox(
            fit: BoxFit.fitHeight,
            alignment: Alignment.centerRight,
            child: Text("Other node max capacity: ${widget.tree.maxCapacity}"),
          ),
        ),
      ],
    );
  }

  Row buildCommandInExecutionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          height: 20,
          child: FittedBox(
            fit: BoxFit.fitHeight,
            alignment: Alignment.centerLeft,
            child: Text(widget.commandInExecution != null
                ? widget.commandInExecution.toString()
                : ""),
          ),
        ),
        SizedBox(
          width: 180,
          height: 20,
          child: FittedBox(
            fit: BoxFit.fitHeight,
            alignment: Alignment.centerRight,
            child:
                Text("Root node max capacity: ${widget.tree.rootMaxCapacity}"),
          ),
        ),
      ],
    );
  }

  Row buildColorReferenceRow(Color color, final String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CustomPaint(
          size: const Size(10, 10),
          painter: RoundedRectanglePainter(color),
        ),
        SizedBox(
          width: 138,
          height: 20,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
            ),
          ),
        ),
      ],
    );
  }
}

class RoundedRectanglePainter extends CustomPainter {
  Color color;
  RoundedRectanglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.strokeWidth = 2;
    paint.color = color;
    canvas.drawRRect(
        RRect.fromLTRBR(
            0, 0, size.height, size.width, const Radius.circular(3)),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
