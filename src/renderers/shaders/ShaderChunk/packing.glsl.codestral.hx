package three.js.src.renderers.shaders.ShaderChunk;

class Packing {
    static function packNormalToRGB(normal:Float):Array<Float> {
        var normalized:Array<Float> = normal.map(x => x / normal.length);
        var scaled:Array<Float> = normalized.map(x => x * 0.5 + 0.5);
        return scaled;
    }

    static function unpackRGBToNormal(rgb:Array<Float>):Array<Float> {
        var unpacked:Array<Float> = rgb.map(x => 2.0 * x - 1.0);
        return unpacked;
    }

    static var PackUpscale:Float = 256.0 / 255.0;
    static var UnpackDownscale:Float = 255.0 / 256.0;

    static var PackFactors:Array<Float> = [256.0 * 256.0 * 256.0, 256.0 * 256.0, 256.0];
    static var UnpackFactors:Array<Float> = PackFactors.map(x => UnpackDownscale / x);
    UnpackFactors.push(1.0);

    static var ShiftRight8:Float = 1.0 / 256.0;

    static function packDepthToRGBA(v:Float):Array<Float> {
        var r:Array<Float> = PackFactors.map(x => v * x);
        r[1] -= r[0] * ShiftRight8;
        r[2] -= r[0] * ShiftRight8;
        r[3] -= r[0] * ShiftRight8;
        r = r.map(x => x - Math.floor(x));
        r.push(v);
        return r.map(x => x * PackUpscale);
    }

    static function unpackRGBAToDepth(v:Array<Float>):Float {
        return v.reduce((a, b, i) => a + b * UnpackFactors[i], 0.0);
    }

    static function packDepthToRG(v:Float):Array<Float> {
        var rgba:Array<Float> = packDepthToRGBA(v);
        return [rgba[1], rgba[0]];
    }

    static function unpackRGToDepth(v:Array<Float>):Float {
        var rgba:Array<Float> = [v[0], v[1], 0.0, 0.0];
        return unpackRGBAToDepth(rgba);
    }

    static function pack2HalfToRGBA(v:Array<Float>):Array<Float> {
        var r:Array<Float> = [v[0], v[0] * 255.0 % 1.0, v[1], v[1] * 255.0 % 1.0];
        return [r[0] - r[1] / 255.0, r[1], r[2] - r[3] / 255.0, r[3]];
    }

    static function unpackRGBATo2Half(v:Array<Float>):Array<Float> {
        return [v[0] + v[1] / 255.0, v[2] + v[3] / 255.0];
    }

    static function viewZToOrthographicDepth(viewZ:Float, near:Float, far:Float):Float {
        return (viewZ + near) / (near - far);
    }

    static function orthographicDepthToViewZ(depth:Float, near:Float, far:Float):Float {
        return depth * (near - far) - near;
    }

    static function viewZToPerspectiveDepth(viewZ:Float, near:Float, far:Float):Float {
        return ((near + viewZ) * far) / ((far - near) * viewZ);
    }

    static function perspectiveDepthToViewZ(depth:Float, near:Float, far:Float):Float {
        return (near * far) / ((far - near) * depth - far);
    }
}