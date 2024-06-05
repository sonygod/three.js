import normalGeometry from "../../accessors/NormalNode";
import TslFn from "../../shadernode/ShaderNode";

var getGeometryRoughness = new TslFn(() => {
  var dxy = normalGeometry.dFdx().abs().max(normalGeometry.dFdy().abs());
  var geometryRoughness = dxy.x.max(dxy.y).max(dxy.z);
  return geometryRoughness;
});

export default getGeometryRoughness;