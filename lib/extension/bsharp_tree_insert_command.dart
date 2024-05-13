import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_model.dart';
import 'package:visualizeit_extensions/common.dart';
import 'package:visualizeit_extensions/logging.dart';
import 'package:uuid/uuid.dart';

class BSharpTreeInsertCommand extends ModelCommand {
  final num _value;
  final String uuid;
  final _logger = Logger("extension.bsharptree.insert");

  BSharpTreeInsertCommand(this._value, super.modelName)
      : uuid = const Uuid().v4();

  @override
  Result call(Model model) {
    BSharpTreeModel treeModel = model as BSharpTreeModel;

    int pendingFrames;
    Model resultModel;

    (pendingFrames, resultModel) = treeModel.executeInsertion(uuid, _value);

    var result = Result(finished: pendingFrames == 0, model: resultModel);

    _logger.info(() => "insertion result $result");

    return result;
  }
}
