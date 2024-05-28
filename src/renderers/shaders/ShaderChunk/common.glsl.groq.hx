package three.js.src.renderers.shaders.common;

// Constants
@:final class Constants {
    public static inline var PI = 3.141592653589793;
    public static inline var PI2 = 6.283185307179586;
    public static inline var PI_HALF = 1.5707963267948966;
    public static inline var RECIPROCAL_PI = 0.3183098861837907;
    public static inline var RECIPROCAL_PI2 = 0.15915494309189535;
    public static inline var EPSILON = 1e-6;
}

// Functions
class ShaderCommon {
    public static function pow2(x:Float):Float {
        return x * x;
    }

    public static function pow2(v:Vec3):Vec3 {
        return v * v;
    }

    public static function pow3(x:Float):Float {
        return x * x * x;
    }

    public static function pow4(x:Float):Float {
        var x2 = x * x;
        return x2 * x2;
    }

    public static function max3(v:Vec3):Float {
        return Math.max(Math.max(v.x, v.y), v.z);
    }

    public static function average(v:Vec3):Float {
        return v.dot(new Vec3(0.3333333));
    }

    public static function rand(uv:Vec2):Float {
        var a = 12.9898;
        var b = 78.233;
        var c = 43758.5453;
        var dt = uv.dot(new Vec2(a, b));
        var sn = dt % Constants.PI;
        return Math.fract(Math.sin(sn) * c);
    }

    public static function precisionSafeLength(v:Vec3):Float {
        #if HIGH_PRECISION
        return v.length();
        #else
        var maxComponent = max3(v.abs());
        return (v / maxComponent).length() * maxComponent;
        #end
    }

    public static function transformDirection(dir:Vec3, matrix:Mat4):Vec3 {
        return normalize((matrix * new Vec4(dir, 0.0)).xyz);
    }

    public static function inverseTransformDirection(dir:Vec3, matrix:Mat4):Vec3 {
        return normalize((new Vec4(dir, 0.0) * matrix).xyz);
    }

    public static function transposeMat3(m:Mat3):Mat3 {
        var tmp = new Mat3();
        tmp[0] = new Vec3(m[0].x, m[1].x, m[2].x);
        tmp[1] = new Vec3(m[0].y, m[1].y, m[2].y);
        tmp[2] = new Vec3(m[0].z, m[1].z, m[2].z);
        return tmp;
    }

    public static function luminance(rgb:Vec3):Float {
        var weights = new Vec3(0.2126729, 0.7151522, 0.0721750);
        return rgb.dot(weights);
    }

    public static function isPerspectiveMatrix(m:Mat4):Bool {
        return m[2][3] == -1.0;
    }

    public static function equirectUv(dir:Vec3):Vec2 {
        var u = Math.atan2(dir.z, dir.x) * Constants.RECIPROCAL_PI2 + 0.5;
        var v = Math.asin(dir.y) * Constants.RECIPROCAL_PI + 0.5;
        return new Vec2(u, v);
    }

    public static function BRDF_Lambert(diffuseColor:Vec3):Vec3 {
        return Constants.RECIPROCAL_PI * diffuseColor;
    }

    public static function F_Schlick(f0:Vec3, f90:Float, dotVH:Float):Vec3 {
        var fresnel = Math.exp2((-5.55473 * dotVH - 6.98316) * dotVH);
        return f0 * (1.0 - fresnel) + (f90 * fresnel);
    }

    public static function F_Schlick(f0:Float, f90:Float, dotVH:Float):Float {
        var fresnel = Math.exp2((-5.55473 * dotVH - 6.98316) * dotVH);
        return f0 * (1.0 - fresnel) + (f90 * fresnel);
    }
}

// Structs
typedef IncidentLight = {
    color:Vec3,
    direction:Vec3,
    visible:Bool
}

typedef ReflectedLight = {
    directDiffuse:Vec3,
    directSpecular:Vec3,
    indirectDiffuse:Vec3,
    indirectSpecular:Vec3
}