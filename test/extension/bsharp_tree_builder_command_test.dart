import 'package:flutter_test/flutter_test.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_builder_command.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_extension.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visualizeit_extensions/common.dart';

class CommandContextMock extends Mock implements CommandContext {}

void main() {
  var commandContextMock = CommandContextMock();
  test("Call test", () {
    var command = BSharpTreeBuilderCommand(3, []);

    var model = command.call(commandContextMock);
    expect(model.extensionId, BSharpTreeExtension.extensionId);
    expect(model.name,
        ""); //TODO arreglar este test cuando entienda que es el name
    expect(model.currentTree.maxCapacity, 3);
    expect(model.currentTree.nodesQuantity, 0);
    expect(model.currentTree.depth, 0);
  });
}
