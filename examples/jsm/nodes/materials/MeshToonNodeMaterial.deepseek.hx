import three.js.examples.jsm.nodes.materials.NodeMaterial;
import three.js.examples.jsm.nodes.functions.ToonLightingModel;
import three.js.MeshToonMaterial;

class MeshToonNodeMaterial extends NodeMaterial {

    public function new(parameters:Dynamic) {

        super();

        this.isMeshToonNodeMaterial = true;

        this.lights = true;

        this.setDefaultValues(new MeshToonMaterial());

        this.setValues(parameters);

    }

    public function setupLightingModel():ToonLightingModel {

        return new ToonLightingModel();

    }

}

NodeMaterial.addNodeMaterial('MeshToonNodeMaterial', MeshToonNodeMaterial);