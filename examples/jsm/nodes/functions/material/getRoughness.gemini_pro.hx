import getGeometryRoughness from "./getGeometryRoughness.hx";
import tslFn from "../../shadernode/ShaderNode.hx";

var getRoughness = tslFn((inputs) => {

	var roughness = inputs.roughness;

	var geometryRoughness = getGeometryRoughness();

	var roughnessFactor = roughness.max(0.0525); // 0.0525 corresponds to the base mip of a 256 cubemap.
	roughnessFactor = roughnessFactor.add(geometryRoughness);
	roughnessFactor = roughnessFactor.min(1.0);

	return roughnessFactor;

});

export default getRoughness;