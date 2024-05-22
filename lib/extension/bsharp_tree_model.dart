import 'package:visualizeit_bsharptree_extension/extension/bsharp_transition.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_command.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_extension.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_extensions/common.dart';

class BSharpTreeModel extends Model {
  final BSharpTree _baseTree;
  BSharpTree? _lastTransitionTree;
  List<BSharpTreeTransition> _transitions = [];
  int _currentFrame = 0;
  //String _currentUuid = "";
  BSharpTreeCommand? commandInExecution;

  BSharpTree? get currentTree => _transitions.isEmpty
      ? _lastTransitionTree
      : _transitions[_currentFrame].transitionTree ?? _lastTransitionTree;

  BSharpTreeTransition? get currentTransition =>
      _transitions.isNotEmpty ? _transitions[_currentFrame] : null;
  int get _pendingFrames => _transitions.length - _currentFrame - 1;

  BSharpTreeModel(String name, int treeCapacity, List<int> initialValues)
      : _baseTree = BSharpTree<num>(treeCapacity),
        super(BSharpTreeExtension.extensionId, name) {
    _baseTree.insertAll(initialValues);
    _lastTransitionTree = _baseTree;
  }
  BSharpTreeModel.copyWith(
      this._baseTree,
      this._currentFrame,
      this.commandInExecution,
      this._lastTransitionTree,
      this._transitions,
      super.name,
      super.extensionId);

  (int, Model) executeCommand(BSharpTreeCommand command) {
    var functionToExecute = getFunctionFromCommand(command);
    if (_canExecuteCommand(command)) {
      if (isInTransition()) {
        //El arbol está en transicion
        _currentFrame++;
        if (_transitions[_currentFrame].hasTree()) {
          _lastTransitionTree = _transitions[_currentFrame].transitionTree!;
        }
      } else {
        //Arranca una transición
        _lastTransitionTree = _baseTree.clone();
        //_currentUuid = command.uuid;
        commandInExecution = command;
        _currentFrame = 0;
        functionToExecute.call(_baseTree);
        _transitions = _baseTree.getTransitions();
        if (_transitions.firstOrNull?.transitionTree != null) {
          _lastTransitionTree = _transitions.first.transitionTree;
        }
      }
      return (_pendingFrames, this);
    } else {
      throw UnsupportedError(
          "cant execute a command while another command is on transition");
    }
  }

  /*(int, Model) executeInsertion(String uuid, num value) {
    if (_canExecuteCommand(uuid)) {
      if (isInTransition()) {
        //El arbol está en transicion
        _currentFrame++;
        if (_transitions[_currentFrame].hasTree()) {
          _lastTransitionTree = _transitions[_currentFrame].transitionTree!;
        }
        /*if (_currentFrame == _transitions.length - 1) {
          //finaliza la transicion
          //_transitions = [];
          //_currentFrame = 0;
          //_currentUuid = "";
          return (0, this);
        }*/
      } else {
        //Arranca una transición
        _lastTransitionTree = _baseTree.clone();
        _currentUuid = uuid;
        _currentFrame = 0;
        _baseTree.insert(value);
        _transitions = _baseTree.getTransitions();
        if (_transitions.firstOrNull?.transitionTree != null) {
          _lastTransitionTree = _transitions.first.transitionTree;
        }
      }
      return (_pendingFrames, this);
    } else {
      throw UnsupportedError(
          "cant execute a command while another command is on transition");
    }
  }*/

  bool _canExecuteCommand(BSharpTreeCommand command) {
    return (commandInExecution != command && !isInTransition()) ||
        (commandInExecution == command && isInTransition());
  }

  bool isInTransition() {
    return _transitions.isNotEmpty && _currentFrame < _transitions.length - 1;
  }

  @override
  Model clone() {
    return BSharpTreeModel.copyWith(
        _baseTree.clone(),
        _currentFrame,
        commandInExecution,
        _lastTransitionTree?.clone(),
        List.of(_transitions),
        name,
        extensionId);
  }

  void Function(BSharpTree<Comparable> tree) getFunctionFromCommand(
      BSharpTreeCommand command) {
    if (command is BSharpTreeInsertCommand) {
      return (BSharpTree tree) => tree.insert(command.value);
    } else {
      return (BSharpTree tree) => tree.remove(command.value);
    }
  }
}
