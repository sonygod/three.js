import NodeMaterial from "./NodeMaterial";
import ShadowMaskModel from "../functions/ShadowMaskModel";
import three.ShadowMaterial;

class ShadowNodeMaterial extends NodeMaterial {

  public var isShadowNodeMaterial:Bool = true;
  public var lights:Bool = true;

  public function new(parameters:Dynamic = null) {
    super();
    this.setDefaultValues(ShadowMaterial.create());
    if (parameters != null) this.setValues(parameters);
  }

  override function setupLightingModel(/*builder*/):ShadowMaskModel {
    return new ShadowMaskModel();
  }
}

NodeMaterial.addNodeMaterial("ShadowNodeMaterial", ShadowNodeMaterial);