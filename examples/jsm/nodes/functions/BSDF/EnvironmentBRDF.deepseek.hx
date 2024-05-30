import DFGApprox from './DFGApprox';
import { tslFn } from '../../shadernode/ShaderNode';

class EnvironmentBRDF {
    static function build(inputs:Dynamic):Dynamic {
        var dotNV = inputs.dotNV;
        var specularColor = inputs.specularColor;
        var specularF90 = inputs.specularF90;
        var roughness = inputs.roughness;

        var fab = DFGApprox.build({ dotNV: dotNV, roughness: roughness });
        return specularColor.mul(fab.x).add(specularF90.mul(fab.y));
    }
}

var EnvironmentBRDF = tslFn(EnvironmentBRDF.build);

export default EnvironmentBRDF;