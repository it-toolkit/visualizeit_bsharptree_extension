import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';

abstract class BSharpTreeTransition {
  final String _targetId;
  final String? _firstOptionalTargetId;
  final String? _secondOptionalTargetId;

  String get targetId => _targetId;
  String? get firstOptionalTarget => _firstOptionalTargetId;
  String? get secondOptionalTargetId => _secondOptionalTargetId;

  BSharpTreeTransition(this._targetId,
      [this._firstOptionalTargetId, this._secondOptionalTargetId]);
}

class NodeCreation extends BSharpTreeTransition {
  NodeCreation(super._targetId) {
    print("Creando nodo con id: $_targetId");
  }
}

class NodeRead extends BSharpTreeTransition {
  NodeRead(super._targetId);
}

class NodeWritten extends BSharpTreeTransition {
  NodeWritten(super._targetId);
}

class NodeOverflow extends BSharpTreeTransition {
  NodeOverflow(super._targetId) {
    print("nodo supera la capacidad maxima: $_targetId");
  }
}

class NodeUnderflow extends BSharpTreeTransition {
  NodeUnderflow(super._targetId);
}

class NodeBalancing extends BSharpTreeTransition {
  NodeBalancing(super._targetId, super._firstOptionalTargetId) {
    print("balanceando nodo $_targetId con nodo _firstOptionalTargetId");
  }
}

class NodeSplit extends BSharpTreeTransition {
  NodeSplit(super._targetId) {
    print("spliteando el nodo $_targetId");
  }
}
