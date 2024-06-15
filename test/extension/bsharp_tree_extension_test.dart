import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_builder_command.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_command.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_extension.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_model.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_bsharptree_extension/widget/tree_widget.dart';
import 'package:visualizeit_extensions/common.dart';
import 'package:visualizeit_extensions/scripting.dart';

class BSharpTreeModelMock extends Mock implements BSharpTreeModel {}

class AnotherModelMock extends Mock implements Model {}

class BuildContextMock extends Mock implements BuildContext {}

void main() {
  var extension = BSharpTreeExtension();
  var treeModelMock = BSharpTreeModelMock();
  var buildContextMock = BuildContextMock();
  var anotherModelMock = AnotherModelMock();

  group("Extension tests - ", () {
    test("command definitions must be 4", () {
      expect(
          extension.getAllCommandDefinitions(),
          allOf(
              hasLength(4),
              containsAll([
                BSharpTreeInsertCommand.commandDefinition,
                BSharpTreeBuilderCommand.commandDefinition,
                BSharpTreeRemoveCommand.commandDefinition,
                BSharpTreeFindCommand.commandDefinition
              ])));
    });

    test("build tree builder command with initial values", () {
      var rawCommand = RawCommand.withNamedArgs("bsharptree-create", {
        "maxCapacity": "3",
        "initialValues": ["1", "3"]
      });
      var maybeCommand = extension.buildCommand(rawCommand);
      expect(maybeCommand, allOf(isNotNull, isA<BSharpTreeBuilderCommand>()));
      var builderCommand = maybeCommand as BSharpTreeBuilderCommand;
      expect(builderCommand.maxCapacity, 3);
      expect(builderCommand.initialValues, containsAll([1, 3]));
    });

     test("build tree builder command with initial values and autoincremental", () {
      var rawCommand = RawCommand.withPositionalArgs("bsharptree-create", [3,["1", "3"],true]);
      var maybeCommand = extension.buildCommand(rawCommand);
      expect(maybeCommand, allOf(isNotNull, isA<BSharpTreeBuilderCommand>()));
      var builderCommand = maybeCommand as BSharpTreeBuilderCommand;
      expect(builderCommand.maxCapacity, 3);
      expect(builderCommand.initialValues, containsAll([1, 3]));
      expect(builderCommand.autoIncremental, allOf(isNotNull, isTrue));
    });

    test("build tree builder command with no initial values", () {
      var rawCommand = RawCommand.withNamedArgs(
          "bsharptree-create", {"maxCapacity": "3", "initialValues": []});
      var maybeCommand = extension.buildCommand(rawCommand);
      expect(maybeCommand, allOf(isNotNull, isA<BSharpTreeBuilderCommand>()));
      var builderCommand = maybeCommand as BSharpTreeBuilderCommand;
      expect(builderCommand.maxCapacity, 3);
      expect(builderCommand.initialValues, isEmpty);
    });

    test("tree insert value command", () {
      var rawCommand =
          RawCommand.withNamedArgs("bsharptree-insert", {"value": "90"});
      var maybeCommand = extension.buildCommand(rawCommand);
      expect(maybeCommand, allOf(isNotNull, isA<BSharpTreeInsertCommand>()));
      var insertCommand = maybeCommand as BSharpTreeInsertCommand;
      expect(insertCommand.value, 90);
    });

    test("tree remove value command", () {
      var rawCommand =
          RawCommand.withNamedArgs("bsharptree-remove", {"value": "90"});
      var maybeCommand = extension.buildCommand(rawCommand);
      expect(maybeCommand, allOf(isNotNull, isA<BSharpTreeRemoveCommand>()));
      var removeCommand = maybeCommand as BSharpTreeRemoveCommand;
      expect(removeCommand.value, 90);
    });

    test("tree find value command", () {
      var rawCommand =
          RawCommand.withNamedArgs("bsharptree-find", {"value": "90"});
      var maybeCommand = extension.buildCommand(rawCommand);
      expect(maybeCommand, allOf(isNotNull, isA<BSharpTreeFindCommand>()));
      var findCommand = maybeCommand as BSharpTreeFindCommand;
      expect(findCommand.value, 90);
    });

    test("non existent command", () {
      var rawCommand = RawCommand.literal("im-non-existent");
      var maybeCommand = extension.buildCommand(rawCommand);
      expect(maybeCommand, isNull);
    });

    test("render a BSharpTree Model", () {
      when(() => treeModelMock.currentTree).thenReturn(BSharpTree<num>(3));
      var maybeWidget = extension.render(treeModelMock, buildContextMock);
      expect(maybeWidget, allOf(isNotNull, isA<TreeWidget>()));
    });

    test("render another Model", () {
      expect(extension.render(anotherModelMock, buildContextMock), isNull);
    });
  });
}
