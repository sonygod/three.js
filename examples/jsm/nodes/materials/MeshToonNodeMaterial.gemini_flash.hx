import NodeMaterial from "./NodeMaterial";
import ToonLightingModel from "../functions/ToonLightingModel";

import MeshToonMaterial from "three/src/materials/MeshToonMaterial";

class MeshToonNodeMaterial extends NodeMaterial {
  public var isMeshToonNodeMaterial:Bool = true;
  public var lights:Bool = true;

  public function new(parameters:Dynamic = null) {
    super();

    this.setDefaultValues(cast MeshToonMaterial.new());
    if (parameters != null) {
      this.setValues(parameters);
    }
  }

  public function setupLightingModel(/*builder*/):ToonLightingModel {
    return new ToonLightingModel();
  }
}

NodeMaterial.addNodeMaterial("MeshToonNodeMaterial", MeshToonNodeMaterial);