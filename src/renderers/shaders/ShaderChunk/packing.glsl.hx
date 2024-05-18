package renderers.shaders.ShaderChunk;

class Packing {
    public static function packNormalToRGB(normal:Vec3):Vec3 {
        return normalize(normal) * 0.5 + 0.5;
    }

    public static function unpackRGBToNormal(rgb:Vec3):Vec3 {
        return 2.0 * rgb - 1.0;
    }

    private static var PackUpscale:Float = 256.0 / 255.0; // fraction -> 0..1 (including 1)
    private static var UnpackDownscale:Float = 255.0 / 256.0; // 0..1 -> fraction (excluding 1)

    private static var PackFactors:Vec3 = new Vec3(256.0 * 256.0 * 256.0, 256.0 * 256.0, 256.0);
    private static var UnpackFactors:Vec4 = new Vec4(UnpackDownscale / PackFactors.x, UnpackDownscale / PackFactors.y, UnpackDownscale / PackFactors.z, 1.0);

    private static var ShiftRight8:Float = 1.0 / 256.0;

    public static function packDepthToRGBA(v:Float):Vec4 {
        var r:Vec4 = new Vec4(Math.fract(v * PackFactors.x), v);
        r.y -= r.x * ShiftRight8; // tidy overflow
        r.z -= r.y * ShiftRight8; // tidy overflow
        r.w -= r.z * ShiftRight8; // tidy overflow
        return r * PackUpscale;
    }

    public static function unpackRGBAToDepth(v:Vec4):Float {
        return v.x * UnpackFactors.x + v.y * UnpackFactors.y + v.z * UnpackFactors.z + v.w * UnpackFactors.w;
    }

    public static function packDepthToRG(v:Float):Vec2 {
        return new Vec2(packDepthToRGBA(v).y, packDepthToRGBA(v).z);
    }

    public static function unpackRGToDepth(v:Vec2):Float {
        return unpackRGBAToDepth(new Vec4(v.x, v.y, 0.0, 0.0));
    }

    public static function pack2HalfToRGBA(v:Vec2):Vec4 {
        var r:Vec4 = new Vec4(v.x, Math.fract(v.x * 255.0), v.y, Math.fract(v.y * 255.0));
        return new Vec4(r.x - r.y / 255.0, r.y, r.z - r.w / 255.0, r.w);
    }

    public static function unpackRGBATo2Half(v:Vec4):Vec2 {
        return new Vec2(v.x + (v.y / 255.0), v.z + (v.w / 255.0));
    }

    // NOTE: viewZ, the z-coordinate in camera space, is negative for points in front of the camera

    public static function viewZToOrthographicDepth(viewZ:Float, near:Float, far:Float):Float {
        // -near maps to 0; -far maps to 1
        return (viewZ + near) / (near - far);
    }

    public static function orthographicDepthToViewZ(depth:Float, near:Float, far:Float):Float {
        // maps orthographic depth in [ 0, 1 ] to viewZ
        return depth * (near - far) - near;
    }

    // NOTE: https://twitter.com/gonnavis/status/1377183786949959682

    public static function viewZToPerspectiveDepth(viewZ:Float, near:Float, far:Float):Float {
        // -near maps to 0; -far maps to 1
        return ((near + viewZ) * far) / ((far - near) * viewZ);
    }

    public static function perspectiveDepthToViewZ(depth:Float, near:Float, far:Float):Float {
        // maps perspective depth in [ 0, 1 ] to viewZ
        return (near * far) / ((far - near) * depth - far);
    }
}