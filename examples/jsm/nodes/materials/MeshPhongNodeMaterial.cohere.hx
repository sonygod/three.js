import NodeMaterial from "./NodeMaterial.hx";
import { shininess, specularColor } from "../core/PropertyNode.hx";
import { materialShininess, materialSpecular } from "../accessors/MaterialNode.hx";
import { float } from "../shadernode/ShaderNode.hx";
import PhongLightingModel from "../functions/PhongLightingModel.hx";

class MeshPhongNodeMaterial extends NodeMaterial {
    public var isMeshPhongNodeMaterial: Bool;
    public var lights: Bool;
    public var shininessNode: Float;
    public var specularNode: Float;

    public function new(parameters: Dynamic = null) {
        super();
        isMeshPhongNodeMaterial = true;
        lights = true;
        setDefaultValues(defaultValues);
        setValues(parameters);
    }

    public function setupLightingModel(): PhongLightingModel {
        return new PhongLightingModel();
    }

    public function setupVariants() {
        // SHININESS
        var shininessNode = if (shininessNode != null) float(shininessNode) else materialShininess;
        shininessNode = max(shininessNode, 1e-4); // to prevent pow(0.0, 0.0)
        shininess.assign(shininessNode);

        // SPECULAR COLOR
        var specularNode = if (specularNode != null) specularNode else materialSpecular;
        specularColor.assign(specularNode);
    }

    public function copy(source: MeshPhongNodeMaterial): MeshPhongNodeMaterial {
        shininessNode = source.shininessNode;
        specularNode = source.specularNode;
        return super.copy(source);
    }
}

var defaultValues = new MeshPhongMaterial();

static function max(a: Float, b: Float): Float {
    if (a > b) {
        return a;
    } else {
        return b;
    }
}

class MeshPhongMaterial {
}

class MaterialNode {
}

class ShaderNode {
}

class PropertyNode {
}

class Function {
}

class Dynamic {
}