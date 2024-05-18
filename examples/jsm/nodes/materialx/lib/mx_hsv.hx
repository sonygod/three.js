package three.js.examples.jsm.nodes.materialx.lib;

import haxe.macro.Expr;
import haxe.macro.Context;
using haxe.macro.Tools;

class MXHSV {
  static var mx_hsvtorgb = new TSLFn([hsv_immutable], () -> {
    var hsv = vec3(hsv_immutable);
    var h = hsv.x;
    var s = hsv.y;
    var v = hsv.z;

    if (s < 0.0001) {
      return vec3(v, v, v);
    } else {
      h = 6.0 * (h - Std.int(h));
      var hi = Std.int(h);
      var f = h - hi;
      var p = v * (1.0 - s);
      var q = v * (1.0 - s * f);
      var t = v * (1.0 - s * (1.0 - f));

      switch (hi) {
        case 0:
          return vec3(v, t, p);
        case 1:
          return vec3(q, v, p);
        case 2:
          return vec3(p, v, t);
        case 3:
          return vec3(p, q, v);
        case 4:
          return vec3(t, p, v);
        default:
          return vec3(v, p, q);
      }
    }
  });

  static var mx_rgbtohsv = new TSLFn([c_immutable], () -> {
    var c = vec3(c_immutable);
    var r = c.x;
    var g = c.y;
    var b = c.z;
    var mincomp = Math.min(r, Math.min(g, b));
    var maxcomp = Math.max(r, Math.max(g, b));
    var delta = maxcomp - mincomp;
    var v = maxcomp;
    var s = delta / maxcomp;
    var h:Float;

    if (maxcomp > 0.0) {
      s = delta / maxcomp;
    } else {
      s = 0.0;
    }

    if (s <= 0.0) {
      h = 0.0;
    } else {
      if (r >= maxcomp) {
        h = (g - b) / delta;
      } else if (g >= maxcomp) {
        h = (b - r) / delta + 2.0;
      } else {
        h = (r - g) / delta + 4.0;
      }
      h /= 6.0;
      if (h < 0.0) {
        h += 1.0;
      }
    }

    return vec3(h, s, v);
  });

  static function main() {
    mx_hsvtorgb.setLayout({
      name: 'mx_hsvtorgb',
      type: 'vec3',
      inputs: [
        { name: 'hsv', type: 'vec3' }
      ]
    });

    mx_rgbtohsv.setLayout({
      name: 'mx_rgbtohsv',
      type: 'vec3',
      inputs: [
        { name: 'c', type: 'vec3' }
      ]
    });
  }
}