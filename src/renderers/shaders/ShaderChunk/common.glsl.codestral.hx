class CommonShaderChunk {
    public static var PI:Float = 3.141592653589793;
    public static var PI2:Float = 6.283185307179586;
    public static var PI_HALF:Float = 1.5707963267948966;
    public static var RECIPROCAL_PI:Float = 0.3183098861837907;
    public static var RECIPROCAL_PI2:Float = 0.15915494309189535;
    public static var EPSILON:Float = 1e-6;

    public static function saturate(a:Float):Float {
        return Math.min(Math.max(a, 0.0), 1.0);
    }

    public static function whiteComplement(a:Float):Float {
        return 1.0 - saturate(a);
    }

    public static function pow2(x:Float):Float {
        return x * x;
    }

    public static function pow2(x:Array<Float>):Array<Float> {
        return [x[0] * x[0], x[1] * x[1], x[2] * x[2]];
    }

    public static function pow3(x:Float):Float {
        return x * x * x;
    }

    public static function pow4(x:Float):Float {
        var x2:Float = x * x;
        return x2 * x2;
    }

    public static function max3(v:Array<Float>):Float {
        return Math.max(Math.max(v[0], v[1]), v[2]);
    }

    public static function average(v:Array<Float>):Float {
        return v[0] * 0.3333333 + v[1] * 0.3333333 + v[2] * 0.3333333;
    }

    public static function rand(uv:Array<Float>):Float {
        var a:Float = 12.9898;
        var b:Float = 78.233;
        var c:Float = 43758.5453;
        var dt:Float = uv[0] * a + uv[1] * b;
        var sn:Float = dt % Math.PI;
        return Math.sin(sn) * c % 1.0;
    }

    public static function precisionSafeLength(v:Array<Float>):Float {
        var maxComponent:Float = max3(v.map(Math.abs));
        return v.map(x => x / maxComponent).reduce((a, b) => a + b * b, 0.0) * Math.sqrt(maxComponent);
    }

    public static function transformDirection(dir:Array<Float>, matrix:Array<Array<Float>>):Array<Float> {
        var result:Array<Float> = [
            dir[0] * matrix[0][0] + dir[1] * matrix[1][0] + dir[2] * matrix[2][0],
            dir[0] * matrix[0][1] + dir[1] * matrix[1][1] + dir[2] * matrix[2][1],
            dir[0] * matrix[0][2] + dir[1] * matrix[1][2] + dir[2] * matrix[2][2]
        ];
        var length:Float = Math.sqrt(result.map(x => x * x).reduce((a, b) => a + b, 0.0));
        return result.map(x => x / length);
    }

    public static function inverseTransformDirection(dir:Array<Float>, matrix:Array<Array<Float>>):Array<Float> {
        var result:Array<Float> = [
            dir[0] * matrix[0][0] + dir[1] * matrix[0][1] + dir[2] * matrix[0][2],
            dir[0] * matrix[1][0] + dir[1] * matrix[1][1] + dir[2] * matrix[1][2],
            dir[0] * matrix[2][0] + dir[1] * matrix[2][1] + dir[2] * matrix[2][2]
        ];
        var length:Float = Math.sqrt(result.map(x => x * x).reduce((a, b) => a + b, 0.0));
        return result.map(x => x / length);
    }

    public static function transposeMat3(m:Array<Array<Float>>):Array<Array<Float>> {
        return [
            [m[0][0], m[1][0], m[2][0]],
            [m[0][1], m[1][1], m[2][1]],
            [m[0][2], m[1][2], m[2][2]]
        ];
    }

    public static function luminance(rgb:Array<Float>):Float {
        var weights:Array<Float> = [0.2126729, 0.7151522, 0.0721750];
        return weights[0] * rgb[0] + weights[1] * rgb[1] + weights[2] * rgb[2];
    }

    public static function isPerspectiveMatrix(m:Array<Array<Float>>):Bool {
        return m[2][3] == -1.0;
    }

    public static function equirectUv(dir:Array<Float>):Array<Float> {
        var u:Float = Math.atan2(dir[2], dir[0]) * RECIPROCAL_PI2 + 0.5;
        var v:Float = Math.asin(Math.min(Math.max(dir[1], -1.0), 1.0)) * RECIPROCAL_PI + 0.5;
        return [u, v];
    }

    public static function BRDF_Lambert(diffuseColor:Array<Float>):Array<Float> {
        var factor:Float = RECIPROCAL_PI;
        return [diffuseColor[0] * factor, diffuseColor[1] * factor, diffuseColor[2] * factor];
    }

    public static function F_Schlick(f0:Array<Float>, f90:Float, dotVH:Float):Array<Float> {
        var fresnel:Float = Math.exp2((-5.55473 * dotVH - 6.98316) * dotVH);
        return [
            f0[0] * (1.0 - fresnel) + f90 * fresnel,
            f0[1] * (1.0 - fresnel) + f90 * fresnel,
            f0[2] * (1.0 - fresnel) + f90 * fresnel
        ];
    }

    public static function F_Schlick(f0:Float, f90:Float, dotVH:Float):Float {
        var fresnel:Float = Math.exp2((-5.55473 * dotVH - 6.98316) * dotVH);
        return f0 * (1.0 - fresnel) + f90 * fresnel;
    }
}