import Vector2 from math/Vector2.hx;
import CurvePath from './CurvePath.hx';
import EllipseCurve from '../curves/EllipseCurve.hx';
import SplineCurve from '../curves/SplineCurve.hx';
import CubicBezierCurve from '../curves/CubicBezierCurve.hx';
import QuadraticBezierCurve from '../curves/QuadraticBezierCurve.hx';
import LineCurve from '../curves/LineCurve.hx';

class Path extends CurvePath {
    public var currentPoint:Vector2;

    public function new(points:Array<Vector2>) {
        super();
        this.type = 'Path';
        this.currentPoint = new Vector2();
        if (points != null) {
            this.setFromPoints(points);
        }
    }

    public function setFromPoints(points:Array<Vector2>):Path {
        this.moveTo(points[0].x, points[0].y);
        for (i in 1...points.length) {
            this.lineTo(points[i].x, points[i].y);
        }
        return this;
    }

    public function moveTo(x:Float, y:Float):Path {
        this.currentPoint.set(x, y);
        return this;
    }

    public function lineTo(x:Float, y:Float):Path {
        var curve = new LineCurve(this.currentPoint.clone(), new Vector2(x, y));
        this.curves.push(curve);
        this.currentPoint.set(x, y);
        return this;
    }

    public function quadraticCurveTo(aCPx:Float, aCPy:Float, aX:Float, aY:Float):Path {
        var curve = new QuadraticBezierCurve(this.currentPoint.clone(), new Vector2(aCPx, aCPy), new Vector2(aX, aY));
        this.curves.push(curve);
        this.currentPoint.set(aX, aY);
        return this;
    }

    public function bezierCurveTo(aCP1x:Float, aCP1y:Float, aCP2x:Float, aCP2y:Float, aX:Float, aY:Float):Path {
        var curve = new CubicBezierCurve(this.currentPoint.clone(), new Vector2(aCP1x, aCP1y), new Vector2(aCP2x, aCP2y), new Vector2(aX, aY));
        this.curves.push(curve);
        this.currentPoint.set(aX, aY);
        return this;
    }

    public function splineThru(pts:Array<Vector2>):Path {
        var npts = [this.currentPoint.clone()].concat(pts);
        var curve = new SplineCurve(npts);
        this.curves.push(curve);
        this.currentPoint.copy(pts[pts.length - 1]);
        return this;
    }

    public function arc(aX:Float, aY:Float, aRadius:Float, aStartAngle:Float, aEndAngle:Float, aClockwise:Bool):Path {
        var x0 = this.currentPoint.x;
        var y0 = this.currentPoint.y;
        this.absarc(aX + x0, aY + y0, aRadius, aStartAngle, aEndAngle, aClockwise);
        return this;
    }

    public function absarc(aX:Float, aY:Float, aRadius:Float, aStartAngle:Float, aEndAngle:Float, aClockwise:Bool):Path {
        this.absellipse(aX, aY, aRadius, aRadius, aStartAngle, aEndAngle, aClockwise);
        return this;
    }

    public function ellipse(aX:Float, aY:Float, xRadius:Float, yRadius:Float, aStartAngle:Float, aEndAngle:Float, aClockwise:Bool, aRotation:Float):Path {
        var x0 = this.currentPoint.x;
        var y0 = this.currentPoint.y;
        this.absellipse(aX + x0, aY + y0, xRadius, yRadius, aStartAngle, aEndAngle, aClockwise, aRotation);
        return this;
    }

    public function absellipse(aX:Float, aY:Float, xRadius:Float, yRadius:Float, aStartAngle:Float, aEndAngle:Float, aClockwise:Bool, aRotation:Float):Path {
        var curve = new EllipseCurve(aX, aY, xRadius, yRadius, aStartAngle, aEndAngle, aClockwise, aRotation);
        if (this.curves.length > 0) {
            var firstPoint = curve.getPoint(0);
            if (!firstPoint.equals(this.currentPoint)) {
                this.lineTo(firstPoint.x, firstPoint.y);
            }
        }
        this.curves.push(curve);
        var lastPoint = curve.getPoint(1);
        this.currentPoint.copy(lastPoint);
        return this;
    }

    public function copy(source:Path):Path {
        super.copy(source);
        this.currentPoint.copy(source.currentPoint);
        return this;
    }

    public function toJSON():Object {
        var data = super.toJSON();
        data.currentPoint = this.currentPoint.toArray();
        return data;
    }

    public function fromJSON(json:Object):Path {
        super.fromJSON(json);
        this.currentPoint.fromArray(json.currentPoint);
        return this;
    }
}

export { Path };