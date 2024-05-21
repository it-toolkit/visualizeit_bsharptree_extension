import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_command.dart';
import 'package:visualizeit_bsharptree_extension/extension/bsharp_tree_model.dart';
import 'package:visualizeit_bsharptree_extension/model/bsharp_tree.dart';
import 'package:visualizeit_extensions/common.dart';

class BSharpTreeMock extends Mock implements BSharpTree<num> {}

void main() {
  test("model empty creation", () {
    int treeCapacity = 3;
    BSharpTreeModel model = BSharpTreeModel("name", treeCapacity, []);

    expect(
      model.currentTree,
      isA<BSharpTree<num>>(),
    );
    expect(model.name, equals("name"));
    expect(model.currentTree!.maxCapacity, treeCapacity);
    expect(model.currentTree!.nodesQuantity, 0);
  });

  test("model creation with initial values", () {
    int treeCapacity = 3;
    BSharpTreeModel model = BSharpTreeModel("name", treeCapacity, [3, 7, 15]);

    expect(
      model.currentTree,
      isA<BSharpTree<num>>(),
    );
    expect(model.name, equals("name"));
    expect(model.currentTree!.maxCapacity, treeCapacity);
    expect(model.currentTree!.nodesQuantity, 2);
  });

  group("insert command execution", () {
    test("execute without transitions", () {
      int treeCapacity = 3;
      int valueToInsert = 10;
      BSharpTreeModel model = BSharpTreeModel("name", treeCapacity, []);

      int pendingFrames;
      Model modelAfterExecution;
      (pendingFrames, modelAfterExecution) = model
          .executeCommand(BSharpTreeInsertCommand(valueToInsert, "modelName"));

      expect(pendingFrames, 1);
      expect(modelAfterExecution, isA<BSharpTreeModel>());
    });

    test("execute with transitions", () {
      int treeCapacity = 3;
      int valueToInsert = 10;
      BSharpTreeModel model =
          BSharpTreeModel("name", treeCapacity, [3, 6, 9, 12]);

      int pendingFrames;
      Model modelAfterExecution;
      (pendingFrames, modelAfterExecution) = model
          .executeCommand(BSharpTreeInsertCommand(valueToInsert, "modelName"));

      expect(pendingFrames, greaterThan(0));
      expect(modelAfterExecution, isA<BSharpTreeModel>());
      expect(
          (modelAfterExecution as BSharpTreeModel).currentTree!.nodesQuantity,
          2);
    });

    test("try to execute while in transition", () {
      int treeCapacity = 3;
      int valueToInsert = 10;
      int anotherValueToInsert = 25;
      BSharpTreeModel model =
          BSharpTreeModel("name", treeCapacity, [3, 6, 9, 12]);

      int pendingFrames;
      BSharpTreeModel modelAfterExecution;
      (pendingFrames, modelAfterExecution as BSharpTreeModel) = model
          .executeCommand(BSharpTreeInsertCommand(valueToInsert, "modelName"));

      expect(pendingFrames, greaterThan(0));
      expect(
          () => modelAfterExecution.executeCommand(
              BSharpTreeInsertCommand(anotherValueToInsert, "modelName")),
          throwsA(const TypeMatcher<UnsupportedError>()));
    });

    test("execute until transitions are over", () {
      int treeCapacity = 3;
      int valueToInsert = 10;
      BSharpTreeModel model =
          BSharpTreeModel("name", treeCapacity, [3, 6, 9, 12]);
      var command = BSharpTreeInsertCommand(valueToInsert, "modelName");

      int pendingFrames;
      Model modelAfterExecution;

      do {
        (pendingFrames, modelAfterExecution) = model.executeCommand(command);
      } while (pendingFrames > 0);

      expect(pendingFrames, 0);
      expect(modelAfterExecution, isA<BSharpTreeModel>());
    });
  });
}
