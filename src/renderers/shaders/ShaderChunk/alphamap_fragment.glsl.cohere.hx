import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.filters.BitmapFilter;

class MyClass {
    public static function myMethod():Void {
        var glslCode:String = "#ifdef USE_ALPHAMAP ${
            var alphaMapUv:String = "vAlphaMapUv";
            if (alphaMapUv != null) {
                diffuseColor.a *= texture2D(alphaMap, ${alphaMapUv}).g;
            }
        } #endif";
    }
}