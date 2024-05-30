class GLTFCubicSplineQuaternionInterpolant extends GLTFCubicSplineInterpolant {

    override function interpolate_(i1:Float, t0:Float, t:Float, t1:Float):Array<Float> {
        var result = super.interpolate_(i1, t0, t, t1);
        _q.fromArray(result).normalize().toArray(result);
        return result;
    }

}