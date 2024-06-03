import three.core.Uniform;
import three.math.Vector3;
import js.Browser.document;

class UniformTests {
    static function main() {
        testInstancing();
        testClone();
    }

    static function testInstancing() {
        var a:Uniform;
        var b:Vector3 = new Vector3(Math.PI / 2, Math.PI / 2, Math.PI / 2);

        a = new Uniform(5);
        trace(a.value == 5, 'New constructor works with simple values');

        a = new Uniform(b);
        trace(a.value.equals(b), 'New constructor works with complex values');
    }

    static function testClone() {
        var a:Uniform = new Uniform(23);
        var b:Uniform = a.clone();

        trace(b.value == a.value, 'clone() with simple values works');

        a = new Uniform(new Vector3(1, 2, 3));
        b = a.clone();

        trace(b.value.equals(a.value), 'clone() with complex values works');
    }
}