import js.Browser.document;

// Assuming the functions are defined in the same file
extern function mx_perlin_noise_float(texcoord:Dynamic):Float;
extern function mx_perlin_noise_vec3(texcoord:Dynamic):Vec3;
extern function mx_worley_noise_float(texcoord:Dynamic, jitter:Float, seed:Int):Float;
extern function mx_worley_noise_vec2(texcoord:Dynamic, jitter:Float, seed:Int):Vec2;
extern function mx_worley_noise_vec3(texcoord:Dynamic, jitter:Float, seed:Int):Vec3;
extern function mx_cell_noise_float(texcoord:Dynamic):Float;
extern function mx_fractal_noise_float(position:Dynamic, octaves:Int, lacunarity:Float, diminish:Float):Float;
extern function mx_fractal_noise_vec2(position:Dynamic, octaves:Int, lacunarity:Float, diminish:Float):Vec2;
extern function mx_fractal_noise_vec3(position:Dynamic, octaves:Int, lacunarity:Float, diminish:Float):Vec3;
extern function mx_fractal_noise_vec4(position:Dynamic, octaves:Int, lacunarity:Float, diminish:Float):Vec4;
extern function mx_hsvtorgb(h:Float, s:Float, v:Float):Vec3;
extern function mx_rgbtohsv(rgb:Vec3):Vec3;
extern function mx_srgb_texture_to_lin_rec709(texture:Dynamic):Dynamic;

// Classes for vector operations
class Vec2 {
    public var x:Float;
    public var y:Float;

    public function new(x:Float, y:Float) {
        this.x = x;
        this.y = y;
    }

    public function length():Float {
        return Math.sqrt(this.x * this.x + this.y * this.y);
    }

    public function mul(scalar:Float):Vec2 {
        return new Vec2(this.x * scalar, this.y * scalar);
    }

    public function add(vector:Vec2):Vec2 {
        return new Vec2(this.x + vector.x, this.y + vector.y);
    }

    // Add more necessary methods here
}

class Vec3 {
    public var x:Float;
    public var y:Float;
    public var z:Float;

    public function new(x:Float, y:Float, z:Float) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    // Add necessary methods here
}

class Vec4 {
    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var w:Float;

    public function new(x:Float, y:Float, z:Float, w:Float) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    public function mul(scalar:Float):Vec4 {
        return new Vec4(this.x * scalar, this.y * scalar, this.z * scalar, this.w * scalar);
    }

    public function add(vector:Vec4):Vec4 {
        return new Vec4(this.x + vector.x, this.y + vector.y, this.z + vector.z, this.w + vector.w);
    }

    // Add more necessary methods here
}

// Utility functions
function float(value:Dynamic):Float {
    return js.Boot.toFloat(value);
}

function int(value:Dynamic):Int {
    return js.Boot.toInt(value);
}

function vec2(x:Float, y:Float):Vec2 {
    return new Vec2(x, y);
}

function vec4(x:Float, y:Float, z:Float, w:Float):Vec4 {
    return new Vec4(x, y, z, w);
}

// Functions from the JavaScript code
function mx_aastep(threshold:Float, value:Float):Float {
    threshold = float(threshold);
    value = float(value);

    var afwidth = vec2(value.dFdx(), value.dFdy()).length() * 0.70710678118654757;

    return smoothstep(threshold - afwidth, threshold + afwidth, value);
}

function _ramp(a:Dynamic, b:Dynamic, uv:Vec2, p:String):Dynamic {
    var uvVal = (p == 'x') ? uv.x : uv.y;
    return mix(a, b, Math.min(Math.max(uvVal, 0), 1));
}

function mx_ramplr(valuel:Dynamic, valuer:Dynamic, texcoord:Vec2 = uv()):Dynamic {
    return _ramp(valuel, valuer, texcoord, 'x');
}

function mx_ramptb(valuet:Dynamic, valueb:Dynamic, texcoord:Vec2 = uv()):Dynamic {
    return _ramp(valuet, valueb, texcoord, 'y');
}

function _split(a:Dynamic, b:Dynamic, center:Float, uv:Vec2, p:String):Dynamic {
    var uvVal = (p == 'x') ? uv.x : uv.y;
    return mix(a, b, mx_aastep(center, uvVal));
}

