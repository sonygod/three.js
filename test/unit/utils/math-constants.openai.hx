package three.test.unit.utils;

import three.math.Vector2;
import three.math.Vector3;

class MathConstants {
    public static var x:Int = 2;
    public static var y:Int = 3;
    public static var z:Int = 4;
    public static var w:Int = 5;

    public static var negInf2:Vector2 = new Vector2(-Math.POSITIVE_INFINITY, -Math.POSITIVE_INFINITY);
    public static var posInf2:Vector2 = new Vector2(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);

    public static var negOne2:Vector2 = new Vector2(-1, -1);

    public static var zero2:Vector2 = new Vector2();
    public static var one2:Vector2 = new Vector2(1, 1);
    public static var two2:Vector2 = new Vector2(2, 2);

    public static var negInf3:Vector3 = new Vector3(-Math.POSITIVE_INFINITY, -Math.POSITIVE_INFINITY, -Math.POSITIVE_INFINITY);
    public static var posInf3:Vector3 = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);

    public static var zero3:Vector3 = new Vector3();
    public static var one3:Vector3 = new Vector3(1, 1, 1);
    public static var two3:Vector3 = new Vector3(2, 2, 2);

    public static var eps:Float = 0.0001;
}