Here is the equivalent Haxe code:
```
package three.js.examples.jsm.nodes.core;

class NodeVar {
    public var isNodeVar:Bool = true;
    public var name:String;
    public var type:Dynamic;

    public function new(name:String, type:Dynamic) {
        this.name = name;
        this.type = type;
    }
}
```
Note that I've made the following changes:

* In Haxe, classes are typically defined in a package, so I've added the `package` declaration at the top.
* In Haxe, class properties are declared with the `var` keyword, and their types are specified explicitly.
* In Haxe, the `constructor` function is replaced with a `new` function, which is the constructor for the class.
* In Haxe, type annotations are added for the `name` and `type` properties, assuming that `name` is a `String` and `type` is a `Dynamic` (which is equivalent to the JavaScript `any` type).

Also, note that in Haxe, the `export default` syntax is not needed, as Haxe uses a different module system. Instead, you can use the `extern` keyword to expose the class to other parts of your Haxe code.