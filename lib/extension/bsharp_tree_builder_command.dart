import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_extension.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_model.dart';
import 'package:visualizeit_extensions/common.dart';
import 'package:visualizeit_extensions/scripting.dart';

class BSharpTreeBuilderCommand extends ModelBuilderCommand {
  static final commandDefinition =
      CommandDefinition(BSharpTreeExtension.extensionId, "bsharptree-create", [
    CommandArgDef("maxCapacity", ArgType.int),
    CommandArgDef("initialValues", ArgType.stringArray)
  ]);
  final int maxCapacity;
  final List<int> initialValues;

  BSharpTreeBuilderCommand(this.maxCapacity, this.initialValues);
  BSharpTreeBuilderCommand.build(RawCommand rawCommand)
      : maxCapacity =
            commandDefinition.getArg(name: "maxCapacity", from: rawCommand),
        initialValues = (commandDefinition.getArg(
                name: "initialValues", from: rawCommand) as List<String>)
            .map(int.parse)
            .toList();

  @override
  BSharpTreeModel call(CommandContext context) {
    return BSharpTreeModel(
        "", maxCapacity, initialValues); //TODO para que es el name?
  }
}
