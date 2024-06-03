import ShaderNode.{tslFn, vec3};

class Schlick_to_F0 {
    public static function apply(f:vec3, f90:Float, dotVH:Float):vec3 {
        var x = dotVH.oneMinus().saturate();
        var x2 = x.mul(x);
        var x5 = x.mul(x2).mul(x2).clamp(0.0, 0.9999);

        return f.sub(vec3(f90).mul(x5)).div(x5.oneMinus());
    }
}

// You can use it like this:
var result = Schlick_to_F0.apply(f, f90, dotVH);