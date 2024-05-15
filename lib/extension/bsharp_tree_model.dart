import 'package:visualizeit_bsharptree_extension/extension/bsharp_transition.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_extension.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_extensions/common.dart';

class BSharpTreeModel extends Model {
  BSharpTree _currentTree;
  List<BSharpTreeTransition> _transitions = [];
  int _currentFrame = 0;
  String _currentUuid = "";

  BSharpTree get currentTree => _currentTree;
  int get _pendingFrames => _transitions.length - _currentFrame - 1;

  BSharpTreeModel(String name, int treeCapacity, List<int> initialValues)
      : _currentTree = BSharpTree<num>(treeCapacity),
        super(BSharpTreeExtension.extensionId, name) {
    _currentTree.insertAll(initialValues);
  }
  /*   : _currentTree = BSharpTree<num>(treeCapacity),
        super(BSharpTreeExtension.extensionId, name);*/

  (int, Model) executeInsertion(String uuid, num value) {
    if (_canExecuteCommand(uuid)) {
      if (isInTransition()) {
        //El arbol está en transicion
        _currentFrame++;
        if (_transitions[_currentFrame].hasTree()) {
          _currentTree = _transitions[_currentFrame].transitionTree!;
        }
        if (_currentFrame == _transitions.length - 1) {
          //finaliza la transicion
          _transitions = [];
          _currentFrame = 0;
          _currentUuid = "";
          return (0, this);
        }
      } else {
        //Arranca una transición
        _currentUuid = uuid;
        _currentTree.insert(value);
        _transitions = _currentTree.getTransitions();
        if (_transitions.firstOrNull != null) {
          _currentTree = _transitions.first.transitionTree!;
        }
      }
      return (_pendingFrames, this);
    } else {
      throw UnsupportedError(
          "cant execute a command while another command is on transition");
    }
  }

  bool _canExecuteCommand(uuid) {
    return _transitions.isEmpty || _currentUuid == uuid;
  }

  bool isInTransition() {
    return _transitions.isNotEmpty;
  }

  @override
  Model clone() {
    return this;
  }
}
