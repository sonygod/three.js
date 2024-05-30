package three.js.examples.jsm.nodes.materials;

import NodeMaterial;
import three.MeshBasicMaterial;

class MeshBasicNodeMaterial extends NodeMaterial {
    public var isMeshBasicNodeMaterial:Bool = true;
    public var lights:Bool = false;
    //public var normals:Bool = false; // @TODO: normals usage by context

    public function new(parameters:Any = null) {
        super();
        setDefaultValues(new MeshBasicMaterial());
        setValues(parameters);
    }
}

NodeMaterial.addNodeMaterial('MeshBasicNodeMaterial', MeshBasicNodeMaterial);