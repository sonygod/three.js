import three.math.Vector3;

class Box3 {
  public isBox3:Bool = true;
  public min:Vector3;
  public max:Vector3;

  public function new(min:Vector3 = new Vector3(Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY), max:Vector3 = new Vector3(Float.NEGATIVE_INFINITY, Float.NEGATIVE_INFINITY, Float.NEGATIVE_INFINITY)) {
    this.min = min;
    this.max = max;
  }

  public function set(min:Vector3, max:Vector3):Box3 {
    this.min.copy(min);
    this.max.copy(max);
    return this;
  }

  public function setFromArray(array:Array<Float>):Box3 {
    this.makeEmpty();
    for (i in 0...array.length) {
      if (i % 3 == 0) {
        this.expandByPoint(new Vector3(array[i], array[i + 1], array[i + 2]));
      }
    }
    return this;
  }

  public function setFromBufferAttribute(attribute:haxe.io.Bytes):Box3 {
    this.makeEmpty();
    for (i in 0...attribute.length / 3) {
      this.expandByPoint(new Vector3(attribute.get(i * 3), attribute.get(i * 3 + 1), attribute.get(i * 3 + 2)));
    }
    return this;
  }

  public function setFromPoints(points:Array<Vector3>):Box3 {
    this.makeEmpty();
    for (point in points) {
      this.expandByPoint(point);
    }
    return this;
  }

  public function setFromCenterAndSize(center:Vector3, size:Vector3):Box3 {
    var halfSize = new Vector3().copy(size).multiplyScalar(0.5);
    this.min.copy(center).sub(halfSize);
    this.max.copy(center).add(halfSize);
    return this;
  }

  public function setFromObject(object:Dynamic, precise:Bool = false):Box3 {
    this.makeEmpty();
    return this.expandByObject(object, precise);
  }

  public function clone():Box3 {
    return new Box3().copy(this);
  }

  public function copy(box:Box3):Box3 {
    this.min.copy(box.min);
    this.max.copy(box.max);
    return this;
  }

  public function makeEmpty():Box3 {
    this.min.x = this.min.y = this.min.z = Float.POSITIVE_INFINITY;
    this.max.x = this.max.y = this.max.z = Float.NEGATIVE_INFINITY;
    return this;
  }

  public function isEmpty():Bool {
    return (this.max.x < this.min.x) || (this.max.y < this.min.y) || (this.max.z < this.min.z);
  }

  public function getCenter(target:Vector3):Vector3 {
    if (this.isEmpty()) {
      return target.set(0, 0, 0);
    } else {
      return target.addVectors(this.min, this.max).multiplyScalar(0.5);
    }
  }

  public function getSize(target:Vector3):Vector3 {
    if (this.isEmpty()) {
      return target.set(0, 0, 0);
    } else {
      return target.subVectors(this.max, this.min);
    }
  }

  public function expandByPoint(point:Vector3):Box3 {
    this.min.min(point);
    this.max.max(point);
    return this;
  }

  public function expandByVector(vector:Vector3):Box3 {
    this.min.sub(vector);
    this.max.add(vector);
    return this;
  }

  public function expandByScalar(scalar:Float):Box3 {
    this.min.addScalar(-scalar);
    this.max.addScalar(scalar);
    return this;
  }

  public function expandByObject(object:Dynamic, precise:Bool = false):Box3 {
    object.updateWorldMatrix(false, false);
    if (object.geometry != null) {
      var positionAttribute = object.geometry.getAttribute('position');
      if (precise && positionAttribute != null && object.isInstancedMesh == false) {
        for (i in 0...positionAttribute.count) {
          if (object.isMesh == true) {
            object.getVertexPosition(i, new Vector3());
          } else {
            var vector = new Vector3();
            vector.fromBufferAttribute(positionAttribute, i);
          }
          vector.applyMatrix4(object.matrixWorld);
          this.expandByPoint(vector);
        }
      } else {
        if (object.boundingBox != null) {
          if (object.boundingBox == null) {
            object.computeBoundingBox();
          }
          var box = new Box3();
          box.copy(object.boundingBox);
        } else {
          if (object.geometry.boundingBox == null) {
            object.geometry.computeBoundingBox();
          }
          var box = new Box3();
          box.copy(object.geometry.boundingBox);
        }
        box.applyMatrix4(object.matrixWorld);
        this.union(box);
      }
    }
    for (child in object.children) {
      this.expandByObject(child, precise);
    }
    return this;
  }

  public function containsPoint(point:Vector3):Bool {
    return !(point.x < this.min.x || point.x > this.max.x ||
        point.y < this.min.y || point.y > this.max.y ||
        point.z < this.min.z || point.z > this.max.z);
  }

  public function containsBox(box:Box3):Bool {
    return (this.min.x <= box.min.x && box.max.x <= this.max.x &&
        this.min.y <= box.min.y && box.max.y <= this.max.y &&
        this.min.z <= box.min.z && box.max.z <= this.max.z);
  }

  public function getParameter(point:Vector3, target:Vector3):Vector3 {
    return target.set(
        (point.x - this.min.x) / (this.max.x - this.min.x),
        (point.y - this.min.y) / (this.max.y - this.min.y),
        (point.z - this.min.z) / (this.max.z - this.min.z)
    );
  }

  public function intersectsBox(box:Box3):Bool {
    return !(box.max.x < this.min.x || box.min.x > this.max.x ||
        box.max.y < this.min.y || box.min.y > this.max.y ||
        box.max.z < this.min.z || box.min.z > this.max.z);
  }

