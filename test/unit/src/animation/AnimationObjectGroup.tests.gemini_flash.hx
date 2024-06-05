import qunit.QUnit;
import three.core.Object3D;
import three.animation.AnimationObjectGroup;
import three.animation.PropertyBinding;

class AnimationObjectGroupTest {

	static function main() {
		QUnit.module("Animation", function() {

			QUnit.module("AnimationObjectGroup", function() {

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
				QUnit.test("Instancing", function(assert) {

					var groupA = new AnimationObjectGroup();
					assert.ok(groupA.isAnimationObjectGroup, "AnimationObjectGroup can be instanciated");

				});

				// PROPERTIES
				QUnit.todo("uuid", function(assert) {

					assert.ok(false, "everything's gonna be alright");

				});

				QUnit.todo("stats", function(assert) {

					assert.ok(false, "everything's gonna be alright");

				});

				// PUBLIC
				QUnit.test("isAnimationObjectGroup", function(assert) {

					var object = new AnimationObjectGroup();
					assert.ok(object.isAnimationObjectGroup, "AnimationObjectGroup.isAnimationObjectGroup should be true");

				});

				QUnit.todo("add", function(assert) {

					assert.ok(false, "everything's gonna be alright");

				});

				QUnit.todo("remove", function(assert) {

					assert.ok(false, "everything's gonna be alright");

				});

				QUnit.todo("uncache", function(assert) {

					assert.ok(false, "everything's gonna be alright");

				});

				// OTHERS
				QUnit.test("smoke test", function(assert) {

					var expect = function(testIndex, group, bindings, path, cached, roots) {

						var rootNodes = new Array<Object3D>();
						var pathsOk = true;
						var nodesOk = true;

						for (var i = group.nCachedObjects; i < bindings.length; ++i) {

							if (bindings[i].path != path) pathsOk = false;
							rootNodes.push(bindings[i].rootNode);

						}

						for (var i = 0; i < roots.length; ++i) {

							if (rootNodes.indexOf(roots[i]) == -1) nodesOk = false;

						}

						assert.ok(pathsOk, QUnit.testIndex + " paths");
						assert.ok(nodesOk, QUnit.testIndex + " nodes");
						assert.ok(group.nCachedObjects == cached, QUnit.testIndex + " cache size");
						assert.ok(bindings.length - group.nCachedObjects == roots.length, QUnit.testIndex + " object count");

					};

					// initial state

					var groupA = new AnimationObjectGroup();
					assert.ok(groupA.isAnimationObjectGroup, "constructor (w/o args)");

					var bindingsAA = groupA.subscribe_(pathA, parsedPathA);
					expect(0, groupA, bindingsAA, pathA, 0, new Array<Object3D>());

					var groupB = new AnimationObjectGroup(objectA, objectB);
					assert.ok(groupB.isAnimationObjectGroup, "constructor (with args)");

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
					expect(5, groupB, bindingsBB, pathB, 3, new Array<Object3D>());

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
					assert.deepEqual(bindingsBC, copyOfBindingsBC, "no more update after unsubscribe");

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

class Array<T> {
	public function copy():Array<T> {
		return this.slice(0);
	}
}

AnimationObjectGroupTest.main();