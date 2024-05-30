import NodeMaterial.NodeMaterial;
import NodeMaterial.addNodeMaterial;
import three.LineBasicMaterial;

class LineBasicNodeMaterial extends NodeMaterial {

  public var isLineBasicNodeMaterial:Bool = true;
  public var lights:Bool = false;
  public var normals:Bool = false;

  public function new(parameters:Dynamic) {
    super();

    var defaultValues:LineBasicMaterial = new LineBasicMaterial();

    this.setDefaultValues(defaultValues);
    this.setValues(parameters);
  }

  static function main() {
    addNodeMaterial('LineBasicNodeMaterial', LineBasicNodeMaterial);
  }
}