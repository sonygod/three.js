import curve.Curve;
import interpolations.CatmullRom;
import math.Vector2;

class SplineCurve extends Curve {
  public var isSplineCurve:Bool = true;
  public var type:String = "SplineCurve";
  public var points:Array<Vector2>;

  public function new(points:Array<Vector2> = []) {
    super();
    this.points = points;
  }

  public function getPoint(t:Float, optionalTarget:Vector2 = new Vector2()):Vector2 {
    var point = optionalTarget;
    var points = this.points;
    var p = (points.length - 1) * t;
    var intPoint = Math.floor(p);
    var weight = p - intPoint;
    var p0 = points[intPoint == 0 ? intPoint : intPoint - 1];
    var p1 = points[intPoint];
    var p2 = points[intPoint > points.length - 2 ? points.length - 1 : intPoint + 1];
    var p3 = points[intPoint > points.length - 3 ? points.length - 1 : intPoint + 2];
    point.set(CatmullRom(weight, p0.x, p1.x, p2.x, p3.x), CatmullRom(weight, p0.y, p1.y, p2.y, p3.y));
    return point;
  }

  public function copy(source:SplineCurve):SplineCurve {
    super.copy(source);
    this.points = [];
    for (i in 0...source.points.length) {
      this.points.push(source.points[i].clone());
    }
    return this;
  }

  public function toJSON():Dynamic {
    var data = super.toJSON();
    data.points = [];
    for (i in 0...this.points.length) {
      data.points.push(this.points[i].toArray());
    }
    return data;
  }

  public function fromJSON(json:Dynamic):SplineCurve {
    super.fromJSON(json);
    this.points = [];
    for (i in 0...json.points.length) {
      this.points.push(new Vector2().fromArray(json.points[i]));
    }
    return this;
  }
}