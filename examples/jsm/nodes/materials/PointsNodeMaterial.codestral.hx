import NodeMaterial;
import three.PointsMaterial;

class PointsNodeMaterial extends NodeMaterial {

    public var isPointsNodeMaterial:Bool = true;
    public var lights:Bool = false;
    public var normals:Bool = false;
    public var transparent:Bool = true;
    public var sizeNode:Dynamic = null;

    public function new(parameters:Dynamic) {
        super();

        var defaultValues = new PointsMaterial();
        this.setDefaultValues(defaultValues);
        this.setValues(parameters);
    }

    public function copy(source:PointsNodeMaterial):PointsNodeMaterial {
        this.sizeNode = source.sizeNode;
        return super.copy(source);
    }
}

NodeMaterial.addNodeMaterial('PointsNodeMaterial', PointsNodeMaterial);