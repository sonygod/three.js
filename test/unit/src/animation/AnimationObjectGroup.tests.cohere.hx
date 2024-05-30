package ;

import js.QUnit;
import js.AnimationObjectGroup;
import js.Object3D;
import js.PropertyBinding;

class TestAnimationObjectGroup {
    static function main() {
        QUnit.module( "Animation", function() {
            QUnit.module( "AnimationObjectGroup", function() {
                var ObjectA = new Object3D();
                var ObjectB = new Object3D();
                var ObjectC = new Object3D();
                var PathA = "object.position";
                var PathB = "object.rotation";
                var PathC = "object.scale";
                var ParsedPathA = PropertyBinding.parseTrackName(PathA);
                var ParsedPathB = PropertyBinding.parseTrackName(PathB);
                var ParsedPathC = PropertyBinding.parseTrackName(PathC);

                // INSTANCING
                QUnit.test("Instancing", function(assert) {
                    var groupA = new AnimationObjectGroup();
                    assert.ok(groupA instanceof AnimationObjectGroup, "AnimationObjectGroup can be instantiated");
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
                    function expect(testIndex, group, bindings, path, cached, roots) {
                        var rootNodes = [];
                        var pathsOk = true;
                        var nodesOk = true;
                        for (var i = 0, n = bindings.length; i < n; i++) {
                            if (bindings[i].path != path) pathsOk = false;
                            rootNodes.push(bindings[i].rootNode);
                        }
                        for (var i = 0, n = roots.length; i < n; i++) {
                            if (rootNodes.indexOf(roots[i]) == -1) nodesOk = false;
                        }
                        assert.ok(pathsOk, QUnit.testIndex + " paths");
                        assert.ok(nodesOk, QUnit.testIndex + " nodes");
                        assert.ok(group.nCachedObjects_ == cached, QUnit.testIndex + " cache size");
                        assert.ok(bindings.length - group.nCachedObjects_ == roots.length, QUnit.testIndex + " object count");
                    }

                    // initial state
                    var groupA = new AnimationObjectGroup();
                    assert.ok(groupA instanceof AnimationObjectGroup, "constructor (w/o args)");
                    var bindingsAA = groupA.subscribe_(PathA, ParsedPathA);
                    expect(0, groupA, bindingsAA, PathA, 0, []);

                    var groupB = new AnimationObjectGroup(ObjectA, ObjectB);
                    assert.ok(groupB instanceof AnimationObjectGroup, "constructor (with args)");
                    var bindingsBB = groupB.subscribe_(PathB, ParsedPathB);
                    expect(1, groupB, bindingsBB, PathB, 0, [ObjectA, ObjectB]);

                    // add
                    groupA.add(ObjectA, ObjectB);
                    expect(2, groupA, bindingsAA, PathA, 0, [ObjectA, ObjectB]);

                    groupB.add(ObjectC);
                    expect(3, groupB, bindingsBB, PathB, 0, [ObjectA, ObjectB, ObjectC]);

                    // remove
                    groupA.remove(ObjectA, ObjectC);
                    expect(4, groupA, bindingsAA, PathA, 1, [ObjectB]);

                    groupB.remove(ObjectA, ObjectB, ObjectC);
                    expect(5, groupB, bindingsBB, PathB, 3, []);

                    // subscribe after re-add
                    groupA.add(ObjectC);
                    expect(6, groupA, bindingsAA, PathA, 1, [ObjectB, ObjectC]);
                    var bindingsAC = groupA.subscribe_(PathC, ParsedPathC);
                    expect(7, groupA, bindingsAC, PathC, 1, [ObjectB, ObjectC]);

                    // re-add after subscribe
                    var bindingsBC = groupB.subscribe_(PathC, ParsedPathC);
                    groupB.add(ObjectA, ObjectB);
                    expect(8, groupB, bindingsBB, PathB, 1, [ObjectA, ObjectB]);

                    // unsubscribe
                    var copyOfBindingsBC = bindingsBC.slice();
                    groupB.unsubscribe_(PathC);
                    groupB.add(ObjectC);
                    assert.deepEqual(bindingsBC, copyOfBindingsBC, "no more update after unsubscribe");

                    // uncache active
                    groupB.uncache(ObjectA);
                    expect(9, groupB, bindingsBB, PathB, 0, [ObjectB, ObjectC]);

                    // uncache cached
                    groupA.uncache(ObjectA);
                    expect(10, groupA, bindingsAC, PathC, 0, [ObjectB, ObjectC]);
                });
            });
        });
    }
}