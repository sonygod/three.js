package three.js.test.unit.src.objects;

import three.js.src.core.Object3D;
import three.js.src.objects.Line;
import three.js.src.objects.LineLoop;

class LineLoopTests {

    public static function main() {

        // INHERITANCE
        var lineLoop = new LineLoop();
        unittest.assert(lineLoop instanceof Object3D);
        unittest.assert(lineLoop instanceof Line);

        // INSTANCING
        var object = new LineLoop();
        unittest.assert(object != null);

        // PROPERTIES
        unittest.assert(object.type == "LineLoop");

        // PUBLIC
        unittest.assert(object.isLineLoop);

    }

}