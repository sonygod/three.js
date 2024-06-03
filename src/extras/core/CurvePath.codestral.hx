import Curve from './Curve';
import Curves from '../curves/Curves';

class CurvePath extends Curve {

    public var curves: Array<Curve> = [];
    public var autoClose: Bool = false;

    public function new() {
        super();
        this.type = 'CurvePath';
    }

    public function add(curve: Curve): Void {
        this.curves.push(curve);
    }

    public function closePath(): CurvePath {
        var startPoint = this.curves[0].getPoint(0);
        var endPoint = this.curves[this.curves.length - 1].getPoint(1);

        if (!startPoint.equals(endPoint)) {
            var lineType = (startPoint is Vector2) ? 'LineCurve' : 'LineCurve3';
            this.curves.push(Type.createInstance(Type.resolveClass(Curves), Type.resolveClass(lineType), [endPoint, startPoint]));
        }

        return this;
    }

    public function getPoint(t: Float, optionalTarget: Dynamic = null): Vector3 {
        var d = t * this.getLength();
        var curveLengths = this.getCurveLengths();
        var i = 0;

        while (i < curveLengths.length) {
            if (curveLengths[i] >= d) {
                var diff = curveLengths[i] - d;
                var curve = this.curves[i];

                var segmentLength = curve.getLength();
                var u = segmentLength == 0 ? 0 : 1 - diff / segmentLength;

                return curve.getPointAt(u, optionalTarget);
            }

            i++;
        }

        return null;
    }

    public function getLength(): Float {
        var lens = this.getCurveLengths();
        return lens[lens.length - 1];
    }

    public function updateArcLengths(): Void {
        this.needsUpdate = true;
        this.cacheLengths = null;
        this.getCurveLengths();
    }

    public function getCurveLengths(): Array<Float> {
        if (this.cacheLengths != null && this.cacheLengths.length == this.curves.length) {
            return this.cacheLengths;
        }

        var lengths = [];
        var sums = 0.0;

        for (var i = 0; i < this.curves.length; i++) {
            sums += this.curves[i].getLength();
            lengths.push(sums);
        }

        this.cacheLengths = lengths;

        return lengths;
    }

    public function getSpacedPoints(divisions: Int = 40): Array<Vector3> {
        var points = [];

        for (var i = 0; i <= divisions; i++) {
            points.push(this.getPoint(i / divisions));
        }

        if (this.autoClose) {
            points.push(points[0]);
        }

        return points;
    }

    public function getPoints(divisions: Int = 12): Array<Vector3> {
        var points = [];
        var last: Vector3 = null;

        for (var i = 0; i < this.curves.length; i++) {
            var curve = this.curves[i];
            var resolution = curve is EllipseCurve ? divisions * 2
                                                  : (curve is LineCurve || curve is LineCurve3) ? 1
                                                  : curve is SplineCurve ? divisions * curve.points.length
                                                  : divisions;

            var pts = curve.getPoints(resolution);

            for (var j = 0; j < pts.length; j++) {
                var point = pts[j];

                if (last != null && last.equals(point)) continue;

                points.push(point);
                last = point;
            }
        }

        if (this.autoClose && points.length > 1 && !points[points.length - 1].equals(points[0])) {
            points.push(points[0]);
        }

        return points;
    }

    public function copy(source: CurvePath): CurvePath {
        super.copy(source);

        this.curves = [];

        for (var i = 0; i < source.curves.length; i++) {
            var curve = source.curves[i];
            this.curves.push(curve.clone());
        }

        this.autoClose = source.autoClose;

        return this;
    }

    public function toJSON(): Dynamic {
        var data = super.toJSON();

        data.autoClose = this.autoClose;
        data.curves = [];

        for (var i = 0; i < this.curves.length; i++) {
            var curve = this.curves[i];
            data.curves.push(curve.toJSON());
        }

        return data;
    }

    public function fromJSON(json: Dynamic): CurvePath {
        super.fromJSON(json);

        this.autoClose = json.autoClose;
        this.curves = [];

        for (var i = 0; i < json.curves.length; i++) {
            var curve = json.curves[i];
            this.curves.push(Type.createInstance(Type.resolveClass(Curves), Type.resolveClass(curve.type), []).fromJSON(curve));
        }

        return this;
    }
}