import NodeMaterial from './NodeMaterial.hx';
import { diffuseColor, metalness, roughness, specularColor, specularF90 } from '../core/PropertyNode.hx';
import { mix } from '../math/MathNode.hx';
import { materialRoughness, materialMetalness } from '../accessors/MaterialNode.hx';
import getRoughness from '../functions/material/getRoughness.hx';
import PhysicalLightingModel from '../functions/PhysicalLightingModel.hx';
import { FloatNode, Vec3Node, Vec4Node } from '../shadernode/ShaderNode.hx';

class MeshStandardNodeMaterial extends NodeMaterial {
    public var isMeshStandardNodeMaterial: Bool;
    public var emissiveNode: Dynamic;
    public var metalnessNode: Dynamic;
    public var roughnessNode: Dynamic;

    public function new(parameters: Dynamic) {
        super();
        isMeshStandardNodeMaterial = true;
        emissiveNode = null;
        metalnessNode = null;
        roughnessNode = null;
        setDefaultValues(defaultValues);
        setValues(parameters);
    }

    public function setupLightingModel(): PhysicalLightingModel {
        return new PhysicalLightingModel();
    }

    public function setupSpecular() {
        var specularColorNode = mix(new Vec3Node(0.04), diffuseColor.rgb, metalness);
        specularColor.assign(specularColorNode);
        specularF90.assign(1.0);
    }

    public function setupVariants() {
        // METALNESS
        var metalnessNode = metalnessNode != null ? FloatNode(metalnessNode) : materialMetalness;
        metalness.assign(metalnessNode);

        // ROUGHNESS
        var roughnessNode = roughnessNode != null ? FloatNode(roughnessNode) : materialRoughness;
        roughnessNode = getRoughness({ roughness: roughnessNode });
        roughness.assign(roughnessNode);

        // SPECULAR COLOR
        setupSpecular();

        // DIFFUSE COLOR
        diffuseColor.assign(Vec4Node(diffuseColor.rgb.mul(metalnessNode.oneMinus()), diffuseColor.a));
    }

    public function copy(source: MeshStandardNodeMaterial): MeshStandardNodeMaterial {
        emissiveNode = source.emissiveNode;
        metalnessNode = source.metalnessNode;
        roughnessNode = source.roughnessNode;
        return super.copy(source);
    }
}

function defaultValues(): MeshStandardMaterial {
    return new MeshStandardMaterial();
}

class MeshStandardMaterial {
}

static function addNodeMaterial(name: String, material: MeshStandardNodeMaterial) {
    // Add NodeMaterial
}