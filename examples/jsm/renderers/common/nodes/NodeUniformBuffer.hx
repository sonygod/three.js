Here is the equivalent Haxe code:
```
package three.js.examples.jvm.renderers.common.nodes;

import UniformBuffer;

class NodeUniformBuffer extends UniformBuffer {
    static var _id:Int = 0;

    public var nodeUniform:Dynamic;

    public function new(nodeUniform:Dynamic) {
        super('UniformBuffer_' + (_id++), nodeUniform != null ? nodeUniform.value : null);
        this.nodeUniform = nodeUniform;
    }

    public function get_buffer():Dynamic {
        return nodeUniform.value;
    }
}
```
Note that I've made the following changes:

* Imported the `UniformBuffer` class from the same package.
* Changed the JavaScript `let` keyword to a Haxe `static var` declaration for the `_id` variable.
* Changed the JavaScript `class` keyword to a Haxe `class` keyword.
* Changed the JavaScript `constructor` function to a Haxe `new` function.
* Changed the JavaScript `get` accessor to a Haxe `get_` function (note the underscore).
* Changed the JavaScript `export default` statement to a Haxe `package` declaration.

Also, I've assumed that the `nodeUniform` variable is of type `Dynamic` since its type is not explicitly specified in the JavaScript code. If you know the actual type of `nodeUniform`, you can replace `Dynamic` with that type.