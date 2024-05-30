package three.js.examples.jsm.nodes.materialx.lib;

import shaders.ShaderNode;
import math.OperatorNode;
import math.MathNode;

class MxHsv {
  static var mx_hsvtorgb:TslFn = (hsvImmutable:Vec3) -> {
    var hsv = hsvImmutable.toVar();
    var h = hsv.x.toFloat().toVar();
    var s = hsv.y.toFloat().toVar();
    var v = hsv.z.toFloat().toVar();

    if (s.lessThan(0.0001)) {
      return new Vec3(v, v, v);
    } else {
      h.assign(mul(6.0, h.sub(floor(h))));
      var hi:Int = trunc(h).toInt().toVar();
      var f = h.sub(hi.toFloat()).toVar();
      var p = v.mul(sub(1.0, s)).toFloat().toVar();
      var q = v.mul(sub(1.0, s.mul(f))).toFloat().toVar();
      var t = v.mul(sub(1.0, s.mul(sub(1.0, f)))).toFloat().toVar();

      switch (hi.toInt()) {
        case 0:
          return new Vec3(v, t, p);
        case 1:
          return new Vec3(q, v, p);
        case 2:
          return new Vec3(p, v, t);
        case 3:
          return new Vec3(p, q, v);
        case 4:
          return new Vec3(t, p, v);
        default:
          return new Vec3(v, p, q);
      }
    }
  }

  static var mx_rgbtohsv:TslFn = (cImmutable:Vec3) -> {
    var c = cImmutable.toVar();
    var r = c.x.toFloat().toVar();
    var g = c.y.toFloat().toVar();
    var b = c.z.toFloat().toVar();
    var minComp = min(r, min(g, b)).toFloat().toVar();
    var maxComp = max(r, max(g, b)).toFloat().toVar();
    var delta = maxComp.sub(minComp).toFloat().toVar();
    var h = new Float().toVar();
    var s = new Float().toVar();
    var v = maxComp.toFloat().toVar();

    if (maxComp.greaterThan(0.0)) {
      s.assign(delta.div(maxComp));
    } else {
      s.assign(0.0);
    }

    if (s.lessThanOrEqualTo(0.0)) {
      h.assign(0.0);
    } else {
      if (r.greaterThanOrEqualTo(maxComp)) {
        h.assign(g.sub(b).div(delta));
      } else if (g.greaterThanOrEqualTo(maxComp)) {
        h.assign(add(2.0, b.sub(r).div(delta)));
      } else {
        h.assign(add(4.0, r.sub(g).div(delta)));
      }
      h.mulAssign(1.0 / 6.0);
      if (h.lessThan(0.0)) {
        h.addAssign(1.0);
      }
    }

    return new Vec3(h, s, v);
  }

  static function setLayouts() {
    mx_hsvtorgb.setLayout({
      name: 'mx_hsvtorgb',
      type: 'vec3',
      inputs: [{
        name: 'hsv',
        type: 'vec3'
      }]
    });

    mx_rgbtohsv.setLayout({
      name: 'mx_rgbtohsv',
      type: 'vec3',
      inputs: [{
        name: 'c',
        type: 'vec3'
      }]
    });
  }
}