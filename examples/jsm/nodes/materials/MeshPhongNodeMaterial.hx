package three.js.examples.jm.nodes.materials;

import three.js.nodes.NodeMaterial;
import three.js.core.PropertyNode.Shininess;
import three.js.core.PropertyNode.SpecularColor;
import three.js.accessors.MaterialNode.MaterialShininess;
import three.js.accessors.MaterialNode.MaterialSpecular;
import three.js.shadernode.ShaderNode.Float;
import three.js.functions.PhongLightingModel;

import three.MeshPhongMaterial;

class MeshPhongNodeMaterial extends NodeMaterial {
    public var isMeshPhongNodeMaterial:Bool = true;
    public var lights:Bool = true;
    public var shininessNode:Null<Float> = null;
    public var specularNode:Null<Float> = null;

    public function new(parameters:Dynamic = null) {
        super();
        setDefaultValues(new MeshPhongMaterial());
        setValues(parameters);
    }

    override public function setupLightingModel(builder:Dynamic):Void {
        return new PhongLightingModel();
    }

    override public function setupVariants():Void {
        // SHININESS
        var shininessNode:Float = (this.shininessNode != null) ? Float(this.shininessNode) : MaterialShininess;
        shininessNode = Math.max(shininessNode, 1e-4); // to prevent pow( 0.0, 0.0 )
        Shininess.assign(shininessNode);

        // SPECULAR COLOR
        var specularNode:Float = (this.specularNode != null) ? this.specularNode : MaterialSpecular;
        SpecularColor.assign(specularNode);
    }

    override public function copy(source:MeshPhongNodeMaterial):MeshPhongNodeMaterial {
        this.shininessNode = source.shininessNode;
        this.specularNode = source.specularNode;
        return cast super.copy(source);
    }
}

NodeMaterial.addNodeMaterial('MeshPhongNodeMaterial', MeshPhongNodeMaterial);