package three.math;

import haxe.ds.Vector;
import haxe.Int64;
import Math;

class MathUtils {
    public static inline var DEG2RAD:Float = Math.PI / 180;
    public static inline var RAD2DEG:Float = 180 / Math.PI;

    private static var _lut:Array<String> = [
        '00', '01', '02', '03', '04', '05', '06', '07', '08', '09', '0a', '0b', '0c', '0d', '0e', '0f',
        '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '1a', '1b', '1c', '1d', '1e', '1f',
        '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '2a', '2b', '2c', '2d', '2e', '2f',
        '30', '31', '32', '33', '34', '35', '36', '37', '38', '39', '3a', '3b', '3c', '3d', '3e', '3f',
        '40', '41', '42', '43', '44', '45', '46', '47', '48', '49', '4a', '4b', '4c', '4d', '4e', '4f',
        '50', '51', '52', '53', '54', '55', '56', '57', '58', '59', '5a', '5b', '5c', '5d', '5e', '5f',
        '60', '61', '62', '63', '64', '65', '66', '67', '68', '69', '6a', '6b', '6c', '6d', '6e', '6f',
        '70', '71', '72', '73', '74', '75', '76', '77', '78', '79', '7a', '7b', '7c', '7d', '7e', '7f',
        '80', '81', '82', '83', '84', '85', '86', '87', '88', '89', '8a', '8b', '8c', '8d', '8e', '8f',
        '90', '91', '92', '93', '94', '95', '96', '97', '98', '99', '9a', '9b', '9c', '9d', '9e', '9f',
        'a0', 'a1', 'a2', 'a3', 'a4', 'a5', 'a6', 'a7', 'a8', 'a9', 'aa', 'ab', 'ac', 'ad', 'ae', 'af',
        'b0', 'b1', 'b2', 'b3', 'b4', 'b5', 'b6', 'b7', 'b8', 'b9', 'ba', 'bb', 'bc', 'bd', 'be', 'bf',
        'c0', 'c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8', 'c9', 'ca', 'cb', 'cc', 'cd', 'ce', 'cf',
        'd0', 'd1', 'd2', 'd3', 'd4', 'd5', 'd6', 'd7', 'd8', 'd9', 'da', 'db', 'dc', 'dd', 'de', 'df',
        'e0', 'e1', 'e2', 'e3', 'e4', 'e5', 'e6', 'e7', 'e8', 'e9', 'ea', 'eb', 'ec', 'ed', 'ee', 'ef',
        'f0', 'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8', 'f9', 'fa', 'fb', 'fc', 'fd', 'fe', 'ff'
    ];

    private static var _seed:Int = 1234567;

    public static function generateUUID():String {
        var d0:Int = Std.random(0xFFFFFFFF) & 0xFFFFFFFF;
        var d1:Int = Std.random(0xFFFFFFFF) & 0xFFFFFFFF;
        var d2:Int = Std.random(0xFFFFFFFF) & 0xFFFFFFFF;
        var d3:Int = Std.random(0xFFFFFFFF) & 0xFFFFFFFF;

        var uuid:String = _lut[d0 & 0xFF] + _lut[d0 >> 8 & 0xFF] + _lut[d0 >> 16 & 0xFF] + _lut[d0 >> 24 & 0xFF] + '-' +
                         _lut[d1 & 0xFF] + _lut[d1 >> 8 & 0xFF] + '-' + _lut[d1 >> 16 & 0x0F | 0x40] + _lut[d1 >> 24 & 0xFF] + '-' +
                         _lut[d2 & 0x3F | 0x80] + _lut[d2 >> 8 & 0xFF] + '-' + _lut[d2 >> 16 & 0xFF] + _lut[d2 >> 24 & 0xFF] +
                         _lut[d3 & 0xFF] + _lut[d3 >> 8 & 0xFF] + _lut[d3 >> 16 & 0xFF] + _lut[d3 >> 24 & 0xFF];

        return uuid.toLowerCase();
    }

    public static function clamp(value:Float, min:Float, max:Float):Float {
        return Math.max(min, Math.min(max, value));
    }

    public static function euclideanModulo(n:Float, m:Float):Float {
        return (n % m + m) % m;
    }

    public static function mapLinear(x:Float, a1:Float, a2:Float, b1:Float, b2:Float):Float {
        return b1 + (x - a1) * (b2 - b1) / (a2 - a1);
    }

    public static function inverseLerp(x:Float, y:Float, value:Float):Float {
        if (x != y) {
            return (value - x) / (y - x);
        } else {
            return 0;
        }
    }

    public static function lerp(x:Float, y:Float, t:Float):Float {
        return (1 - t) * x + t * y;
    }

    public static function damp(x:Float, y:Float, lambda:Float, dt:Float):Float {
        return lerp(x, y, 1 - Math.exp(-lambda * dt));
    }

