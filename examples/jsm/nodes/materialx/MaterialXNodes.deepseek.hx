import three.js.examples.jsm.nodes.materialx.mx_noise.MxNoise;
import three.js.examples.jsm.nodes.materialx.mx_hsv.MxHsv;
import three.js.examples.jsm.nodes.materialx.mx_transform_color.MxTransformColor;
import three.js.examples.jsm.nodes.math.MathNode;
import three.js.examples.jsm.nodes.accessors.UVNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class MaterialXNodes {
    static function mx_aastep(threshold:Float, value:Float):Float {
        var afwidth = Math.sqrt(MathNode.dFdx(value) * MathNode.dFdx(value) + MathNode.dFdy(value) * MathNode.dFdy(value)) * 0.70710678118654757;
        return MathNode.smoothstep(threshold - afwidth, threshold + afwidth, value);
    }

    static function mx_ramplr(valuel:Float, valuer:Float, texcoord:UVNode = UVNode.uv()):Float {
        return _ramp(valuel, valuer, texcoord, 'x');
    }

    static function mx_ramptb(valuet:Float, valueb:Float, texcoord:UVNode = UVNode.uv()):Float {
        return _ramp(valuet, valueb, texcoord, 'y');
    }

    static function mx_splitlr(valuel:Float, valuer:Float, center:Float, texcoord:UVNode = UVNode.uv()):Float {
        return _split(valuel, valuer, center, texcoord, 'x');
    }

    static function mx_splittb(valuet:Float, valueb:Float, center:Float, texcoord:UVNode = UVNode.uv()):Float {
        return _split(valuet, valueb, center, texcoord, 'y');
    }

    static function mx_transform_uv(uv_scale:Float = 1, uv_offset:Float = 0, uv_geo:UVNode = UVNode.uv()):UVNode {
        return uv_geo.mul(uv_scale).add(uv_offset);
    }

    static function mx_safepower(in1:Float, in2:Float = 1):Float {
        return Math.sign(in1) * Math.pow(Math.abs(in1), in2);
    }

    static function mx_contrast(input:Float, amount:Float = 1, pivot:Float = .5):Float {
        return (input - pivot) * amount + pivot;
    }

    static function mx_noise_float(texcoord:UVNode = UVNode.uv(), amplitude:Float = 1, pivot:Float = 0):Float {
        return MxNoise.mx_perlin_noise_float(texcoord.convert('vec2|vec3')).mul(amplitude).add(pivot);
    }

    static function mx_noise_vec3(texcoord:UVNode = UVNode.uv(), amplitude:Float = 1, pivot:Float = 0):Float {
        return MxNoise.mx_perlin_noise_vec3(texcoord.convert('vec2|vec3')).mul(amplitude).add(pivot);
    }

    static function mx_noise_vec4(texcoord:UVNode = UVNode.uv(), amplitude:Float = 1, pivot:Float = 0):Float {
        texcoord = texcoord.convert('vec2|vec3');
        var noise_vec4 = new ShaderNode.vec4(MxNoise.mx_perlin_noise_vec3(texcoord), MxNoise.mx_perlin_noise_float(texcoord.add(new ShaderNode.vec2(19, 73))));
        return noise_vec4.mul(amplitude).add(pivot);
    }

    static function mx_worley_noise_float(texcoord:UVNode = UVNode.uv(), jitter:Float = 1):Float {
        return MxNoise.mx_worley_noise_float(texcoord.convert('vec2|vec3'), jitter, 1);
    }

    static function mx_worley_noise_vec2(texcoord:UVNode = UVNode.uv(), jitter:Float = 1):Float {
        return MxNoise.mx_worley_noise_vec2(texcoord.convert('vec2|vec3'), jitter, 1);
    }

    static function mx_worley_noise_vec3(texcoord:UVNode = UVNode.uv(), jitter:Float = 1):Float {
        return MxNoise.mx_worley_noise_vec3(texcoord.convert('vec2|vec3'), jitter, 1);
    }

    static function mx_cell_noise_float(texcoord:UVNode = UVNode.uv()):Float {
        return MxNoise.mx_cell_noise_float(texcoord.convert('vec2|vec3'));
    }

    static function mx_fractal_noise_float(position:UVNode = UVNode.uv(), octaves:Int = 3, lacunarity:Float = 2, diminish:Float = .5, amplitude:Float = 1):Float {
        return MxNoise.mx_fractal_noise_float(position, octaves, lacunarity, diminish).mul(amplitude);
    }

    static function mx_fractal_noise_vec2(position:UVNode = UVNode.uv(), octaves:Int = 3, lacunarity:Float = 2, diminish:Float = .5, amplitude:Float = 1):Float {
        return MxNoise.mx_fractal_noise_vec2(position, octaves, lacunarity, diminish).mul(amplitude);
    }

    static function mx_fractal_noise_vec3(position:UVNode = UVNode.uv(), octaves:Int = 3, lacunarity:Float = 2, diminish:Float = .5, amplitude:Float = 1):Float {
        return MxNoise.mx_fractal_noise_vec3(position, octaves, lacunarity, diminish).mul(amplitude);
    }

    static function mx_fractal_noise_vec4(position:UVNode = UVNode.uv(), octaves:Int = 3, lacunarity:Float = 2, diminish:Float = .5, amplitude:Float = 1):Float {
        return MxNoise.mx_fractal_noise_vec4(position, octaves, lacunarity, diminish).mul(amplitude);
    }

    static function mx_hsvtorgb(h:Float, s:Float, v:Float):ShaderNode.vec3 {
        return MxHsv.mx_hsvtorgb(h, s, v);
    }

    static function mx_rgbtohsv(rgb:ShaderNode.vec3):ShaderNode.vec3 {
        return MxHsv.mx_rgbtohsv(rgb);
    }

    static function mx_srgb_texture_to_lin_rec709(srgb:ShaderNode.vec3):ShaderNode.vec3 {
        return MxTransformColor.mx_srgb_texture_to_lin_rec709(srgb);
    }
}