import three.js.examples.jsm.nodes.materials.NodeMaterial;
import three.MeshBasicMaterial;

class MeshBasicNodeMaterial extends NodeMaterial {

    public function new(parameters:Dynamic) {
        super();

        this.isMeshBasicNodeMaterial = true;

        this.lights = false;
        //this.normals = false; @TODO: normals usage by context

        this.setDefaultValues(new MeshBasicMaterial());

        this.setValues(parameters);
    }

}

NodeMaterial.addNodeMaterial('MeshBasicNodeMaterial', MeshBasicNodeMaterial);