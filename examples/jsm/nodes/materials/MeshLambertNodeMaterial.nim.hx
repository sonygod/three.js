import NodeMaterial.NodeMaterial;
import PhongLightingModel.PhongLightingModel;
import MeshLambertMaterial.MeshLambertMaterial;

class MeshLambertNodeMaterial extends NodeMaterial {

  public var isMeshLambertNodeMaterial:Bool = true;
  public var lights:Bool = true;

  public function new(parameters:Dynamic) {
    super();

    this.setDefaultValues(new MeshLambertMaterial());
    this.setValues(parameters);
  }

  public function setupLightingModel():PhongLightingModel {
    return new PhongLightingModel(false);
  }

  static function main() {
    addNodeMaterial('MeshLambertNodeMaterial', MeshLambertNodeMaterial);
  }
}