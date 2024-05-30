import three.js.examples.jsm.nodes.materials.NodeMaterial;
import three.js.examples.jsm.nodes.functions.PhongLightingModel;
import three.js.MeshLambertMaterial;

class MeshLambertNodeMaterial extends NodeMaterial {

    public function new(parameters:Dynamic) {

        super();

        this.isMeshLambertNodeMaterial = true;

        this.lights = true;

        this.setDefaultValues(new MeshLambertMaterial());

        this.setValues(parameters);

    }

    public function setupLightingModel(/*builder*/) {

        return new PhongLightingModel(false); // ( specular ) -> force lambert

    }

}

NodeMaterial.addNodeMaterial('MeshLambertNodeMaterial', MeshLambertNodeMaterial);