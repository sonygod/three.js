package three.js.examples.jsh.nodes.functions.BSDF;

import shader_node.ShaderNode;

class DFGApprox {
    public static function tslFn(roughness:Float, dotNV:Vec3):Vec2 {
        var c0:Vec4 = new Vec4(-1, -0.0275, -0.572, 0.022);
        var c1:Vec4 = new Vec4(1, 0.0425, 1.04, -0.04);

        var r:Vec4 = new Vec4(roughness * c0.x, roughness * c0.y, roughness * c0.z, roughness * c0.w);
        r = r.add(c1);

        var a004:Float = r.x * r.x;
        a004 = Math.min(a004, Math.exp2(dotNV.x * -9.28));
        a004 *= r.x;
        a004 += r.y;

        var fab:Vec2 = new Vec2(-1.04 * a004, 1.04 * a004);
        fab.x += r.z;
        fab.y += r.w;

        return fab;
    }

    public static function setLayout():Void {
        ShaderNode.setLayout({
            name: 'DFGApprox',
            type: 'vec2',
            inputs: [
                { name: 'roughness', type: 'float' },
                { name: 'dotNV', type: 'vec3' }
            ]
        });
    }
}