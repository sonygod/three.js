import NodeMaterial from "./NodeMaterial";
import { addNodeMaterial } from "./NodeMaterial";
import { shininess, specularColor } from "../core/PropertyNode";
import { materialShininess, materialSpecular } from "../accessors/MaterialNode";
import { float } from "../shadernode/ShaderNode";
import PhongLightingModel from "../functions/PhongLightingModel";

import { MeshPhongMaterial } from "three";

class MeshPhongNodeMaterial extends NodeMaterial {

  public var isMeshPhongNodeMaterial:Bool = true;

  public var lights:Bool = true;

  public var shininessNode:Dynamic = null;
  public var specularNode:Dynamic = null;

  public function new(parameters:Dynamic = null) {
    super();

    this.setDefaultValues(new MeshPhongMaterial());

    if (parameters != null) {
      this.setValues(parameters);
    }
  }

  public function setupLightingModel() : PhongLightingModel {
    return new PhongLightingModel();
  }

  public function setupVariants() {

    // SHININESS

    var shininessNode = if (this.shininessNode != null) float(this.shininessNode) else materialShininess;
    shininessNode = shininessNode.max(1e-4); // to prevent pow( 0.0, 0.0 )

    shininess.assign(shininessNode);

    // SPECULAR COLOR

    var specularNode = if (this.specularNode != null) this.specularNode else materialSpecular;

    specularColor.assign(specularNode);
  }

  public function copy(source:MeshPhongNodeMaterial) : MeshPhongNodeMaterial {
    this.shininessNode = source.shininessNode;
    this.specularNode = source.specularNode;

    super.copy(source);

    return this;
  }
}

addNodeMaterial("MeshPhongNodeMaterial", MeshPhongNodeMaterial);