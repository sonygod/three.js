import three.js.examples.jsm.nodes.materials.NodeMaterial;
import three.js.examples.jsm.nodes.core.PropertyNode;
import three.js.examples.jsm.nodes.math.MathNode;
import three.js.examples.jsm.nodes.accessors.MaterialNode;
import three.js.examples.jsm.nodes.functions.material.getRoughness;
import three.js.examples.jsm.nodes.functions.PhysicalLightingModel;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

import three.MeshStandardMaterial;

class MeshStandardNodeMaterial extends NodeMaterial {

    public function new(parameters:Dynamic) {
        super();

        this.isMeshStandardNodeMaterial = true;

        this.emissiveNode = null;

        this.metalnessNode = null;
        this.roughnessNode = null;

        this.setDefaultValues(new MeshStandardMaterial());

        this.setValues(parameters);
    }

    public function setupLightingModel(/*builder*/) {
        return new PhysicalLightingModel();
    }

    public function setupSpecular() {
        var specularColorNode = MathNode.mix(new ShaderNode.vec3(0.04), PropertyNode.diffuseColor.rgb, PropertyNode.metalness);

        PropertyNode.specularColor.assign(specularColorNode);
        PropertyNode.specularF90.assign(1.0);
    }

    public function setupVariants() {
        // METALNESS
        var metalnessNode = this.metalnessNode ? new ShaderNode.float(this.metalnessNode) : MaterialNode.materialMetalness;

        PropertyNode.metalness.assign(metalnessNode);

        // ROUGHNESS
        var roughnessNode = this.roughnessNode ? new ShaderNode.float(this.roughnessNode) : MaterialNode.materialRoughness;
        roughnessNode = getRoughness({roughness: roughnessNode});

        PropertyNode.roughness.assign(roughnessNode);

        // SPECULAR COLOR
        this.setupSpecular();

        // DIFFUSE COLOR
        PropertyNode.diffuseColor.assign(new ShaderNode.vec4(PropertyNode.diffuseColor.rgb.mul(metalnessNode.oneMinus()), PropertyNode.diffuseColor.a));
    }

    public function copy(source:MeshStandardNodeMaterial) {
        this.emissiveNode = source.emissiveNode;

        this.metalnessNode = source.metalnessNode;
        this.roughnessNode = source.roughnessNode;

        return super.copy(source);
    }
}

NodeMaterial.addNodeMaterial('MeshStandardNodeMaterial', MeshStandardNodeMaterial);