import three.materials.PointsMaterial;
import three.materials.NodeMaterial;

class PointsNodeMaterial extends NodeMaterial {

  public var sizeNode:Dynamic = null;

  public function new(parameters:Dynamic = null) {
    super();
    this.isPointsNodeMaterial = true;
    this.lights = false;
    this.normals = false;
    this.transparent = true;
    this.setDefaultValues(new PointsMaterial());
    this.setValues(parameters);
  }

  public function copy(source:PointsNodeMaterial):PointsNodeMaterial {
    this.sizeNode = source.sizeNode;
    return super.copy(source);
  }

}

addNodeMaterial("PointsNodeMaterial", PointsNodeMaterial);