import DFGApprox;
import ShaderNode.tslFn;

class EnvironmentBRDF {
    public static function new(inputs:Dynamic) {
        var dotNV = inputs.dotNV;
        var specularColor = inputs.specularColor;
        var specularF90 = inputs.specularF90;
        var roughness = inputs.roughness;

        var fab = DFGApprox.new({dotNV: dotNV, roughness: roughness});
        return specularColor.mul(fab.x).add(specularF90.mul(fab.y));
    }
}

export default EnvironmentBRDF;