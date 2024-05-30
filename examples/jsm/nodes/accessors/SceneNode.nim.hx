import Node from '../core/Node.js';
import { addNodeClass } from '../core/Node.js';
import { nodeImmutable } from '../shadernode/ShaderNode.js';
import { reference } from './ReferenceNode.js';

class SceneNode extends Node {

	public var scope:String;
	public var scene:Null<Dynamic>;

	public function new( scope:String = SceneNode.BACKGROUND_BLURRINESS, scene:Null<Dynamic> = null ) {

		super();

		this.scope = scope;
		this.scene = scene;

	}

	public function setup( builder:Dynamic ) {

		var scope:String = this.scope;
		var scene:Dynamic = this.scene != null ? this.scene : builder.scene;

		var output:Dynamic;

		if ( scope == SceneNode.BACKGROUND_BLURRINESS ) {

			output = reference( 'backgroundBlurriness', 'float', scene );

		} else if ( scope == SceneNode.BACKGROUND_INTENSITY ) {

			output = reference( 'backgroundIntensity', 'float', scene );

		} else {

			trace.error( 'THREE.SceneNode: Unknown scope:', scope );

		}

		return output;

	}

}

SceneNode.BACKGROUND_BLURRINESS = 'backgroundBlurriness';
SceneNode.BACKGROUND_INTENSITY = 'backgroundIntensity';

@:expose
@:keep
class SceneNodeClass {
	public static var SceneNode:Class<SceneNode> = SceneNode;
}

@:expose
@:keep
class SceneNodeConstants {
	public static var BACKGROUND_BLURRINESS:String = 'backgroundBlurriness';
	public static var BACKGROUND_INTENSITY:String = 'backgroundIntensity';
}

@:expose
@:keep
class SceneNodeFunctions {
	public static function backgroundBlurriness():Node {
		return nodeImmutable( SceneNode, SceneNode.BACKGROUND_BLURRINESS );
	}

	public static function backgroundIntensity():Node {
		return nodeImmutable( SceneNode, SceneNode.BACKGROUND_INTENSITY );
	}
}

addNodeClass( 'SceneNode', SceneNode );