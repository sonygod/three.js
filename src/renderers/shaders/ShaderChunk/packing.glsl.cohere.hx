package math;

class ShaderFunctions {
    public static function packNormalToRGB(normal:Vec3<Float>) -> Vec3<Float> {
        return normal.normalize() * 0.5 + 0.5;
    }

    public static function unpackRGBToNormal(rgb:Vec3<Float>) -> Vec3<Float> {
        return (rgb * 2.0) - 1.0;
    }

    private static inline function PackUpscale = 256.0 / 255.0;
    private static inline function UnpackDownscale = 255.0 / 256.0;
    private static inline function PackFactors = Vec3<Float>.ofData([256.0 * 256.0 * 256.0, 256.0 * 256.0, 256.0]);
    private static inline function UnpackFactors = Vec4<Float>.ofData([UnpackDownscale / PackFactors.x, UnpackDownscale / PackFactors.y, UnpackDownscale / PackFactors.z, 1.0]);
    private static inline function ShiftRight8 = 1.0 / 256.0;

    public static function packDepthToRGBA(v:Float) -> Vec4<Float> {
        var r = Vec4<Float>.ofData([v * PackFactors.x, v * PackFactors.y, v * PackFactors.z, v]);
        r.y -= r.x * ShiftRight8;
        r.z -= r.y * ShiftRight8;
        r.w -= r.z * ShiftRight8;
        return r * PackUpscale;
    }

    public static function unpackRGBAToDepth(v:Vec4<Float>) -> Float {
        return v.dot(UnpackFactors);
    }

    public static function packDepthToRG(v:Float) -> Vec2<Float> {
        var rgba = packDepthToRGBA(v);
        return Vec2<Float>.ofData([rgba.y, rgba.x]);
    }

    public static function unpackRGToDepth(v:Vec2<Float>) -> Float {
        var rgba = Vec4<Float>.ofData([v.y, v.x, 0.0, 0.0]);
        return unpackRGBAToDepth(rgba);
    }

    public static function pack2HalfToRGBA(v:Vec2<Float>) -> Vec4<Float> {
        var r = Vec4<Float>.ofData([v.x, v.x * 255.0, v.y, v.y * 255.0]);
        r.y = r.y - Std.int(r.y);
        r.w = r.w - Std.int(r.w);
        return Vec4<Float>.ofData([r.x - r.y / 255.0, r.y, r.z - r.w / 255.0, r.w]);
    }

    public static function unpackRGBATo2Half(v:Vec4<Float>) -> Vec2<Float> {
        return Vec2<Float>.ofData([v.x + v.y / 255.0, v.z + v.w / 255.0]);
    }

    public static function viewZToOrthographicDepth(viewZ:Float, near:Float, far:Float) -> Float {
        return (viewZ + near) / (near - far);
    }

    public static function orthographicDepthToViewZ(depth:Float, near:Float, far:Float) -> Float {
        return depth * (near - far) - near;
    }

    public static function viewZToPerspectiveDepth(viewZ:Float, near:Float, far:Float) -> Float {
        return ((near + viewZ) * far) / ((far - near) * viewZ);
    }

    public static function perspectiveDepthToViewZ(depth:Float, near:Float, far:Float) -> Float {
        return (near * far) / ((far - near) * depth - far);
    }
}