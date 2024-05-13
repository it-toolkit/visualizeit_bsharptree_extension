import 'package:flutter_test/flutter_test.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_builder_command.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_model.dart';

void main() {
  test("Call test", () {
    var command = BSharpTreeBuilderCommand(3);

    var model = command.call();
    expect(model.extensionId, BSharpTreeModel.BSharpTreeExtensionId);
    expect(model.name,
        ""); //TODO arreglar este test cuando entienda que es el name
    expect(model.currentTree.maxCapacity, 3);
    expect(model.currentTree.nodesQuantity, 0);
    expect(model.currentTree.depth, 0);
  });
}