    public static function pingpong(x:Float, length:Float = 1):Float {
        return length - Math.abs(euclideanModulo(x, length * 2) - length);
    }

    public static function smoothstep(x:Float, min:Float, max:Float):Float {
        if (x <= min) return 0;
        if (x >= max) return 1;

        x = (x - min) / (max - min);
        return x * x * (3 - 2 * x);
    }

    public static function smootherstep(x:Float, min:Float, max:Float):Float {
        if (x <= min) return 0;
        if (x >= max) return 1;

        x = (x - min) / (max - min);
        return x * x * x * (x * (x * 6 - 15) + 10);
    }

    public static function randInt(low:Int, high:Int):Int {
        return low + Std.random(high - low + 1);
    }

    public static function randFloat(low:Float, high:Float):Float {
        return low + Math.random() * (high - low);
    }

    public static function randFloatSpread(range:Float):Float {
        return range * (0.5 - Math.random());
    }

    public static function seededRandom(s:Null<Int> = null):Float {
        if (s != null) _seed = s;

        var t:Int = _seed += 0x6D2B79F5;

        t = (t ^ t >>> 15) * 0x5851F42D;
        t = (t ^ t >>> 21) * 0x5851F42D;
        t = (t ^ t >>> 4);

        return (t >> 0) / 4294967296.0;
    }

    public static function degToRad(degrees:Float):Float {
        return degrees * DEG2RAD;
    }

    public static function radToDeg(radians:Float):Float {
        return radians * RAD2DEG;
    }

    public static function isPowerOfTwo(value:Int):Bool {
        return (value & (value - 1)) == 0 && value != 0;
    }

    public static function ceilPowerOfTwo(value:Int):Int {
        return Math.pow(2, Math.ceil(Math.log(value) / Math.LN2));
    }

    public static function floorPowerOfTwo(value:Int):Int {
        return Math.pow(2, Math.floor(Math.log(value) / Math.LN2));
    }

    public static function setQuaternionFromProperEuler(q:Vector<Float>, a:Float, b:Float, c:Float, order:String):Void {
        var cos:Float -> Float = Math.cos;
        var sin:Float -> Float = Math.sin;

        var c2:Float = cos(b / 2);
        var s2:Float = sin(b / 2);

        var c13:Float = cos((a + c) / 2);
        var s13:Float = sin((a + c) / 2);

        var c1_3:Float = cos((a - c) / 2);
        var s1_3:Float = sin((a - c) / 2);

        var c3_1:Float = cos((c - a) / 2);
        var s3_1:Float = sin((c - a) / 2);

        switch (order) {
            case 'XYX':
                q[0] = c2 * s13;
                q[1] = s2 * c1_3;
                q[2] = s2 * s1_3;
                q[3] = c2 * c13;
            case 'YZY':
                q[0] = s2 * s1_3;
                q[1] = c2 * s13;
                q[2] = s2 * c1_3;
                q[3] = c2 * c13;
            case 'ZXZ':
                q[0] = s2 * c1_3;
                q[1] = s2 * s1_3;
                q[2] = c2 * s13;
                q[3] = c2 * c13;
            case 'XZX':
                q[0] = c2 * s13;
                q[1] = s2 * s3_1;
                q[2] = s2 * c3_1;
                q[3] = c2 * c13;
            case 'YXY':
                q[0] = s2 * c3_1;
                q[1] = c2 * s13;
                q[2] = s2 * s3_1;
                q[3] = c2 * c13;
            case 'ZYZ':
                q[0] = s2 * s3_1;
                q[1] = s2 * c3_1;
                q[2] = c2 * s13;
                q[3] = c2 * c13;
            default:
                throw 'Unknown order: ' + order;
        }
    }

    public static function denormalize(value:Float, array:Array<Float>):Float {
        switch (Type.getClass(array)) {
            case Float32Array:
                return value;
            case Uint32Array:
                return value / 4294967295.0;
            case Uint16Array:
                return value / 65535.0;
            case Uint8Array:
                return value / 255.0;
            case Int32Array:
                return Math.max(value / 2147483647.0, -1.0);
            case Int16Array:
                return Math.max(value / 32767.0, -1.0);
            case Int8Array:
                return Math.max(value / 127.0, -1.0);
            default:
                throw 'Invalid component type.';
        }
    }

    public static function normalize(value:Float, array:Array<Float>):Float {
        switch (Type.getClass(array)) {
            case Float32Array:
                return value;
            case Uint32Array:
                return Math.round(value * 4294967295.0);
            case Uint16Array:
                return Math.round(value * 65535.0);
            case Uint8Array:
                return Math.round(value * 255.0);
            case Int32Array:
                return Math.round(value * 2147483647.0);
            case Int16Array:
                return Math.round(value * 32767.0);
            case Int8Array:
                return Math.round(value * 127.0);
            default:
                throw 'Invalid component type.';
        }
    }
}