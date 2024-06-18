import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_builder_command.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_command.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_extension.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_model.dart';
import 'package:visualizeit_extensions/common.dart';
import 'package:visualizeit_extensions/scripting.dart';
import 'package:visualizeit_extensions/visualizer.dart';

class BuildContextMock extends Mock implements BuildContext {}

void main() {
  var buildContextMock = BuildContextMock();
  var createRawCommand = RawCommand.withNamedArgs("bsharptree-create", {
    "maxCapacity": "3",
    "initialValues": ["1", "3"]
  });

  var insertRawCommand =
      RawCommand.withNamedArgs("bsharptree-insert", {"value": "90"});

  var extensionBuilder = BSharpTreeExtensionBuilder();

  testWidgets("test tree creation", (tester) async {
    var extension = await extensionBuilder.build();

    Scripting scriptingExtension = extension.scripting;
    Renderer visualizerExtension = extension.renderer;

    BSharpTreeBuilderCommand? createCommand = scriptingExtension
        .buildCommand(createRawCommand) as BSharpTreeBuilderCommand?;

    BSharpTreeModel? model = createCommand!.call(CommandContext());
    var treeWidget = visualizerExtension.renderAll(model, buildContextMock);

    // Check the widget after the model creation
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: InteractiveViewer(
        clipBehavior: Clip.none,
        child: treeWidget.elementAt(0),
      ),
    )));
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('90'), findsNothing);
  });

  testWidgets("test tree insertion", (tester) async {
    var extension = await extensionBuilder.build();

    Scripting scriptingExtension = extension.scripting;
    Renderer visualizerExtension = extension.renderer;

    BSharpTreeBuilderCommand? createCommand = scriptingExtension
        .buildCommand(createRawCommand) as BSharpTreeBuilderCommand?;
    BSharpTreeInsertCommand? insertCommand = scriptingExtension
        .buildCommand(insertRawCommand) as BSharpTreeInsertCommand?;

    BSharpTreeModel? model = createCommand!.call(CommandContext());
    Result result = insertCommand!.call(model, CommandContext());
    model = result.model as BSharpTreeModel?;

    // Check the widget
    var treeWidget = visualizerExtension.renderAll(model!, buildContextMock);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: InteractiveViewer(
        clipBehavior: Clip.none,
        child: treeWidget.elementAt(0),
      ),
    )));
    expect(result.finished, false);
    expect(model, isNotNull);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('90'), findsNothing);
  });

  testWidgets("test tree insertion - second step", (tester) async {
    var extension = await extensionBuilder.build();

    Scripting scriptingExtension = extension.scripting;
    Renderer visualizerExtension = extension.renderer;

    BSharpTreeBuilderCommand? createCommand = scriptingExtension
        .buildCommand(createRawCommand) as BSharpTreeBuilderCommand?;
    BSharpTreeInsertCommand? insertCommand = scriptingExtension
        .buildCommand(insertRawCommand) as BSharpTreeInsertCommand?;

    BSharpTreeModel? model = createCommand!.call(CommandContext());
    Result firstResult = insertCommand!.call(model, CommandContext());

    expect(firstResult.finished, false);
    expect(firstResult.model, isNotNull);
    Result secondResult =
        insertCommand.call(firstResult.model!, CommandContext());

    expect(secondResult.finished, true);
    expect(secondResult.model, isNotNull);

    // Check the widget
    var treeWidget =
        visualizerExtension.renderAll(secondResult.model!, buildContextMock);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: InteractiveViewer(
        clipBehavior: Clip.none,
        child: treeWidget.elementAt(0),
      ),
    )));

    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('90'), findsOneWidget);
  });
}
