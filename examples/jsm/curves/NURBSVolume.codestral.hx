import three.math.Vector4;
import NURBSUtils from 'three.curves.NURBSUtils';

class NURBSVolume {

    public var degree1:Int;
    public var degree2:Int;
    public var degree3:Int;
    public var knots1:Array<Float>;
    public var knots2:Array<Float>;
    public var knots3:Array<Float>;
    public var controlPoints:Array<Array<Array<Vector4>>>;

    public function new(degree1:Int, degree2:Int, degree3:Int, knots1:Array<Float>, knots2:Array<Float>, knots3:Array<Float>, controlPoints:Array<Array<Array<Dynamic>>>){
        this.degree1 = degree1;
        this.degree2 = degree2;
        this.degree3 = degree3;
        this.knots1 = knots1;
        this.knots2 = knots2;
        this.knots3 = knots3;
        this.controlPoints = [];

        var len1 = knots1.length - degree1 - 1;
        var len2 = knots2.length - degree2 - 1;
        var len3 = knots3.length - degree3 - 1;

        for (var i = 0; i < len1; ++i) {
            this.controlPoints[i] = [];

            for (var j = 0; j < len2; ++j) {
                this.controlPoints[i][j] = [];

                for (var k = 0; k < len3; ++k) {
                    var point = controlPoints[i][j][k];
                    this.controlPoints[i][j][k] = new Vector4(point.x, point.y, point.z, point.w);
                }
            }
        }
    }

    public function getPoint(t1:Float, t2:Float, t3:Float, target:Vector4):Void {
        var u = this.knots1[0] + t1 * (this.knots1[this.knots1.length - 1] - this.knots1[0]);
        var v = this.knots2[0] + t2 * (this.knots2[this.knots2.length - 1] - this.knots2[0]);
        var w = this.knots3[0] + t3 * (this.knots3[this.knots3.length - 1] - this.knots3[0]);

        NURBSUtils.calcVolumePoint(this.degree1, this.degree2, this.degree3, this.knots1, this.knots2, this.knots3, this.controlPoints, u, v, w, target);
    }
}