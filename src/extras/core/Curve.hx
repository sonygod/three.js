package three.extras.core;

import math.MathUtils;
import math.Vector2;
import math.Vector3;
import math.Matrix4;

class Curve {
    public var type:String;
    public var arcLengthDivisions:Int;
    public var cacheArcLengths:Array<Float>;
    public var needsUpdate:Bool;

    public function new() {
        type = 'Curve';
        arcLengthDivisions = 200;
        cacheArcLengths = null;
        needsUpdate = false;
    }

    // Virtual base class method to overwrite and implement in subclasses
    //  - t [0 .. 1]
    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        trace('THREE.Curve: .getPoint() not implemented.');
        return null;
    }

    // Get point at relative position in curve according to arc length
    // - u [0 .. 1]
    public function getPointAt(u:Float, ?optionalTarget:Vector3):Vector3 {
        var t:Float = getUtoTmapping(u);
        return getPoint(t, optionalTarget);
    }

    // Get sequence of points using getPoint( t )
    public function getPoints(divisions:Int = 5):Array<Vector3> {
        var points:Array<Vector3> = [];
        for (i in 0...divisions + 1) {
            points.push(getPoint(i / divisions));
        }
        return points;
    }

    // Get sequence of points using getPointAt( u )
    public function getSpacedPoints(divisions:Int = 5):Array<Vector3> {
        var points:Array<Vector3> = [];
        for (i in 0...divisions + 1) {
            points.push(getPointAt(i / divisions));
        }
        return points;
    }

    // Get total curve arc length
    public function getLength():Float {
        var lengths:Array<Float> = getLengths();
        return lengths[lengths.length - 1];
    }

    // Get list of cumulative segment lengths
    public function getLengths(divisions:Int = arcLengthDivisions):Array<Float> {
        if (cacheArcLengths != null && cacheArcLengths.length == divisions + 1 && !needsUpdate) {
            return cacheArcLengths;
        }
        needsUpdate = false;
        var cache:Array<Float> = [];
        var current:Vector3;
        var last:Vector3 = getPoint(0);
        var sum:Float = 0;
        cache.push(0);
        for (p in 1...divisions + 1) {
            current = getPoint(p / divisions);
            sum += current.distanceTo(last);
            cache.push(sum);
            last = current;
        }
        cacheArcLengths = cache;
        return cache;
    }

    public function updateArcLengths() {
        needsUpdate = true;
        getLengths();
    }

    // Given u ( 0 .. 1 ), get a t to find p. This gives you points which are equidistant
    public function getUtoTmapping(u:Float, ?distance:Float):Float {
        var arcLengths:Array<Float> = getLengths();
        var i:Int = 0;
        var il:Int = arcLengths.length;
        var targetArcLength:Float;
        if (distance != null) {
            targetArcLength = distance;
        } else {
            targetArcLength = u * arcLengths[il - 1];
        }
        // binary search for the index with largest value smaller than target u distance
        var low:Int = 0;
        var high:Int = il - 1;
        var comparison:Float;
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
        // we could get finer grain at lengths, or use simple interpolation between two points
        var lengthBefore:Float = arcLengths[i];
        var lengthAfter:Float = arcLengths[i + 1];
        var segmentLength:Float = lengthAfter - lengthBefore;
        // determine where we are between the 'before' and 'after' points
        var segmentFraction:Float = (targetArcLength - lengthBefore) / segmentLength;
        // add that fractional amount to t
        var t:Float = (i + segmentFraction) / (il - 1);
        return t;
    }

    // Returns a unit vector tangent at t
    // In case any sub curve does not implement its tangent derivation,
    // 2 points a small delta apart will be used to find its gradient
    // which seems to give a reasonable approximation
    public function getTangent(t:Float, ?optionalTarget:Vector3):Vector3 {
        var delta:Float = 0.0001;
        var t1:Float = t - delta;
        var t2:Float = t + delta;
        // Capping in case of danger
        if (t1 < 0) t1 = 0;
        if (t2 > 1) t2 = 1;
        var pt1:Vector3 = getPoint(t1);
        var pt2:Vector3 = getPoint(t2);
        var tangent:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        tangent.copy(pt2).sub(pt1).normalize();
        return tangent;
    }

    public function getTangentAt(u:Float, ?optionalTarget:Vector3):Vector3 {
        var t:Float = getUtoTmapping(u);
        return getTangent(t, optionalTarget);
    }

    public function computeFrenetFrames(segments:Int, closed:Bool):{
        tangents:Array<Vector3>,
        normals:Array<Vector3>,
        binormals:Array<Vector3>
    } {
        // see http://www.cs.indiana.edu/pub/techreports/TR425.pdf
        var normal:Vector3 = new Vector3();
        var tangents:Array<Vector3> = [];
        var normals:Array<Vector3> = [];
        var binormals:Array<Vector3> = [];
        var vec:Vector3 = new Vector3();
        var mat:Matrix4 = new Matrix4();
        // compute the tangent vectors for each segment on the curve
        for (i in 0...segments + 1) {
            var u:Float = i / segments;
            tangents[i] = getTangentAt(u, new Vector3());
        }
        // select an initial normal vector perpendicular to the first tangent vector,
        // and in the direction of the minimum tangent xyz component
        normals[0] = new Vector3();
        binormals[0] = new Vector3();
        var min:Float = Math.POSITIVE_INFINITY;
        var tx:Float = Math.abs(tangents[0].x);
        var ty:Float = Math.abs(tangents[0].y);
        var tz:Float = Math.abs(tangents[0].z);
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
        // compute the slowly-varying normal and binormal vectors for each segment on the curve
        for (i in 1...segments + 1) {
            normals[i] = normals[i - 1].clone();
            binormals[i] = binormals[i - 1].clone();
            vec.crossVectors(tangents[i - 1], tangents[i]);
            if (vec.length() > Math.EPSILON) {
                vec.normalize();
                var theta:Float = Math.acos(MathUtils.clamp(tangents[i - 1].dot(tangents[i]), -1, 1)); // clamp for floating pt errors
                normals[i].applyMatrix4(mat.makeRotationAxis(vec, theta));
            }
            binormals[i].crossVectors(tangents[i], normals[i]);
        }
        // if the curve is closed, postprocess the vectors so the first and last normal vectors are the same
        if (closed) {
            var theta:Float = Math.acos(MathUtils.clamp(normals[0].dot(normals[segments]), -1, 1));
            theta /= segments;
            if (tangents[0].dot(vec.crossVectors(normals[0], normals[segments])) > 0) {
                theta = -theta;
            }
            for (i in 1...segments + 1) {
                // twist a little...
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

    public function clone():Curve {
        return new Curve().copy(this);
    }

    public function copy(source:Curve):Curve {
        arcLengthDivisions = source.arcLengthDivisions;
        return this;
    }

    public function toJSON():Dynamic {
        var data:Dynamic = {
            metadata: {
                version: 4.6,
                type: 'Curve',
                generator: 'Curve.toJSON'
            }
        };
        data.arcLengthDivisions = arcLengthDivisions;
        data.type = type;
        return data;
    }

    public function fromJSON(json:Dynamic):Curve {
        arcLengthDivisions = json.arcLengthDivisions;
        return this;
    }
}