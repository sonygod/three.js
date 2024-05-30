import mx_perlin_noise_float.mx_perlin_noise_float;
import mx_perlin_noise_vec3.mx_perlin_noise_vec3;
import mx_worley_noise_float.worley_noise_float;
import mx_worley_noise_vec2.worley_noise_vec2;
import mx_worley_noise_vec3.worley_noise_vec3;
import mx_cell_noise_float.cell_noise_float;
import mx_fractal_noise_float.fractal_noise_float;
import mx_fractal_noise_vec2.fractal_noise_vec2;
import mx_fractal_noise_vec3.fractal_noise_vec3;
import mx_fractal_noise_vec4.fractal_noise_vec4;
import mx_hsvtorgb.mx_hsvtorgb;
import mx_rgbtohsv.mx_rgbtohsv;
import mx_srgb_texture_to_lin_rec709.mx_srgb_texture_to_lin_rec709;
import mix.mix;
import smoothstep.smoothstep;
import uv.uv;
import float.float;
import vec2.vec2;
import vec4.vec4;
import int.int;

class MaterialXNodes {

    public static function mx_aastep(threshold:Float, value:Float):Float {

        threshold = float(threshold);
        value = float(value);

        var afwidth = vec2(value.dFdx(), value.dFdy()).length().mul(0.70710678118654757);

        return smoothstep(threshold.sub(afwidth), threshold.add(afwidth), value);

    }

    private static function _ramp(a:Float, b:Float, uv:Vec2, p:String):Float {

        return mix(a, b, uv[p].clamp());

    }

    public static function mx_ramplr(valuel:Float, valuer:Float, texcoord:Vec2 = uv()):Float {

        return _ramp(valuel, valuer, texcoord, 'x');

    }

    public static function mx_ramptb(valuet:Float, valueb:Float, texcoord:Vec2 = uv()):Float {

        return _ramp(valuet, valueb, texcoord, 'y');

    }

    private static function _split(a:Float, b:Float, center:Float, uv:Vec2, p:String):Float {

        return mix(a, b, mx_aastep(center, uv[p]));

    }

    public static function mx_splitlr(valuel:Float, valuer:Float, center:Float, texcoord:Vec2 = uv()):Float {

        return _split(valuel, valuer, center, texcoord, 'x');

    }

    public static function mx_splittb(valuet:Float, valueb:Float, center:Float, texcoord:Vec2 = uv()):Float {

        return _split(valuet, valueb, center, texcoord, 'y');

    }

    public static function mx_transform_uv(uv_scale:Float = 1, uv_offset:Float = 0, uv_geo:Vec2 = uv()):Vec2 {

        return uv_geo.mul(uv_scale).add(uv_offset);

    }

    public static function mx_safepower(in1:Float, in2:Float = 1):Float {

        in1 = float(in1);

        return in1.abs().pow(in2).mul(in1.sign());

    }

    public static function mx_contrast(input:Float, amount:Float = 1, pivot:Float = .5):Float {

        return float(input).sub(pivot).mul(amount).add(pivot);

    }

    public static function mx_noise_float(texcoord:Vec2 = uv(), amplitude:Float = 1, pivot:Float = 0):Float {

        return mx_perlin_noise_float(texcoord.convert('vec2|vec3')).mul(amplitude).add(pivot);

    }

    public static function mx_noise_vec3(texcoord:Vec2 = uv(), amplitude:Float = 1, pivot:Float = 0):Vec3 {

        return mx_perlin_noise_vec3(texcoord.convert('vec2|vec3')).mul(amplitude).add(pivot);

    }

    public static function mx_noise_vec4(texcoord:Vec2 = uv(), amplitude:Float = 1, pivot:Float = 0):Vec4 {

        texcoord = texcoord.convert('vec2|vec3'); // overloading type

        var noise_vec4 = vec4(mx_perlin_noise_vec3(texcoord), mx_perlin_noise_float(texcoord.add(vec2(19, 73))));

        return noise_vec4.mul(amplitude).add(pivot);

    }

    public static function mx_worley_noise_float(texcoord:Vec2 = uv(), jitter:Float = 1):Float {

        return worley_noise_float(texcoord.convert('vec2|vec3'), jitter, int(1));

    }

    public static function mx_worley_noise_vec2(texcoord:Vec2 = uv(), jitter:Float = 1):Vec2 {

        return worley_noise_vec2(texcoord.convert('vec2|vec3'), jitter, int(1));

    }

    public static function mx_worley_noise_vec3(texcoord:Vec2 = uv(), jitter:Float = 1):Vec3 {

        return worley_noise_vec3(texcoord.convert('vec2|vec3'), jitter, int(1));

    }

    public static function mx_cell_noise_float(texcoord:Vec2 = uv()):Float {

        return cell_noise_float(texcoord.convert('vec2|vec3'));

    }

    public static function mx_fractal_noise_float(position:Vec2 = uv(), octaves:Int = 3, lacunarity:Float = 2, diminish:Float = .5, amplitude:Float = 1):Float {

        return fractal_noise_float(position, int(octaves), lacunarity, diminish).mul(amplitude);

    }

    public static function mx_fractal_noise_vec2(position:Vec2 = uv(), octaves:Int = 3, lacunarity:Float = 2, diminish:Float = .5, amplitude:Float = 1):Vec2 {

        return fractal_noise_vec2(position, int(octaves), lacunarity, diminish).mul(amplitude);

    }

    public static function mx_fractal_noise_vec3(position:Vec2 = uv(), octaves:Int = 3, lacunarity:Float = 2, diminish:Float = .5, amplitude:Float = 1):Vec3 {

        return fractal_noise_vec3(position, int(octaves), lacunarity, diminish).mul(amplitude);

    }

    public static function mx_fractal_noise_vec4(position:Vec2 = uv(), octaves:Int = 3, lacunarity:Float = 2, diminish:Float = .5, amplitude:Float = 1):Vec4 {

        return fractal_noise_vec4(position, int(octaves), lacunarity, diminish).mul(amplitude);

    }

    public static function mx_hsvtorgb(h:Float, s:Float, v:Float):Vec3 {

        return mx_hsvtorgb(h, s, v);

    }

    public static function mx_rgbtohsv(r:Float, g:Float, b:Float):Vec3 {

        return mx_rgbtohsv(r, g, b);

    }

    public static function mx_srgb_texture_to_lin_rec709(color:Vec3):Vec3 {

        return mx_srgb_texture_to_lin_rec709(color);

    }

}