import js.Lib;
import three.js.src.math.Vector2;
import three.js.src.math.Matrix3;
import three.js.src.core.BufferAttribute;
import three.js.utils.math_constants;

class Vector2Tests {
    static function main() {
        unittest.run();
    }

    static function testInstancing(unittest:Assert) {
        var a = new Vector2();
        unittest.assert(a.x == 0);
        unittest.assert(a.y == 0);

        a = new Vector2(math_constants.x, math_constants.y);
        unittest.assert(a.x == math_constants.x);
        unittest.assert(a.y == math_constants.y);
    }

    static function testProperties(unittest:Assert) {
        var a = new Vector2(0, 0);
        var width = 100;
        var height = 200;

        unittest.assert(a.width = width);
        unittest.assert(a.height = height);

        a.set(width, height);
        unittest.assert(a.width == width);
        unittest.assert(a.height == height);
    }

    // ... 其他测试函数 ...

    static function testSetXSetY(unittest:Assert) {
        var a = new Vector2();
        unittest.assert(a.x == 0);
        unittest.assert(a.y == 0);

        a.setX(math_constants.x);
        a.setY(math_constants.y);
        unittest.assert(a.x == math_constants.x);
        unittest.assert(a.y == math_constants.y);
    }

    static function testSetComponentGetComponent(unittest:Assert) {
        var a = new Vector2();
        unittest.assert(a.x == 0);
        unittest.assert(a.y == 0);

        a.setComponent(0, 1);
        a.setComponent(1, 2);
        unittest.assert(a.getComponent(0) == 1);
        unittest.assert(a.getComponent(1) == 2);
    }

    // ... 其他测试函数 ...

    static function testMultiplyDivide(unittest:Assert) {
        var a = new Vector2(math_constants.x, math_constants.y);
        var b = new Vector2(-math_constants.x, -math_constants.y);

        a.multiplyScalar(-2);
        unittest.assert(a.x == math_constants.x * -2);
        unittest.assert(a.y == math_constants.y * -2);

        b.multiplyScalar(-2);
        unittest.assert(b.x == 2 * math_constants.x);
        unittest.assert(b.y == 2 * math_constants.y);

        a.divideScalar(-2);
        unittest.assert(a.x == math_constants.x);
        unittest.assert(a.y == math_constants.y);

        b.divideScalar(-2);
        unittest.assert(b.x == -math_constants.x);
        unittest.assert(b.y == -math_constants.y);
    }

    // ... 其他测试函数 ...

    static function testSetScalarAddScalarSubScalar(unittest:Assert) {
        var a = new Vector2(1, 1);
        var s = 3;

        a.setScalar(s);
        unittest.assert(a.x == s);
        unittest.assert(a.y == s);

        a.addScalar(s);
        unittest.assert(a.x == 2 * s);
        unittest.assert(a.y == 2 * s);

        a.subScalar(2 * s);
        unittest.assert(a.x == 0);
        unittest.assert(a.y == 0);
    }

    static function testMultiplyDivide(unittest:Assert) {
        var a = new Vector2(math_constants.x, math_constants.y);
        var b = new Vector2(2 * math_constants.x, 2 * math_constants.y);
        var c = new Vector2(4 * math_constants.x, 4 * math_constants.y);

        a.multiply(b);
        unittest.assert(a.x == math_constants.x * b.x);
        unittest.assert(a.y == math_constants.y * b.y);

        b.divide(c);
        unittest.assert(b.x == 0.5);
        unittest.assert(b.y == 0.5);
    }

    // ... 其他测试函数 ...
}

class Unittest {
    public function assert(cond:Bool) {
        if (!cond) {
            throw "Assertion failed";
        }
    }

    public function run() {
        Vector2Tests.testInstancing(this);
        Vector2Tests.testProperties(this);
        // ... 运行其他测试函数 ...
    }
}

@:build(js.Lib.require('qunit'))
class Main {
    static function main() {
        Vector2Tests.main();
    }
}