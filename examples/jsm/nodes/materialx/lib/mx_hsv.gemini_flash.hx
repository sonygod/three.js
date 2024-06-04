import three.shadernode.ShaderNode;
import three.shadernode.math.MathNode;
import three.shadernode.math.OperatorNode;

class MX {

  static function mx_hsvtorgb(hsv: ShaderNode.Vec3): ShaderNode.Vec3 {
    var hsv = hsv.toVar();
    var h = hsv.x.toVar().cast<ShaderNode.Float>();
    var s = hsv.y.toVar().cast<ShaderNode.Float>();
    var v = hsv.z.toVar().cast<ShaderNode.Float>();

    return new ShaderNode.If(s.lessThan(0.0001)).then(() -> {
      return new ShaderNode.Vec3(v, v, v);
    }).else(() -> {
      h.assign(h.sub(ShaderNode.MathNode.floor(h)).mul(6.0));
      var hi = ShaderNode.MathNode.trunc(h).toVar().cast<ShaderNode.Int>();
      var f = h.sub(hi.cast<ShaderNode.Float>()).toVar().cast<ShaderNode.Float>();
      var p = v.mul(1.0 - s).toVar().cast<ShaderNode.Float>();
      var q = v.mul(1.0 - s.mul(f)).toVar().cast<ShaderNode.Float>();
      var t = v.mul(1.0 - s.mul(1.0 - f)).toVar().cast<ShaderNode.Float>();

      return new ShaderNode.If(hi.equal(0)).then(() -> {
        return new ShaderNode.Vec3(v, t, p);
      }).elseif(hi.equal(1)).then(() -> {
        return new ShaderNode.Vec3(q, v, p);
      }).elseif(hi.equal(2)).then(() -> {
        return new ShaderNode.Vec3(p, v, t);
      }).elseif(hi.equal(3)).then(() -> {
        return new ShaderNode.Vec3(p, q, v);
      }).elseif(hi.equal(4)).then(() -> {
        return new ShaderNode.Vec3(t, p, v);
      }).else(() -> {
        return new ShaderNode.Vec3(v, p, q);
      });
    });
  }

  static function mx_rgbtohsv(c: ShaderNode.Vec3): ShaderNode.Vec3 {
    var c = c.toVar();
    var r = c.x.toVar().cast<ShaderNode.Float>();
    var g = c.y.toVar().cast<ShaderNode.Float>();
    var b = c.z.toVar().cast<ShaderNode.Float>();
    var mincomp = ShaderNode.MathNode.min(r, ShaderNode.MathNode.min(g, b)).toVar().cast<ShaderNode.Float>();
    var maxcomp = ShaderNode.MathNode.max(r, ShaderNode.MathNode.max(g, b)).toVar().cast<ShaderNode.Float>();
    var delta = maxcomp.sub(mincomp).toVar().cast<ShaderNode.Float>();
    var h = new ShaderNode.Float().toVar();
    var s = new ShaderNode.Float().toVar();
    var v = new ShaderNode.Float().toVar();
    v.assign(maxcomp);

    return new ShaderNode.If(maxcomp.greaterThan(0.0)).then(() -> {
      s.assign(delta.div(maxcomp));
    }).else(() -> {
      s.assign(0.0);
    }).then(() -> {
      return new ShaderNode.If(s.lessThanEqual(0.0)).then(() -> {
        h.assign(0.0);
      }).else(() -> {
        return new ShaderNode.If(r.greaterThanEqual(maxcomp)).then(() -> {
          h.assign(g.sub(b).div(delta));
        }).elseif(g.greaterThanEqual(maxcomp)).then(() -> {
          h.assign(2.0 + b.sub(r).div(delta));
        }).else(() -> {
          h.assign(4.0 + r.sub(g).div(delta));
        }).then(() -> {
          h.mulAssign(1.0 / 6.0);
          return new ShaderNode.If(h.lessThan(0.0)).then(() -> {
            h.addAssign(1.0);
          }).else(() -> {
            return new ShaderNode.Vec3(h, s, v);
          });
        });
      });
    });
  }
}