import Math.Sphere;
import Math.Ray;
import Math.Matrix4;
import Core.Object3D;
import Math.Vector3;
import Materials.LineBasicMaterial;
import Core.BufferGeometry;
import Core.Float32BufferAttribute;

class Line extends Object3D {

  public static var _vStart(default, default):Vector3 = new Vector3();
  public static var _vEnd(default, default):Vector3 = new Vector3();

  public static var _inverseMatrix(default, default):Matrix4 = new Matrix4();
  public static var _ray(default, default):Ray = new Ray();
  public static var _sphere(default, default):Sphere = new Sphere();

  public static var _intersectPointOnRay(default, default):Vector3 = new Vector3();
  public static var _intersectPointOnSegment(default, default):Vector3 = new Vector3();

  public var geometry:BufferGeometry;
  public var material:LineBasicMaterial;

  public function new(geometry:BufferGeometry = new BufferGeometry(), material:LineBasicMaterial = new LineBasicMaterial()) {

    super();

    this.isLine = true;

    this.type = 'Line';

    this.geometry = geometry;
    this.material = material;

    this.updateMorphTargets();

  }

  public function copy(source:Line, recursive:Bool):Line {

    super.copy(source, recursive);

    this.material = Array.isArray(source.material) ? source.material.slice() : source.material;
    this.geometry = source.geometry;

    return this;

  }

  public function computeLineDistances():Line {

    var geometry = this.geometry;

    // we assume non-indexed geometry

    if (geometry.index == null) {

      var positionAttribute = geometry.attributes.position;
      var lineDistances = [0];

      for (i in 1...positionAttribute.count) {

        _vStart.fromBufferAttribute(positionAttribute, i - 1);
        _vEnd.fromBufferAttribute(positionAttribute, i);

        lineDistances[i] = lineDistances[i - 1];
        lineDistances[i] += _vStart.distanceTo(_vEnd);

      }

      geometry.setAttribute('lineDistance', new Float32BufferAttribute(lineDistances, 1));

    } else {

      trace('THREE.Line.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.');

    }

    return this;

  }

  public function raycast(raycaster:Raycaster, intersects:Array<Dynamic>):Void {

    var geometry = this.geometry;
    var matrixWorld = this.matrixWorld;
    var threshold = raycaster.params.Line.threshold;
    var drawRange = geometry.drawRange;

    // Checking boundingSphere distance to ray

    if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

    _sphere.copy(geometry.boundingSphere);
    _sphere.applyMatrix4(matrixWorld);
    _sphere.radius += threshold;

    if (!raycaster.ray.intersectsSphere(_sphere)) return;

    //

    _inverseMatrix.copy(matrixWorld).invert();
    _ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);

    var localThreshold = threshold / ((this.scale.x + this.scale.y + this.scale.z) / 3);
    var localThresholdSq = localThreshold * localThreshold;

    var step = this.isLineSegments ? 2 : 1;

    var index = geometry.index;
    var attributes = geometry.attributes;
    var positionAttribute = attributes.position;

    if (index != null) {

      var start = Math.max(0, drawRange.start);
      var end = Math.min(index.count, (drawRange.start + drawRange.count));

      for (i in start...end - 1) {

        var a = index.getX(i);
        var b = index.getX(i + 1);

        var intersect = checkIntersection(this, raycaster, _ray, localThresholdSq, a, b);

        if (intersect != null) {

          intersects.push(intersect);

        }

      }

      if (this.isLineLoop) {

        var a = index.getX(end - 1);
        var b = index.getX(start);

        var intersect = checkIntersection(this, raycaster, _ray, localThresholdSq, a, b);

        if (intersect != null) {

          intersects.push(intersect);

        }

      }

    } else {

      var start = Math.max(0, drawRange.start);
      var end = Math.min(positionAttribute.count, (drawRange.start + drawRange.count));

      for (i in start...end - 1) {

        var intersect = checkIntersection(this, raycaster, _ray, localThresholdSq, i, i + 1);

        if (intersect != null) {

          intersects.push(intersect);

        }

      }

      if (this.isLineLoop) {

        var intersect = checkIntersection(this, raycaster, _ray, localThresholdSq, end - 1, start);

        if (intersect != null) {

          intersects.push(intersect);

        }

      }

    }

  }

  public function updateMorphTargets():Void {

    var geometry = this.geometry;

    var morphAttributes = geometry.morphAttributes;
    var keys = Reflect.fields(morphAttributes);

    if (keys.length > 0) {

      var morphAttribute = morphAttributes[keys[0]];

      if (morphAttribute != null) {

        this.morphTargetInfluences = [];
        this.morphTargetDictionary = new haxe.ds.StringMap<Int>();

        for (m in 0...morphAttribute.length) {

          var name = morphAttribute[m].name != null ? morphAttribute[m].name : Std.string(m);

          this.morphTargetInfluences.push(0);
          this.morphTargetDictionary.set(name, m);

        }

      }

    }

  }

}

function checkIntersection(object:Line, raycaster:Raycaster, ray:Ray, thresholdSq:Float, a:Int, b:Int):Dynamic {

  var positionAttribute = object.geometry.attributes.position;

  _vStart.fromBufferAttribute(positionAttribute, a);
  _vEnd.fromBufferAttribute(positionAttribute, b);

  var distSq = ray.distanceSqToSegment(_vStart, _vEnd, _intersectPointOnRay, _intersectPointOnSegment);

  if (distSq > thresholdSq) return null;

  _intersectPointOnRay.applyMatrix4(object.matrixWorld); // Move back to world space for distance calculation

  var distance = raycaster.ray.origin.distanceTo(_intersectPointOnRay);

  if (distance < raycaster.near || distance > raycaster.far) return null;

  return {

    distance: distance,
    // What do we want? intersection point on the ray or on the segment??
    // point: raycaster.ray.at( distance ),
    point: _intersectPointOnSegment.clone().applyMatrix4(object.matrixWorld),
    index: a,
    face: null,
    faceIndex: null,
    object: object

  };

}