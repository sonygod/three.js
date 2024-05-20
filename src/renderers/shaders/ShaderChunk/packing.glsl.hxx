class Packing {
    static function packNormalToRGB(normal:Float3):Float3 {
        return normal.normalize() * 0.5 + 0.5;
    }

    static function unpackRGBToNormal(rgb:Float3):Float3 {
        return rgb.xyz * 2.0 - 1.0;
    }

    static var PackUpscale = 256. / 255.; // fraction -> 0..1 (including 1)
    static var UnpackDownscale = 255. / 256.; // 0..1 -> fraction (excluding 1)

    static var PackFactors = new Float3(256. * 256. * 256., 256. * 256., 256.);
    static var UnpackFactors = UnpackDownscale / new Float4(PackFactors, 1.);

    static var ShiftRight8 = 1. / 256.;

    static function packDepthToRGBA(v:Float):Float4 {
        var r = new Float4(v * PackFactors, v);
        r.yzw -= r.xyz * ShiftRight8; // tidy overflow
        return r * PackUpscale;
    }

    static function unpackRGBAToDepth(v:Float4):Float {
        return v.dot(UnpackFactors);
    }

    static function packDepthToRG(v:Float):Float2 {
        return packDepthToRGBA(v).yx;
    }

    static function unpackRGToDepth(v:Float2):Float {
        return unpackRGBAToDepth(new Float4(v.xy, 0.0, 0.0));
    }

    static function pack2HalfToRGBA(v:Float2):Float4 {
        var r = new Float4(v.x, v.x * 255.0, v.y, v.y * 255.0);
        return new Float4(r.x - r.y / 255.0, r.y, r.z - r.w / 255.0, r.w);
    }

    static function unpackRGBATo2Half(v:Float4):Float2 {
        return new Float2(v.x + (v.y / 255.0), v.z + (v.w / 255.0));
    }

    static function viewZToOrthographicDepth(viewZ:Float, near:Float, far:Float):Float {
        // -near maps to 0; -far maps to 1
        return (viewZ + near) / (near - far);
    }

    static function orthographicDepthToViewZ(depth:Float, near:Float, far:Float):Float {
        // maps orthographic depth in [ 0, 1 ] to viewZ
        return depth * (near - far) - near;
    }

    static function viewZToPerspectiveDepth(viewZ:Float, near:Float, far:Float):Float {
        // -near maps to 0; -far maps to 1
        return ((near + viewZ) * far) / ((far - near) * viewZ);
    }

    static function perspectiveDepthToViewZ(depth:Float, near:Float, far:Float):Float {
        // maps perspective depth in [ 0, 1 ] to viewZ
        return (near * far) / ((far - near) * depth - far);
    }
}