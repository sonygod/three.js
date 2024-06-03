import three.extras.curves.CatmullRomCurve3;
import three.extras.core.Curve;
import three.math.Vector3;

class CatmullRomCurve3Tests {
    public static function main() {
        var positions:Array<Vector3> = [
            new Vector3(-60, -100, 60),
            new Vector3(-60, 20, 60),
            new Vector3(-60, 120, 60),
            new Vector3(60, 20, -60),
            new Vector3(60, -100, -60)
        ];

        var object = new CatmullRomCurve3();
        trace(object is Curve); // Extending
        trace(object != null); // Instancing
        trace(object.type == 'CatmullRomCurve3'); // type
        trace(object.isCatmullRomCurve3); // isCatmullRomCurve3

        // Add tests for other methods as needed
    }
}