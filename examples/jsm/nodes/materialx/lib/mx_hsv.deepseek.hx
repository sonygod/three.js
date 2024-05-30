// Three.js Transpiler
// https://github.com/AcademySoftwareFoundation/MaterialX/blob/main/libraries/stdlib/genglsl/lib/mx_hsv.glsl

import three.js.examples.jsm.nodes.materialx.lib.ShaderNode;
import three.js.examples.jsm.nodes.materialx.lib.OperatorNode;
import three.js.examples.jsm.nodes.materialx.lib.MathNode;

class MxHsvToRgb extends ShaderNode {

    public function new(hsv_immutable:Vec3) {
        super();

        var hsv = new Vec3(hsv_immutable);
        var h = new Float(hsv.x);
        var s = new Float(hsv.y);
        var v = new Float(hsv.z);

        if (s.lessThan(0.0001)) {
            return new Vec3(v, v, v);
        } else {
            h = h.mul(6.0).sub(Math.floor(h));
            var hi = new Int(Math.trunc(h));
            var f = new Float(h.sub(new Float(hi)));
            var p = new Float(v.mul(1.0 - s));
            var q = new Float(v.mul(1.0 - s.mul(f)));
            var t = new Float(v.mul(1.0 - s.mul(1.0 - f)));

            if (hi.equal(new Int(0))) {
                return new Vec3(v, t, p);
            } else if (hi.equal(new Int(1))) {
                return new Vec3(q, v, p);
            } else if (hi.equal(new Int(2))) {
                return new Vec3(p, v, t);
            } else if (hi.equal(new Int(3))) {
                return new Vec3(p, q, v);
            } else if (hi.equal(new Int(4))) {
                return new Vec3(t, p, v);
            }

            return new Vec3(v, p, q);
        }
    }
}

class MxRgbToHsv extends ShaderNode {

    public function new(c_immutable:Vec3) {
        super();

        var c = new Vec3(c_immutable);
        var r = new Float(c.x);
        var g = new Float(c.y);
        var b = new Float(c.z);
        var mincomp = new Float(Math.min(r, Math.min(g, b)));
        var maxcomp = new Float(Math.max(r, Math.max(g, b)));
        var delta = new Float(maxcomp.sub(mincomp));
        var h = new Float();
        var s = new Float();
        var v = new Float();
        v = maxcomp;

        if (maxcomp.greaterThan(0.0)) {
            s = delta.div(maxcomp);
        } else {
            s = 0.0;
        }

        if (s.lessThanEqual(0.0)) {
            h = 0.0;
        } else {
            if (r.greaterThanEqual(maxcomp)) {
                h = g.sub(b).div(delta);
            } else if (g.greaterThanEqual(maxcomp)) {
                h = new Float(2.0).add(b.sub(r).div(delta));
            } else {
                h = new Float(4.0).add(r.sub(g).div(delta));
            }

            h = h.mul(1.0 / 6.0);

            if (h.lessThan(0.0)) {
                h = h.add(1.0);
            }
        }

        return new Vec3(h, s, v);
    }
}

// layouts

MxHsvToRgb.setLayout({
    name: 'mx_hsvtorgb',
    type: 'vec3',
    inputs: [
        { name: 'hsv', type: 'vec3' }
    ]
});

MxRgbToHsv.setLayout({
    name: 'mx_rgbtohsv',
    type: 'vec3',
    inputs: [
        { name: 'c', type: 'vec3' }
    ]
});

// export

typedef MxHsvToRgb = MxHsvToRgb;
typedef MxRgbToHsv = MxRgbToHsv;