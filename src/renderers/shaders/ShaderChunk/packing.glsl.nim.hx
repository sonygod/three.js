package three.js.src.renderers.shaders.ShaderChunk;

class Packing {
    public static function packNormalToRGB(normal:Float3):Float3 {
        return normalize(normal) * 0.5 + 0.5;
    }

    public static function unpackRGBToNormal(rgb:Float3):Float3 {
        return 2.0 * rgb.xyz - 1.0;
    }

    private static inline var PackUpscale:Float = 256. / 255.;
    private static inline var UnpackDownscale:Float = 255. / 256.;

    private static inline var PackFactors:Float3 = new Float3(256. * 256. * 256., 256. * 256., 256.);
    private static inline var UnpackFactors:Float4 = new Float4(UnpackDownscale / PackFactors.x, UnpackDownscale / PackFactors.y, UnpackDownscale / PackFactors.z, UnpackDownscale);

    private static inline var ShiftRight8:Float = 1. / 256.;

    public static function packDepthToRGBA(v:Float):Float4 {
        var r:Float4 = new Float4(fract(v * PackFactors.x), fract(v * PackFactors.y), fract(v * PackFactors.z), v);
        r.yzw -= r.xyz * ShiftRight8;
        return r * PackUpscale;
    }

    public static function unpackRGBAToDepth(v:Float4):Float {
        return dot(v, UnpackFactors);
    }

    public static function packDepthToRG(v:Float):Float2 {
        return packDepthToRGBA(v).yx;
    }

    public static function unpackRGToDepth(v:Float2):Float {
        return unpackRGBAToDepth(new Float4(v.x, v.y, 0.0, 0.0));
    }

    public static function pack2HalfToRGBA(v:Float2):Float4 {
        var r:Float4 = new Float4(v.x, fract(v.x * 255.0), v.y, fract(v.y * 255.0));
        return new Float4(r.x - r.y / 255.0, r.y, r.z - r.w / 255.0, r.w);
    }

    public static function unpackRGBATo2Half(v:Float4):Float2 {
        return new Float2(v.x + (v.y / 255.0), v.z + (v.w / 255.0));
    }

    public static function viewZToOrthographicDepth(viewZ:Float, near:Float, far:Float):Float {
        return (viewZ + near) / (near - far);
    }

    public static function orthographicDepthToViewZ(depth:Float, near:Float, far:Float):Float {
        return depth * (near - far) - near;
    }

    public static function viewZToPerspectiveDepth(viewZ:Float, near:Float, far:Float):Float {
        return ((near + viewZ) * far) / ((far - near) * viewZ);
    }

    public static function perspectiveDepthToViewZ(depth:Float, near:Float, far:Float):Float {
        return (near * far) / ((far - near) * depth - far);
    }
}