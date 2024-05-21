import 'package:flutter/material.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_builder_command.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_command.dart';
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
      "packages/visualizeit_bsharptree_extension/assets/docs";
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

class BSharpTreeExtension extends DefaultScriptingExtension
    implements ScriptingExtension, VisualizerExtension {
  static const extensionId = "bsharp-tree-extension";

  BSharpTreeExtension()
      : super({
          BSharpTreeBuilderCommand.commandDefinition:
              BSharpTreeBuilderCommand.build,
          BSharpTreeInsertCommand.commandDefinition:
              BSharpTreeInsertCommand.build,
          BSharpTreeRemoveCommand.commandDefinition:
              BSharpTreeRemoveCommand.build
        });

  @override
  Widget? render(Model model, BuildContext context) {
    if (model is BSharpTreeModel) {
      return TreeWidget(model.currentTree!, model.currentTransition);
    } else {
      return null;
    }
  }
}
