import 'package:flutter_test/flutter_test.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_command.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visualizeit_extensions/common.dart';
import 'package:visualizeit_extensions/scripting.dart';

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

  test("remove command construction", () {
    var command = BSharpTreeRemoveCommand(10, "modelName");

    expect(command.uuid, isNotEmpty);
    expect(command.modelName, equals("modelName"));
  });

  test("insert command call on a model that has no pending frames", () {
    var command = BSharpTreeInsertCommand(10, "modelName");
    when(() => treeModelMock.executeCommand(command))
        .thenReturn((0, resultTreeModelMock));
    when(() => treeModelMock.clone()).thenReturn(treeModelMock);

    var commandResult = command.call(treeModelMock, commandContextMock);

    expect(commandResult.finished, isTrue);
    expect(commandResult.model,
        allOf(isA<BSharpTreeModel>(), equals(resultTreeModelMock)));
  });

  test("remove command call on a model that has no pending frames", () {
    var command = BSharpTreeRemoveCommand(10, "modelName");
    when(() => treeModelMock.executeCommand(command))
        .thenReturn((0, resultTreeModelMock));
    when(() => treeModelMock.clone()).thenReturn(treeModelMock);

    var commandResult = command.call(treeModelMock, commandContextMock);

    expect(commandResult.finished, isTrue);
    expect(commandResult.model,
        allOf(isA<BSharpTreeModel>(), equals(resultTreeModelMock)));
  });

  test("insert command call on a model that keeps ongoing", () {
    var command = BSharpTreeInsertCommand(10, "modelName");
    when(() => treeModelMock.executeCommand(command))
        .thenReturn((4, resultTreeModelMock));
    when(() => treeModelMock.clone()).thenReturn(treeModelMock);

    var commandResult = command.call(treeModelMock, commandContextMock);

    expect(commandResult.finished, isFalse);
    expect(commandResult.model,
        allOf(isA<BSharpTreeModel>(), equals(resultTreeModelMock)));
  });

  test("remove command call on a model that keeps ongoing", () {
    var command = BSharpTreeRemoveCommand(10, "modelName");
    when(() => treeModelMock.executeCommand(command))
        .thenReturn((4, resultTreeModelMock));
    when(() => treeModelMock.clone()).thenReturn(treeModelMock);

    var commandResult = command.call(treeModelMock, commandContextMock);

    expect(commandResult.finished, isFalse);
    expect(commandResult.model,
        allOf(isA<BSharpTreeModel>(), equals(resultTreeModelMock)));
  });

  test("Insert Value under min range", () {
    var rawCommand =
        RawCommand.withPositionalArgs("bsharptree-insert", [0]);

    expect(
        () => BSharpTreeInsertCommand.build(rawCommand),
        throwsA(allOf(
            isException,
            predicate((e) =>
                e.toString().contains("'value' must be in range")))));
  });

  test("Insert Value over max range", () {
    var rawCommand =
        RawCommand.withPositionalArgs("bsharptree-insert", [100000]);

    expect(
        () => BSharpTreeInsertCommand.build(rawCommand),
        throwsA(allOf(
            isException,
            predicate((e) =>
                e.toString().contains("'value' must be in range")))));
  });

  test("Remove Value under min range", () {
    var rawCommand =
        RawCommand.withPositionalArgs("bsharptree-remove", [0]);

    expect(
        () => BSharpTreeInsertCommand.build(rawCommand),
        throwsA(allOf(
            isException,
            predicate((e) =>
                e.toString().contains("'value' must be in range")))));
  });

  test("Remove Value over max range", () {
    var rawCommand =
        RawCommand.withPositionalArgs("bsharptree-remove", [100000]);

    expect(
        () => BSharpTreeInsertCommand.build(rawCommand),
        throwsA(allOf(
            isException,
            predicate((e) =>
                e.toString().contains("'value' must be in range")))));
  });

  test("Find Value under min range", () {
    var rawCommand =
        RawCommand.withPositionalArgs("bsharptree-find", [0]);

    expect(
        () => BSharpTreeInsertCommand.build(rawCommand),
        throwsA(allOf(
            isException,
            predicate((e) =>
                e.toString().contains("'value' must be in range")))));
  });

  test("Find Value over max range", () {
    var rawCommand =
        RawCommand.withPositionalArgs("bsharptree-find", [100000]);

    expect(
        () => BSharpTreeInsertCommand.build(rawCommand),
        throwsA(allOf(
            isException,
            predicate((e) =>
                e.toString().contains("'value' must be in range")))));
  });
}
