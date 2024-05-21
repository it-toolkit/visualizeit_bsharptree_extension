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
}

class NodeCreation extends BSharpTreeTransition {
  NodeCreation({required super.targetId, super.transitionTree}) {
    logger.debug(() => "Creando nodo con id: $_targetId");
  }

  @override
  String toString() {
    return "Creando nodo: ${super.toString()}";
  }
}

class NodeRead extends BSharpTreeTransition {
  NodeRead({required super.targetId}) {
    logger.debug(() => "nodo $_targetId leido");
  }
}

class NodeWritten extends BSharpTreeTransition {
  NodeWritten({required super.targetId, super.transitionTree}) {
    logger.debug(() => "nodo $_targetId escrito");
  }
}

class NodeOverflow extends BSharpTreeTransition {
  NodeOverflow({required super.targetId, super.transitionTree}) {
    logger.debug(() => "nodo $_targetId supera la capacidad maxima");
  }
}

class NodeUnderflow extends BSharpTreeTransition {
  NodeUnderflow({required super.targetId, super.transitionTree}) {
    logger.debug(() => "nodo $_targetId por debajo de la capacidad minima");
  }
}

class NodeBalancing extends BSharpTreeTransition {
  NodeBalancing(
      {required super.targetId,
      required super.firstOptionalTargetId,
      super.secondOptionalTargetId,
      super.transitionTree}) {
    var buffer = StringBuffer(
        "balanceando nodo $_targetId con nodo $_firstOptionalTargetId");
    if (secondOptionalTargetId != null) {
      buffer.write("y nodo $secondOptionalTargetId");
    }
    logger.debug(() => buffer.toString());
  }
}

class NodeSplit extends BSharpTreeTransition {
  NodeSplit({required super.targetId, required super.firstOptionalTargetId}) {
    logger.debug(
        () => "spliteando el nodo $_targetId con $_firstOptionalTargetId");
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
}

class NodeRelease extends BSharpTreeTransition {
  NodeRelease({required super.targetId, super.transitionTree}) {
    logger.debug(() => "liberando el nodo $_targetId");
  }
}
