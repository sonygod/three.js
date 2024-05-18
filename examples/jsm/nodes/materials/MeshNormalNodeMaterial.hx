package three.js.examples.jsm.nodes.materials;

import NodeMaterial;
import three.core.PropertyNode;
import three.utils.PackingNode;
import three.accessors.MaterialNode;
import three.accessors.NormalNode;
import three.shadernode.ShaderNode;
import three.MeshNormalMaterial;

class MeshNormalNodeMaterial extends NodeMaterial {

    public var isMeshNormalNodeMaterial:Bool = true;

    public function new(?parameters:Any) {
        super();
        setDefaultValues(new MeshNormalMaterial());
        setValues(parameters);
    }

    public function setupDiffuseColor():Void {
        var opacityNode:Float = (this.opacityNode != null) ? float(this.opacityNode) : materialOpacity;
        diffuseColor.assign(vec4(directionToColor(transformedNormalView), opacityNode));
    }

    static public function main() {
        addNodeMaterial('MeshNormalNodeMaterial', MeshNormalNodeMaterial);
    }
}