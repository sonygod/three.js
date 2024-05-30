import three.shadernode.ShaderNode;

class DFGApprox extends ShaderNode {

    public function new() {
        super();
        this.name = 'DFGApprox';
        this.type = 'vec2';
        this.inputs = [
            { name: 'roughness', type: 'float' },
            { name: 'dotNV', type: 'vec3' }
        ];
    }

    public function compute(roughness:Float, dotNV:Vec3):Vec2 {
        var c0 = new Vec4(-1, -0.0275, -0.572, 0.022);
        var c1 = new Vec4(1, 0.0425, 1.04, -0.04);
        var r = roughness.mul(c0).add(c1);
        var a004 = r.x.mul(r.x).min(dotNV.mul(-9.28).exp2()).mul(r.x).add(r.y);
        var fab = new Vec2(-1.04, 1.04).mul(a004).add(r.zw);
        return fab;
    }
}