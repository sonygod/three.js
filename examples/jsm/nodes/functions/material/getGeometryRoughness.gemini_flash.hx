import NormalNode from "../../accessors/NormalNode";
import ShaderNode from "../../shadernode/ShaderNode";

class GeometryRoughness extends ShaderNode {
  public function new() {
    super();
  }

  override function generateCode(builder:ShaderNode.Builder):Void {
    builder.add(
      "const dxy = abs(NormalNode.dFdx()).max(abs(NormalNode.dFdy()));",
      "const geometryRoughness = max(max(dxy.x, dxy.y), dxy.z);"
    );
    builder.addOutput("geometryRoughness");
  }
}

var getGeometryRoughness = new GeometryRoughness();

export default getGeometryRoughness;