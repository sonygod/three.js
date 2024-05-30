package three.js.curves;

import three.Vector3;
import three.Vector4;

class NURBSUtils {
    public static function findSpan(p:Int, u:Float, U:Array<Float>):Int {
        var n:Int = U.length - p - 1;
        if (u >= U[n]) return n - 1;
        if (u <= U[p]) return p;
        var low:Int = p;
        var high:Int = n;
        var mid:Int = Math.floor((low + high) / 2);
        while (u < U[mid] || u >= U[mid + 1]) {
            if (u < U[mid]) high = mid; else low = mid;
            mid = Math.floor((low + high) / 2);
        }
        return mid;
    }

    public static function calcBasisFunctions(span:Int, u:Float, p:Int, U:Array<Float>):Array<Float> {
        var N:Array<Float> = new Array<Float>();
        var left:Array<Float> = new Array<Float>();
        var right:Array<Float> = new Array<Float>();
        N[0] = 1.0;
        for (j in 1...p + 1) {
            left[j] = u - U[span + 1 - j];
            right[j] = U[span + j] - u;
            var saved:Float = 0.0;
            for (r in 0...j) {
                var rv:Float = right[r + 1];
                var lv:Float = left[j - r];
                var temp:Float = N[r] / (rv + lv);
                N[r] = saved + rv * temp;
                saved = lv * temp;
            }
            N[j] = saved;
        }
        return N;
    }

    public static function calcBSplinePoint(p:Int, U:Array<Float>, P:Array<Vector4>, u:Float):Vector4 {
        var span:Int = findSpan(p, u, U);
        var N:Array<Float> = calcBasisFunctions(span, u, p, U);
        var C:Vector4 = new Vector4(0, 0, 0, 0);
        for (j in 0...p + 1) {
            var point:Vector4 = P[span - p + j];
            var Nj:Float = N[j];
            var wNj:Float = point.w * Nj;
            C.x += point.x * wNj;
            C.y += point.y * wNj;
            C.z += point.z * wNj;
            C.w += point.w * Nj;
        }
        return C;
    }

    public static function calcBasisFunctionDerivatives(span:Int, u:Float, p:Int, n:Int, U:Array<Float>):Array<Array<Float>> {
        // ... (rest of the function implementation)
    }

    public static function calcBSplineDerivatives(p:Int, U:Array<Float>, P:Array<Vector4>, u:Float, nd:Int):Array<Vector4> {
        // ... (rest of the function implementation)
    }

    public static function calcRationalCurveDerivatives(Pders:Array<Vector4>):Array<Vector3> {
        // ... (rest of the function implementation)
    }

    public static function calcNURBSDerivatives(p:Int, U:Array<Float>, P:Array<Vector4>, u:Float, nd:Int):Array<Vector3> {
        return calcRationalCurveDerivatives(calcBSplineDerivatives(p, U, P, u, nd));
    }

    public static function calcSurfacePoint(p:Int, q:Int, U:Array<Float>, V:Array<Float>, P:Array<Vector4>, u:Float, v:Float, target:Vector3):Void {
        // ... (rest of the function implementation)
    }

    public static function calcVolumePoint(p:Int, q:Int, r:Int, U:Array<Float>, V:Array<Float>, W:Array<Float>, P:Array<Vector4>, u:Float, v:Float, w:Float, target:Vector3):Void {
        // ... (rest of the function implementation)
    }
}