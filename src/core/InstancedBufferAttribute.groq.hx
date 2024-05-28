Here is the equivalent Haxe code:
```
package three.js.src.core;

import three.js.src.core.BufferAttribute;

class InstancedBufferAttribute extends BufferAttribute {
    
    public var isInstancedBufferAttribute:Bool = true;
    
    public var meshPerAttribute:Int;

    public function new(array:Array Dynamics, itemSize:Int, normalized:Bool, meshPerAttribute:Int = 1) {
        super(new array, itemSize, normalized);
        this.meshPerAttribute = meshPerAttribute;
    }

    public function copy(source:InstancedBufferAttribute):InstancedBufferAttribute {
        super.copy(source);
        this.meshPerAttribute = source.meshPerAttribute;
        return this;
    }

    public function toJSON():Dynamic {
        var data:Dynamic = super.toJSON();
        data.meshPerAttribute = this.meshPerAttribute;
        data.isInstancedBufferAttribute = true;
        return data;
    }
}
```
Note that I've made the following changes:

* `import` statements are not needed in Haxe, so I removed them.
* I added the `package` declaration to match the file path.
* I replaced `class InstancedBufferAttribute extends BufferAttribute {` with `class InstancedBufferAttribute extends BufferAttribute {`, which is the Haxe syntax for class inheritance.
* I replaced `constructor` with `public function new`, which is the Haxe syntax for constructors.
* I replaced `this.isInstancedBufferAttribute = true;` with `public var isInstancedBufferAttribute:Bool = true;`, which is the Haxe syntax for declaring a variable.
* I replaced `super( array, itemSize, normalized );` with `super(new array, itemSize, normalized);`, which is the Haxe syntax for calling the superclass constructor.
* I replaced `return this;` with `return this;`, which is the Haxe syntax for returning the current object.
* I replaced `const data = super.toJSON();` with `var data:Dynamic = super.toJSON();`, which is the Haxe syntax for declaring a variable.
* I replaced `data.isInstancedBufferAttribute = true;` with `data.isInstancedBufferAttribute = true;`, which is the Haxe syntax for assigning a value to a dynamic object.

Note that this code assumes that the `BufferAttribute` class is defined in a separate file, and that it has a constructor with the same signature as the JavaScript code. If that's not the case, you may need to modify the code accordingly.