package three.js.test.unit.src.extras.curves;

import three.js.extras.curves.ArcCurve;
import three.js.extras.curves.EllipseCurve;

class ArcCurveTests {
    public function new() {}

    public static function main() {
        // INHERITANCE
        testCase("Extending", function(assert: Assert) {
            var object = new ArcCurve();
            assertTrue(object instanceof EllipseCurve, 'ArcCurve extends from EllipseCurve');
        });

        // INSTANCING
        testCase("Instancing", function(assert: Assert) {
            var object = new ArcCurve();
            assertNotNull(object, 'Can instantiate an ArcCurve.');
        });

        // PROPERTIES
        testCase("type", function(assert: Assert) {
            var object = new ArcCurve();
            assertEquals(object.type, 'ArcCurve', 'ArcCurve.type should be ArcCurve');
        });

        // PUBLIC
        testCase("isArcCurve", function(assert: Assert) {
            var object = new ArcCurve();
            assertTrue(object.isArcCurve, 'ArcCurve.isArcCurve should be true');
        });
    }
}