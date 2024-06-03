import Quaternion; // assuming Quaternion is imported or defined

class GLTFCubicSplineQuaternionInterpolant extends GLTFCubicSplineInterpolant {

    public function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Float> {
        var result = super.super_interpolate_(i1, t0, t, t1);

        var q = new Quaternion();
        q.fromArray(result);
        q.normalize();
        q.toArray(result);

        return result;
    }
}