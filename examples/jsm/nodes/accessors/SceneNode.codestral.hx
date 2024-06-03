import Node from '../core/Node';
import NodeUtils from '../core/NodeUtils';
import ShaderNode from '../shadernode/ShaderNode';
import ReferenceNode from './ReferenceNode';

class SceneNode extends Node {

    public var scope:String;
    public var scene:Dynamic;

    public function new(scope:String = SceneNode.BACKGROUND_BLURRINESS, scene:Dynamic = null) {
        super();
        this.scope = scope;
        this.scene = scene;
    }

    public function setup(builder:Dynamic):Dynamic {
        var scene:Dynamic = this.scene != null ? this.scene : builder.scene;
        var output:Dynamic;

        switch (this.scope) {
            case SceneNode.BACKGROUND_BLURRINESS:
                output = ReferenceNode.reference('backgroundBlurriness', 'float', scene);
                break;
            case SceneNode.BACKGROUND_INTENSITY:
                output = ReferenceNode.reference('backgroundIntensity', 'float', scene);
                break;
            default:
                trace('THREE.SceneNode: Unknown scope: ' + this.scope);
                break;
        }

        return output;
    }
}

class SceneNodeFactory {
    public static inline var BACKGROUND_BLURRINESS:String = 'backgroundBlurriness';
    public static inline var BACKGROUND_INTENSITY:String = 'backgroundIntensity';

    public static function backgroundBlurriness():Dynamic {
        return ShaderNode.nodeImmutable(SceneNode, SceneNodeFactory.BACKGROUND_BLURRINESS);
    }

    public static function backgroundIntensity():Dynamic {
        return ShaderNode.nodeImmutable(SceneNode, SceneNodeFactory.BACKGROUND_INTENSITY);
    }
}

NodeUtils.addNodeClass('SceneNode', SceneNode);