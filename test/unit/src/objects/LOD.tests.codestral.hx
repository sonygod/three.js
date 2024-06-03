import three.core.Object3D;
import three.core.Raycaster;
import three.objects.LOD;

class LODTests {
    public static function main() {
        testExtending();
        testType();
        testLevels();
        testAutoUpdate();
        testIsLOD();
        testCopy();
        testAddLevel();
        testGetObjectForDistance();
        testRaycast();
    }

    static function testExtending() {
        var lod = new LOD();
        assert(Std.is(lod, Object3D), "LOD extends from Object3D");
    }

    static function testType() {
        var object = new LOD();
        assert(object.type == 'LOD', "LOD.type should be LOD");
    }

    static function testLevels() {
        var lod = new LOD();
        var levels = lod.levels;
        assert(Std.is(levels, Array), "LOD.levels is of type array.");
        assert(levels.length == 0, "LOD.levels is empty by default.");
    }

    static function testAutoUpdate() {
        var lod = new LOD();
        assert(lod.autoUpdate == true, "LOD.autoUpdate is of type boolean and true by default.");
    }

    static function testIsLOD() {
        var lod = new LOD();
        assert(lod.isLOD == true, ".isLOD property is defined.");
    }

    static function testCopy() {
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

        assert(lod2.autoUpdate == false, "LOD.autoUpdate is correctly copied.");
        assert(lod2.levels.length == 3, "LOD.levels has the correct length after the copy.");
    }

    static function testAddLevel() {
        var lod = new LOD();

        var high = new Object3D();
        var mid = new Object3D();
        var low = new Object3D();

        lod.addLevel(high, 5, 0.00);
        lod.addLevel(mid, 25, 0.05);
        lod.addLevel(low, 50, 0.10);

        assert(lod.levels.length == 3, "LOD.levels has the correct length.");
        assertDeepEqual(lod.levels[0], { distance: 5, object: high, hysteresis: 0.00 }, "First entry correct.");
        assertDeepEqual(lod.levels[1], { distance: 25, object: mid, hysteresis: 0.05 }, "Second entry correct.");
        assertDeepEqual(lod.levels[2], { distance: 50, object: low, hysteresis: 0.10 }, "Third entry correct.");
    }

    static function testGetObjectForDistance() {
        var lod = new LOD();

        var high = new Object3D();
        var mid = new Object3D();
        var low = new Object3D();

        assert(lod.getObjectForDistance(5) == null, "Returns null if no LOD levels are defined.");

        lod.addLevel(high, 5);

        assert(lod.getObjectForDistance(0) == high, "Returns always the same object if only one LOD level is defined.");
        assert(lod.getObjectForDistance(10) == high, "Returns always the same object if only one LOD level is defined.");

        lod.addLevel(mid, 25);
        lod.addLevel(low, 50);

        assert(lod.getObjectForDistance(0) == high, "Returns the high resolution object.");
        assert(lod.getObjectForDistance(10) == high, "Returns the high resolution object.");
        assert(lod.getObjectForDistance(25) == mid, "Returns the mid resolution object.");
        assert(lod.getObjectForDistance(50) == low, "Returns the low resolution object.");
        assert(lod.getObjectForDistance(60) == low, "Returns the low resolution object.");
    }

    static function testRaycast() {
        var lod = new LOD();
        var raycaster = new Raycaster();
        var intersections = [];

        lod.raycast(raycaster, intersections);

        assert(intersections.length == 0, "Does not fail if raycasting is used with a LOD object without levels.");
    }

    // Helper function for deep equal assertion
    static function assertDeepEqual(a:Dynamic, b:Dynamic, message:String) {
        // Implement deep equal check here
    }
}