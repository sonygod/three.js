import Node from "../core/Node";
import NodeTools from "../core/NodeTools";
import ShaderNode from "../shadernode/ShaderNode";
import ReferenceNode from "./ReferenceNode";

class SceneNode extends Node {

	public static BACKGROUND_BLURRINESS:String = "backgroundBlurriness";
	public static BACKGROUND_INTENSITY:String = "backgroundIntensity";

	public scope:String;
	public scene:Dynamic;

	public function new(scope:String = SceneNode.BACKGROUND_BLURRINESS, scene:Dynamic = null) {
		super();
		this.scope = scope;
		this.scene = scene;
	}

	public function setup(builder:Dynamic):Dynamic {
		var scope = this.scope;
		var scene = this.scene != null ? this.scene : builder.scene;

		var output:Dynamic;

		if (scope == SceneNode.BACKGROUND_BLURRINESS) {
			output = ReferenceNode.reference("backgroundBlurriness", "float", scene);
		} else if (scope == SceneNode.BACKGROUND_INTENSITY) {
			output = ReferenceNode.reference("backgroundIntensity", "float", scene);
		} else {
			console.error("THREE.SceneNode: Unknown scope:", scope);
		}

		return output;
	}

}

var backgroundBlurriness = ShaderNode.nodeImmutable(SceneNode, SceneNode.BACKGROUND_BLURRINESS);
var backgroundIntensity = ShaderNode.nodeImmutable(SceneNode, SceneNode.BACKGROUND_INTENSITY);

NodeTools.addNodeClass("SceneNode", SceneNode);

export { SceneNode, backgroundBlurriness, backgroundIntensity };