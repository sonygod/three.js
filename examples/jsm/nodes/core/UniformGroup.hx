Here is the equivalent Haxe code for the provided JavaScript code:
```
package three.js.examples.jsm.nodes.core;

class UniformGroup {

    public var name:String;
    public var isUniformGroup:Bool;

    public function new(name:String) {
        this.name = name;
        this.isUniformGroup = true;
    }
}
```
Note that in Haxe, we don't need to use the `export default` syntax, as Haxe has its own module system. Also, in Haxe, we need to specify the type of the variables explicitly, so I added the types for `name` and `isUniformGroup`.

Also, in Haxe, the constructor is defined using the `new` keyword, and the `this` keyword is not needed to access the class properties.

This code should be saved in a file named `UniformGroup.hx` in the package `three.js.examples.jsm.nodes.core`.