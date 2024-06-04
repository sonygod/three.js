import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.ComplexType;

// https://github.com/cabbibo/glsl-tri-noise-3d

class ShaderNode {
  public static function tslFn<T>(f:T):T {
    return f;
  }

  public static function float(value:Float):Expr {
    return Expr.withExpr(value);
  }

  public static function vec3(x:Expr, y:Expr, z:Expr):Expr {
    return Expr.call("vec3", [x, y, z]);
  }

  public static function toVar(e:Expr):Expr {
    return Expr.withExpr(e);
  }
}

class Loop {
  public static function loop(start:Expr, end:Expr, condition:String, f:Expr):Expr {
    return Expr.block([
      Expr.var("i", start),
      Expr.while(Expr.binop(condition, Expr.withExpr("i"), end), [
        f
      ]),
    ]);
  }
}

var tri = ShaderNode.tslFn((x:Expr) => {
  return Expr.binop("-", Expr.binop(".", x, "fract"), Expr.withExpr(0.5)).call("abs");
});

var tri3 = ShaderNode.tslFn((p:Expr) => {
  return ShaderNode.vec3(
    tri(Expr.binop("+", Expr.binop(".", p, "z"), tri(Expr.binop("*", Expr.binop(".", p, "y"), Expr.withExpr(1.0)))),
    tri(Expr.binop("+", Expr.binop(".", p, "z"), tri(Expr.binop("*", Expr.binop(".", p, "x"), Expr.withExpr(1.0)))),
    tri(Expr.binop("+", Expr.binop(".", p, "y"), tri(Expr.binop("*", Expr.binop(".", p, "x"), Expr.withExpr(1.0))))
  );
});

var triNoise3D = ShaderNode.tslFn((p_immutable:Expr, spd:Expr, time:Expr) => {
  var p = ShaderNode.vec3(Expr.binop(".", p_immutable, "x"), Expr.binop(".", p_immutable, "y"), Expr.binop(".", p_immutable, "z")).toVar();
  var z = ShaderNode.float(1.4).toVar();
  var rz = ShaderNode.float(0.0).toVar();
  var bp = ShaderNode.vec3(Expr.binop(".", p, "x"), Expr.binop(".", p, "y"), Expr.binop(".", p, "z")).toVar();

  Loop.loop(ShaderNode.float(0.0), ShaderNode.float(3.0), "<=", () => {
    var dg = ShaderNode.vec3(tri3(Expr.binop("*", bp, Expr.withExpr(2.0)))).toVar();
    p.assign(Expr.binop("+", p, Expr.binop("+", dg, Expr.binop("*", time, Expr.binop("*", ShaderNode.float(0.1), spd)))));
    bp.assign(Expr.binop("*", bp, Expr.withExpr(1.8)));
    z.assign(Expr.binop("*", z, Expr.withExpr(1.5)));
    p.assign(Expr.binop("*", p, Expr.withExpr(1.2)));

    var t = ShaderNode.float(tri(Expr.binop("+", Expr.binop("+", Expr.binop(".", p, "z"), tri(Expr.binop("+", Expr.binop(".", p, "x"), tri(Expr.binop(".", p, "y"))))), Expr.withExpr(0.0)))).toVar();
    rz.assign(Expr.binop("+", rz, Expr.binop("/", t, z)));
    bp.assign(Expr.binop("+", bp, Expr.withExpr(0.14)));
  });

  return rz;
});

class Layout {
  public static function setLayout(node:Expr, name:String, type:String, inputs:Array<{name:String, type:String}>) {
    return Context.get().call("setLayout", [node, Expr.withExpr(name), Expr.withExpr(type), Expr.withExpr(inputs)]);
  }
}

Layout.setLayout(tri, "tri", "float", [{ name: "x", type: "float" }]);
Layout.setLayout(tri3, "tri3", "vec3", [{ name: "p", type: "vec3" }]);
Layout.setLayout(triNoise3D, "triNoise3D", "float", [{ name: "p", type: "vec3" }, { name: "spd", type: "float" }, { name: "time", type: "float" }]);

class Exports {
  static function main():Void {
    Context.get().setContext({ kind: Context.KIND_EXPRESSION });
    Context.get().expr(Expr.block([
      Expr.withExpr(tri),
      Expr.withExpr(tri3),
      Expr.withExpr(triNoise3D)
    ]));
  }
}

class Main {
  static function main():Void {
    Exports.main();
  }
}