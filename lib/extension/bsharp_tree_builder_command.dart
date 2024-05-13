import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_model.dart';
import 'package:visualizeit_extensions/common.dart';

class BSharpTreeBuilderCommand extends ModelBuilderCommand {
  final int treeCapacity;

  BSharpTreeBuilderCommand(this.treeCapacity);

  @override
  BSharpTreeModel call() {
    return BSharpTreeModel("", treeCapacity); //TODO para que es el name?
  }
}
