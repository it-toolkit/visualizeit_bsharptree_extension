import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_extensions/logging.dart';

final logger = Logger("extension.bsharptree.model");

abstract class BSharpTreeTransition {
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

  BSharpTreeTransition(
      {required String targetId,
      String? firstOptionalTargetId,
      String? secondOptionalTargetId,
      BSharpTree? transitionTree})
      : _targetId = targetId,
        _firstOptionalTargetId = firstOptionalTargetId,
        _secondOptionalTargetId = secondOptionalTargetId,
        _transitionTree = transitionTree;

  bool isATarget(String id) {
    return _targetId == id ||
        _firstOptionalTargetId == id ||
        _secondOptionalTargetId == id;
  }
}

class NodeCreation extends BSharpTreeTransition {
  NodeCreation({required super.targetId, super.transitionTree}) {
    logger.debug(() => "Creando nodo con id: $_targetId");
  }

  @override
  String toString() {
    return "Creating node: ${super.toString()}";
  }
}

class NodeReuse extends BSharpTreeTransition {
  NodeReuse({required super.targetId, super.transitionTree}) {
    logger.debug(() => "Reutilizando nodo con id: $_targetId");
  }

  @override
  String toString() {
    return "Reusing node: ${super.toString()}";
  }
}

class NodeRead extends BSharpTreeTransition {
  NodeRead({required super.targetId}) {
    logger.debug(() => "nodo $_targetId leido");
  }
  @override
  String toString() {
    return "Node read: ${super.toString()}";
  }
}

class NodeWritten extends BSharpTreeTransition {
  NodeWritten({required super.targetId, super.transitionTree}) {
    logger.debug(() => "nodo $_targetId escrito");
  }
  @override
  String toString() {
    return "Node Written: ${super.toString()}";
  }
}

class NodeOverflow extends BSharpTreeTransition {
  NodeOverflow({required super.targetId, super.transitionTree}) {
    logger.debug(() => "nodo $_targetId supera la capacidad maxima");
  }
  @override
  String toString() {
    return "Overflowed node: ${super.toString()}";
  }
}

class NodeUnderflow extends BSharpTreeTransition {
  NodeUnderflow({required super.targetId, super.transitionTree}) {
    logger.debug(() => "nodo $_targetId por debajo de la capacidad minima");
  }
  @override
  String toString() {
    return "Underflowed Node: ${super.toString()}";
  }
}

class NodeBalancing extends BSharpTreeTransition {
  NodeBalancing(
      {required super.targetId,
      required super.firstOptionalTargetId,
      super.secondOptionalTargetId,
      super.transitionTree}) {
    var buffer = StringBuffer(
        "Balanceando nodo $_targetId con nodo $_firstOptionalTargetId");
    if (secondOptionalTargetId != null) {
      buffer.write("y nodo $secondOptionalTargetId");
    }
    logger.debug(() => buffer.toString());
  }
  @override
  String toString() {
    return "Node balancing: $_targetId with $_firstOptionalTargetId ${secondOptionalTargetId != null ? "and $secondOptionalTargetId" : ""}";
  }
}

class NodeSplit extends BSharpTreeTransition {
  NodeSplit({required super.targetId, required super.firstOptionalTargetId}) {
    logger.debug(
        () => "spliteando el nodo $_targetId con $_firstOptionalTargetId");
  }
  @override
  String toString() {
    return "Splitting node: $_targetId with $_firstOptionalTargetId";
  }
}

class NodeFusion extends BSharpTreeTransition {
  NodeFusion(
      {required super.targetId,
      required super.firstOptionalTargetId,
      super.secondOptionalTargetId}) {
    var buffer = StringBuffer(
        "fusionando nodo $_targetId con nodo $_firstOptionalTargetId");
    if (secondOptionalTargetId != null) {
      buffer.write("y nodo $secondOptionalTargetId");
    }
    logger.debug(() => buffer.toString());
  }
  @override
  String toString() {
    return "Fusing node: $_targetId with $_firstOptionalTargetId ${secondOptionalTargetId != null ? "and $secondOptionalTargetId" : ""}";
  }
}

class NodeRelease extends BSharpTreeTransition {
  NodeRelease({required super.targetId, super.transitionTree}) {
    logger.debug(() => "liberando el nodo $_targetId");
  }
  @override
  String toString() {
    return "Releasing node: ${super.toString()}";
  }
}
