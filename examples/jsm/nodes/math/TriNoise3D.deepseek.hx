// https://github.com/cabbibo/glsl-tri-noise-3d

import three.js.examples.jsm.nodes.utils.LoopNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class TriNoise3D {

    static function tri(x:Float):Float {
        return x.fract() - 0.5;
    }

    static function tri3(p:Vector3):Vector3 {
        return new Vector3(tri(p.z + tri(p.y)), tri(p.z + tri(p.x)), tri(p.y + tri(p.x)));
    }

    static function triNoise3D(p:Vector3, spd:Float, time:Float):Float {
        var z:Float = 1.4;
        var rz:Float = 0.0;
        var bp:Vector3 = p;

        for (i in 0...3) {
            var dg:Vector3 = tri3(bp * 2.0);
            p += dg + time * 0.1 * spd;
            bp *= 1.8;
            z *= 1.5;
            p *= 1.2;

            var t:Float = tri(p.z + tri(p.x + tri(p.y)));
            rz += t / z;
            bp += 0.14;
        }

        return rz;
    }
}

// layouts

TriNoise3D.tri.setLayout({
    name: 'tri',
    type: 'float',
    inputs: [
        { name: 'x', type: 'float' }
    ]
});

TriNoise3D.tri3.setLayout({
    name: 'tri3',
    type: 'vec3',
    inputs: [
        { name: 'p', type: 'vec3' }
    ]
});

TriNoise3D.triNoise3D.setLayout({
    name: 'triNoise3D',
    type: 'float',
    inputs: [
        { name: 'p', type: 'vec3' },
        { name: 'spd', type: 'float' },
        { name: 'time', type: 'float' }
    ]
});

export TriNoise3D;