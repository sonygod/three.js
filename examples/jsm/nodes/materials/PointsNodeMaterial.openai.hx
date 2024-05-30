package three.js.examples.jvm.nodes.materials;

import three.js.materials.PointsMaterial;
import three.js.nodes.NodeMaterial;

class PointsNodeMaterial extends NodeMaterial {
    public var isPointsNodeMaterial:Bool = true;

    public var lights:Bool = false;
    public var normals:Bool = false;
    public var transparent:Bool = true;

    public var sizeNode:Dynamic = null;

    public function new(parameters:Dynamic) {
        super();

        var defaultValues:PointsMaterial = new PointsMaterial();
        setDefaultValues(defaultValues);
        setValues(parameters);
    }

    override public function copy(source:Dynamic):Dynamic {
        sizeNode = source.sizeNode;
        return super.copy(source);
    }
}

 registroNodes( 'PointsNodeMaterial', PointsNodeMaterial );