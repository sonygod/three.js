import Vector3 from "../../math/Vector3.hx";
import Curve from "../core/Curve.hx";

class CubicPoly {
  var c0: Float;
  var c1: Float;
  var c2: Float;
  var c3: Float;

  public function new() {
    this.c0 = 0;
    this.c1 = 0;
    this.c2 = 0;
    this.c3 = 0;
  }

  public function init(x0: Float, x1: Float, t0: Float, t1: Float): Void {
    this.c0 = x0;
    this.c1 = t0;
    this.c2 = -3 * x0 + 3 * x1 - 2 * t0 - t1;
    this.c3 = 2 * x0 - 2 * x1 + t0 + t1;
  }

  public function initCatmullRom(
    x0: Float,
    x1: Float,
    x2: Float,
    x3: Float,
    tension: Float
  ): Void {
    this.init(x1, x2, tension * (x2 - x0), tension * (x3 - x1));
  }

  public function initNonuniformCatmullRom(
    x0: Float,
    x1: Float,
    x2: Float,
    x3: Float,
    dt0: Float,
    dt1: Float,
    dt2: Float
  ): Void {
    var t1 = (x1 - x0) / dt0 - (x2 - x0) / (dt0 + dt1) + (x2 - x1) / dt1;
    var t2 = (x2 - x1) / dt1 - (x3 - x1) / (dt1 + dt2) + (x3 - x2) / dt2;

    t1 *= dt1;
    t2 *= dt1;

    this.init(x1, x2, t1, t2);
  }

  public function calc(t: Float): Float {
    return this.c0 + this.c1 * t + this.c2 * t * t + this.c3 * t * t * t;
  }
}

class CatmullRomCurve3 extends Curve {
  public var isCatmullRomCurve3: Bool;
  public var type: String;
  public var points: Array<Vector3>;
  public var closed: Bool;
  public var curveType: String;
  public var tension: Float;

  public function new(
    points: Array<Vector3> = [],
    closed: Bool = false,
    curveType: String = "centripetal",
    tension: Float = 0.5
  ) {
    super();
    this.isCatmullRomCurve3 = true;
    this.type = "CatmullRomCurve3";
    this.points = points;
    this.closed = closed;
    this.curveType = curveType;
    this.tension = tension;
  }

  public function getPoint(
    t: Float,
    optionalTarget: Vector3 = new Vector3()
  ): Vector3 {
    var point = optionalTarget;
    var l = this.points.length;
    var p = (l - (if (this.closed) 0 else 1)) * t;
    var intPoint = Std.floor(p);
    var weight = p - intPoint;

    if (this.closed) {
      intPoint += if (intPoint > 0) 0 else Std.floor(Std.abs(intPoint) / l) + 1;
    } else if (weight == 0 && intPoint == l - 1) {
      intPoint = l - 2;
      weight = 1;
    }

    var p0: Vector3;
    var p3: Vector3;

    if (this.closed || intPoint > 0) {
      p0 = this.points[(intPoint - 1) % l];
    } else {
      // extrapolate first point
      p0 = Vector3.subtract(
        this.points[0],
        this.points[1]
      ).add(this.points[0]);
    }

    var p1 = this.points[intPoint % l];
    var p2 = this.points[(intPoint + 1) % l];

    if (this.closed || intPoint + 2 < l) {
      p3 = this.points[(intPoint + 2) % l];
    } else {
      // extrapolate last point
      p3 = Vector3.subtract(
        this.points[l - 1],
        this.points[l - 2]
      ).add(this.points[l - 1]);
    }

    if (
      this.curveType == "centripetal" ||
      this.curveType == "chordal"
    ) {
      // init Centripetal / Chordal Catmull-Rom
      var pow = if (this.curveType == "chordal") 0.5 else 0.25;
      var dt0 = Math.pow(
        Vector3.distanceSquared(p0, p1),
        pow
      );
      var dt1 = Math.pow(
        Vector3.distanceSquared(p1, p2),
        pow
      );
      var dt2 = Math.pow(
        Vector3.distanceSquared(p2, p3),
        pow
      );

      // safety check for repeated points
      if (dt1 < 1e-4) dt1 = 1.0;
      if (dt0 < 1e-4) dt0 = dt1;
      if (dt2 < 1e-4) dt2 = dt1;

      var px = new CubicPoly();
      var py = new CubicPoly();
      var pz = new CubicPoly();

      px.initNonuniformCatmullRom(
        p0.x,
        p1.x,
        p2.x,
        p3.x,
        dt0,
        dt1,
        dt2
      );
      py.initNonuniformCatmullRom(
        p0.y,
        p1.y,
        p2.y,
        p3.y,
        dt0,
        dt1,
        dt2
      );
      pz.initNonuniformCatmullRom(
        p0.z,
        p1.z,
        p2.z,
        p3.z,
        dt0,
        dt1,
        dt2
      );
    } else if (this.curveType == "catmullrom") {
      var px = new CubicPoly();
      var py = new CubicPoly();
      var pz = new CubicPoly();

      px.initCatmullRom(p0.x, p1.x, p2.x, p3.x, this.tension);
      py.initCatmullRom(p0.y, p1.y, p2.y, p3.y, this.tension);
      pz.initCatmullRom(p0.z, p1.z, p2.z, p3.z, this.tension);
    }

    point.set(
      px.calc(weight),
      py.calc(weight),
      pz.calc(weight)
    );

    return point;
  }

  public function copy(source: CatmullRomCurve3): CatmullRomCurve3 {
    super.copy(source);
    this.points = [];

    for (i in 0...source.points.length) {
      this.points.push(source.points[i].clone());
    }

    this.closed = source.closed;
    this.curveType = source.curveType;
    this.tension = source.tension;

    return this;
  }

  public function toJSON(): Dynamic {
    var data = super.toJSON();
    data.points = [];

    for (i in 0...this.points.length) {
      data.points.push(this.points[i].toArray());
    }

    data.closed = this.closed;
    data.curveType = this.curveType;
    data.tension = this.tension;

    return data;
  }

  public function fromJSON(json: Dynamic): CatmullRomCurve3 {
    super.fromJSON(json);
    this.points = [];

    for (i in 0...json.points.length) {
      this.points.push(new Vector3().fromArray(json.points[i]));
    }

    this.closed = json.closed;
    this.curveType = json.curveType;
    this.tension = json.tension;

    return this;
  }
}

export { CatmullRomCurve3 };