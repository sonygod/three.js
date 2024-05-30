import NodeMaterial.NodeMaterial;
import NodeMaterial.addNodeMaterial;
import three.MeshBasicMaterial;

class MeshBasicNodeMaterial extends NodeMaterial {
  public var isMeshBasicNodeMaterial:Bool = true;
  public var lights:Bool = false;

  public function new(parameters:Dynamic) {
    super();

    this.isMeshBasicNodeMaterial = true;
    this.lights = false;

    var defaultValues = new MeshBasicMaterial();
    this.setDefaultValues(defaultValues);
    this.setValues(parameters);
  }

  static function main() {
    addNodeMaterial('MeshBasicNodeMaterial', MeshBasicNodeMaterial);
  }
}