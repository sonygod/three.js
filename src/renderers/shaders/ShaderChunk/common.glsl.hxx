class Common {
    static var PI:Float = 3.141592653589793;
    static var PI2:Float = 6.283185307179586;
    static var PI_HALF:Float = 1.5707963267948966;
    static var RECIPROCAL_PI:Float = 0.3183098861837907;
    static var RECIPROCAL_PI2:Float = 0.15915494309189535;
    static var EPSILON:Float = 1e-6;

    static function saturate(a:Float):Float {
        return Math.clamp(a, 0.0, 1.0);
    }

    static function whiteComplement(a:Float):Float {
        return 1.0 - saturate(a);
    }

    static function pow2(x:Float):Float {
        return x * x;
    }

    static function pow3(x:Float):Float {
        return x * x * x;
    }

    static function pow4(x:Float):Float {
        var x2 = x * x;
        return x2 * x2;
    }

    static function max3(v:haxe.math.Vec3):Float {
        return Math.max(Math.max(v.x, v.y), v.z);
    }

    static function average(v:haxe.math.Vec3):Float {
        return haxe.math.Vec3.dot(v, new haxe.math.Vec3(0.3333333, 0.3333333, 0.3333333));
    }

    static function rand(uv:haxe.math.Vec2):Float {
        var a:Float = 12.9898, b:Float = 78.233, c:Float = 43758.5453;
        var dt:Float = haxe.math.Vec2.dot(uv, new haxe.math.Vec2(a, b));
        var sn:Float = dt % Common.PI;
        return Math.fract(Math.sin(sn) * c);
    }

    static function precisionSafeLength(v:haxe.math.Vec3):Float {
        return haxe.math.Vec3.length(v);
    }

    static function transformDirection(dir:haxe.math.Vec3, matrix:haxe.math.Mat4):haxe.math.Vec3 {
        return haxe.math.Vec3.normalize((matrix * new haxe.math.Vec4(dir, 0.0)).xyz);
    }

    static function inverseTransformDirection(dir:haxe.math.Vec3, matrix:haxe.math.Mat4):haxe.math.Vec3 {
        return haxe.math.Vec3.normalize((new haxe.math.Vec4(dir, 0.0) * matrix).xyz);
    }

    static function transposeMat3(m:haxe.math.Mat3):haxe.math.Mat3 {
        var tmp:haxe.math.Mat3 = new haxe.math.Mat3();
        tmp[0] = new haxe.math.Vec3(m[0].x, m[1].x, m[2].x);
        tmp[1] = new haxe.math.Vec3(m[0].y, m[1].y, m[2].y);
        tmp[2] = new haxe.math.Vec3(m[0].z, m[1].z, m[2].z);
        return tmp;
    }

    static function luminance(rgb:haxe.math.Vec3):Float {
        var weights:haxe.math.Vec3 = new haxe.math.Vec3(0.2126729, 0.7151522, 0.0721750);
        return haxe.math.Vec3.dot(weights, rgb);
    }

    static function isPerspectiveMatrix(m:haxe.math.Mat4):Bool {
        return m[2][3] == -1.0;
    }

    static function equirectUv(dir:haxe.math.Vec3):haxe.math.Vec2 {
        var u:Float = Math.atan2(dir.z, dir.x) * Common.RECIPROCAL_PI2 + 0.5;
        var v:Float = Math.asin(Math.clamp(dir.y, -1.0, 1.0)) * Common.RECIPROCAL_PI + 0.5;
        return new haxe.math.Vec2(u, v);
    }

    static function BRDF_Lambert(diffuseColor:haxe.math.Vec3):haxe.math.Vec3 {
        return Common.RECIPROCAL_PI * diffuseColor;
    }

    static function F_Schlick(f0:haxe.math.Vec3, f90:Float, dotVH:Float):haxe.math.Vec3 {
        var fresnel:Float = Math.exp2((-5.55473 * dotVH - 6.98316) * dotVH);
        return f0 * (1.0 - fresnel) + (f90 * fresnel);
    }

    static function F_Schlick(f0:Float, f90:Float, dotVH:Float):Float {
        var fresnel:Float = Math.exp2((-5.55473 * dotVH - 6.98316) * dotVH);
        return f0 * (1.0 - fresnel) + (f90 * fresnel);
    }
}