  public function intersectsSphere(sphere:Dynamic):Bool {
    var vector = new Vector3();
    this.clampPoint(sphere.center, vector);
    return vector.distanceToSquared(sphere.center) <= (sphere.radius * sphere.radius);
  }

  public function intersectsPlane(plane:Dynamic):Bool {
    var min:Float;
    var max:Float;
    if (plane.normal.x > 0) {
      min = plane.normal.x * this.min.x;
      max = plane.normal.x * this.max.x;
    } else {
      min = plane.normal.x * this.max.x;
      max = plane.normal.x * this.min.x;
    }
    if (plane.normal.y > 0) {
      min += plane.normal.y * this.min.y;
      max += plane.normal.y * this.max.y;
    } else {
      min += plane.normal.y * this.max.y;
      max += plane.normal.y * this.min.y;
    }
    if (plane.normal.z > 0) {
      min += plane.normal.z * this.min.z;
      max += plane.normal.z * this.max.z;
    } else {
      min += plane.normal.z * this.max.z;
      max += plane.normal.z * this.min.z;
    }
    return (min <= -plane.constant && max >= -plane.constant);
  }

  public function intersectsTriangle(triangle:Dynamic):Bool {
    if (this.isEmpty()) {
      return false;
    }
    var center = new Vector3();
    var extents = new Vector3();
    this.getCenter(center);
    extents.subVectors(this.max, center);
    var v0 = new Vector3();
    var v1 = new Vector3();
    var v2 = new Vector3();
    v0.subVectors(triangle.a, center);
    v1.subVectors(triangle.b, center);
    v2.subVectors(triangle.c, center);
    var f0 = new Vector3();
    var f1 = new Vector3();
    var f2 = new Vector3();
    f0.subVectors(v1, v0);
    f1.subVectors(v2, v1);
    f2.subVectors(v0, v2);
    var axes = [
      0, -f0.z, f0.y, 0, -f1.z, f1.y, 0, -f2.z, f2.y,
      f0.z, 0, -f0.x, f1.z, 0, -f1.x, f2.z, 0, -f2.x,
      -f0.y, f0.x, 0, -f1.y, f1.x, 0, -f2.y, f2.x, 0
    ];
    if (!satForAxes(axes, v0, v1, v2, extents)) {
      return false;
    }
    axes = [ 1, 0, 0, 0, 1, 0, 0, 0, 1 ];
    if (!satForAxes(axes, v0, v1, v2, extents)) {
      return false;
    }
    var triangleNormal = new Vector3();
    triangleNormal.crossVectors(f0, f1);
    axes = [ triangleNormal.x, triangleNormal.y, triangleNormal.z ];
    return satForAxes(axes, v0, v1, v2, extents);
  }

  public function clampPoint(point:Vector3, target:Vector3):Vector3 {
    return target.copy(point).clamp(this.min, this.max);
  }

  public function distanceToPoint(point:Vector3):Float {
    var vector = new Vector3();
    return this.clampPoint(point, vector).distanceTo(point);
  }

  public function getBoundingSphere(target:Dynamic):Dynamic {
    if (this.isEmpty()) {
      target.makeEmpty();
    } else {
      this.getCenter(target.center);
      var vector = new Vector3();
      target.radius = this.getSize(vector).length() * 0.5;
    }
    return target;
  }

  public function intersect(box:Box3):Box3 {
    this.min.max(box.min);
    this.max.min(box.max);
    if (this.isEmpty()) {
      this.makeEmpty();
    }
    return this;
  }

  public function union(box:Box3):Box3 {
    this.min.min(box.min);
    this.max.max(box.max);
    return this;
  }

  public function applyMatrix4(matrix:Dynamic):Box3 {
    if (this.isEmpty()) {
      return this;
    }
    var points = [
      new Vector3(),
      new Vector3(),
      new Vector3(),
      new Vector3(),
      new Vector3(),
      new Vector3(),
      new Vector3(),
      new Vector3(),
    ];
    points[0].set(this.min.x, this.min.y, this.min.z).applyMatrix4(matrix);
    points[1].set(this.min.x, this.min.y, this.max.z).applyMatrix4(matrix);
    points[2].set(this.min.x, this.max.y, this.min.z).applyMatrix4(matrix);
    points[3].set(this.min.x, this.max.y, this.max.z).applyMatrix4(matrix);
    points[4].set(this.max.x, this.min.y, this.min.z).applyMatrix4(matrix);
    points[5].set(this.max.x, this.min.y, this.max.z).applyMatrix4(matrix);
    points[6].set(this.max.x, this.max.y, this.min.z).applyMatrix4(matrix);
    points[7].set(this.max.x, this.max.y, this.max.z).applyMatrix4(matrix);
    this.setFromPoints(points);
    return this;
  }

  public function translate(offset:Vector3):Box3 {
    this.min.add(offset);
    this.max.add(offset);
    return this;
  }

  public function equals(box:Box3):Bool {
    return box.min.equals(this.min) && box.max.equals(this.max);
  }
}

function satForAxes(axes:Array<Float>, v0:Vector3, v1:Vector3, v2:Vector3, extents:Vector3):Bool {
  for (i in 0...axes.length) {
    if (i % 3 == 0) {
      var testAxis = new Vector3(axes[i], axes[i + 1], axes[i + 2]);
      var r = extents.x * Math.abs(testAxis.x) + extents.y * Math.abs(testAxis.y) + extents.z * Math.abs(testAxis.z);
      var p0 = v0.dot(testAxis);
      var p1 = v1.dot(testAxis);
      var p2 = v2.dot(testAxis);
      if (Math.max(-Math.max(p0, p1, p2), Math.min(p0, p1, p2)) > r) {
        return false;
      }
    }
  }
  return true;
}