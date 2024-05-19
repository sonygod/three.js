package three.js.test.unit.src.animation;

import haxe.unit.TestCase;

import three.animation.AnimationObjectGroup;
import three.core.Object3D;
import three.animation.PropertyBinding;

class AnimationObjectGroupTest extends TestCase {
    public function new() {
        super();
    }

    override public function setup():Void {
        // setup code
    }

    override public function tearDown():Void {
        // teardown code
    }

    public function testInstancing():Void {
        var groupA = new AnimationObjectGroup();
        assertTrue(groupA instanceof AnimationObjectGroup);
    }

    public function testIsAnimationObjectGroup():Void {
        var object = new AnimationObjectGroup();
        assertTrue(object.isAnimationObjectGroup);
    }

    public function testSmokeTest():Void {
        var objectA = new Object3D();
        var objectB = new Object3D();
        var objectC = new Object3D();

        var pathA = 'object.position';
        var pathB = 'object.rotation';
        var pathC = 'object.scale';

        var parsedPathA = PropertyBinding.parseTrackName(pathA);
        var parsedPathB = PropertyBinding.parseTrackName(pathB);
        var parsedPathC = PropertyBinding.parseTrackName(pathC);

        var expect = function(testIndex:Int, group:AnimationObjectGroup, bindings:Array<PropertyBinding>, path:String, cached:Int, roots:Array<Object3D>) {
            var rootNodes:Array<Object3D> = [];
            var pathsOk = true;
            var nodesOk = true;

            for (i in 0...bindings.length) {
                if (bindings[i].path != path) pathsOk = false;
                rootNodes.push(bindings[i].rootNode);
            }

            for (i in 0...roots.length) {
                if (rootNodes.indexOf(roots[i]) == -1) nodesOk = false;
            }

            assertTrue(pathsOk, '$testIndex paths');
            assertTrue(nodesOk, '$testIndex nodes');
            assertEquals(group.nCachedObjects_, cached, '$testIndex cache size');
            assertEquals(bindings.length - group.nCachedObjects_, roots.length, '$testIndex object count');
        };

        // initial state
        var groupA = new AnimationObjectGroup();
        assertTrue(groupA instanceof AnimationObjectGroup);

        var bindingsAA = groupA.subscribe_(pathA, parsedPathA);
        expect(0, groupA, bindingsAA, pathA, 0, []);

        var groupB = new AnimationObjectGroup(objectA, objectB);
        assertTrue(groupB instanceof AnimationObjectGroup);

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
        assertEquals(bindingsBC, copyOfBindingsBC);

        // uncache active
        groupB.uncache(objectA);
        expect(9, groupB, bindingsBB, pathB, 0, [objectB, objectC]);

        // uncache cached
        groupA.uncache(objectA);
        expect(10, groupA, bindingsAC, pathC, 0, [objectB, objectC]);
    }
}