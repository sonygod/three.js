package three.js.src.extras.core;

import three.js.src.extras.curves.Curve;

class CurvePath extends Curve {
    public var curves:Array<Curve> = [];
    public var autoClose:Bool = false;

    public function new() {
        super();
        this.type = 'CurvePath';
    }

    public function add(curve:Curve):Void {
        this.curves.push(curve);
    }

    public function closePath():CurvePath {
        var startPoint:Vector2 = this.curves[0].getPoint(0);
        var endPoint:Vector2 = this.curves[this.curves.length - 1].getPoint(1);
        if (!startPoint.equals(endPoint)) {
            var lineType:String = (startPoint.isVector2 ? 'LineCurve' : 'LineCurve3');
            this.curves.push(new Curves[lineType](endPoint, startPoint));
        }
        return this;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector2):Vector2 {
        var d:Float = t * this.getLength();
        var curveLengths:Array<Float> = this.getCurveLengths();
        var i:Int = 0;

        while (i < curveLengths.length) {
            if (curveLengths[i] >= d) {
                var diff:Float = curveLengths[i] - d;
                var curve:Curve = this.curves[i];
                var segmentLength:Float = curve.getLength();
                var u:Float = segmentLength == 0 ? 0 : 1 - diff / segmentLength;
                return curve.getPointAt(u, optionalTarget);
            }
            i++;
        }
        return null;
    }

    public function getLength():Float {
        var lens:Array<Float> = this.getCurveLengths();
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

        var lengths:Array<Float> = [];
        var sums:Float = 0;
        for (i in 0...this.curves.length) {
            sums += this.curves[i].getLength();
            lengths.push(sums);
        }

        this.cacheLengths = lengths;
        return lengths;
    }

    public function getSpacedPoints(divisions:Int = 40):Array<Vector2> {
        var points:Array<Vector2> = [];
        for (i in 0...divisions + 1) {
            points.push(this.getPoint(i / divisions));
        }
        if (autoClose) {
            points.push(points[0]);
        }
        return points;
    }

    public function getPoints(divisions:Int = 12):Array<Vector2> {
        var points:Array<Vector2> = [];
        var last:Vector2;
        for (curve in this.curves) {
            var resolution:Int = curve.isEllipseCurve ? divisions * 2
                : (curve.isLineCurve || curve.isLineCurve3) ? 1
                    : curve.isSplineCurve ? divisions * curve.points.length
                        : divisions;
            var pts:Array<Vector2> = curve.getPoints(resolution);
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
            curves.push(new Curves[curve.type]().fromJSON(curve));
        }
        return this;
    }
}