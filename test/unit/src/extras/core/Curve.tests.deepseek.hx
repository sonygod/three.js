package three.js.test.unit.src.extras.core;

import three.js.src.extras.core.Curve;
import js.Lib;

class CurveTests {

    public static function main() {
        // INSTANCING
        var object = new Curve();
        Lib.assert(object != null, 'Can instantiate a Curve.');

        // PROPERTIES
        Lib.assert(object.type == 'Curve', 'Curve.type should be Curve');

        // TODO: Implement the rest of the tests
    }
}