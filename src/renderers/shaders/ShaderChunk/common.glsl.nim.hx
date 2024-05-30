package three.js.src.renderers.shaders.ShaderChunk;

class Common {
    static var PI:Float = 3.141592653589793;
    static var PI2:Float = 6.283185307179586;
    static var PI_HALF:Float = 1.5707963267948966;
    static var RECIPROCAL_PI:Float = 0.3183098861837907;
    static var RECIPROCAL_PI2:Float = 0.15915494309189535;
    static var EPSILON:Float = 1e-6;

    static function saturate(a:Float):Float {
        return Math.max(0.0, Math.min(1.0, a));
    }

    static function whiteComplement(a:Float):Float {
        return 1.0 - saturate(a);
    }

    static function pow2(x:Float):Float {
        return x * x;
    }

    static function pow2(x:three.js.src.math.Vector3):three.js.src.math.Vector3 {
        return x * x;
    }

    static function pow3(x:Float):Float {
        return x * x * x;
    }

    static function pow4(x:Float):Float {
        var x2 = x * x;
        return x2 * x2;
    }

    static function max3(v:three.js.src.math.Vector3):Float {
        return Math.max(Math.max(v.x, v.y), v.z);
    }

    static function average(v:three.js.src.math.Vector3):Float {
        return v.x * 0.3333333 + v.y * 0.3333333 + v.z * 0.3333333;
    }

    static function rand(uv:three.js.src.math.Vector2):Float {
        var a = 12.9898;
        var b = 78.233;
        var c = 43758.5453;
        var dt = uv.x * a + uv.y * b;
        var sn = dt % PI;
        return Math.fract(Math.sin(sn) * c);
    }

    static function precisionSafeLength(v:three.js.src.math.Vector3):Float {
        #if high_precision
            return v.length();
        #else
            var maxComponent = Math.max(Math.max(Math.abs(v.x), Math.abs(v.y)), Math.abs(v.z));
            return (v / maxComponent).length() * maxComponent;
        #end
    }

    static function transformDirection(dir:three.js.src.math.Vector3, matrix:three.js.src.math.Matrix4):three.js.src.math.Vector3 {
        return (matrix * new three.js.src.math.Vector4(dir.x, dir.y, dir.z, 0.0)).normalize();
    }

    static function inverseTransformDirection(dir:three.js.src.math.Vector3, matrix:three.js.src.math.Matrix4):three.js.src.math.Vector3 {
        return (new three.js.src.math.Vector4(dir.x, dir.y, dir.z, 0.0) * matrix).normalize();
    }

    static function transposeMat3(m:three.js.src.math.Matrix3):three.js.src.math.Matrix3 {
        return new three.js.src.math.Matrix3(m[0].x, m[1].x, m[2].x, m[0].y, m[1].y, m[2].y, m[0].z, m[1].z, m[2].z);
    }

    static function luminance(rgb:three.js.src.math.Vector3):Float {
        var weights = new three.js.src.math.Vector3(0.2126729, 0.7151522, 0.0721750);
        return weights.dot(rgb);
    }

    static function isPerspectiveMatrix(m:three.js.src.math.Matrix4):Bool {
        return m[2][3] == -1.0;
    }

    static function equirectUv(dir:three.js.src.math.Vector3):three.js.src.math.Vector2 {
        var u = Math.atan2(dir.z, dir.x) * RECIPROCAL_PI2 + 0.5;
        var v = Math.asin(Math.clamp(dir.y, -1.0, 1.0)) * RECIPROCAL_PI + 0.5;
        return new three.js.src.math.Vector2(u, v);
    }

    static function BRDF_Lambert(diffuseColor:three.js.src.math.Vector3):three.js.src.math.Vector3 {
        return new three.js.src.math.Vector3(RECIPROCAL_PI * diffuseColor.x, RECIPROCAL_PI * diffuseColor.y, RECIPROCAL_PI * diffuseColor.z);
    }

    static function F_Schlick(f0:three.js.src.math.Vector3, f90:Float, dotVH:Float):three.js.src.math.Vector3 {
        var fresnel = Math.exp2((-5.55473 * dotVH - 6.98316) * dotVH);
        return f0 * (1.0 - fresnel) + new three.js.src.math.Vector3(f90 * fresnel, f90 * fresnel, f90 * fresnel);
    }

    static function F_Schlick(f0:Float, f90:Float, dotVH:Float):Float {
        var fresnel = Math.exp2((-5.55473 * dotVH - 6.98316) * dotVH);
        return f0 * (1.0 - fresnel) + f90 * fresnel;
    }
}