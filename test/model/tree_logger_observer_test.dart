import 'package:flutter_test/flutter_test.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_bsharptree_extension/model/tree_logger_observer.dart';

void main() {
  test("find function observed", () {
    var tree = BSharpTree<num>(2);
    tree.insertAll([10, 22, 150, 166, 210, 233, 370]);

    TreeLoggerObserver(tree);

    tree.find(166);
  });
}
