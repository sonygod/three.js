import js.Curve;
import js.Curves.*;

class CurvePath extends js.Curve {
    public var curves:Array<js.Curve>;
    public var autoClose:Bool;

    public function new() {
        super();
        type = 'CurvePath';
        curves = [];
        autoClose = false;
    }

    public function add(curve:js.Curve) {
        curves.push(curve);
    }

    public function closePath():Void {
        var startPoint = curves[0].getPoint(0);
        var endPoint = curves[curves.length - 1].getPoint(1);

        if (!startPoint.equals(endPoint)) {
            var lineType = (startPoint as Dynamic).isVector2 ? 'LineCurve' : 'LineCurve3';
            curves.push(Type.createInstance(js.Curves, lineType, [endPoint, startPoint]));
        }
    }

    public function getPoint(t:Float, ?optionalTarget:Dynamic):Dynamic {
        var d = t * getLength();
        var curveLengths = getCurveLengths();
        var i = 0;

        while (i < curveLengths.length) {
            if (curveLengths[i] >= d) {
                var diff = curveLengths[i] - d;
                var curve = curves[i];
                var segmentLength = curve.getLength();
                var u = (if (segmentLength == 0) 0 else 1 - diff / segmentLength);
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
        needsUpdate = true;
        cacheLengths = null;
        getCurveLengths();
    }

    public function getCurveLengths():Array<Float> {
        if (cacheLengths != null && cacheLengths.length == curves.length) {
            return cacheLengths;
        }

        var lengths = [];
        var sums:Float = 0;

        for (i in 0...curves.length) {
            sums += curves[i].getLength();
            lengths.push(sums);
        }

        cacheLengths = lengths;
        return lengths;
    }

    public function getSpacedPoints(divisions:Int = 40):Array<Dynamic> {
        var points = [];

        for (i in 0...(divisions + 1)) {
            points.push(getPoint(i / divisions));
        }

        if (autoClose) {
            points.push(points[0]);
        }

        return points;
    }

    public function getPoints(divisions:Int = 12):Array<Dynamic> {
        var points = [];
        var last:Dynamic;

        for (i in 0...curves.length) {
            var curve = curves[i];
            var resolution = (if (curve.isEllipseCurve) divisions * 2 else (if (curve.isLineCurve || curve.isLineCurve3) 1 else (if (curve.isSplineCurve) divisions * curve.points.length else divisions)));
            var pts = curve.getPoints(resolution);

            for (j in 0...pts.length) {
                var point = pts[j];
                if (last != null && last.equals(point)) continue;
                points.push(point);
                last = point;
            }
        }

        if (autoClose && points.length > 1 && !points[points.length - 1].equals(points[0])) {
            points.push(points[0]);
        }

        return points;
    }

    public function copy(source:CurvePath):Void {
        super.copy(source);
        curves = [];

        for (i in 0...source.curves.length) {
            var curve = source.curves[i];
            curves.push(curve.clone());
        }

        autoClose = source.autoClose;
    }

    public function toJSON():Dynamic {
        var data = super.toJSON();
        data.autoClose = autoClose;
        data.curves = [];

        for (i in 0...curves.length) {
            var curve = curves[i];
            data.curves.push(curve.toJSON());
        }

        return data;
    }

    public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);
        autoClose = json.autoClose;
        curves = [];

        for (i in 0...json.curves.length) {
            var curve = json.curves[i];
            curves.push(Type.createInstance(js.Curves, curve.type, []).fromJSON(curve));
        }
    }
}