import 'package:flutter_test/flutter_test.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_builder_command.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_extension.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visualizeit_extensions/common.dart';
import 'package:visualizeit_extensions/scripting.dart';

class CommandContextMock extends Mock implements CommandContext {}

void main() {
  var commandContextMock = CommandContextMock();
  test("Build tree without autoincremental parameter", () {
    var command = BSharpTreeBuilderCommand(3, []);

    var model = command.call(commandContextMock);
    expect(model.extensionId, BSharpTreeExtension.extensionId);
    expect(model.name, "");
    expect(model.currentTree!.maxCapacity, 3);
    expect(model.currentTree!.nodesQuantity, 0);
    expect(model.currentTree!.depth, 0);
    expect(model.currentTree!.keysAreAutoincremental, false);
  });

  test("Build tree with autoincremental parameter", () {
    var command = BSharpTreeBuilderCommand(3, [], true);

    var model = command.call(commandContextMock);
    expect(model.extensionId, BSharpTreeExtension.extensionId);
    expect(model.name, "");
    expect(model.currentTree!.maxCapacity, 3);
    expect(model.currentTree!.nodesQuantity, 0);
    expect(model.currentTree!.depth, 0);
    expect(model.currentTree!.keysAreAutoincremental, true);
  });

  test("Max capacity under min range", () {
    var rawCommand =
        RawCommand.withPositionalArgs("bsharptree-create", [2, []]);

    expect(
        () => BSharpTreeBuilderCommand.build(rawCommand),
        throwsA(allOf(
            isException,
            predicate((e) =>
                e.toString().contains("'maxCapacity' must be in range")))));
  });

  test("Max capacity over max range", () {
    var rawCommand =
        RawCommand.withPositionalArgs("bsharptree-create", [11, []]);

    expect(
        () => BSharpTreeBuilderCommand.build(rawCommand),
        throwsA(allOf(
            isException,
            predicate((e) =>
                e.toString().contains("'maxCapacity' must be in range")))));
  });
}
