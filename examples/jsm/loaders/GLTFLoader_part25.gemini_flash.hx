import kha.math.Quaternion;

class GLTFCubicSplineQuaternionInterpolant extends GLTFCubicSplineInterpolant {

	override public function interpolate_( i1:Int, t0:Float, t:Float, t1:Float ):Array<Float> {

		var result = super.interpolate_( i1, t0, t, t1 );

		var q = new Quaternion();
		q.setFromFloatArray( result );
		q.normalize();
		q.toFloatArray( result );

		return result;

	}

}