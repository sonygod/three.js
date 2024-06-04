import three.materials.LineBasicMaterial;
import NodeMaterial from "./NodeMaterial";

class LineBasicNodeMaterial extends NodeMaterial {

  public var isLineBasicNodeMaterial:Bool = true;

  public var lights:Bool = false;
  public var normals:Bool = false;

  public function new(parameters:Dynamic = null) {
    super();
    this.setDefaultValues(new LineBasicMaterial());
    this.setValues(parameters);
  }
}

NodeMaterial.addNodeMaterial("LineBasicNodeMaterial", LineBasicNodeMaterial);