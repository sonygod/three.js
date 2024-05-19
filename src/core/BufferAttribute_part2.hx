Here is the equivalent Haxe code:
```
package three.core;

import js.html.Int8Array;

class Int8BufferAttribute extends BufferAttribute {
    public function new(array:Array<Dynamic>, itemSize:Int, normalized:Bool) {
        super(new Int8Array(array), itemSize, normalized);
    }
}
```
Note that in Haxe, we need to specify the package and import statements explicitly. We also need to specify the types for the constructor parameters, and use the `new` keyword to create a new instance of `Int8Array`.

Also, in Haxe, we need to use the `Dynamic` type to represent the `array` parameter, since it can be any type of array. If you know the specific type of array, you can replace `Dynamic` with that type.

You can adjust the package name and import statements according to your project's configuration.