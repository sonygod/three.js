package three.js.examples.jsm.nodes.materials;

import three.js.NodeMaterial;
import three.js.core.PropertyNode;
import three.js.utils.PackingNode;
import three.js.accessors.MaterialNode;
import three.js.accessors.NormalNode;
import three.js.shadernode.ShaderNode;
import three.js.THREE.MeshNormalMaterial;

class MeshNormalNodeMaterial extends NodeMaterial {
    public var isMeshNormalNodeMaterial:Bool = true;

    public function new(parameters:Dynamic = null) {
        super();
        setDefaultValues(new MeshNormalMaterial());
        setValues(parameters);
    }

    public function setupDiffuseColor():Void {
        var opacityNode:ShaderNode = (this.opacityNode != null) ? float(this.opacityNode) : MaterialNode.materialOpacity;
        PropertyNode.diffuseColor.assign(vec4(directionToColor(NormalNode.transformedNormalView), opacityNode));
    }
}

registerNodeMaterial('MeshNormalNodeMaterial', MeshNormalNodeMaterial);