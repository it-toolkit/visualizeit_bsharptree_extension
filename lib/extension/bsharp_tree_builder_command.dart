import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_extension.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_model.dart';
import 'package:visualizeit_extensions/common.dart';
import 'package:visualizeit_extensions/scripting.dart';

class BSharpTreeBuilderCommand extends ModelBuilderCommand {
  static final commandDefinition =
    CommandDefinition(BSharpTreeExtension.extensionId, "bsharptree-create", [
    CommandArgDef("maxCapacity", ArgType.int),
    CommandArgDef("initialValues", ArgType.intArray),
    CommandArgDef("autoIncremental", ArgType.boolean, required: false, defaultValue: "false")
  ]);

  final int maxCapacity;
  final List<int> initialValues;
  final bool? autoIncremental;

  BSharpTreeBuilderCommand(this.maxCapacity, this.initialValues,
      [this.autoIncremental]);
  BSharpTreeBuilderCommand.build(RawCommand rawCommand)
      : maxCapacity = _getIntArgInRange(name: "maxCapacity", from: rawCommand, min: 1, max: 30),
        initialValues = (commandDefinition.getArg(name: "initialValues", from: rawCommand) as List<int>),
        autoIncremental = commandDefinition.getArg(name: "autoIncremental", from: rawCommand);

  @override
  BSharpTreeModel call(CommandContext context) {
    return BSharpTreeModel("", maxCapacity, initialValues, autoIncremental ?? false); //TODO para que es el name?
  }

  static int _getIntArgInRange({required String name, required RawCommand from, required int min, required int max}) {
    int value = commandDefinition.getArg(name: name, from: from);
    if (value < min || value > max) throw Exception("Value must be in range [ $min , $max ]");

    return value;
  }
}
