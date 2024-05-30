import NodeMaterial from './NodeMaterial.hx';
import { diffuseColor } from '../core/PropertyNode.hx';
import { directionToColor } from '../utils/PackingNode.hx';
import { materialOpacity } from '../accessors/MaterialNode.hx';
import { transformedNormalView } from '../accessors/NormalNode.hx';
import { FloatNode, Vec4Node } from '../shadernode/ShaderNode.hx';

class MeshNormalNodeMaterial extends NodeMaterial {
    public isMeshNormalNodeMaterial: Bool = true;

    public function new(parameters: Dynamic = null) {
        super();
        this.setDefaultValues(new MeshNormalMaterial());
        this.setValues(parameters);
    }

    public function setupDiffuseColor() {
        var opacityNode = this.opacityNode != null ? FloatNode.fromFloat(this.opacityNode) : materialOpacity;
        diffuseColor.assign(Vec4Node.fromVec4(directionToColor(transformedNormalView), opacityNode));
    }
}

class MeshNormalMaterial {
}