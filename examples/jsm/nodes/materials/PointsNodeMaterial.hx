package three.js.examples.jvm.nodes.materials;

import three.js.examples.jvm.nodes.NodeMaterial;
import three.js.Three;

class PointsNodeMaterial extends NodeMaterial {
    public var isPointsNodeMaterial:Bool = true;
    public var lights:Bool = false;
    public var normals:Bool = false;
    public var transparent:Bool = true;
    public var sizeNode:Null<Dynamic>;

    public function new(parameters:Dynamic = null) {
        super();
        setDefaultValues(new Three.PointsMaterial());
        setValues(parameters);
    }

    override public function copy(source:PointsNodeMaterial):PointsNodeMaterial {
        sizeNode = source.sizeNode;
        return super.copy(source);
    }

    static function main() {
        addNodeMaterial('PointsNodeMaterial', PointsNodeMaterial);
    }
}