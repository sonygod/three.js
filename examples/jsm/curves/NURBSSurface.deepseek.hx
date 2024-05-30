import three.Vector4;
import NURBSUtils.*;

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

        var len1 = knots1.length - degree1 - 1;
        var len2 = knots2.length - degree2 - 1;

        for (i in 0...len1) {
            this.controlPoints[i] = [];

            for (j in 0...len2) {
                var point = controlPoints[i][j];
                this.controlPoints[i][j] = new Vector4(point.x, point.y, point.z, point.w);
            }
        }
    }

    public function getPoint(t1:Float, t2:Float, target:Vector4) {
        var u = this.knots1[0] + t1 * (this.knots1[this.knots1.length - 1] - this.knots1[0]);
        var v = this.knots2[0] + t2 * (this.knots2[this.knots2.length - 1] - this.knots2[0]);

        NURBSUtils.calcSurfacePoint(this.degree1, this.degree2, this.knots1, this.knots2, this.controlPoints, u, v, target);
    }
}