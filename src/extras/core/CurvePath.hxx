package three.js.src.extras.core;

import three.js.src.curves.Curves;
import three.js.src.extras.core.Curve;

class CurvePath extends Curve {

    public var curves:Array<Curve>;
    public var autoClose:Bool;
    private var cacheLengths:Array<Float>;

    public function new() {
        super();
        this.type = 'CurvePath';
        this.curves = [];
        this.autoClose = false;
    }

    public function add(curve:Curve) {
        this.curves.push(curve);
    }

    public function closePath():CurvePath {
        var startPoint = this.curves[0].getPoint(0);
        var endPoint = this.curves[this.curves.length - 1].getPoint(1);
        if (!startPoint.equals(endPoint)) {
            var lineType = (startPoint.isVector2 == true) ? 'LineCurve' : 'LineCurve3';
            this.curves.push(Type.createInstance(Curves[lineType], [endPoint, startPoint]));
        }
        return this;
    }

    public function getPoint(t:Float, optionalTarget:Dynamic = null):Dynamic {
        var d = t * this.getLength();
        var curveLengths = this.getCurveLengths();
        var i = 0;
        while (i < curveLengths.length) {
            if (curveLengths[i] >= d) {
                var diff = curveLengths[i] - d;
                var curve = this.curves[i];
                var segmentLength = curve.getLength();
                var u = (segmentLength == 0) ? 0 : 1 - diff / segmentLength;
                return curve.getPointAt(u, optionalTarget);
            }
            i++;
        }
        return null;
    }

    public function getLength():Float {
        var lens = this.getCurveLengths();
        return lens[lens.length - 1];
    }

    public function updateArcLengths() {
        this.needsUpdate = true;
        this.cacheLengths = null;
        this.getCurveLengths();
    }

    public function getCurveLengths():Array<Float> {
        if (this.cacheLengths != null && this.cacheLengths.length == this.curves.length) {
            return this.cacheLengths;
        }
        var lengths = [];
        var sums = 0;
        for (i in this.curves) {
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
        for (i in this.curves) {
            var curve = this.curves[i];
            var resolution = (curve.isEllipseCurve) ? divisions * 2 : ((curve.isLineCurve || curve.isLineCurve3) ? 1 : ((curve.isSplineCurve) ? divisions * curve.points.length : divisions));
            var pts = curve.getPoints(resolution);
            for (j in pts) {
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

    public function copy(source:CurvePath):CurvePath {
        super.copy(source);
        this.curves = [];
        for (i in source.curves) {
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
        for (i in this.curves) {
            var curve = this.curves[i];
            data.curves.push(curve.toJSON());
        }
        return data;
    }

    public function fromJSON(json:Dynamic):CurvePath {
        super.fromJSON(json);
        this.autoClose = json.autoClose;
        this.curves = [];
        for (i in json.curves) {
            var curve = json.curves[i];
            this.curves.push(Type.createInstance(Curves[curve.type], []).fromJSON(curve));
        }
        return this;
    }
}