package three.examples.jsm.nodes.materials;

import three.js.NodeMaterial;
import three.js.Nodes;

class LineBasicNodeMaterial extends NodeMaterial
{
    public var isLineBasicNodeMaterial:Bool = true;

    public function new(parameters:Dynamic)
    {
        super();

        lights = false;
        normals = false;

        setDefaultValues(new three.js.LineBasicMaterial());

        setValues(parameters);
    }
}

Nodes.addNodeMaterial('LineBasicNodeMaterial', LineBasicNodeMaterial);