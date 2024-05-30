package three.js.examples.javascript.nodes.materials;

import NodeMaterial;
import ShaderNode.FloatNode;
import MaterialNode.MaterialNode;
import PhongLightingModel;

class MeshPhongNodeMaterial extends NodeMaterial {
    public var isMeshPhongNodeMaterial:Bool = true;
    public var lights:Bool = true;
    public var shininessNode:FloatNode;
    public var specularNode:MaterialNode;

    public function new(parameters:Dynamic) {
        super();
        setDefaultValues(new MeshPhongMaterial());
        setValues(parameters);
    }

    public function setupLightingModel(builder:Dynamic):PhongLightingModel {
        return new PhongLightingModel();
    }

    public function setupVariants():Void {
        // SHININESS
        var shininessNode:FloatNode = (this.shininessNode != null) ? FloatNode.from(this.shininessNode) : MaterialNode.materialShininess;
        shininessNode = shininessNode.max(1e-4); // to prevent pow( 0.0, 0.0 )
        MaterialNode.shininess.assign(shininessNode);

        // SPECULAR COLOR
        var specularNode:MaterialNode = (this.specularNode != null) ? this.specularNode : MaterialNode.materialSpecular;
        MaterialNode.specularColor.assign(specularNode);
    }

    public function copy(source:MeshPhongNodeMaterial):MeshPhongNodeMaterial {
        this.shininessNode = source.shininessNode;
        this.specularNode = source.specularNode;
        return super.copy(source);
    }
}

NodeMaterial.addNodeMaterial("MeshPhongNodeMaterial", MeshPhongNodeMaterial);