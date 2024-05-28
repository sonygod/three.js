Here is the equivalent Haxe code:
```
package three.scenes;

import three.math.Color;

class Fog {
    public var isFog:Bool = true;
    public var name:String = '';
    public var color:Color;
    public var near:Float;
    public var far:Float;

    public function new(color:Int, near:Float = 1, far:Float = 1000) {
        this.color = new Color(color);
        this.near = near;
        this.far = far;
    }

    public function clone():Fog {
        return new Fog(this.color.getHex(), this.near, this.far);
    }

    public function toJSON(?meta:Dynamic):Dynamic {
        return {
            type: 'Fog',
            name: this.name,
            color: this.color.getHex(),
            near: this.near,
            far: this.far
        };
    }
}
```
Note that I've taken the following assumptions:

* I've kept the same package structure as the original JavaScript code, assuming that the `three` package is already defined in Haxe.
* I've used the `Bool` type for `isFog` since it's a boolean value in the original code.
* I've used the `Float` type for `near` and `far` since they are numeric values in the original code.
* I've kept the same method names and signatures as the original code, but adapted them to Haxe syntax.
* I've used the `?meta:Dynamic` parameter in the `toJSON` method since the original code has an optional `meta` parameter, but it's not clear what type it should be in Haxe. You may want to adjust this depending on your specific use case.

Let me know if you have any questions or need further adjustments!