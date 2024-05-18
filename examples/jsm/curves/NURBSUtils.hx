import Vector3, Vector4 from "openfl/geom/Vector3";
import Vector4 from "openfl/geom/Vector4";

class NURBSUtils {

	public static function findSpan(p:Int, u:Float, U:Array<Float>):Int {
		...
	}

	public static function calcBasisFunctions(span:Int, u:Float, p:Int, U:Array<Float>):Array<Float> {
		...
	}

	public static function calcBSplinePoint(p:Int, U:Array<Float>, P:Array<Vector4>, u:Float):Vector4 {
		...
	}

	public static function calcBasisFunctionDerivatives(span:Int, u:Float, p:Int, n:Int, U:Array<Float>):Array<Array<Float>> {
		...
	}

	public static function calcBSplineDerivatives(p:Int, U:Array<Float>, P:Array<Vector4>, u:Float, nd:Int):Array<Vector4> {
		...
	}

	public static function calcKoverI(k:Int, i:Int):Float {
		...
	}

	public static function calcRationalCurveDerivatives(Pders:Array<Vector4>):Array<Vector3> {
		...
	}

	public static function calcNURBSDerivatives(p:Int, U:Array<Float>, P:Array<Vector4>, u:Float, nd:Int):Array<Vector3> {
		...
	}

	public static function calcSurfacePoint(p:Int, q:Int, U:Array<Float>, V:Array<Float>, P:Array<Array<Vector4>>, u:Float, v:Float, target:Vector3) {
		...
	}

	public static function calcVolumePoint(p:Int, q:Int, r:Int, U:Array<Float>, V:Array<Float>, W:Array<Float>, P:Array<Array<Array<Vector4>>>, u:Float, v:Float, w:Float, target:Vector3) {
		...
	}
}