function mx_splitlr(valuel:Dynamic, valuer:Dynamic, center:Float, texcoord:Vec2 = uv()):Dynamic {
    return _split(valuel, valuer, center, texcoord, 'x');
}

function mx_splittb(valuet:Dynamic, valueb:Dynamic, center:Float, texcoord:Vec2 = uv()):Dynamic {
    return _split(valuet, valueb, center, texcoord, 'y');
}

function mx_transform_uv(uv_scale:Float = 1, uv_offset:Float = 0, uv_geo:Vec2 = uv()):Vec2 {
    return uv_geo.mul(uv_scale).add(vec2(uv_offset, uv_offset));
}

function mx_safepower(in1:Float, in2:Float = 1):Float {
    in1 = float(in1);
    return Math.pow(Math.abs(in1), in2) * Math.sign(in1);
}

function mx_contrast(input:Float, amount:Float = 1, pivot:Float = .5):Float {
    input = float(input);
    return (input - pivot) * amount + pivot;
}

function mx_noise_float(texcoord:Vec2 = uv(), amplitude:Float = 1, pivot:Float = 0):Float {
    return mx_perlin_noise_float(texcoord).mul(amplitude).add(pivot);
}

function mx_noise_vec3(texcoord:Vec2 = uv(), amplitude:Float = 1, pivot:Float = 0):Vec3 {
    return mx_perlin_noise_vec3(texcoord).mul(amplitude).add(vec3(pivot, pivot, pivot));
}

function mx_noise_vec4(texcoord:Vec2 = uv(), amplitude:Float = 1, pivot:Float = 0):Vec4 {
    var noise_vec4 = vec4(mx_perlin_noise_vec3(texcoord).x, mx_perlin_noise_vec3(texcoord).y, mx_perlin_noise_vec3(texcoord).z, mx_perlin_noise_float(texcoord.add(vec2(19, 73))));
    return noise_vec4.mul(amplitude).add(vec4(pivot, pivot, pivot, pivot));
}

function mx_worley_noise_float(texcoord:Vec2 = uv(), jitter:Float = 1):Float {
    return mx_worley_noise_float(texcoord, jitter, int(1));
}

function mx_worley_noise_vec2(texcoord:Vec2 = uv(), jitter:Float = 1):Vec2 {
    return mx_worley_noise_vec2(texcoord, jitter, int(1));
}

function mx_worley_noise_vec3(texcoord:Vec2 = uv(), jitter:Float = 1):Vec3 {
    return mx_worley_noise_vec3(texcoord, jitter, int(1));
}

function mx_cell_noise_float(texcoord:Vec2 = uv()):Float {
    return mx_cell_noise_float(texcoord);
}

function mx_fractal_noise_float(position:Vec2 = uv(), octaves:Int = 3, lacunarity:Float = 2, diminish:Float = .5, amplitude:Float = 1):Float {
    return mx_fractal_noise_float(position, int(octaves), lacunarity, diminish).mul(amplitude);
}

function mx_fractal_noise_vec2(position:Vec2 = uv(), octaves:Int = 3, lacunarity:Float = 2, diminish:Float = .5, amplitude:Float = 1):Vec2 {
    return mx_fractal_noise_vec2(position, int(octaves), lacunarity, diminish).mul(amplitude);
}

function mx_fractal_noise_vec3(position:Vec2 = uv(), octaves:Int = 3, lacunarity:Float = 2, diminish:Float = .5, amplitude:Float = 1):Vec3 {
    return mx_fractal_noise_vec3(position, int(octaves), lacunarity, diminish).mul(amplitude);
}

function mx_fractal_noise_vec4(position:Vec2 = uv(), octaves:Int = 3, lacunarity:Float = 2, diminish:Float = .5, amplitude:Float = 1):Vec4 {
    return mx_fractal_noise_vec4(position, int(octaves), lacunarity, diminish).mul(amplitude);
}

// Export functions
export function mx_hsvtorgb(h:Float, s:Float, v:Float):Vec3 {
    return mx_hsvtorgb(h, s, v);
}

export function mx_rgbtohsv(rgb:Vec3):Vec3 {
    return mx_rgbtohsv(rgb);
}

export function mx_srgb_texture_to_lin_rec709(texture:Dynamic):Dynamic {
    return mx_srgb_texture_to_lin_rec709(texture);
}