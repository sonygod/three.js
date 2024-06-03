import three.math.Ray;
import three.math.Vector3;
import three.math.Box3;
import three.math.Sphere;
import three.math.Plane;
import three.math.Matrix4;
import three.utils.Constants;

class RayTests {
    static function main() {
        var a:Ray = new Ray();
        trace(a.origin.equals(Constants.zero3), 'Passed!');
        trace(a.direction.equals(new Vector3(0, 0, -1)), 'Passed!');

        a = new Ray(Constants.two3.clone(), Constants.one3.clone());
        trace(a.origin.equals(Constants.two3), 'Passed!');
        trace(a.direction.equals(Constants.one3), 'Passed!');

        // Add other tests here...
    }
}