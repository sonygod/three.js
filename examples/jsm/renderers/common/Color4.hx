Here is the equivalent Haxe code:
```
package three.js.examples.jvm.renderers.common;

import three.Color;

class Color4 extends Color {
    public var a:Float;

    public function new(r:Float, g:Float, b:Float, a:Float = 1.0) {
        super(r, g, b);
        this.a = a;
    }

    public function set(r:Float, g:Float, b:Float, a:Float = 1.0):Color4 {
        this.a = a;
        return cast super.set(r, g, b);
    }

    public function copy(color:Color4):Color4 {
        if (color.a != null) this.a = color.a;
        return cast super.copy(color);
    }

    public function clone():Color4 {
        return new Color4(this.r, this.g, this.b, this.a);
    }
}
```
Note that I've made the following changes:

* Imported the `Color` class from `three` package.
* Changed the class declaration to use the Haxe syntax.
* Replaced the JavaScript `constructor` with a Haxe `new` function.
* Changed the `this.a` assignments to use the Haxe syntax.
* Changed the `super.set` and `super.copy` calls to use the Haxe syntax.
* Changed the `clone` method to use the Haxe `new` keyword.
* Removed the `export default` statement, as it's not necessary in Haxe.

Note that I've assumed that the `Color` class is already defined in the `three` package, and that it has the same methods and properties as the JavaScript `Color` class. If this is not the case, you may need to modify the code accordingly.