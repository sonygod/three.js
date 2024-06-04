import LightingModel from "../core/LightingModel";
import diffuseColor from "../core/PropertyNode";
import float from "../shadernode/ShaderNode";

class ShadowMaskModel extends LightingModel {

	public var shadowNode:FloatNode;

	public function new() {
		super();
		this.shadowNode = float(1).toVar('shadowMask');
	}

	public function direct(shadowMask:FloatNode):Void {
		this.shadowNode.mulAssign(shadowMask);
	}

	public function finish(context:LightingContext):Void {
		diffuseColor.a.mulAssign(this.shadowNode.oneMinus());
		context.outgoingLight.rgb.assign(diffuseColor.rgb);
	}
}

export default ShadowMaskModel;