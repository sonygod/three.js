import hxmath.Matrix4;
import hxmath.Matrix3;
import hxmath.Box3;
import hxmath.Box2;
import hxmath.Line3;
import hxmath.Euler;
import hxmath.Vector4;
import hxmath.Vector3;
import hxmath.Vector2;
import hxmath.Quaternion;
import hxmath.Color;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.EnumValueList;
import hxmath.math.Spherical;
import hxmath.math.Cylindrical;
import hxmath.math.Plane;
import hxmath.math.Frustum;
import hxmath.math.Sphere;
import hxmath.math.Ray;
import haxe.ds.ObjectMap;

// Adjust the module namespacing according to your folder structure,
// e.g for the 'three.js/src/Three.js' file path, the module name would be 'three.Three'
@:module("three.Three")
class Three {

    // Declare static constants, variables or methods as needed, e.g

    public static var REVISION:String = "";

    // Import the required classes using @:new and access their static methods using class name, e.g

    @:new("three.loaders.LoadingManager")
    public static var DefaultLoadingManager:Dynamic;

    @:new("three.math.MathUtils")
    public static function abs(value:Float):Float;

    // Repeat the import statement for every class you want to import from an external module
    // For example, for the following line:
    //
    // export { EventDispatcher } from './core/EventDispatcher.js';
    //
    // You'll write in Haxe:

    @:new("three.core.EventDispatcher")
    public static class EventDispatcher {
    	
        function on(type:String, listener:Dynamic, context:Dynamic = null):Dynamic;
        function once(type:String, listener:Dynamic, context:Dynamic = null):Dynamic;
        function off(type:String, listener:Dynamic = null, context:Dynamic = null):Dynamic;
        function dispatchEvent(event:Dynamic):Void;
    	
    }

    // For the exported objects that need to be used like a type, e.g
    //
    // export { BooleanKeyframeTrack } from './animation/tracks/BooleanKeyframeTrack.js';
    //
    // You'll write in Haxe:

    @:new("three.animation.tracks.BooleanKeyframeTrack")
    public static class BooleanKeyframeTrack<T> {
    	
    }

    // Repeat the @:new and class definition for every exported object
    // that needs to be used as a type in your Haxe code

}


The `Three` class serves as a namespace for all the imported classes. Since Haxe does not have a built-in way to create namespaces, we'll use a class for grouping all the imported classes' static methods.

Make sure to replace the `@:new` and `@:module` directives according to your folder structure and the actual path of the JavaScript files.

After completing the conversion, you can now use these classes static methods in your Haxe code. For example, you can create a `Matrix4` using:


var m = Matrix4.identity();