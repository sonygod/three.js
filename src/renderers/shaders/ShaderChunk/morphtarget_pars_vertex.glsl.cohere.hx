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
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class MyClass {
    public static function getMorph (vertexIndex:Int, morphTargetIndex:Int, offset:Int):Float {
        var texelIndex = vertexIndex * MORPHTARGETS_TEXTURE_STRIDE + offset;
        var y = texelIndex / morphTargetsTextureSize.x;
        var x = texelIndex - y * morphTargetsTextureSize.x;

        var morphUV = new openfl.geom.Vector3D(x, y, morphTargetIndex);
        var texel = morphTargetsTexture.getPixel3D(morphUV.x, morphUV.y, morphUV.z);

        return texel.r;
    }
}