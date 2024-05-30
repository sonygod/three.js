import three.js.examples.jsm.nodes.functions.BSDF.ShaderNode;

class D_GGX_Anisotropic {
    static var RECIPROCAL_PI:Float = 1 / Math.PI;

    static function D_GGX_Anisotropic(alphaT:Float, alphaB:Float, dotNH:Float, dotTH:Float, dotBH:Float):Float {
        var a2:Float = alphaT * alphaB;
        var v:Vec3 = new Vec3(alphaB * dotTH, alphaT * dotBH, a2 * dotNH);
        var v2:Float = v.dot(v);
        var w2:Float = a2 / v2;

        return RECIPROCAL_PI * a2 * Math.pow(w2, 2);
    }
}

class Vec3 {
    var x:Float;
    var y:Float;
    var z:Float;

    public function new(x:Float, y:Float, z:Float) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public function dot(v:Vec3):Float {
        return this.x * v.x + this.y * v.y + this.z * v.z;
    }
}