import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_bsharptree_extension/widget/transition_view.dart';

abstract class BSharpTreeTransition implements TransitionView {
  final String _targetId;
  final String? _firstOptionalTargetId;
  final String? _secondOptionalTargetId;
  final BSharpTree? _transitionTree;

  String get targetId => _targetId;
  String? get firstOptionalTarget => _firstOptionalTargetId;
  String? get secondOptionalTargetId => _secondOptionalTargetId;
  BSharpTree? get transitionTree => _transitionTree;
  bool hasTree() => _transitionTree != null;

  @override
  String toString() {
    var buffer = StringBuffer(_targetId);
    if (_firstOptionalTargetId != null) {
      buffer.write(" -> $_firstOptionalTargetId");
      if (_secondOptionalTargetId != null) {
        buffer.write(",$_secondOptionalTargetId");
      }
    }
    return buffer.toString();
  }

  BSharpTreeTransition({
    required String targetId,
    String? firstOptionalTargetId,
    String? secondOptionalTargetId,
    BSharpTree? transitionTree,
  })  : _targetId = targetId,
        _firstOptionalTargetId = firstOptionalTargetId,
        _secondOptionalTargetId = secondOptionalTargetId,
        _transitionTree = transitionTree;

  bool isATarget(String id) {
    return _targetId == id ||
        _firstOptionalTargetId == id ||
        _secondOptionalTargetId == id;
  }
}

class NodeCreation extends BSharpTreeTransition with NodeCreationView {
  NodeCreation({required super.targetId, super.transitionTree});

  @override
  String toString() {
    return "Creating node: ${super.toString()}";
  }
}

class NodeReuse extends BSharpTreeTransition with NodeReuseView {
  NodeReuse({required super.targetId, super.transitionTree});

  @override
  String toString() {
    return "Reusing node: ${super.toString()}";
  }
}

class NodeRead extends BSharpTreeTransition with NodeReadView {
  NodeRead({required super.targetId});
  @override
  String toString() {
    return "Node read: ${super.toString()}";
  }
}

class NodeWritten extends BSharpTreeTransition with NodeWrittenView {
  NodeWritten({required super.targetId, super.transitionTree});
  @override
  String toString() {
    return "Node Written: ${super.toString()}";
  }
}

class NodeOverflow extends BSharpTreeTransition with NodeOverflowView {
  NodeOverflow({required super.targetId, super.transitionTree});
  @override
  String toString() {
    return "Overflowed node: ${super.toString()}";
  }
}

class NodeUnderflow extends BSharpTreeTransition with NodeUnderflowView {
  NodeUnderflow({required super.targetId, super.transitionTree});
  @override
  String toString() {
    return "Underflowed Node: ${super.toString()}";
  }
}

class NodeBalancing extends BSharpTreeTransition with NodeBalancingView {
  NodeBalancing(
      {required super.targetId,
      required super.firstOptionalTargetId,
      super.secondOptionalTargetId,
      super.transitionTree});
  @override
  String toString() {
    return "Node balancing: $_targetId with $_firstOptionalTargetId ${secondOptionalTargetId != null ? "and $secondOptionalTargetId" : ""}";
  }
}

class NodeSplit extends BSharpTreeTransition with NodeSplitView {
  NodeSplit({required super.targetId, required super.firstOptionalTargetId});
  @override
  String toString() {
    return "Splitting node: $_targetId with $_firstOptionalTargetId";
  }
}

class NodeFusion extends BSharpTreeTransition with NodeFusionView {
  NodeFusion(
      {required super.targetId,
      required super.firstOptionalTargetId,
      super.secondOptionalTargetId});
  @override
  String toString() {
    return "Fusing node: $_targetId with $_firstOptionalTargetId ${secondOptionalTargetId != null ? "and $secondOptionalTargetId" : ""}";
  }
}

class NodeRelease extends BSharpTreeTransition with NodeReleaseView {
  NodeRelease({required super.targetId, super.transitionTree});
  @override
  String toString() {
    return "Releasing node: ${super.toString()}";
  }
}

class NodeFound extends BSharpTreeTransition with NodeFoundView {
  NodeFound({required super.targetId});
  @override
  String toString() {
    return "Node found: ${super.toString()}";
  }
}
