import three.math.Vector3;
import three.extras.core.Curve;

class CubicPoly {
    private var c0:Float = 0;
    private var c1:Float = 0;
    private var c2:Float = 0;
    private var c3:Float = 0;

    private function init(x0:Float, x1:Float, t0:Float, t1:Float):Void {
        c0 = x0;
        c1 = t0;
        c2 = -3 * x0 + 3 * x1 - 2 * t0 - t1;
        c3 = 2 * x0 - 2 * x1 + t0 + t1;
    }

    public function new() {}

    public function initCatmullRom(x0:Float, x1:Float, x2:Float, x3:Float, tension:Float):Void {
        init(x1, x2, tension * (x2 - x0), tension * (x3 - x1));
    }

    public function initNonuniformCatmullRom(x0:Float, x1:Float, x2:Float, x3:Float, dt0:Float, dt1:Float, dt2:Float):Void {
        var t1:Float = (x1 - x0) / dt0 - (x2 - x0) / (dt0 + dt1) + (x2 - x1) / dt1;
        var t2:Float = (x2 - x1) / dt1 - (x3 - x1) / (dt1 + dt2) + (x3 - x2) / dt2;

        t1 *= dt1;
        t2 *= dt1;

        init(x1, x2, t1, t2);
    }

    public function calc(t:Float):Float {
        var t2:Float = t * t;
        var t3:Float = t2 * t;
        return c0 + c1 * t + c2 * t2 + c3 * t3;
    }
}

class CatmullRomCurve3 extends Curve {
    public var points:Array<Vector3>;
    public var closed:Bool;
    public var curveType:String;
    public var tension:Float;

    private var tmp:Vector3 = new Vector3();
    private var px:CubicPoly = new CubicPoly();
    private var py:CubicPoly = new CubicPoly();
    private var pz:CubicPoly = new CubicPoly();

    public function new(points:Array<Vector3> = [], closed:Bool = false, curveType:String = 'centripetal', tension:Float = 0.5) {
        super();
        this.points = points;
        this.closed = closed;
        this.curveType = curveType;
        this.tension = tension;
    }

    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point:Vector3 = optionalTarget;

        var l:Int = points.length;
        var p:Float = (l - (closed ? 0 : 1)) * t;
        var intPoint:Int = Math.floor(p);
        var weight:Float = p - intPoint;

        if (closed) {
            intPoint += intPoint > 0 ? 0 : (Math.floor(Math.abs(intPoint) / l) + 1) * l;
        } else if (weight == 0 && intPoint == l - 1) {
            intPoint = l - 2;
            weight = 1;
        }

        var p0:Vector3;
        var p3:Vector3;

        if (closed || intPoint > 0) {
            p0 = points[(intPoint - 1) % l];
        } else {
            tmp.subVectors(points[0], points[1]).add(points[0]);
            p0 = tmp;
        }

        var p1:Vector3 = points[intPoint % l];
        var p2:Vector3 = points[(intPoint + 1) % l];

        if (closed || intPoint + 2 < l) {
            p3 = points[(intPoint + 2) % l];
        } else {
            tmp.subVectors(points[l - 1], points[l - 2]).add(points[l - 1]);
            p3 = tmp;
        }

        if (curveType == 'centripetal' || curveType == 'chordal') {
            var pow:Float = curveType == 'chordal' ? 0.5 : 0.25;
            var dt0:Float = Math.pow(p0.distanceToSquared(p1), pow);
            var dt1:Float = Math.pow(p1.distanceToSquared(p2), pow);
            var dt2:Float = Math.pow(p2.distanceToSquared(p3), pow);

            if (dt1 < 1e-4) dt1 = 1.0;
            if (dt0 < 1e-4) dt0 = dt1;
            if (dt2 < 1e-4) dt2 = dt1;

            px.initNonuniformCatmullRom(p0.x, p1.x, p2.x, p3.x, dt0, dt1, dt2);
            py.initNonuniformCatmullRom(p0.y, p1.y, p2.y, p3.y, dt0, dt1, dt2);
            pz.initNonuniformCatmullRom(p0.z, p1.z, p2.z, p3.z, dt0, dt1, dt2);
        } else if (curveType == 'catmullrom') {
            px.initCatmullRom(p0.x, p1.x, p2.x, p3.x, tension);
            py.initCatmullRom(p0.y, p1.y, p2.y, p3.y, tension);
            pz.initCatmullRom(p0.z, p1.z, p2.z, p3.z, tension);
        }

        point.set(px.calc(weight), py.calc(weight), pz.calc(weight));

        return point;
    }

    public function copy(source:CatmullRomCurve3):CatmullRomCurve3 {
        super.copy(source);

        this.points = [];
        for (i in 0...source.points.length) {
            var point = source.points[i];
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
        for (i in 0...points.length) {
            var point = points[i];
            data.points.push(point.toArray());
        }

        data.closed = closed;
        data.curveType = curveType;
        data.tension = tension;

        return data;
    }

    public function fromJSON(json:Dynamic):CatmullRomCurve3 {
        super.fromJSON(json);

        this.points = [];
        for (i in 0...json.points.length) {
            var point = json.points[i];
            this.points.push(new Vector3().fromArray(point));
        }

        this.closed = json.closed;
        this.curveType = json.curveType;
        this.tension = json.tension;

        return this;
    }
}