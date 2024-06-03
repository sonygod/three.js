import NodeMaterial;
import NodeMaterialUtils.addNodeMaterial;
import PropertyNode.diffuseColor;
import PackingNode.directionToColor;
import MaterialNode.materialOpacity;
import NormalNode.transformedNormalView;
import ShaderNode.float;
import ShaderNode.vec4;
import three.MeshNormalMaterial;

class MeshNormalNodeMaterial extends NodeMaterial {

    public var isMeshNormalNodeMaterial:Bool = true;
    private var defaultValues:MeshNormalMaterial = new MeshNormalMaterial();

    public function new(parameters:Dynamic) {
        super();
        this.setDefaultValues(defaultValues);
        this.setValues(parameters);
    }

    public function setupDiffuseColor():Void {
        var opacityNode:Dynamic = this.opacityNode != null ? float(this.opacityNode) : materialOpacity;
        diffuseColor.assign(vec4(directionToColor(transformedNormalView), opacityNode));
    }
}

addNodeMaterial('MeshNormalNodeMaterial', MeshNormalNodeMaterial);