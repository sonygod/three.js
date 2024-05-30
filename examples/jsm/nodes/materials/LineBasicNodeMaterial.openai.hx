package three.js.examples.jsm.nodes.materials;

import NodeMaterial;
import three.LineBasicMaterial;

class LineBasicNodeMaterial extends NodeMaterial {
    public var isLineBasicNodeMaterial:Bool = true;

    public function new(parameters:Dynamic = null) {
        super();
        lights = false;
        normals = false;
        setDefaultValues(new LineBasicMaterial());
        setValues(parameters);
    }
}

addNodeMaterial('LineBasicNodeMaterial', LineBasicNodeMaterial);