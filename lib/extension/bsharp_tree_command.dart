import 'package:uuid/uuid.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_extensions/common.dart';
import 'package:visualizeit_extensions/logging.dart';
import 'package:visualizeit_extensions/scripting.dart';

import 'bsharp_tree_extension.dart';
import 'bsharp_tree_model.dart';

abstract class BSharpTreeCommand extends ModelCommand {
  final num value;
  final String uuid;
  final Logger _logger;
  BSharpTreeCommand(this.value, this.uuid, this._logger, super.modelName);

  @override
  Result call(Model model, CommandContext context) {
    BSharpTreeModel treeModel = (model.clone()) as BSharpTreeModel;

    int pendingFrames;
    Model? resultModel;

    (pendingFrames, resultModel) = treeModel.executeCommand(this);

    var result = Result(finished: pendingFrames == 0, model: resultModel);

    _logger.info(() => "command result: $result");

    return result;
  }

  @override
  bool operator ==(Object other) {
    if (other is BSharpTreeCommand) {
      if (runtimeType == other.runtimeType) {
        if (uuid == other.uuid) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll([value, uuid, modelName]);

  Function commandToFunction();

  static CommandDefinition createBSharpTreeCommandDefinition(
      String commandName) {
    return CommandDefinition(BSharpTreeExtension.extensionId, commandName,
        [CommandArgDef("value", ArgType.int)]);
  }
}

class BSharpTreeInsertCommand extends BSharpTreeCommand {
  static final commandDefinition =
      BSharpTreeCommand.createBSharpTreeCommandDefinition("bsharptree-insert");

  BSharpTreeInsertCommand(int value, String modelName)
      : super(value, const Uuid().v4(), Logger("extension.bsharptree.insert"),
            modelName);

  BSharpTreeInsertCommand.build(RawCommand rawCommand)
      : super(
            commandDefinition.getArg(name: "value", from: rawCommand),
            const Uuid().v4(),
            Logger("extension.bsharptree.insert"),
            ""); //TODO entender para que es necesario el modelName acá

  @override
  String toString() {
    return "Inserting value: $value";
  }

  @override
  Function commandToFunction() {
    return (BSharpTree tree) => tree.insert(value);
  }
}

class BSharpTreeRemoveCommand extends BSharpTreeCommand {
  static final commandDefinition =
      BSharpTreeCommand.createBSharpTreeCommandDefinition("bsharptree-remove");

  BSharpTreeRemoveCommand(int value, String modelName)
      : super(value, const Uuid().v4(), Logger("extension.bsharptree.insert"),
            modelName);

  BSharpTreeRemoveCommand.build(RawCommand rawCommand)
      : super(
            commandDefinition.getArg(name: "value", from: rawCommand),
            const Uuid().v4(),
            Logger("extension.bsharptree.remove"),
            ""); //TODO entender para que es necesario el modelName acá
  @override
  String toString() {
    return "Removing value: $value";
  }

  @override
  Function commandToFunction() {
    return (BSharpTree tree) => tree.remove(value);
  }
}

class BSharpTreeFindCommand extends BSharpTreeCommand {
  static final commandDefinition =
      BSharpTreeCommand.createBSharpTreeCommandDefinition("bsharptree-find");

  BSharpTreeFindCommand(int value, String modelName)
      : super(value, const Uuid().v4(), Logger("extension.bsharptree.find"),
            modelName);

  BSharpTreeFindCommand.build(RawCommand rawCommand)
      : super(
            commandDefinition.getArg(name: "value", from: rawCommand),
            const Uuid().v4(),
            Logger("extension.bsharptree.find"),
            ""); //TODO entender para que es necesario el modelName acá
  @override
  String toString() {
    return "Finding value: $value";
  }

  @override
  Function commandToFunction() {
    return (BSharpTree tree) => tree.find(value);
  }
}
