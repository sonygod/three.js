import js.Lib;
import js.Math;
import js.RegExp;
import js.QUnit;

class MathUtils {
    static function generateUUID():String {
        return js.Lib.uuid();
    }

    static function clamp(value:Float, min:Float, max:Float):Float {
        return Math.max(min, Math.min(max, value));
    }

    static function euclideanModulo(n:Float, m:Float):Float {
        return ((n % m) + m) % m;
    }

    static function mapLinear(x:Float, a1:Float, a2:Float, b1:Float, b2:Float):Float {
        return b1 + (x - a1) * (b2 - b1) / (a2 - a1);
    }

    static function inverseLerp(x:Float, y:Float, value:Float):Float {
        if (value == y) return 0;
        if (value == x) return 1;
        return (value - x) / (y - x);
    }

    static function lerp(x:Float, y:Float, t:Float):Float {
        return (1 - t) * x + t * y;
    }

    static function damp(x:Float, y:Float, lambda:Float, dt:Float):Float {
        return Math.exp(-lambda * dt) * (x - y) + y;
    }

    static function pingpong(x:Float, length:Float = 2):Float {
        x = MathUtils.euclideanModulo(x, length);
        return length - Math.abs(x);
    }

    static function smoothstep(x:Float, min:Float, max:Float):Float {
        var t = MathUtils.clamp((x - min) / (max - min), 0.0, 1.0);
        return t * t * (3.0 - 2.0 * t);
    }

    static function smootherstep(x:Float, min:Float, max:Float):Float {
        var t = MathUtils.clamp((x - min) / (max - min), 0.0, 1.0);
        return t * t * t * (t * (t * 6 - 15) + 10);
    }

    static function randInt(low:Int, high:Int):Int {
        return js.Lib.random(low, high);
    }

    static function randFloat(low:Float, high:Float):Float {
        return js.Lib.random(low, high);
    }

    static function randFloatSpread(range:Float):Float {
        return range * (0.5 - js.Lib.random());
    }

    static function degToRad(degrees:Float):Float {
        return degrees * (Math.PI / 180);
    }

    static function radToDeg(radians:Float):Float {
        return radians * (180 / Math.PI);
    }

    static function isPowerOfTwo(value:Int):Bool {
        return (value & (value - 1)) == 0 && value != 0;
    }

    static function ceilPowerOfTwo(value:Int):Int {
        value--;
        value |= value >> 1;
        value |= value >> 2;
        value |= value >> 4;
        value |= value >> 8;
        value |= value >> 16;
        value++;
        return value;
    }

    static function floorPowerOfTwo(value:Int):Int {
        return 1 << ((31 - js.Math.clz32(value)) - 1);
    }
}

class MathUtilsTest {
    static function main() {
        QUnit.module("Maths");
        QUnit.module("Math");

        QUnit.test("generateUUID", (assert) -> {
            var a = MathUtils.generateUUID();
            var regex = new RegExp(/[A-Z0-9]{8}-[A-Z0-9]{4}-4[A-Z0-9]{3}-[A-Z0-9]{4}-[A-Z0-9]{12}/i);
            assert.ok(regex.test(a), "Generated UUID matches the expected pattern");
        });

        // ... 其他测试代码 ...

        QUnit.start();
    }
}

class Main {
    static function main() {
        MathUtilsTest.main();
    }
}