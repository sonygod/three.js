import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ComplexType;
import haxe.macro.ComplexType.TInst;

class AlphaHash {

  static function getAlphaHashThreshold( pos:hl.Vec3) : Float {

    // Find the discretized derivatives of our coordinates
    var maxDeriv = Math.max(
      hl.Vec3.length(hl.Vec3.dFdx(pos)),
      hl.Vec3.length(hl.Vec3.dFdy(pos))
    );
    var pixScale = 1.0 / (ALPHA_HASH_SCALE * maxDeriv);

    // Find two nearest log-discretized noise scales
    var pixScales = hl.Vec2.new(
      Math.pow(2, Math.floor(Math.log2(pixScale))),
      Math.pow(2, Math.ceil(Math.log2(pixScale)))
    );

    // Compute alpha thresholds at our two noise scales
    var alpha = hl.Vec2.new(
      hash3D(hl.Vec3.floor(hl.Vec3.mul(pixScales.x, pos))),
      hash3D(hl.Vec3.floor(hl.Vec3.mul(pixScales.y, pos)))
    );

    // Factor to interpolate lerp with
    var lerpFactor = Math.fract(Math.log2(pixScale));

    // Interpolate alpha threshold from noise at two scales
    var x = (1.0 - lerpFactor) * alpha.x + lerpFactor * alpha.y;

    // Pass into CDF to compute uniformly distrib threshold
    var a = Math.min(lerpFactor, 1.0 - lerpFactor);
    var cases = hl.Vec3.new(
      x * x / (2.0 * a * (1.0 - a)),
      (x - 0.5 * a) / (1.0 - a),
      1.0 - ((1.0 - x) * (1.0 - x) / (2.0 * a * (1.0 - a)))
    );

    // Find our final, uniformly distributed alpha threshold (ατ)
    var threshold = (x < (1.0 - a))
      ? ((x < a) ? cases.x : cases.y)
      : cases.z;

    // Avoids ατ == 0. Could also do ατ =1-ατ
    return Math.clamp(threshold, 1.0e-6, 1.0);
  }

  static function hash2D(value:hl.Vec2) : Float {
    return Math.fract(1.0e4 * Math.sin(17.0 * value.x + 0.1 * value.y) * (0.1 + Math.abs(Math.sin(13.0 * value.y + value.x))));
  }

  static function hash3D(value:hl.Vec3) : Float {
    return hash2D(hl.Vec2.new(hash2D(hl.Vec2.new(value.x, value.y)), value.z));
  }

  static inline var ALPHA_HASH_SCALE = 0.05;
}

class AlphaHashMacro {
  static function get(c:Context):Expr {
    var t = Type.get(c, "hl.Vec3");
    if (t == null) throw "Type 'hl.Vec3' not found";
    var tInst = ComplexType.TInst(t, []);
    var expr = Expr.call(Expr.field(Expr.ident("AlphaHash"), "getAlphaHashThreshold"), [Expr.ident("position")]);
    return Expr.block([Expr.if_(Expr.ident("USE_ALPHAHASH"), expr, Expr.literal(0.0))]);
  }
}

#if USE_ALPHAHASH

/**
 * See: https://casual-effects.com/research/Wyman2017Hashed/index.html
 */
@:macro(AlphaHashMacro.get)
function getAlphaHashThreshold(position:hl.Vec3):Float {
  return 0.0;
}

#end