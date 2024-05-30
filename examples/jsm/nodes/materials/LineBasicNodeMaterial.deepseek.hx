import three.js.examples.jsm.nodes.materials.NodeMaterial;
import three.js.examples.jsm.nodes.materials.addNodeMaterial;
import three.js.LineBasicMaterial;

class LineBasicNodeMaterial extends NodeMaterial {

    public function new(parameters:Dynamic) {
        super();

        this.isLineBasicNodeMaterial = true;

        this.lights = false;
        this.normals = false;

        this.setDefaultValues(new LineBasicMaterial());

        this.setValues(parameters);
    }

}

addNodeMaterial('LineBasicNodeMaterial', LineBasicNodeMaterial);