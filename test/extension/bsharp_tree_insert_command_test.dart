import 'package:flutter_test/flutter_test.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_insert_command.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visualizeit_extensions/common.dart';

class BSharpTreeModelMock extends Mock implements BSharpTreeModel {}

class CommandContextMock extends Mock implements CommandContext {}

void main() {
  var treeModelMock = BSharpTreeModelMock();
  var resultTreeModelMock = BSharpTreeModelMock();
  var commandContextMock = CommandContextMock();

  tearDown(() => reset(treeModelMock));

  test("insert command construction", () {
    var command = BSharpTreeInsertCommand(10, "modelName");

    expect(command.uuid, isNotEmpty);
    expect(command.modelName, equals("modelName"));
  });

  test("insert command call on a model that has no pending frames", () {
    when(() => treeModelMock.executeInsertion(any(), any()))
        .thenReturn((0, resultTreeModelMock));
    var command = BSharpTreeInsertCommand(10, "modelName");

    var commandResult = command.call(treeModelMock, commandContextMock);

    expect(commandResult.finished, isTrue);
    expect(commandResult.model,
        allOf(isA<BSharpTreeModel>(), equals(resultTreeModelMock)));
  });

  test("insert command call on a model that keeps ongoing", () {
    when(() => treeModelMock.executeInsertion(any(), any()))
        .thenReturn((4, resultTreeModelMock));
    var command = BSharpTreeInsertCommand(10, "modelName");

    var commandResult = command.call(treeModelMock, commandContextMock);

    expect(commandResult.finished, isFalse);
    expect(commandResult.model,
        allOf(isA<BSharpTreeModel>(), equals(resultTreeModelMock)));
  });
}
