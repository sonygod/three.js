import three.extras.core.Curve;
import three.extras.curves.Curves;

/**************************************************************
 *  Curved Path - a curve path is simply a array of connected
 *  curves, but retains the api of a curve
 **************************************************************/

class CurvePath extends Curve {

    public var type:String;
    public var curves:Array<Curve>;
    public var autoClose:Bool;
    private var cacheLengths:Array<Float>;

    public function new() {
        super();
        this.type = 'CurvePath';
        this.curves = [];
        this.autoClose = false; // Automatically closes the path
        this.cacheLengths = null;
    }

    public function add(curve:Curve):Void {
        this.curves.push(curve);
    }

    public function closePath():CurvePath {
        // Add a line curve if start and end of lines are not connected
        var startPoint = this.curves[0].getPoint(0);
        var endPoint = this.curves[this.curves.length - 1].getPoint(1);

        if (!startPoint.equals(endPoint)) {
            var lineType = (startPoint.isVector2 == true) ? 'LineCurve' : 'LineCurve3';
            this.curves.push(Type.createInstance(Reflect.field(Curves, lineType), [endPoint, startPoint]));
        }

        return this;
    }

    public function getPoint(t:Float, optionalTarget:Dynamic = null):Dynamic {
        var d = t * this.getLength();
        var curveLengths = this.getCurveLengths();
        var i = 0;

        // To think about boundaries points.
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

        // loop where sum != 0, sum > d , sum+1 <d
    }

    public function getLength():Float {
        var lens = this.getCurveLengths();
        return lens[lens.length - 1];
    }

    public function updateArcLengths():Void {
        this.needsUpdate = true;
        this.cacheLengths = null;
        this.getCurveLengths();
    }

    public function getCurveLengths():Array<Float> {
        // We use cache values if curves and cache array are same length
        if (this.cacheLengths != null && this.cacheLengths.length == this.curves.length) {
            return this.cacheLengths;
        }

        // Get length of sub-curve
        // Push sums into cached array
        var lengths = [];
        var sums = 0;

        for (i in 0...this.curves.length) {
            sums += this.curves[i].getLength();
            lengths.push(sums);
        }

        this.cacheLengths = lengths;
        return lengths;
    }

    public function getSpacedPoints(divisions:Int = 40):Array<Dynamic> {
        var points = [];

        for (i in 0...divisions + 1) {
            points.push(this.getPoint(i / divisions));
        }

        if (this.autoClose) {
            points.push(points[0]);
        }

        return points;
    }

    public function getPoints(divisions:Int = 12):Array<Dynamic> {
        var points = [];
        var last:Dynamic = null;

        for (i in 0...this.curves.length) {
            var curve = this.curves[i];
            var resolution = curve.isEllipseCurve ? divisions * 2 :
                             (curve.isLineCurve || curve.isLineCurve3) ? 1 :
                             curve.isSplineCurve ? divisions * curve.points.length :
                             divisions;

            var pts = curve.getPoints(resolution);

            for (j in 0...pts.length) {
                var point = pts[j];

                if (last != null && last.equals(point)) continue; // ensures no consecutive points are duplicates

                points.push(point);
                last = point;
            }
        }

        if (this.autoClose && points.length > 1 && !points[points.length - 1].equals(points[0])) {
            points.push(points[0]);
        }

        return points;
    }

    public function copy(source:CurvePath):CurvePath {
        super.copy(source);

        this.curves = [];

        for (i in 0...source.curves.length) {
            var curve = source.curves[i];
            this.curves.push(curve.clone());
        }

        this.autoClose = source.autoClose;

        return this;
    }

    public function toJSON():Dynamic {
        var data = super.toJSON();

        data.autoClose = this.autoClose;
        data.curves = [];

        for (i in 0...this.curves.length) {
            var curve = this.curves[i];
            data.curves.push(curve.toJSON());
        }

        return data;
    }

    public function fromJSON(json:Dynamic):CurvePath {
        super.fromJSON(json);

        this.autoClose = json.autoClose;
        this.curves = [];

        for (i in 0...json.curves.length) {
            var curve = json.curves[i];
            this.curves.push(Type.createInstance(Reflect.field(Curves, curve.type), []).fromJSON(curve));
        }

        return this;
    }

}