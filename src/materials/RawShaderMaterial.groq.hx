Here is the equivalent Haxe code for the provided JavaScript code:
```
package three.materials;

import three.materials.ShaderMaterial;

class RawShaderMaterial extends ShaderMaterial {
    public var isRawShaderMaterial:Bool;
    public var type:String;

    public function new(parameters:Dynamic) {
        super(parameters);
        isRawShaderMaterial = true;
        type = 'RawShaderMaterial';
    }
}
```
Note that I've made the following changes:

* In Haxe, we use `package` statements to define the namespace, which is equivalent to the file path in JavaScript.
* I've replaced `class` with `public class` to make the class public, as it's the default behavior in Haxe.
* I've replaced `extends` with `extends` to define the inheritance relationship.
* I've replaced `constructor` with `public function new` to define the constructor.
* I've replaced `this.isRawShaderMaterial` and `this.type` with `public var isRawShaderMaterial:Bool` and `public var type:String` to define the class properties.
* I've replaced `super(parameters)` with `super(parameters)` to call the parent constructor.
* I've removed the `export` statement, as Haxe uses a different mechanism for exporting classes and variables.

Also, note that in Haxe, we need to specify the type of the `parameters` variable in the constructor, which in this case is `Dynamic`, as it's equivalent to `any` in JavaScript.