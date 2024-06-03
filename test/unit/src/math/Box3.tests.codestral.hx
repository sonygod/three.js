import three.math.Box3;
import three.math.Sphere;
import three.math.Triangle;
import three.math.Plane;
import three.math.Vector3;
import three.math.Matrix4;
import three.objects.Mesh;
import three.core.BufferAttribute;
import three.geometries.BoxGeometry;
import three.geometries.SphereGeometry;
import three.utils.MathConstants;
import haxe.unit.TestCase;
import haxe.unit.TestRunner;

class Box3Tests extends TestCase {

    public function new() {
        super("Box3Tests");
    }

    private function compareBox(a: Box3, b: Box3, threshold: Float = 0.0001): Bool {
        return (a.min.distanceTo(b.min) < threshold && a.max.distanceTo(b.max) < threshold);
    }

    public function testInstancing(): Void {
        var a = new Box3();
        this.assertTrue(a.min.equals(MathConstants.posInf3), 'Passed!');
        this.assertTrue(a.max.equals(MathConstants.negInf3), 'Passed!');

        a = new Box3(MathConstants.zero3.clone(), MathConstants.zero3.clone());
        this.assertTrue(a.min.equals(MathConstants.zero3), 'Passed!');
        this.assertTrue(a.max.equals(MathConstants.zero3), 'Passed!');

        a = new Box3(MathConstants.zero3.clone(), MathConstants.one3.clone());
        this.assertTrue(a.min.equals(MathConstants.zero3), 'Passed!');
        this.assertTrue(a.max.equals(MathConstants.one3), 'Passed!');
    }

    // You can continue to convert other functions in a similar way.
    // Remember to include necessary imports and to call the assert functions from the TestCase class.
}

class Box3TestsRunner extends TestRunner {
    public static function main() {
        new Box3TestsRunner().run(new Box3Tests());
    }
}