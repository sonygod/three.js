package three.js.test.unit.src.objects;

import haxe.unit.TestCase;
import three.Objects.LOD;
import three.core.Object3D;
import three.core.Raycaster;

class LODTest extends TestCase {
    public function new() {
        super();

        test("Extending", function(assert) {
            var lod = new LOD();
            assertTrue(lod instanceof Object3D, "LOD extends from Object3D");
        });

        test("type", function(assert) {
            var object = new LOD();
            assertEquals(object.type, "LOD", "LOD.type should be LOD");
        });

        test("levels", function(assert) {
            var lod = new LOD();
            var levels = lod.levels;

            assertTrue(levels.isArray(), "LOD.levels is of type array.");
            assertEquals(levels.length, 0, "LOD.levels is empty by default.");
        });

        test("autoUpdate", function(assert) {
            var lod = new LOD();

            assertTrue(lod.autoUpdate, "LOD.autoUpdate is of type boolean and true by default.");
        });

        test("isLOD", function(assert) {
            var lod = new LOD();

            assertTrue(lod.isLOD, ".isLOD property is defined.");
        });

        test("copy", function(assert) {
            var lod1 = new LOD();
            var lod2 = new LOD();

            var high = new Object3D();
            var mid = new Object3D();
            var low = new Object3D();

            lod1.addLevel(high, 5);
            lod1.addLevel(mid, 25);
            lod1.addLevel(low, 50);

            lod1.autoUpdate = false;

            lod2.copy(lod1);

            assertEquals(lod2.autoUpdate, false, "LOD.autoUpdate is correctly copied.");
            assertEquals(lod2.levels.length, 3, "LOD.levels has the correct length after the copy.");
        });

        test("addLevel", function(assert) {
            var lod = new LOD();

            var high = new Object3D();
            var mid = new Object3D();
            var low = new Object3D();

            lod.addLevel(high, 5, 0.00);
            lod.addLevel(mid, 25, 0.05);
            lod.addLevel(low, 50, 0.10);

            assertEquals(lod.levels.length, 3, "LOD.levels has the correct length.");
            assertEquals(lod.levels[0], { distance: 5, object: high, hysteresis: 0.00 }, "First entry correct.");
            assertEquals(lod.levels[1], { distance: 25, object: mid, hysteresis: 0.05 }, "Second entry correct.");
            assertEquals(lod.levels[2], { distance: 50, object: low, hysteresis: 0.10 }, "Third entry correct.");
        });

        todo("getCurrentLevel", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        test("getObjectForDistance", function(assert) {
            var lod = new LOD();

            var high = new Object3D();
            var mid = new Object3D();
            var low = new Object3D();

            assertEquals(lod.getObjectForDistance(5), null, "Returns null if no LOD levels are defined.");

            lod.addLevel(high, 5);

            assertEquals(lod.getObjectForDistance(0), high, "Returns always the same object if only one LOD level is defined.");
            assertEquals(lod.getObjectForDistance(10), high, "Returns always the same object if only one LOD level is defined.");

            lod.addLevel(mid, 25);
            lod.addLevel(low, 50);

            assertEquals(lod.getObjectForDistance(0), high, "Returns the high resolution object.");
            assertEquals(lod.getObjectForDistance(10), high, "Returns the high resolution object.");
            assertEquals(lod.getObjectForDistance(25), mid, "Returns the mid resolution object.");
            assertEquals(lod.getObjectForDistance(50), low, "Returns the low resolution object.");
            assertEquals(lod.getObjectForDistance(60), low, "Returns the low resolution object.");
        });

        test("raycast", function(assert) {
            var lod = new LOD();
            var raycaster = new Raycaster();
            var intersections = [];

            lod.raycast(raycaster, intersections);

            assertEquals(intersections.length, 0, "Does not fail if raycasting is used with a LOD object without levels.");
        });

        todo("update", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todo("toJSON", function(assert) {
            assert.fail("everything's gonna be alright");
        });
    }
}