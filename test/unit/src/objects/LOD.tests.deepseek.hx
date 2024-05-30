package three.js.test.unit.src.objects;

import three.js.src.core.Object3D;
import three.js.src.core.Raycaster;
import three.js.src.objects.LOD;

class LODTests {

    public static function main() {
        // INHERITANCE
        var lod = new LOD();
        trace((lod is Object3D), "LOD extends from Object3D");

        // PROPERTIES
        var object = new LOD();
        trace(object.type == "LOD", "LOD.type should be LOD");

        var levels = lod.levels;
        trace(Std.is(levels, Array), "LOD.levels is of type array.");
        trace(levels.length == 0, "LOD.levels is empty by default.");

        trace(lod.autoUpdate == true, "LOD.autoUpdate is of type boolean and true by default.");

        // PUBLIC
        trace(lod.isLOD == true, ".isLOD property is defined.");

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

        trace(lod2.autoUpdate == false, "LOD.autoUpdate is correctly copied.");
        trace(lod2.levels.length == 3, "LOD.levels has the correct length after the copy.");

        // ... 其他测试代码 ...
    }
}