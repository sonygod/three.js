import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class DFGApprox {
    public static function call(roughness: Float, dotNV: Vec3): Vec2 {
        var c0 = new Vec4(-1, -0.0275, -0.572, 0.022);
        var c1 = new Vec4(1, 0.0425, 1.04, -0.04);

        var r = c0.mul(roughness).add(c1);
        var a004 = r.x * r.x * Math.min(Math.pow(2, dotNV.x * -9.28), 1) * r.x + r.y;

        var fab = new Vec2(-1.04, 1.04).mul(a004).add(new Vec2(r.z, r.w));

        return fab;
    }
}

typedef Vec2 = Array<Float>;
typedef Vec3 = Array<Float>;
typedef Vec4 = Array<Float>;

class Vec3 {
    public var x: Float;
    public var y: Float;
    public var z: Float;

    public function new(x: Float, y: Float, z: Float) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public function mul(s: Float): Vec3 {
        return new Vec3(this.x * s, this.y * s, this.z * s);
    }
}

class Vec4 {
    public var x: Float;
    public var y: Float;
    public var z: Float;
    public var w: Float;

    public function new(x: Float, y: Float, z: Float, w: Float) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    public function mul(s: Float): Vec4 {
        return new Vec4(this.x * s, this.y * s, this.z * s, this.w * s);
    }

    public function add(v: Vec4): Vec4 {
        return new Vec4(this.x + v.x, this.y + v.y, this.z + v.z, this.w + v.w);
    }
}