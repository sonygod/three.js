package three.js.test.unit.src.core;

import three.js.src.core.Uniform;
import three.js.src.math.Vector3;
import three.js.utils.math_constants.*;

class UniformTests {

    static function main() {

        // INSTANCING
        var a:Uniform;
        var b = new Vector3(x, y, z);

        a = new Uniform(5);
        unittest.assert(a.value == 5, 'New constructor works with simple values');

        a = new Uniform(b);
        unittest.assert(a.value.equals(b), 'New constructor works with complex values');

        // PROPERTIES
        unittest.todo('value', (assert) -> {
            unittest.assert(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        var a = new Uniform(23);
        var b = a.clone();

        unittest.assert(b.value == a.value, 'clone() with simple values works');

        a = new Uniform(new Vector3(1, 2, 3));
        b = a.clone();

        unittest.assert(b.value.equals(a.value), 'clone() with complex values works');

    }

}