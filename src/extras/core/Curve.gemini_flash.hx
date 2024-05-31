import MathUtils from "three/math/MathUtils";
import Vector2 from "three/math/Vector2";
import Vector3 from "three/math/Vector3";
import Matrix4 from "three/math/Matrix4";

/**
 * Extensible curve object.
 *
 * Some common of curve methods:
 * .getPoint( t, optionalTarget ), .getTangent( t, optionalTarget )
 * .getPointAt( u, optionalTarget ), .getTangentAt( u, optionalTarget )
 * .getPoints(), .getSpacedPoints()
 * .getLength()
 * .updateArcLengths()
 *
 * This following curves inherit from THREE.Curve:
 *
 * -- 2D curves --
 * THREE.ArcCurve
 * THREE.CubicBezierCurve
 * THREE.EllipseCurve
 * THREE.LineCurve
 * THREE.QuadraticBezierCurve
 * THREE.SplineCurve
 *
 * -- 3D curves --
 * THREE.CatmullRomCurve3
 * THREE.CubicBezierCurve3
 * THREE.LineCurve3
 * THREE.QuadraticBezierCurve3
 *
 * A series of curves can be represented as a THREE.CurvePath.
 *
 **/
class Curve {
  public type:String = "Curve";
  public arcLengthDivisions:Int = 200;
  public cacheArcLengths:Array<Float> = [];
  public needsUpdate:Bool = false;

  public constructor() {
  }

  // Virtual base class method to overwrite and implement in subclasses
  //	- t [0 .. 1]
  public getPoint(t:Float, optionalTarget:Null<Dynamic>):Dynamic {
    console.warn('THREE.Curve: .getPoint() not implemented.');
    return null;
  }

  // Get point at relative position in curve according to arc length
  // - u [0 .. 1]
  public getPointAt(u:Float, optionalTarget:Null<Dynamic>):Dynamic {
    const t = this.getUtoTmapping(u);
    return this.getPoint(t, optionalTarget);
  }

  // Get sequence of points using getPoint( t )
  public getPoints(divisions:Int = 5):Array<Dynamic> {
    const points:Array<Dynamic> = [];
    for (let d = 0; d <= divisions; d++) {
      points.push(this.getPoint(d / divisions));
    }
    return points;
  }

  // Get sequence of points using getPointAt( u )
  public getSpacedPoints(divisions:Int = 5):Array<Dynamic> {
    const points:Array<Dynamic> = [];
    for (let d = 0; d <= divisions; d++) {
      points.push(this.getPointAt(d / divisions));
    }
    return points;
  }

  // Get total curve arc length
  public getLength():Float {
    const lengths = this.getLengths();
    return lengths[lengths.length - 1];
  }

  // Get list of cumulative segment lengths
  public getLengths(divisions:Int = this.arcLengthDivisions):Array<Float> {
    if (this.cacheArcLengths.length == divisions + 1 && !this.needsUpdate) {
      return this.cacheArcLengths;
    }
    this.needsUpdate = false;
    const cache:Array<Float> = [];
    let current:Dynamic, last = this.getPoint(0);
    let sum:Float = 0;
    cache.push(0);
    for (let p = 1; p <= divisions; p++) {
      current = this.getPoint(p / divisions);
      sum += current.distanceTo(last);
      cache.push(sum);
      last = current;
    }
    this.cacheArcLengths = cache;
    return cache;
  }

  public updateArcLengths() {
    this.needsUpdate = true;
    this.getLengths();
  }

  // Given u ( 0 .. 1 ), get a t to find p. This gives you points which are equidistant
  public getUtoTmapping(u:Float, distance:Null<Float> = null):Float {
    const arcLengths = this.getLengths();
    let i = 0;
    const il = arcLengths.length;
    let targetArcLength:Float;
    if (distance != null) {
      targetArcLength = distance;
    } else {
      targetArcLength = u * arcLengths[il - 1];
    }
    let low = 0, high = il - 1, comparison:Float;
    while (low <= high) {
      i = Math.floor(low + (high - low) / 2);
      comparison = arcLengths[i] - targetArcLength;
      if (comparison < 0) {
        low = i + 1;
      } else if (comparison > 0) {
        high = i - 1;
      } else {
        high = i;
        break;
      }
    }
    i = high;
    if (arcLengths[i] == targetArcLength) {
      return i / (il - 1);
    }
    const lengthBefore = arcLengths[i];
    const lengthAfter = arcLengths[i + 1];
    const segmentLength = lengthAfter - lengthBefore;
    const segmentFraction = (targetArcLength - lengthBefore) / segmentLength;
    const t = (i + segmentFraction) / (il - 1);
    return t;
  }

