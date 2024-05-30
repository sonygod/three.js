import three.js.examples.jsm.nodes.materials.NodeMaterial;
import three.js.examples.jsm.nodes.materials.addNodeMaterial;
import three.js.PointsMaterial;

class PointsNodeMaterial extends NodeMaterial {

    public var isPointsNodeMaterial:Bool;
    public var lights:Bool;
    public var normals:Bool;
    public var transparent:Bool;
    public var sizeNode:Dynamic;

    public function new(parameters:Dynamic) {
        super();

        this.isPointsNodeMaterial = true;
        this.lights = false;
        this.normals = false;
        this.transparent = true;
        this.sizeNode = null;

        var defaultValues = new PointsMaterial();
        this.setDefaultValues(defaultValues);

        this.setValues(parameters);
    }

    public function copy(source:Dynamic):Dynamic {
        this.sizeNode = source.sizeNode;
        return super.copy(source);
    }
}

addNodeMaterial('PointsNodeMaterial', PointsNodeMaterial);