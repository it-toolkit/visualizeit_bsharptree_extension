import 'package:visualizeit_bsharptree_extension/extension/bsharp_transition.dart';
import 'package:visualizeit_bsharptree_extension/model/tree_observer.dart';
import 'package:visualizeit_extensions/logging.dart';

class TreeLoggerObserver extends TreeObserver {
  TreeLoggerObserver(super.observedTree);
  final logger = Logger("extension.bsharptree.model");

  @override
  void notify(BSharpTreeTransition transition) {
    logger.trace(() => transition.toString());
  }
}
