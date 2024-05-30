package three.examples.jsm.utils;

import three.BufferAttribute;
import three.Matrix3;
import three.Matrix4;
import three.Vector3;
import three.Mesh;
import three.Geometry;
import three.PackedPhongMaterial;

class GeometryCompressionUtils {

    public static function compressNormals(mesh:Mesh, encodeMethod:String):Void {
        // ...
    }

    public static function compressPositions(mesh:Mesh):Void {
        // ...
    }

    public static function compressUvs(mesh:Mesh):Void {
        // ...
    }

    private static function defaultEncode(x:Float, y:Float, z:Float, bytes:Int):Array<Int> {
        // ...
    }

    private static function anglesEncode(x:Float, y:Float, z:Float):Array<Int> {
        // ...
    }

    private static function octEncodeBest(x:Float, y:Float, z:Float, bytes:Int):Array<Int> {
        // ...
    }

    private static function quantizedEncode(array:Array<Float>, bytes:Int):Dynamic {
        // ...
    }

    private static function quantizedEncodeUV(array:Array<Float>, bytes:Int):Dynamic {
        // ...
    }
}