import DFGApprox from './DFGApprox.js';
import { tslFn } from '../../shadernode/ShaderNode.js';

class EnvironmentBRDF {
    public static tslFn(inputs: Dynamic): Dynamic {
        const dotNV = inputs.dotNV;
        const specularColor = inputs.specularColor;
        const specularF90 = inputs.specularF90;
        const roughness = inputs.roughness;

        const fab = DFGApprox({dotNV, roughness});
        return specularColor.mul(fab.x).add(specularF90.mul(fab.y));
    }
}

export default EnvironmentBRDF;