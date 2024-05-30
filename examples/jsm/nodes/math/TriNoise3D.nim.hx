// https://github.com/cabbibo/glsl-tri-noise-3d

import three.shaders.LoopNode;
import three.shaders.ShaderNode;

class TriNoise3D {
    static function main() {
        var tri = tslFn(function(x) {
            return x.fract().sub(0.5).abs();
        });

        var tri3 = tslFn(function(p) {
            return vec3(tri(p.z.add(tri(p.y.mul(1.)))), tri(p.z.add(tri(p.x.mul(1.)))), tri(p.y.add(tri(p.x.mul(1.)))));
        });

        var triNoise3D = tslFn(function(p_immutable, spd, time) {
            var p = vec3(p_immutable).toVar();
            var z = 1.4.toVar();
            var rz = 0.0.toVar();
            var bp = vec3(p).toVar();

            LoopNode.loop({ start: 0.0, end: 3.0, type: 'float', condition: '<=' }, function() {
                var dg = vec3(tri3(bp.mul(2.0))).toVar();
                p.addAssign(dg.add(time.mul(0.1.mul(spd))));
                bp.mulAssign(1.8);
                z.mulAssign(1.5);
                p.mulAssign(1.2);

                var t = tri(p.z.add(tri(p.x.add(tri(p.y))))).toVar();
                rz.addAssign(t.div(z));
                bp.addAssign(0.14);
            });

            return rz;
        });

        // layouts
        tri.setLayout({
            name: 'tri',
            type: 'float',
            inputs: [
                { name: 'x', type: 'float' }
            ]
        });

        tri3.setLayout({
            name: 'tri3',
            type: 'vec3',
            inputs: [
                { name: 'p', type: 'vec3' }
            ]
        });

        triNoise3D.setLayout({
            name: 'triNoise3D',
            type: 'float',
            inputs: [
                { name: 'p', type: 'vec3' },
                { name: 'spd', type: 'float' },
                { name: 'time', type: 'float' }
            ]
        });

        export { tri, tri3, triNoise3D };
    }
}