package three.js.examples.jsm.nodes.materials;

import three.js.nodes.NodeMaterial;
import three.js.core.PropertyNode;
import three.js.math.MathNode;
import three.js.accessors.MaterialNode;
import three.js.functions.material.getRoughness;
import three.js.functions.PhysicalLightingModel;
import three.js.shadernode.ShaderNode;

class MeshStandardNodeMaterial extends NodeMaterial {

    public var isMeshStandardNodeMaterial:Bool = true;

    public var emissiveNode:Null<Any> = null;

    public var metalnessNode:Null<Any> = null;
    public var roughnessNode:Null:Any> = null;

    public function new(parameters:Any = null) {
        super();
        this.setDefaultValues(new MeshStandardMaterial());
        this.setValues(parameters);
    }

    public function setupLightingModel(/*builder*/) {
        return new PhysicalLightingModel();
    }

    public function setupSpecular() {
        var specularColorNode = MathNode.mix(vec3.create(0.04), diffuseColor.rgb, metalness);
        specularColor.assign(specularColorNode);
        specularF90.assign(1.0);
    }

    public function setupVariants() {
        // METALNESS
        var metalnessNode = (this.metalnessNode != null) ? float(this.metalnessNode) : materialMetalness;
        metalness.assign(metalnessNode);

        // ROUGHNESS
        var roughnessNode = (this.roughnessNode != null) ? float(this.roughnessNode) : materialRoughness;
        roughnessNode = getRoughness({ roughness: roughnessNode });
        roughness.assign(roughnessNode);

        // SPECULAR COLOR
        this.setupSpecular();

        // DIFFUSE COLOR
        diffuseColor.assign(vec4.create(diffuseColor.rgb.mul(metalness.oneMinus()), diffuseColor.a));
    }

    public override function copy(source:MeshStandardNodeMaterial) {
        this.emissiveNode = source.emissiveNode;

        this.metalnessNode = source.metalnessNode;
        this.roughnessNode = source.roughnessNode;

        return super.copy(source);
    }
}

addNodeMaterial('MeshStandardNodeMaterial', MeshStandardNodeMaterial);