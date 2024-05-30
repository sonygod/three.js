package three.js.examples.jm.nodes.materialx;

import mx_noise.MxPerlinNoiseFloat;
import mx_noise.MxPerlinNoiseVec3;
import mx_noise.MxWorleyNoiseFloat;
import mx_noise.MxWorleyNoiseVec2;
import mx_noise.MxWorleyNoiseVec3;
import mx_noise.MxCellNoiseFloat;
import mx_noise.MxFractalNoiseFloat;
import mx_noise.MxFractalNoiseVec2;
import mx_noise.MxFractalNoiseVec3;
import mx_noise.MxFractalNoiseVec4;
import mx_hsv.MxHsvToRgb;
import mx_hsv.MxRgbToHsv;
import mx_transform_color.MxSrgbTextureToLinRec709;
import math.MathNode.Mix;
import math.MathNode.Smoothstep;
import accessors.UVNode.Uv;
import shadernode.ShaderNode.Float;
import shadernode.ShaderNode.Vec2;
import shadernode.ShaderNode.Vec4;
import shadernode.ShaderNode.Int;

class MaterialXNodes
{
    public static function mx_aastep(threshold: Float, value: Float): Float
    {
        threshold = Float(threshold);
        value = Float(value);

        var afwidth = Vec2(value.dFdx(), value.dFdy()).length() * 0.70710678118654757;
        return Smoothstep(threshold - afwidth, threshold + afwidth, value);
    }

    private static function _ramp(a: Float, b: Float, uv: Vec2, p: String): Float
    {
        return Mix(a, b, uv[p].clamp());
    }

    public static function mx_ramplr(valuel: Float, valuer: Float, texcoord: Vec2 = Uv()): Float
    {
        return _ramp(valuel, valuer, texcoord, 'x');
    }

    public static function mx_ramptb(valuet: Float, valueb: Float, texcoord: Vec2 = Uv()): Float
    {
        return _ramp(valuet, valueb, texcoord, 'y');
    }

    private static function _split(a: Float, b: Float, center: Float, uv: Vec2, p: String): Float
    {
        return Mix(a, b, mx_aastep(center, uv[p]));
    }

    public static function mx_splitlr(valuel: Float, valuer: Float, center: Float, texcoord: Vec2 = Uv()): Float
    {
        return _split(valuel, valuer, center, texcoord, 'x');
    }

    public static function mx_splittb(valuet: Float, valueb: Float, center: Float, texcoord: Vec2 = Uv()): Float
    {
        return _split(valuet, valueb, center, texcoord, 'y');
    }

    public static function mx_transform_uv(uv_scale: Float = 1, uv_offset: Float = 0, uv_geo: Vec2 = Uv()): Vec2
    {
        return uv_geo.mul(uv_scale).add(uv_offset);
    }

    public static function mx_safepower(in1: Float, in2: Float = 1): Float
    {
        in1 = Float(in1);
        return in1.abs().pow(in2).mul(in1.sign());
    }

    public static function mx_contrast(input: Float, amount: Float = 1, pivot: Float = .5): Float
    {
        return Float(input).sub(pivot).mul(amount).add(pivot);
    }

    public static function mx_noise_float(texcoord: Vec2 = Uv(), amplitude: Float = 1, pivot: Float = 0): Float
    {
        return MxPerlinNoiseFloat(texcoord.convert('vec2|vec3')).mul(amplitude).add(pivot);
    }

    public static function mx_noise_vec3(texcoord: Vec2 = Uv(), amplitude: Float = 1, pivot: Float = 0): Vec3
    {
        return MxPerlinNoiseVec3(texcoord.convert('vec2|vec3')).mul(amplitude).add(pivot);
    }

    public static function mx_noise_vec4(texcoord: Vec2 = Uv(), amplitude: Float = 1, pivot: Float = 0): Vec4
    {
        texcoord = texcoord.convert('vec2|vec3'); // overloading type
        var noise_vec4 = Vec4(MxPerlinNoiseVec3(texcoord), MxPerlinNoiseFloat(texcoord.add(Vec2(19, 73))));
        return noise_vec4.mul(amplitude).add(pivot);
    }

    public static function mx_worley_noise_float(texcoord: Vec2 = Uv(), jitter: Float = 1): Float
    {
        return MxWorleyNoiseFloat(texcoord.convert('vec2|vec3'), jitter, Int(1));
    }

    public static function mx_worley_noise_vec2(texcoord: Vec2 = Uv(), jitter: Float = 1): Vec2
    {
        return MxWorleyNoiseVec2(texcoord.convert('vec2|vec3'), jitter, Int(1));
    }

    public static function mx_worley_noise_vec3(texcoord: Vec2 = Uv(), jitter: Float = 1): Vec3
    {
        return MxWorleyNoiseVec3(texcoord.convert('vec2|vec3'), jitter, Int(1));
    }

    public static function mx_cell_noise_float(texcoord: Vec2 = Uv()): Float
    {
        return MxCellNoiseFloat(texcoord.convert('vec2|vec3'));
    }

    public static function mx_fractal_noise_float(position: Vec2 = Uv(), octaves: Int = 3, lacunarity: Float = 2, diminish: Float = .5, amplitude: Float = 1): Float
    {
        return MxFractalNoiseFloat(position, octaves, lacunarity, diminish).mul(amplitude);
    }

    public static function mx_fractal_noise_vec2(position: Vec2 = Uv(), octaves: Int = 3, lacunarity: Float = 2, diminish: Float = .5, amplitude: Float = 1): Vec2
    {
        return MxFractalNoiseVec2(position, octaves, lacunarity, diminish).mul(amplitude);
    }

    public static function mx_fractal_noise_vec3(position: Vec2 = Uv(), octaves: Int = 3, lacunarity: Float = 2, diminish: Float = .5, amplitude: Float = 1): Vec3
    {
        return MxFractalNoiseVec3(position, octaves, lacunarity, diminish).mul(amplitude);
    }

    public static function mx_fractal_noise_vec4(position: Vec2 = Uv(), octaves: Int = 3, lacunarity: Float = 2, diminish: Float = .5, amplitude: Float = 1): Vec4
    {
        return MxFractalNoiseVec4(position, octaves, lacunarity, diminish).mul(amplitude);
    }
}