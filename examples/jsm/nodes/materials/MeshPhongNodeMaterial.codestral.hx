import js.Browser.document;
import js.Boot;
import three.examples.jsm.nodes.materials.NodeMaterial;
import three.examples.jsm.core.PropertyNode;
import three.examples.jsm.accessors.MaterialNode;
import three.examples.jsm.shadernode.ShaderNode;
import three.examples.jsm.functions.PhongLightingModel;
import three.MeshPhongMaterial;

class MeshPhongNodeMaterial extends NodeMaterial {

    public var isMeshPhongNodeMaterial:Bool = true;
    public var lights:Bool = true;
    public var shininessNode:Dynamic = null;
    public var specularNode:Dynamic = null;

    public function new(parameters:Dynamic) {
        super();

        var defaultValues = new MeshPhongMaterial();
        this.setDefaultValues(defaultValues);
        this.setValues(parameters);
    }

    public function setupLightingModel():PhongLightingModel {
        return new PhongLightingModel();
    }

    public function setupVariants() {
        // SHININESS
        var shininessNode:Dynamic = this.shininessNode != null ? ShaderNode.float(this.shininessNode) : MaterialNode.materialShininess;
        shininessNode = shininessNode.max(1e-4); // to prevent pow( 0.0, 0.0 )
        PropertyNode.shininess.assign(shininessNode);

        // SPECULAR COLOR
        var specularNode:Dynamic = this.specularNode != null ? this.specularNode : MaterialNode.materialSpecular;
        PropertyNode.specularColor.assign(specularNode);
    }

    public function copy(source:MeshPhongNodeMaterial):MeshPhongNodeMaterial {
        this.shininessNode = source.shininessNode;
        this.specularNode = source.specularNode;
        return super.copy(source);
    }
}

js.Boot.getClass(js.Browser.document).<MeshPhongNodeMaterial>().addNodeMaterial("MeshPhongNodeMaterial", MeshPhongNodeMaterial);