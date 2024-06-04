import NodeMaterial from "./NodeMaterial";
import MaterialReferenceNode from "../accessors/MaterialReferenceNode";
import PropertyNode from "../core/PropertyNode";
import ShaderNode from "../shadernode/ShaderNode";
import MeshMatcapMaterial from "three";
import MathNode from "../math/MathNode";
import MatcapUVNode from "../utils/MatcapUVNode";

class MeshMatcapNodeMaterial extends NodeMaterial {
  public var isMeshMatcapNodeMaterial:Bool = true;
  public var lights:Bool = false;

  public function new(parameters:Dynamic) {
    super();
    this.setDefaultValues(new MeshMatcapMaterial());
    this.setValues(parameters);
  }

  override function setupVariants(builder:Dynamic) {
    var uv = MatcapUVNode.matcapUV;

    var matcapColor:Dynamic;

    if (builder.material.matcap != null) {
      matcapColor = MaterialReferenceNode.materialReference('matcap', 'texture').context({ getUV: () -> uv });
    } else {
      matcapColor = ShaderNode.vec3(MathNode.mix(0.2, 0.8, uv.y)); // default if matcap is missing
    }

    PropertyNode.diffuseColor.rgb.mulAssign(matcapColor.rgb);
  }
}

NodeMaterial.addNodeMaterial('MeshMatcapNodeMaterial', MeshMatcapNodeMaterial);

export default MeshMatcapNodeMaterial;