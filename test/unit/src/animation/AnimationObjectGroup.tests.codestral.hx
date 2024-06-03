import js.Browser.document;
import js.html.QUnit;
import three.animation.AnimationObjectGroup;
import three.core.Object3D;
import three.animation.PropertyBinding;

class AnimationObjectGroupTests {
    public function new() {
        QUnit.module("Animation", () -> {
            QUnit.module("AnimationObjectGroup", () -> {
                var ObjectA: Object3D = new Object3D();
                var ObjectB: Object3D = new Object3D();
                var ObjectC: Object3D = new Object3D();

                var PathA: String = "object.position";
                var PathB: String = "object.rotation";
                var PathC: String = "object.scale";

                var ParsedPathA: PropertyBinding.ParsedTrackName = PropertyBinding.parseTrackName(PathA);
                var ParsedPathB: PropertyBinding.ParsedTrackName = PropertyBinding.parseTrackName(PathB);
                var ParsedPathC: PropertyBinding.ParsedTrackName = PropertyBinding.parseTrackName(PathC);

                // INSTANCING
                QUnit.test("Instancing", (assert: QUnit.Assert) -> {
                    var groupA: AnimationObjectGroup = new AnimationObjectGroup();
                    assert.ok(Std.is(groupA, AnimationObjectGroup), "AnimationObjectGroup can be instanciated");
                });

                // PUBLIC
                QUnit.test("isAnimationObjectGroup", (assert: QUnit.Assert) -> {
                    var object: AnimationObjectGroup = new AnimationObjectGroup();
                    assert.ok(object.isAnimationObjectGroup, "AnimationObjectGroup.isAnimationObjectGroup should be true");
                });

                // OTHERS
                QUnit.test("smoke test", (assert: QUnit.Assert) -> {
                    var expect = (testIndex: Int, group: AnimationObjectGroup, bindings: Array<PropertyBinding>, path: String, cached: Int, roots: Array<Object3D>) -> {
                        var rootNodes: Array<Object3D> = new Array<Object3D>();
                        var pathsOk: Bool = true;
                        var nodesOk: Bool = true;

                        for (i in group.nCachedObjects...bindings.length) {
                            if (bindings[i].path !== path) pathsOk = false;
                            rootNodes.push(bindings[i].rootNode);
                        }

                        for (i in 0...roots.length) {
                            if (rootNodes.indexOf(roots[i]) === -1) nodesOk = false;
                        }

                        assert.ok(pathsOk, QUnit.testIndex + " paths");
                        assert.ok(nodesOk, QUnit.testIndex + " nodes");
                        assert.ok(group.nCachedObjects_ === cached, QUnit.testIndex + " cache size");
                        assert.ok(bindings.length - group.nCachedObjects_ === roots.length, QUnit.testIndex + " object count");
                    };

                    // initial state
                    var groupA: AnimationObjectGroup = new AnimationObjectGroup();
                    assert.ok(Std.is(groupA, AnimationObjectGroup), "constructor (w/o args)");

                    var bindingsAA: Array<PropertyBinding> = groupA.subscribe_(PathA, ParsedPathA);
                    expect(0, groupA, bindingsAA, PathA, 0, new Array<Object3D>());

                    var groupB: AnimationObjectGroup = new AnimationObjectGroup([ObjectA, ObjectB]);
                    assert.ok(Std.is(groupB, AnimationObjectGroup), "constructor (with args)");

                    var bindingsBB: Array<PropertyBinding> = groupB.subscribe_(PathB, ParsedPathB);
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
                    expect(5, groupB, bindingsBB, PathB, 3, new Array<Object3D>());

                    // subscribe after re-add
                    groupA.add(ObjectC);
                    expect(6, groupA, bindingsAA, PathA, 1, [ObjectB, ObjectC]);
                    var bindingsAC: Array<PropertyBinding> = groupA.subscribe_(PathC, ParsedPathC);
                    expect(7, groupA, bindingsAC, PathC, 1, [ObjectB, ObjectC]);

                    // re-add after subscribe
                    var bindingsBC: Array<PropertyBinding> = groupB.subscribe_(PathC, ParsedPathC);
                    groupB.add(ObjectA, ObjectB);
                    expect(8, groupB, bindingsBB, PathB, 1, [ObjectA, ObjectB]);

                    // unsubscribe
                    var copyOfBindingsBC: Array<PropertyBinding> = bindingsBC.slice();
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