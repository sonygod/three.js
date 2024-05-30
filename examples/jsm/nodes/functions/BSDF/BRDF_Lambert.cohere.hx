import tslFn from "../../shadernode/ShaderNode.hx";

const BRDF_Lambert = tslFn(function (inputs) {
	return inputs.diffuseColor.mul(1 / Math.PI); // punctual light
}); // validated

export default BRDF_Lambert;