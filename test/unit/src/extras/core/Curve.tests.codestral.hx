import three.extras.core.Curve;

class CurveTests {
    public static function main() {
        testInstancing();
        testType();
    }

    private static function testInstancing() {
        var object = new Curve();
        trace(object != null, "Can instantiate a Curve.");
    }

    private static function testType() {
        var object = new Curve();
        trace(object.type == "Curve", "Curve.type should be Curve");
    }
}