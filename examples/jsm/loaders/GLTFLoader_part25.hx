package three.js.examples.jsm.loaders;

import haxe.ds.Vector;

class GLTFCubicSplineQuaternionInterpolant extends GLTFCubicSplineInterpolant {
    override function interpolate_(i1:Float, t0:Float, t:Float, t1:Float):Vector<Float> {
        var result:Vector<Float> = super.interpolate_(i1, t0, t, t1);
        _q.fromArray(result).normalize().toArray(result);
        return result;
    }
}