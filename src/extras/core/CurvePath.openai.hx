import curves.Curve;
import curves.Curves;
import curves.LineCurve;
import curves.LineCurve3;

class CurvePath extends Curve {

    public var curves:Array<Curve>;
    public var autoClose:Bool;

    public function new() {
        super();
        this.type = "CurvePath";
        this.curves = new Array<Curve>();
        this.autoClose = false;
    }

    public function add(curve:Curve):Void {
        curves.push(curve);
    }

    public function closePath():Void {
        var startPoint = curves[0].getPoint(0);
        var endPoint = curves[curves.length - 1].getPoint(1);
        
        if (!startPoint.equals(endPoint)) {
            var lineType = startPoint.isVector2 ? "LineCurve" : "LineCurve3";
            curves.push(new Curves.([lineType])(endPoint, startPoint));
        }
    }

    public function getPoint(t:Float, ?optionalTarget):Null<Vector> {
        var d = t * getLength();
        var curveLengths = getCurveLengths();
        var i = 0;

        while (i < curveLengths.length) {
            if (curveLengths[i] >= d) {
                var diff = curveLengths[i] - d;
                var curve = curves[i];
                var segmentLength = curve.getLength();
                var u:Float = segmentLength == 0 ? 0 : 1 - diff / segmentLength;

                return curve.getPointAt(u, optionalTarget);
            }
            i++;
        }

        return null;
    }

    public function getLength():Float {
        var lens = getCurveLengths();
        return lens[lens.length - 1];
    }

    public function updateArcLengths():Void {
        this.needsUpdate = true;
        this.cacheLengths = null;
        this.getCurveLengths();
    }

    public function getCurveLengths():Array<Float> {
        if (this.cacheLengths != null && this.cacheLengths.length == this.curves.length) {
            return this.cacheLengths;
        }

        var lengths = new Array<Float>();
        var sums:Float = 0;

        for (i in 0...curves.length) {
            sums += curves[i].getLength();
            lengths.push(sums);
        }

        this.cacheLengths = lengths;

        return lengths;
    }

    public function getSpacedPoints(?divisions:Int = 40):Array<Vector> {
        var points = new Array<Vector>();

        for (i in 0...divisions + 1) {
            points.push(getPoint(i / divisions));
        }

        if (this.autoClose) {
            points.push(points[0]);
        }

        return points;
    }

    public function getPoints(?divisions:Int = 12):Array<Vector> {
        var points = new Array<Vector>();
        var last:Vector;

        for (curve in curves) {
            var resolution = curve.isEllipseCurve ? divisions * 2 :
                (curve.isLineCurve || curve.isLineCurve3) ? 1 :
                curve.isSplineCurve ? divisions * curve.points.length :
                divisions;

            var pts = curve.getPoints(resolution);

            for (point in pts) {
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

    public function copy(source:CurvePath):CurvePath {
        super.copy(source);
        this.curves = [];

        for (curve in source.curves) {
            this.curves.push(curve.clone());
        }

        this.autoClose = source.autoClose;

        return this;
    }

    public override function toJSON():Dynamic {
        var data = super.toJSON();
        data.autoClose = this.autoClose;
        data.curves = [];

        for (curve in this.curves) {
            data.curves.push(curve.toJSON());
        }

        return data;
    }

    public override function fromJSON(json:Dynamic):Dynamic {
        super.fromJSON(json);
        this.autoClose = json.autoClose;
        this.curves = [];

        for (curve in json.curves) {
            this.curves.push(new Curves[curve.type]().fromJSON(curve));
        }

        return this;
    }

}