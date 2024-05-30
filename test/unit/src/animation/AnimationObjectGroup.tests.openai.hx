package three.test.unit.animation;

import three.animation.AnimationObjectGroup;
import three.core.Object3D;
import three.animation.PropertyBinding;

class AnimationObjectGroupTest {
  public function new() {}

  public static function main() {
    Tester.module("Animation", () => {
      Tester.module("AnimationObjectGroup", () => {
        var objectA = new Object3D();
        var objectB = new Object3D();
        var objectC = new Object3D();

        var pathA = "object.position";
        var pathB = "object.rotation";
        var pathC = "object.scale";

        var parsedPathA = PropertyBinding.parseTrackName(pathA);
        var parsedPathB = PropertyBinding.parseTrackName(pathB);
        var parsedPathC = PropertyBinding.parseTrackName(pathC);

        // INSTANCING
        Tester.test("Instancing", (assert) => {
          var groupA = new AnimationObjectGroup();
          assert.ok(groupA instanceof AnimationObjectGroup, 'AnimationObjectGroup can be instanciated');
        });

        // PROPERTIES
        Tester.todo("uuid", (assert) => {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        Tester.todo("stats", (assert) => {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        Tester.test("isAnimationObjectGroup", (assert) => {
          var object = new AnimationObjectGroup();
          assert.ok(object.isAnimationObjectGroup, 'AnimationObjectGroup.isAnimationObjectGroup should be true');
        });

        Tester.todo("add", (assert) => {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        Tester.todo("remove", (assert) => {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        Tester.todo("uncache", (assert) => {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        // OTHERS
        Tester.test("smoke test", (assert) => {
          var expect = function(testIndex, group, bindings, path, cached, roots) {
            var rootNodes = [];
            var pathsOk = true;
            var nodesOk = true;

            for (i in 0...bindings.length) {
              if (bindings[i].path != path) pathsOk = false;
              rootNodes.push(bindings[i].rootNode);
            }

            for (i in 0...roots.length) {
              if (rootNodes.indexOf(roots[i]) == -1) nodesOk = false;
            }

            assert.ok(pathsOk, testIndex + ' paths');
            assert.ok(nodesOk, testIndex + ' nodes');
            assert.ok(group.nCachedObjects_ == cached, testIndex + ' cache size');
            assert.ok(bindings.length - group.nCachedObjects_ == roots.length, testIndex + ' object count');
          };

          // initial state
          var groupA = new AnimationObjectGroup();
          assert.ok(groupA instanceof AnimationObjectGroup, 'constructor (w/o args)');

          var bindingsAA = groupA.subscribe_(pathA, parsedPathA);
          expect(0, groupA, bindingsAA, pathA, 0, []);

          var groupB = new AnimationObjectGroup(objectA, objectB);
          assert.ok(groupB instanceof AnimationObjectGroup, 'constructor (with args)');

          var bindingsBB = groupB.subscribe_(pathB, parsedPathB);
          expect(1, groupB, bindingsBB, pathB, 0, [objectA, objectB]);

          // add
          groupA.add(objectA, objectB);
          expect(2, groupA, bindingsAA, pathA, 0, [objectA, objectB]);

          groupB.add(objectC);
          expect(3, groupB, bindingsBB, pathB, 0, [objectA, objectB, objectC]);

          // remove
          groupA.remove(objectA, objectC);
          expect(4, groupA, bindingsAA, pathA, 1, [objectB]);

          groupB.remove(objectA, objectB, objectC);
          expect(5, groupB, bindingsBB, pathB, 3, []);

          // subscribe after re-add
          groupA.add(objectC);
          expect(6, groupA, bindingsAA, pathA, 1, [objectB, objectC]);
          var bindingsAC = groupA.subscribe_(pathC, parsedPathC);
          expect(7, groupA, bindingsAC, pathC, 1, [objectB, objectC]);

          // re-add after subscribe
          var bindingsBC = groupB.subscribe_(pathC, parsedPathC);
          groupB.add(objectA, objectB);
          expect(8, groupB, bindingsBB, pathB, 1, [objectA, objectB]);

          // unsubscribe
          var copyOfBindingsBC = bindingsBC.copy();
          groupB.unsubscribe_(pathC);
          groupB.add(objectC);
          assert.deepEqual(bindingsBC, copyOfBindingsBC, 'no more update after unsubscribe');

          // uncache active
          groupB.uncache(objectA);
          expect(9, groupB, bindingsBB, pathB, 0, [objectB, objectC]);

          // uncache cached
          groupA.uncache(objectA);
          expect(10, groupA, bindingsAC, pathC, 0, [objectB, objectC]);
        });
      });
    });
  }
}