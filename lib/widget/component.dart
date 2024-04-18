import 'package:flutter/widgets.dart';

class Component {
  final String id;
  final Alignment alignment;
  final Widget widget;

  Component(this.id, this.alignment, this.widget);
}
class ComponentLayoutDelegate extends MultiChildLayoutDelegate {
  ComponentLayoutDelegate({
    required this.components,
  });

  final List<Component> components;

  // Perform layout will be called when re-layout is needed.
  @override
  void performLayout(Size size) {
    for (final Component component in components) {
      // layoutChild must be called exactly once for each child.
      final Size currentSize = layoutChild(
        component.id,
        BoxConstraints(maxHeight: size.height, maxWidth: size.width),
      );
      // positionChild must be called to change the position of a child from
      // what it was in the previous layout. Each child starts at (0, 0) for the
      // first layout.
      var alignment = component.alignment;
      var offset = switch (alignment) {
        Alignment.bottomLeft => size.bottomLeft(Offset.zero) - currentSize.bottomLeft(Offset.zero),
        Alignment.bottomCenter => size.bottomCenter(Offset.zero) - currentSize.bottomCenter(Offset.zero),
        Alignment.bottomRight => size.bottomRight(Offset.zero) - currentSize.bottomRight(Offset.zero),
        Alignment.centerLeft => size.centerLeft(Offset.zero) - currentSize.centerLeft(Offset.zero),
        Alignment.center => size.center(Offset.zero) - currentSize.center(Offset.zero),
        Alignment.centerRight => size.centerRight(Offset.zero) - currentSize.centerRight(Offset.zero),
        Alignment.topLeft => Offset.zero,
        Alignment.topCenter => size.topCenter(Offset.zero) - currentSize.topCenter(Offset.zero),
        Alignment.topRight => size.topRight(Offset.zero) - currentSize.topRight(Offset.zero),
        _ => size.centerLeft(Offset.zero).translate(alignment.x, alignment.y)
      };

      positionChild(component.id, offset);
    }
  }

  // shouldRelayout is called to see if the delegate has changed and requires a
  // layout to occur. Should only return true if the delegate state itself
  // changes: changes in the CustomMultiChildLayout attributes will
  // automatically cause a relayout, like any other widget.
  @override
  bool shouldRelayout(ComponentLayoutDelegate oldDelegate) {
    return false;
  }
}
