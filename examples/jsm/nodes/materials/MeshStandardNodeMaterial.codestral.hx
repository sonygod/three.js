import three.NodeMaterial;
import three.nodes.core.PropertyNode;
import three.nodes.math.MathNode;
import three.nodes.accessors.MaterialNode;
import three.nodes.functions.material.GetRoughness;
import three.nodes.functions.PhysicalLightingModel;
import three.nodes.shadernode.ShaderNode;
import three.materials.MeshStandardMaterial;

class MeshStandardNodeMaterial extends NodeMaterial {
    public var emissiveNode:ShaderNode = null;
    public var metalnessNode:ShaderNode = null;
    public var roughnessNode:ShaderNode = null;

    public function new(parameters:Dynamic) {
        super();
        this.isMeshStandardNodeMaterial = true;

        var defaultValues = new MeshStandardMaterial();
        this.setDefaultValues(defaultValues);
        this.setValues(parameters);
    }

    public function setupLightingModel():PhysicalLightingModel {
        return new PhysicalLightingModel();
    }

    public function setupSpecular() {
        var specularColorNode = MathNode.mix(ShaderNode.vec3(0.04), PropertyNode.diffuseColor.rgb, PropertyNode.metalness);

        PropertyNode.specularColor.assign(specularColorNode);
        PropertyNode.specularF90.assign(1.0);
    }

    public function setupVariants() {
        var metalnessNode = this.metalnessNode != null ? ShaderNode.float(this.metalnessNode) : MaterialNode.materialMetalness;
        PropertyNode.metalness.assign(metalnessNode);

        var roughnessNode = this.roughnessNode != null ? ShaderNode.float(this.roughnessNode) : MaterialNode.materialRoughness;
        roughnessNode = new GetRoughness({ roughness: roughnessNode });
        PropertyNode.roughness.assign(roughnessNode);

        this.setupSpecular();

        PropertyNode.diffuseColor.assign(ShaderNode.vec4(PropertyNode.diffuseColor.rgb.mul(metalnessNode.oneMinus()), PropertyNode.diffuseColor.a));
    }

    public function copy(source:MeshStandardNodeMaterial):MeshStandardNodeMaterial {
        this.emissiveNode = source.emissiveNode;
        this.metalnessNode = source.metalnessNode;
        this.roughnessNode = source.roughnessNode;

        return super.copy(source);
    }
}

NodeMaterial.addNodeMaterial('MeshStandardNodeMaterial', MeshStandardNodeMaterial);