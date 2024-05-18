Here is the equivalent Haxe code for the provided JavaScript code:
```
package three.js.examples.jsm.nodes.accessors;

import three.js.core.Node;
import three.js.core.addNodeClass;
import three.js.shadernode.ShaderNode;

class SceneNode extends Node {
    public static inline var BACKGROUND_BLURRINESS:String = 'backgroundBlurriness';
    public static inline var BACKGROUND_INTENSITY:String = 'backgroundIntensity';

    public var scope:String;
    public var scene:Scene;

    public function new(?scope:String = BACKGROUND_BLURRINESS, ?scene:Scene = null) {
        super();
        this.scope = scope;
        this.scene = scene;
    }

    public function setup(builder:Dynamic):Dynamic {
        var scope:String = this.scope;
        var scene:Scene = this.scene != null ? this.scene : builder.scene;

        var output:Dynamic;

        switch (scope) {
            case BACKGROUND_BLURRINESS:
                output = reference('backgroundBlurriness', 'float', scene);
            case BACKGROUND_INTENSITY:
                output = reference('backgroundIntensity', 'float', scene);
            default:
                trace('THREE.SceneNode: Unknown scope: $scope');
        }

        return output;
    }
}

addNodeClass('SceneNode', SceneNode);

var backgroundBlurriness:SceneNode = nodeImmutable(SceneNode, SceneNode.BACKGROUND_BLURRINESS);
var backgroundIntensity:SceneNode = nodeImmutable(SceneNode, SceneNode.BACKGROUND_INTENSITY);
```
Note that I've used the `public` access modifier for the class fields and methods, as Haxe uses a more explicit access control system than JavaScript. I've also used the `inline` keyword for the static constants, as Haxe has a stronger type system that requires explicit type annotations. Additionally, I've used the `switch` statement instead of the `if-else` chain, as it's a more concise and expressive way to handle the different scope values.

Also, I've assumed that the `Scene` type is defined elsewhere in the Haxe codebase, and that the `reference` and `nodeImmutable` functions are defined in the `ShaderNode` module. If this is not the case, you may need to modify the code accordingly.