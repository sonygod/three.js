package three.js.examples.jsm.loaders;

import three.js.loaders.GLTFLoader;
import three.math.Quaternion;

class GLTFCubicSplineQuaternionInterpolant extends GLTFCubicSplineInterpolant {
    override function interpolate_(i1:Float, t0:Float, t:Float, t1:Float):Array<Float> {
        var result:Array<Float> = super.interpolate_(i1, t0, t, t1);
        var q:Quaternion = new Quaternion();
        q.fromArray(result);
        q.normalize();
        q.toArray(result);
        return result;
    }
}