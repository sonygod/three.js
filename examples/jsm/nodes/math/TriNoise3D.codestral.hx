import three.js.nodes.math.LoopNode;
import three.js.nodes.shadernode.ShaderNode;

class TriNoise3D {
    static public function tri(x: Float): Float {
        return x.fract().sub(0.5).abs();
    }

    static public function tri3(p: ShaderNode.Vec3): ShaderNode.Vec3 {
        return new ShaderNode.Vec3(tri(p.z.add(tri(p.y))), tri(p.z.add(tri(p.x))), tri(p.y.add(tri(p.x))));
    }

    static public function triNoise3D(p_immutable: ShaderNode.Vec3, spd: Float, time: Float): Float {
        var p: ShaderNode.Vec3 = new ShaderNode.Vec3(p_immutable);
        var z: Float = 1.4;
        var rz: Float = 0.0;
        var bp: ShaderNode.Vec3 = new ShaderNode.Vec3(p);

        for (var i: Int = 0; i <= 3; i++) {
            var dg: ShaderNode.Vec3 = new ShaderNode.Vec3(tri3(bp.mul(2.0)));
            p = p.add(dg.add(time.mul(0.1).mul(spd)));
            bp = bp.mul(1.8);
            z = z * 1.5;
            p = p.mul(1.2);

            var t: Float = tri(p.z.add(tri(p.x.add(tri(p.y)))));
            rz = rz + t / z;
            bp = bp.add(0.14);
        }

        return rz;
    }
}