package three.js.nodes.accessors;

import three.js.core.Node;

class SceneNode extends Node {
  public static inline var BACKGROUND_BLURRINESS:String = 'backgroundBlurriness';
  public static inline var BACKGROUND_INTENSITY:String = 'backgroundIntensity';

  private var scope:String;
  private var scene:Scene;

  public function new(scope:String = BACKGROUND_BLURRINESS, scene:Scene = null) {
    super();
    this.scope = scope;
    this.scene = scene;
  }

  public function setup(builder:Builder):Dynamic {
    var scope = this.scope;
    var scene:Scene = this.scene != null ? this.scene : builder.scene;

    var output:Dynamic;

    switch (scope) {
      case BACKGROUND_BLURRINESS:
        output = reference('backgroundBlurriness', 'float', scene);
      case BACKGROUND_INTENSITY:
        output = reference('backgroundIntensity', 'float', scene);
      default:
        console.error('THREE.SceneNode: Unknown scope:', scope);
    }

    return output;
  }
}

// Expose constants
@:keep
extern class SceneNode {
  @:keep
  public static var BACKGROUND_BLURRINESS(get, never):String;
  @:keep
  public static var BACKGROUND_INTENSITY(get, never):String;
}

// Expose static methods
@:keep
extern class SceneNode {
  @:keep
  public static function backgroundBlurriness():ShaderNode;
  @:keep
  public static function backgroundIntensity():ShaderNode;
}

// Register node class
.addNodeClass('SceneNode', SceneNode);