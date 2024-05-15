import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_extension.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_model.dart';
import 'package:visualizeit_extensions/common.dart';
import 'package:visualizeit_extensions/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:visualizeit_extensions/scripting.dart';

class BSharpTreeInsertCommand extends ModelCommand {
  static final commandDefinition = CommandDefinition(
      BSharpTreeExtension.extensionId,
      "bsharptree-insert",
      [CommandArgDef("value", ArgType.int)]);

  final num value;
  final String uuid;
  final _logger = Logger("extension.bsharptree.insert");

  BSharpTreeInsertCommand(this.value, super.modelName)
      : uuid = const Uuid().v4();

  BSharpTreeInsertCommand.build(RawCommand rawCommand)
      : value = commandDefinition.getArg(name: "value", from: rawCommand),
        uuid = const Uuid().v4(),
        super(""); //TODO entender para que es necesario el modelName acá

  @override
  Result call(Model model, CommandContext context) {
    BSharpTreeModel treeModel = model as BSharpTreeModel;

    int pendingFrames;
    Model resultModel;

    (pendingFrames, resultModel) = treeModel.executeInsertion(uuid, value);

    var result = Result(finished: pendingFrames == 0, model: resultModel);

    _logger.info(() => "insertion result $result");

    return result;
  }
}
