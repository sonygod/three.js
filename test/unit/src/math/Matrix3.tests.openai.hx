package three.math;

import haxe.ds.Vector;

class Matrix3 {
    public var elements:Vector<Float>;

    public function new() {
        elements = new Vector<Float>(9);
    }

    public function set(n11:Float, n12:Float, n13:Float, n21:Float, n22:Float, n23:Float, n31:Float, n32:Float, n33:Float) {
        elements[0] = n11;
        elements[1] = n12;
        elements[2] = n13;
        elements[3] = n21;
        elements[4] = n22;
        elements[5] = n23;
        elements[6] = n31;
        elements[7] = n32;
        elements[8] = n33;
    }

    public function clone():Matrix3 {
        var matrix = new Matrix3();
        matrix.elements.blit(0, elements, 0, 9);
        return matrix;
    }

    public function copy(matrix:Matrix3):Matrix3 {
        elements.blit(0, matrix.elements, 0, 9);
        return this;
    }

    // ... rest of the methods ...
}

class Matrix4 {
    public var elements:Vector<Float>;

    public function new() {
        elements = new Vector<Float>(16);
    }

    public function set(n11:Float, n12:Float, n13:Float, n14:Float, n21:Float, n22:Float, n23:Float, n24:Float, n31:Float, n32:Float, n33:Float, n34:Float, n41:Float, n42:Float, n43:Float, n44:Float) {
        elements[0] = n11;
        elements[1] = n12;
        elements[2] = n13;
        elements[3] = n14;
        elements[4] = n21;
        elements[5] = n22;
        elements[6] = n23;
        elements[7] = n24;
        elements[8] = n31;
        elements[9] = n32;
        elements[10] = n33;
        elements[11] = n34;
        elements[12] = n41;
        elements[13] = n42;
        elements[14] = n43;
        elements[15] = n44;
    }

    // ... rest of the methods ...
}

class Vector2 {
    public var x:Float;
    public var y:Float;

    public function new(x:Float, y:Float) {
        this.x = x;
        this.y = y;
    }
}

class TestUtils {
    public static function matrixEquals3(a:Matrix3, b:Matrix3):Bool {
        for (i in 0...9) {
            if (Math.abs(a.elements[i] - b.elements[i]) > 0.0001) {
                return false;
            }
        }
        return true;
    }

    public static function toMatrix4(m3:Matrix3):Matrix4 {
        var result = new Matrix4();
        result.elements[0] = m3.elements[0];
        result.elements[1] = m3.elements[1];
        result.elements[2] = m3.elements[2];
        result.elements[4] = m3.elements[3];
        result.elements[5] = m3.elements[4];
        result.elements[6] = m3.elements[5];
        result.elements[8] = m3.elements[6];
        result.elements[9] = m3.elements[7];
        result.elements[10] = m3.elements[8];
        return result;
    }
}

class QUnitTests {
    public static function runTests() {
        // INSTANCING
        var a = new Matrix3();
        QUnit.assert.ok(a.determinant() == 1, 'Passed!');

        var b = new Matrix3().set(0, 1, 2, 3, 4, 5, 6, 7, 8);
        QUnit.assert.ok(b.elements[0] == 0);
        QUnit.assert.ok(b.elements[1] == 3);
        QUnit.assert.ok(b.elements[2] == 6);
        QUnit.assert.ok(b.elements[3] == 1);
        QUnit.assert.ok(b.elements[4] == 4);
        QUnit.assert.ok(b.elements[5] == 7);
        QUnit.assert.ok(b.elements[6] == 2);
        QUnit.assert.ok(b.elements[7] == 5);
        QUnit.assert.ok(b.elements[8] == 8);

        var c = new Matrix3(0, 1, 2, 3, 4, 5, 6, 7, 8);
        QUnit.assert.ok(c.elements[0] == 0);
        QUnit.assert.ok(c.elements[1] == 3);
        QUnit.assert.ok(c.elements[2] == 6);
        QUnit.assert.ok(c.elements[3] == 1);
        QUnit.assert.ok(c.elements[4] == 4);
        QUnit.assert.ok(c.elements[5] == 7);
        QUnit.assert.ok(c.elements[6] == 2);
        QUnit.assert.ok(c.elements[7] == 5);
        QUnit.assert.ok(c.elements[8] == 8);

        // ... rest of the tests ...
    }
}