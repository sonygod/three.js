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
    this.setValues(parameters);
  }

  public function setupLightingModel(builder:Dynamic):PhongLightingModel {
    return new PhongLightingModel();
  }

  public function setupVariants() {
    // SHININESS
    var shininessNode = (this.shininessNode != null ? float(this.shininessNode) : materialShininess).max(1e-4);
    shininess.assign(shininessNode);

    // SPECULAR COLOR
    var specularNode = this.specularNode != null ? this.specularNode : materialSpecular;
    specularColor.assign(specularNode);
  }

  public function copy(source:MeshPhongNodeMaterial):MeshPhongNodeMaterial {
    this.shininessNode = source.shininessNode;
    this.specularNode = source.specularNode;
    return super.copy(source);
  }
}

export default MeshPhongNodeMaterial;

addNodeMaterial("MeshPhongNodeMaterial", MeshPhongNodeMaterial);