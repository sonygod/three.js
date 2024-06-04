import three.Vector3;

class Capsule {
  public var start:Vector3;
  public var end:Vector3;
  public var radius:Float;

  public function new(start:Vector3 = new Vector3(0, 0, 0), end:Vector3 = new Vector3(0, 1, 0), radius:Float = 1) {
    this.start = start;
    this.end = end;
    this.radius = radius;
  }

  public function clone():Capsule {
    return new Capsule(this.start.clone(), this.end.clone(), this.radius);
  }

  public function set(start:Vector3, end:Vector3, radius:Float):Void {
    this.start.copy(start);
    this.end.copy(end);
    this.radius = radius;
  }

  public function copy(capsule:Capsule):Void {
    this.start.copy(capsule.start);
    this.end.copy(capsule.end);
    this.radius = capsule.radius;
  }

  public function getCenter(target:Vector3):Vector3 {
    return target.copy(this.end).add(this.start).multiplyScalar(0.5);
  }

  public function translate(v:Vector3):Void {
    this.start.add(v);
    this.end.add(v);
  }

  public function checkAABBAxis(p1x:Float, p1y:Float, p2x:Float, p2y:Float, minx:Float, maxx:Float, miny:Float, maxy:Float, radius:Float):Bool {
    return (
      (minx - p1x < radius || minx - p2x < radius) &&
      (p1x - maxx < radius || p2x - maxx < radius) &&
      (miny - p1y < radius || miny - p2y < radius) &&
      (p1y - maxy < radius || p2y - maxy < radius)
    );
  }

  public function intersectsBox(box:Box3):Bool {
    return (
      this.checkAABBAxis(
        this.start.x, this.start.y, this.end.x, this.end.y,
        box.min.x, box.max.x, box.min.y, box.max.y,
        this.radius
      ) &&
      this.checkAABBAxis(
        this.start.x, this.start.z, this.end.x, this.end.z,
        box.min.x, box.max.x, box.min.z, box.max.z,
        this.radius
      ) &&
      this.checkAABBAxis(
        this.start.y, this.start.z, this.end.y, this.end.z,
        box.min.y, box.max.y, box.min.z, box.max.z,
        this.radius
      )
    );
  }
}