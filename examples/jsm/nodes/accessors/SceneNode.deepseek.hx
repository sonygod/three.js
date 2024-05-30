import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.Node.addNodeClass;
import three.js.examples.jsm.nodes.shadernode.ShaderNode.nodeImmutable;
import three.js.examples.jsm.nodes.accessors.ReferenceNode.reference;

class SceneNode extends Node {

	public var scope:String;
	public var scene:Dynamic;

	public function new(scope:String = SceneNode.BACKGROUND_BLURRINESS, scene:Dynamic = null) {
		super();
		this.scope = scope;
		this.scene = scene;
	}

	public function setup(builder:Dynamic):Dynamic {
		var scope:String = this.scope;
		var scene:Dynamic = this.scene != null ? this.scene : builder.scene;
		var output:Dynamic;

		if (scope == SceneNode.BACKGROUND_BLURRINESS) {
			output = reference('backgroundBlurriness', 'float', scene);
		} else if (scope == SceneNode.BACKGROUND_INTENSITY) {
			output = reference('backgroundIntensity', 'float', scene);
		} else {
			trace('THREE.SceneNode: Unknown scope:', scope);
		}

		return output;
	}

	public static var BACKGROUND_BLURRINESS:String = 'backgroundBlurriness';
	public static var BACKGROUND_INTENSITY:String = 'backgroundIntensity';

}

var backgroundBlurriness:Dynamic = nodeImmutable(SceneNode, SceneNode.BACKGROUND_BLURRINESS);
var backgroundIntensity:Dynamic = nodeImmutable(SceneNode, SceneNode.BACKGROUND_INTENSITY);

addNodeClass('SceneNode', SceneNode);