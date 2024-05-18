package three.js.examples.jsm.nodes.functions.BSDF;

import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class EnvironmentBRDF {
  public static function tslFn(inputs:Dynamic):Dynamic {
    var dotNV:Float = inputs.dotNV;
    var specularColor:Dynamic = inputs.specularColor;
    var specularF90:Dynamic = inputs.specularF90;
    var roughness:Float = inputs.roughness;

    var fab = DFGApprox.getInstance({ dotNV: dotNV, roughness: roughness });
    return specularColor.mul(fab.x).add(specularF90.mul(fab.y));
  }
}

@:keep
@:expose("EnvironmentBRDF")
class EnvironmentBRDF_Main {
  public static function main() {
    var EnvironmentBRDF = tslFn;
    js.Lib.export("default", EnvironmentBRDF);
  }
}