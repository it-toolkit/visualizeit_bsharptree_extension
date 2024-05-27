import 'package:visualizeit_bsharptree_extension/extension/bsharp_transition.dart';
import 'package:visualizeit_bsharptree_extension/model/tree_observer.dart';

class TreeTransitionObserver extends TreeObserver {
  final List<BSharpTreeTransition> _transitions = [];

  TreeTransitionObserver(super.observedTree);

  List<BSharpTreeTransition> get transitions => _transitions;

  @override
  void notify(BSharpTreeTransition transition) {
    _transitions.add(transition);
  }
}
