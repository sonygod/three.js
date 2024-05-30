class GLTFCubicSplineQuaternionInterpolant extends GLTFCubicSplineInterpolant {
	function interpolate_(i1:Float32Array, t0:Float, t:Float, t1:Float):Float32Array {
		var result = super.interpolate_(i1, t0, t, t1);
		_q.fromArray(result).normalize().toArray(result);
		return result;
	}
}