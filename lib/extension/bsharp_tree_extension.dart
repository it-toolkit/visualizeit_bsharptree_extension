import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_transition.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_builder_command.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_insert_command.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_model.dart';
import 'package:visualizeit_bsharptree_extension/widget/tree_widget.dart';
import 'package:visualizeit_extensions/common.dart';
import 'package:visualizeit_extensions/extension.dart';
import 'package:visualizeit_extensions/logging.dart';
import 'package:visualizeit_extensions/scripting.dart';
import 'package:visualizeit_extensions/visualizer.dart';

final _logger = Logger("extension.bsharptree");

class BSharpTreeExtensionBuilder implements ExtensionBuilder {
  static const _docsLocationPath =
      "packages/visualizeit_extension_template/assets/docs";
  static const _availableDocsLanguages = [LanguageCodes.en];

  @override
  Future<Extension> build() async {
    _logger.trace(() => "Building B# Tree extension");
    var extension = BSharpTreeExtension();

    final markdownDocs = {
      for (final languageCode in _availableDocsLanguages)
        languageCode: '$_docsLocationPath/$languageCode.md'
    };

    return Extension(
        BSharpTreeExtension.extensionId, extension, extension, markdownDocs);
  }
}

class BSharpTreeExtension implements ScriptingExtension, VisualizerExtension {
  static const extensionId = "bsharp-tree-extension";

  @override
  Command? buildCommand(RawCommand rawCommand) {
    var maybeCommand = getAllCommandDefinitions()
        .firstWhereOrNull((commandDef) => commandDef.name == rawCommand.name);
    if (maybeCommand == null) {
      return null;
    } else {
      if (maybeCommand.name ==
          BSharpTreeBuilderCommand.commandDefinition.name) {
        return BSharpTreeBuilderCommand.build(rawCommand);
      } else if (maybeCommand.name ==
          BSharpTreeInsertCommand.commandDefinition.name) {
        return BSharpTreeInsertCommand.build(rawCommand);
      } else {
        return null; // TODO mas comandos
      }
    }
  }

  @override
  List<CommandDefinition> getAllCommandDefinitions() {
    _logger.trace(() => "Getting B# tree extension command definitions");
    return [
      BSharpTreeBuilderCommand.commandDefinition,
      BSharpTreeInsertCommand.commandDefinition
    ];
  }

  @override
  Widget? render(Model model, BuildContext context) {
    //TODO logica de elección de arbol a retornar
    if (model is BSharpTreeModel) {
      return TreeWidget(model.currentTree!, model.currentTransition);
    } else {
      return null;
    }
  }
}
