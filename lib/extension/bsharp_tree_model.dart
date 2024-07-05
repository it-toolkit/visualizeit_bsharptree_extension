import 'package:visualizeit_bsharptree_extension/extension/bsharp_transition.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_command.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_extension.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_bsharptree_extension/model/tree_logger_observer.dart';
import 'package:visualizeit_bsharptree_extension/model/tree_transition_observer.dart';
import 'package:visualizeit_extensions/common.dart';

class BSharpTreeModel extends Model {
  final BSharpTree _baseTree;
  BSharpTree? _lastTransitionTree;
  List<BSharpTreeTransition> _transitions = [];
  late TreeLoggerObserver loggerObserver;

  int _currentFrame = 0;
  BSharpTreeCommand? commandInExecution;

  BSharpTreeModel(String name, int treeCapacity, List<int> initialValues, [bool autoIncremental = false])
      : _baseTree = BSharpTree<num>(treeCapacity, keysAreAutoincremental: autoIncremental),
        super(BSharpTreeExtension.extensionId, name) {
    loggerObserver = TreeLoggerObserver(_baseTree);
    _baseTree.insertAll(initialValues);
    _lastTransitionTree = _baseTree;
  }
  BSharpTreeModel.copyWith(
      this._baseTree,
      this._currentFrame,
      this.commandInExecution,
      this._lastTransitionTree,
      this._transitions,
      super.extensionId,
      super.name);

  BSharpTree? get currentTree => _transitions.isEmpty
      ? _lastTransitionTree
      : _transitions[_currentFrame].transitionTree ?? _lastTransitionTree;

  BSharpTreeTransition? get currentTransition =>
      _transitions.isNotEmpty ? _transitions[_currentFrame] : null;
  int get _pendingFrames => _transitions.length - _currentFrame - 1;

  (int, Model) executeCommand(BSharpTreeCommand command, {bool isInstantExecution = false}) {
    if (_canExecuteCommand(command)) {
      if (isInTransition()) {
        //El arbol está en transicion
        _currentFrame++;
        if (_transitions[_currentFrame].hasTree()) {
          _lastTransitionTree = _transitions[_currentFrame].transitionTree!;
        }
      } else {
        //Arranca una nueva ejecución
        executeNewCommand(command, isInstantExecution);
      }
      return (_pendingFrames, this);
    } else {
      throw UnsupportedError(
          "cant execute a command while another command is on transition");
    }
  }

  void executeNewCommand(BSharpTreeCommand command, bool isInstantExecution) {
    _lastTransitionTree = _baseTree.clone();
    var transitionObserver = TreeTransitionObserver(_baseTree);
    var functionToExecute = command.commandToFunction();
    try {
      functionToExecute(_baseTree);
    } catch(exception){
      logger.error(() => "Exception thrown: $exception");
    }
    _currentFrame = 0;
    if(!isInstantExecution){
      commandInExecution = command;
      _currentFrame = 0;
      _transitions = transitionObserver.transitions;
    } else {
      _lastTransitionTree = _baseTree.clone();
    }
    
    transitionObserver.removeObserver();
    if (_transitions.firstOrNull?.transitionTree != null) {
      _lastTransitionTree = _transitions.first.transitionTree;
    }
  }

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
        extensionId,
        name);
  }
}
