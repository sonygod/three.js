import js.Browser.document;
import three.math.Vector3;
import three.extras.core.Curve;

class CubicPoly {
    private var c0:Float = 0.0;
    private var c1:Float = 0.0;
    private var c2:Float = 0.0;
    private var c3:Float = 0.0;

    public function init(x0:Float, x1:Float, t0:Float, t1:Float):Void {
        c0 = x0;
        c1 = t0;
        c2 = - 3.0 * x0 + 3.0 * x1 - 2.0 * t0 - t1;
        c3 = 2.0 * x0 - 2.0 * x1 + t0 + t1;
    }

    public function initCatmullRom(x0:Float, x1:Float, x2:Float, x3:Float, tension:Float):Void {
        init(x1, x2, tension * (x2 - x0), tension * (x3 - x1));
    }

    public function initNonuniformCatmullRom(x0:Float, x1:Float, x2:Float, x3:Float, dt0:Float, dt1:Float, dt2:Float):Void {
        var t1 = (x1 - x0) / dt0 - (x2 - x0) / (dt0 + dt1) + (x2 - x1) / dt1;
        var t2 = (x2 - x1) / dt1 - (x3 - x1) / (dt1 + dt2) + (x3 - x2) / dt2;

        t1 *= dt1;
        t2 *= dt1;

        init(x1, x2, t1, t2);
    }

    public function calc(t:Float):Float {
        var t2 = t * t;
        var t3 = t2 * t;
        return c0 + c1 * t + c2 * t2 + c3 * t3;
    }
}

var tmp:Vector3 = new Vector3();
var px:CubicPoly = new CubicPoly();
var py:CubicPoly = new CubicPoly();
var pz:CubicPoly = new CubicPoly();

class CatmullRomCurve3 extends Curve {
    public var points:Array<Vector3> = [];
    public var closed:Bool = false;
    public var curveType:String = 'centripetal';
    public var tension:Float = 0.5;

    public function new(points:Array<Vector3> = [], closed:Bool = false, curveType:String = 'centripetal', tension:Float = 0.5) {
        super();

        this.points = points;
        this.closed = closed;
        this.curveType = curveType;
        this.tension = tension;
    }

    public function getPoint(t:Float, optionalTarget:Vector3 = null):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();

        var l = this.points.length;

        var p = (l - (this.closed ? 0 : 1)) * t;
        var intPoint = Math.floor(p);
        var weight = p - intPoint;

        if (this.closed) {
            intPoint += intPoint > 0 ? 0 : (Math.floor(Math.abs(intPoint) / l) + 1) * l;
        } else if (weight == 0.0 && intPoint == l - 1) {
            intPoint = l - 2;
            weight = 1.0;
        }

        var p0:Vector3, p3:Vector3;

        if (this.closed || intPoint > 0) {
            p0 = this.points[(intPoint - 1) % l];
        } else {
            tmp.subVectors(this.points[0], this.points[1]).add(this.points[0]);
            p0 = tmp;
        }

        var p1 = this.points[intPoint % l];
        var p2 = this.points[(intPoint + 1) % l];

        if (this.closed || intPoint + 2 < l) {
            p3 = this.points[(intPoint + 2) % l];
        } else {
            tmp.subVectors(this.points[l - 1], this.points[l - 2]).add(this.points[l - 1]);
            p3 = tmp;
        }

        if (this.curveType == 'centripetal' || this.curveType == 'chordal') {
            var pow = this.curveType == 'chordal' ? 0.5 : 0.25;
            var dt0 = Math.pow(p0.distanceToSquared(p1), pow);
            var dt1 = Math.pow(p1.distanceToSquared(p2), pow);
            var dt2 = Math.pow(p2.distanceToSquared(p3), pow);

            if (dt1 < 1e-4) dt1 = 1.0;
            if (dt0 < 1e-4) dt0 = dt1;
            if (dt2 < 1e-4) dt2 = dt1;

            px.initNonuniformCatmullRom(p0.x, p1.x, p2.x, p3.x, dt0, dt1, dt2);
            py.initNonuniformCatmullRom(p0.y, p1.y, p2.y, p3.y, dt0, dt1, dt2);
            pz.initNonuniformCatmullRom(p0.z, p1.z, p2.z, p3.z, dt0, dt1, dt2);
        } else if (this.curveType == 'catmullrom') {
            px.initCatmullRom(p0.x, p1.x, p2.x, p3.x, this.tension);
            py.initCatmullRom(p0.y, p1.y, p2.y, p3.y, this.tension);
            pz.initCatmullRom(p0.z, p1.z, p2.z, p3.z, this.tension);
        }

        point.set(px.calc(weight), py.calc(weight), pz.calc(weight));

        return point;
    }

    public function copy(source:CatmullRomCurve3):CatmullRomCurve3 {
        super.copy(source);

        this.points = [];

        for (point in source.points) {
            this.points.push(point.clone());
        }

        this.closed = source.closed;
        this.curveType = source.curveType;
        this.tension = source.tension;

        return this;
    }

    public function toJSON():Dynamic {
        var data = super.toJSON();

        data.points = [];

        for (point in this.points) {
            data.points.push(point.toArray());
        }

        data.closed = this.closed;
        data.curveType = this.curveType;
        data.tension = this.tension;

        return data;
    }

    public function fromJSON(json:Dynamic):CatmullRomCurve3 {
        super.fromJSON(json);

        this.points = [];

        for (point in json.points) {
            this.points.push(new Vector3().fromArray(point));
        }

        this.closed = json.closed;
        this.curveType = json.curveType;
        this.tension = json.tension;

        return this;
    }
}