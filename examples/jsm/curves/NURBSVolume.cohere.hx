import js.three.Vector4;
import js.NURBSUtils.NURBSUtils;

class NURBSVolume {
    var degree1:Int;
    var degree2:Int;
    var degree3:Int;
    var knots1:Array<Float>;
    var knots2:Array<Float>;
    var knots3:Array<Float>;
    var controlPoints:Array<Array<Array<Vector4>>>;

    public function new(degree1:Int, degree2:Int, degree3:Int, knots1:Array<Float>, knots2:Array<Float>, knots3:Array<Float>, controlPoints:Array<Array<Array<Vector4>>>) {
        this.degree1 = degree1;
        this.degree2 = degree2;
        this.degree3 = degree3;
        this.knots1 = knots1;
        this.knots2 = knots2;
        this.knots3 = knots3;
        this.controlPoints = controlPoints;

        var len1 = knots1.length - degree1 - 1;
        var len2 = knots2.length - degree2 - 1;
        var len3 = knots3.length - degree3 - 1;

        for (i in 0...len1) {
            for (j in 0...len2) {
                for (k in 0...len3) {
                    var point = controlPoints[i][j][k];
                    this.controlPoints[i][j][k] = new Vector4(point.x, point.y, point.z, point.w);
                }
            }
        }
    }

    public function getPoint(t1:Float, t2:Float, t3:Float, target:Vector4):Void {
        var u = knots1[0] + t1 * (knots1[knots1.length - 1] - knots1[0]);
        var v = knots2[0] + t2 * (knots2[knots2.length - 1] - knots2[0]);
        var w = knots3[0] + t3 * (knots3[knots3.length - 1] - knots3[0]);

        NURBSUtils.calcVolumePoint(degree1, degree2, degree3, knots1, knots2, knots3, controlPoints, u, v, w, target);
    }
}

class js.NURBSUtils.NURBSVolume {
    public static inline function getPoint(t1:Float, t2:Float, t3:Float, target:Vector4):Void {
        var u = knots1[0] + t1 * (knots1[knots1.length - 1] - knots1[0]);
        var v = knots2[0] + t2 * (knots2[knots2.length - 1] - knots2[0]);
        var w = knots3[0] + t3 * (knots3[knots3.length - 1] - knots3[0]);

        NURBSUtils.calcVolumePoint(degree1, degree2, degree3, knots1, knots2, knots3, controlPoints, u, v, w, target);
    }
}