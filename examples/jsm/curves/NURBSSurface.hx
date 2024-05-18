package three.js.examples.jsm.curves;

import three.Vector4;
import three.curves.NURBSUtils;

/**
 * NURBS surface object
 *
 * Implementation is based on (x, y [, z=0 [, w=1]]) control points with w=weight.
 **/

class NURBSSurface {
    public var degree1:Int;
    public var degree2:Int;
    public var knots1:Array<Float>;
    public var knots2:Array<Float>;
    public var controlPoints:Array<Array<Vector4>>;

    public function new(degree1:Int, degree2:Int, knots1:Array<Float>, knots2:Array<Float>, controlPoints:Array<Array<Vector4>>) {
        this.degree1 = degree1;
        this.degree2 = degree2;
        this.knots1 = knots1;
        this.knots2 = knots2;
        this.controlPoints = [];

        var len1:Int = knots1.length - degree1 - 1;
        var len2:Int = knots2.length - degree2 - 1;

        // ensure Vector4 for control points
        for (i in 0...len1) {
            this.controlPoints[i] = [];

            for (j in 0...len2) {
                var point:Vector4 = controlPoints[i][j];
                this.controlPoints[i][j] = new Vector4(point.x, point.y, point.z, point.w);
            }
        }
    }

    public function getPoint(t1:Float, t2:Float, target:Vector4):Void {
        var u:Float = knots1[0] + t1 * (knots1[knots1.length - 1] - knots1[0]); // linear mapping t1->u
        var v:Float = knots2[0] + t2 * (knots2[knots2.length - 1] - knots2[0]); // linear mapping t2->u

        NURBSUtils.calcSurfacePoint(degree1, degree2, knots1, knots2, controlPoints, u, v, target);
    }
}