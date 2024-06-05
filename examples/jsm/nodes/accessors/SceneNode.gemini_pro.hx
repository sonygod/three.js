import Node from "../core/Node";
import {addNodeClass} from "../core/Node";
import {nodeImmutable} from "../shadernode/ShaderNode";
import {reference} from "./ReferenceNode";

class SceneNode extends Node {
  public var scope:String;
  public var scene:Dynamic;

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
      output = reference("backgroundBlurriness", "float", scene);
    } else if (scope == SceneNode.BACKGROUND_INTENSITY) {
      output = reference("backgroundIntensity", "float", scene);
    } else {
      console.error("THREE.SceneNode: Unknown scope:", scope);
    }
    return output;
  }

  public static var BACKGROUND_BLURRINESS:String = "backgroundBlurriness";
  public static var BACKGROUND_INTENSITY:String = "backgroundIntensity";
}

addNodeClass("SceneNode", SceneNode);

var backgroundBlurriness = nodeImmutable(SceneNode, SceneNode.BACKGROUND_BLURRINESS);
var backgroundIntensity = nodeImmutable(SceneNode, SceneNode.BACKGROUND_INTENSITY);