  // Returns a unit vector tangent at t
  // In case any sub curve does not implement its tangent derivation,
  // 2 points a small delta apart will be used to find its gradient
  // which seems to give a reasonable approximation
  public getTangent(t:Float, optionalTarget:Null<Dynamic>):Dynamic {
    const delta:Float = 0.0001;
    let t1:Float = t - delta;
    let t2:Float = t + delta;
    if (t1 < 0) t1 = 0;
    if (t2 > 1) t2 = 1;
    const pt1 = this.getPoint(t1);
    const pt2 = this.getPoint(t2);
    const tangent:Dynamic = optionalTarget != null ? optionalTarget : (pt1.isVector2 ? new Vector2() : new Vector3());
    tangent.copy(pt2).sub(pt1).normalize();
    return tangent;
  }

  public getTangentAt(u:Float, optionalTarget:Null<Dynamic>):Dynamic {
    const t = this.getUtoTmapping(u);
    return this.getTangent(t, optionalTarget);
  }

  public computeFrenetFrames(segments:Int, closed:Bool):{ tangents:Array<Vector3>, normals:Array<Vector3>, binormals:Array<Vector3> } {
    // see http://www.cs.indiana.edu/pub/techreports/TR425.pdf
    const normal = new Vector3();
    const tangents:Array<Vector3> = [];
    const normals:Array<Vector3> = [];
    const binormals:Array<Vector3> = [];
    const vec = new Vector3();
    const mat = new Matrix4();
    for (let i = 0; i <= segments; i++) {
      const u = i / segments;
      tangents[i] = this.getTangentAt(u, new Vector3());
    }
    normals[0] = new Vector3();
    binormals[0] = new Vector3();
    let min = Number.MAX_VALUE;
    const tx = Math.abs(tangents[0].x);
    const ty = Math.abs(tangents[0].y);
    const tz = Math.abs(tangents[0].z);
    if (tx <= min) {
      min = tx;
      normal.set(1, 0, 0);
    }
    if (ty <= min) {
      min = ty;
      normal.set(0, 1, 0);
    }
    if (tz <= min) {
      normal.set(0, 0, 1);
    }
    vec.crossVectors(tangents[0], normal).normalize();
    normals[0].crossVectors(tangents[0], vec);
    binormals[0].crossVectors(tangents[0], normals[0]);
    for (let i = 1; i <= segments; i++) {
      normals[i] = normals[i - 1].clone();
      binormals[i] = binormals[i - 1].clone();
      vec.crossVectors(tangents[i - 1], tangents[i]);
      if (vec.length() > Number.EPSILON) {
        vec.normalize();
        const theta = Math.acos(MathUtils.clamp(tangents[i - 1].dot(tangents[i]), -1, 1));
        normals[i].applyMatrix4(mat.makeRotationAxis(vec, theta));
      }
      binormals[i].crossVectors(tangents[i], normals[i]);
    }
    if (closed) {
      let theta = Math.acos(MathUtils.clamp(normals[0].dot(normals[segments]), -1, 1));
      theta /= segments;
      if (tangents[0].dot(vec.crossVectors(normals[0], normals[segments])) > 0) {
        theta = -theta;
      }
      for (let i = 1; i <= segments; i++) {
        normals[i].applyMatrix4(mat.makeRotationAxis(tangents[i], theta * i));
        binormals[i].crossVectors(tangents[i], normals[i]);
      }
    }
    return {
      tangents: tangents,
      normals: normals,
      binormals: binormals
    };
  }

  public clone():Curve {
    return cast this.constructor().copy(this);
  }

  public copy(source:Curve):Curve {
    this.arcLengthDivisions = source.arcLengthDivisions;
    return this;
  }

  public toJSON():Dynamic {
    const data:Dynamic = {
      metadata: {
        version: 4.6,
        type: "Curve",
        generator: "Curve.toJSON"
      }
    };
    data.arcLengthDivisions = this.arcLengthDivisions;
    data.type = this.type;
    return data;
  }

  public fromJSON(json:Dynamic):Curve {
    this.arcLengthDivisions = json.arcLengthDivisions;
    return this;
  }
}

export default Curve;