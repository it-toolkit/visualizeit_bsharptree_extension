import 'package:visualizeit_bsharptree_extension/extension/bsharp_transition.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';

abstract class TreeObserver {
  final BSharpTree _observedTree;

  TreeObserver(this._observedTree) {
    _observedTree.registerObserver(this);
  }

  void notify(BSharpTreeTransition transition);

  void removeObserver() {
    _observedTree.removeObserver(this);
  }
}
