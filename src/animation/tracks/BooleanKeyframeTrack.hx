Here is the converted Haxe code:
```
package three.animation.tracks;

import three.constants.InterpolateDiscrete;
import three.animation.tracks.KeyframeTrack;

/**
 * A Track of Boolean keyframe values.
 */
class BooleanKeyframeTrack extends KeyframeTrack {

    public function new(name:String, times:Array<Float>, values:Array<Bool>) {
        super(name, times, values);
    }

    static public var ValueTypeName:String = 'bool';
    static public var ValueBufferType:Array<Bool> = [];
    static public var DefaultInterpolation:InterpolateDiscrete = InterpolateDiscrete;
    static public var InterpolantFactoryMethodLinear:Null<Dynamic> = null;
    static public var InterpolantFactoryMethodSmooth:Null<Dynamic> = null;
}
```
Note:

* In Haxe, we use `package` declaration to specify the package name, which corresponds to the file path in JavaScript.
* We use `import` statements to import the required classes and constants.
* The class declaration is similar to JavaScript, but we use `public function new` to declare the constructor.
* We use `static public` to declare the static properties, and `:Type` to specify the type of each property.
* We use `Null<Dynamic>` to represent the `undefined` value in JavaScript.
* We use `Array<Bool>` to represent the `Array` type in JavaScript, with a type parameter `Bool`.
* We don't need to use `export` statement in Haxe, as the class is already accessible from other files in the same package.