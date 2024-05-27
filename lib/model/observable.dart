import 'package:visualizeit_bsharptree_extension/extension/bsharp_transition.dart';
import 'package:visualizeit_bsharptree_extension/model/tree_observer.dart';

class Observable {
  final List<TreeObserver> _observers = [];

  void registerObserver(TreeObserver observer) {
    _observers.add(observer);
  }

  void notifyObservers(BSharpTreeTransition transition) {
    for (var observer in _observers) {
      observer.notify(transition);
    }
  }

  void removeObserver(TreeObserver observer) {
    _observers.removeWhere((element) => element == observer);
  }
}
