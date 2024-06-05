import shadernode.ShaderNode;

class D_GGX_Anisotropic extends ShaderNode.TslFn {
  static var RECIPROCAL_PI:ShaderNode.Float = ShaderNode.Float.fromFloat(1 / Math.PI);

  public function new() {
    super(function(args) {
      var alphaT = args.alphaT;
      var alphaB = args.alphaB;
      var dotNH = args.dotNH;
      var dotTH = args.dotTH;
      var dotBH = args.dotBH;

      var a2 = alphaT.mul(alphaB);
      var v = new ShaderNode.Vec3(alphaB.mul(dotTH), alphaT.mul(dotBH), a2.mul(dotNH));
      var v2 = v.dot(v);
      var w2 = a2.div(v2).pow(2);

      return RECIPROCAL_PI.mul(a2.mul(w2));
    });
    this.setLayout({
      name: "D_GGX_Anisotropic",
      type: "float",
      inputs: [
        { name: "alphaT", type: "float", qualifier: "in" },
        { name: "alphaB", type: "float", qualifier: "in" },
        { name: "dotNH", type: "float", qualifier: "in" },
        { name: "dotTH", type: "float", qualifier: "in" },
        { name: "dotBH", type: "float", qualifier: "in" }
      ]
    });
  }
}

class Main {
  static function main() {
    var dggx = new D_GGX_Anisotropic();
    // ... use dggx here
  }
}