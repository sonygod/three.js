package three.js.src.extras.core;

import three.js.src.extras.core.Curve;

class CurvePath extends Curve {
    public var type(default, null):String = 'CurvePath';
    public var curves:Array<Curve> = [];
    public var autoClose:Bool = false; // Automatically closes the path
    private var cacheLengths:Array<Float> = null;

    public function new() {
        super();
    }

    public function add(curve:Curve):Void {
        curves.push(curve);
    }

    public function closePath():CurvePath {
        // Add a line curve if start and end of lines are not connected
        var startPoint:Vector = curves[0].getPoint(0);
        var endPoint:Vector = curves[curves.length - 1].getPoint(1);

        if (!startPoint.equals(endPoint)) {
            var lineType:String = startPoint.isVector2 ? 'LineCurve' : 'LineCurve3';
            curves.push(Type.createInstance(Type.resolveClass('curves.' + lineType), [endPoint, startPoint]));
        }

        return this;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector):Vector {
        var d:Float = t * getLength();
        var curveLengths:Array<Float> = getCurveLengths();
        var i:Int = 0;

        // To think about boundaries points.

        while (i < curveLengths.length) {
            if (curveLengths[i] >= d) {
                var diff:Float = curveLengths[i] - d;
                var curve:Curve = curves[i];

                var segmentLength:Float = curve.getLength();
                var u:Float = segmentLength == 0 ? 0 : 1 - diff / segmentLength;

                return curve.getPointAt(u, optionalTarget);
            }

            i++;
        }

        return null;
    }

    public function getLength():Float {
        var lens:Array<Float> = getCurveLengths();
        return lens[lens.length - 1];
    }

    public function updateArcLengths():Void {
        needsUpdate = true;
        cacheLengths = null;
        getCurveLengths();
    }

    public function getCurveLengths():Array<Float> {
        // We use cache values if curves and cache array are same length
        if (cacheLengths != null && cacheLengths.length == curves.length) {
            return cacheLengths;
        }

        // Get length of sub-curve
        // Push sums into cached array
        var lengths:Array<Float> = [];
        var sums:Float = 0;

        for (i in 0...curves.length) {
            sums += curves[i].getLength();
            lengths.push(sums);
        }

        cacheLengths = lengths;

        return lengths;
    }

    public function getSpacedPoints(divisions:Int = 40):Array<Vector> {
        var points:Array<Vector> = [];

        for (i in 0...divisions + 1) {
            points.push(getPoint(i / divisions));
        }

        if (autoClose) {
            points.push(points[0]);
        }

        return points;
    }

    public function getPoints(divisions:Int = 12):Array<Vector> {
        var points:Array<Vector> = [];
        var last:Vector = null;

        for (curve in curves) {
            var resolution:Int = curve.isEllipseCurve ? divisions * 2
                : curve.isLineCurve || curve.isLineCurve3 ? 1
                    : curve.isSplineCurve ? divisions * curve.points.length
                        : divisions;

            var pts:Array<Vector> = curve.getPoints(resolution);

            for (pt in pts) {
                if (last != null && last.equals(pt)) continue; // ensures no consecutive points are duplicates

                points.push(pt);
                last = pt;
            }
        }

        if (autoClose && points.length > 1 && !points[points.length - 1].equals(points[0])) {
            points.push(points[0]);
        }

        return points;
    }

    public function copy(source:CurvePath):CurvePath {
        super.copy(source);

        curves = [];

        for (curve in source.curves) {
            curves.push(curve.clone());
        }

        autoClose = source.autoClose;

        return this;
    }

    public function toJSON():Dynamic {
        var data:Dynamic = super.toJSON();

        data.autoClose = autoClose;
        data.curves = [];

        for (curve in curves) {
            data.curves.push(curve.toJSON());
        }

        return data;
    }

    public function fromJSON(json:Dynamic):CurvePath {
        super.fromJSON(json);

        autoClose = json.autoClose;
        curves = [];

        for (curve in json.curves) {
            curves.push(Type.createInstance(Type.resolveClass('curves.' + curve.type), []).fromJSON(curve));
        }

        return this;
    }
}