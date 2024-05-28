package threejs.curves;

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
        cacheArcLengths = new Array<Float>();
        needsUpdate = false;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        Console.warn('THREE.Curve: .getPoint() not implemented.');
        return null;
    }

    public function getPointAt(u:Float, ?optionalTarget:Vector3):Vector3 {
        var t:Float = getUtoTmapping(u);
        return getPoint(t, optionalTarget);
    }

    public function getPoints(divisions:Int = 5):Array<Vector3> {
        var points:Array<Vector3> = new Array<Vector3>();
        for (i in 0...divisions + 1) {
            points.push(getPoint(i / divisions));
        }
        return points;
    }

    public function getSpacedPoints(divisions:Int = 5):Array<Vector3> {
        var points:Array<Vector3> = new Array<Vector3>();
        for (i in 0...divisions + 1) {
            points.push(getPointAt(i / divisions));
        }
        return points;
    }

    public function getLength():Float {
        var lengths:Array<Float> = getLengths();
        return lengths[lengths.length - 1];
    }

    public function getLengths(divisions:Int = arcLengthDivisions):Array<Float> {
        if (cacheArcLengths != null && cacheArcLengths.length == divisions + 1 && !needsUpdate) {
            return cacheArcLengths;
        }
        needsUpdate = false;
        var cache:Array<Float> = [0];
        var current:Vector3;
        var last:Vector3 = getPoint(0);
        var sum:Float = 0;
        for (p in 1...divisions + 1) {
            current = getPoint(p / divisions);
            sum += current.distanceTo(last);
            cache.push(sum);
            last = current;
        }
        cacheArcLengths = cache;
        return cache;
    }

    public function updateArcLengths():Void {
        needsUpdate = true;
        getLengths();
    }

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
        var lengthBefore:Float = arcLengths[i];
        var lengthAfter:Float = arcLengths[i + 1];
        var segmentLength:Float = lengthAfter - lengthBefore;
        var segmentFraction:Float = (targetArcLength - lengthBefore) / segmentLength;
        var t:Float = (i + segmentFraction) / (il - 1);
        return t;
    }

    public function getTangent(t:Float, ?optionalTarget:Vector3):Vector3 {
        var delta:Float = 0.0001;
        var t1:Float = t - delta;
        var t2:Float = t + delta;
        if (t1 < 0) t1 = 0;
        if (t2 > 1) t2 = 1;
        var pt1:Vector3 = getPoint(t1);
        var pt2:Vector3 = getPoint(t2);
        var tangent:Vector3 = optionalTarget != null ? optionalTarget : (pt1.isVector2 ? new Vector2() : new Vector3());
        tangent.copy(pt2).sub(pt1).normalize();
        return tangent;
    }

    public function getTangentAt(u:Float, ?optionalTarget:Vector3):Vector3 {
        var t:Float = getUtoTmapping(u);
        return getTangent(t, optionalTarget);
    }

    public function computeFrenetFrames(segments:Int, closed:Bool):{tangents:Array<Vector3>, normals:Array<Vector3>, binormals:Array<Vector3>} {
        // see http://www.cs.indiana.edu/pub/techreports/TR425.pdf
        var normal:Vector3 = new Vector3();
        var tangents:Array<Vector3> = [];
        var normals:Array<Vector3> = [];
        var binormals:Array<Vector3> = [];
        var vec:Vector3 = new Vector3();
        var mat:Matrix4 = new Matrix4();

        for (i in 0...segments + 1) {
            var u:Float = i / segments;
            tangents[i] = getTangentAt(u, new Vector3());
        }

        normal.set(0, 0, 1);
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

        for (i in 1...segments + 1) {
            normals[i] = normals[i - 1].clone();
            binormals[i] = binormals[i - 1].clone();
            vec.crossVectors(tangents[i - 1], tangents[i]);
            if (vec.length > Math.EPSILON) {
                vec.normalize();
                var theta:Float = Math.acos(MathUtils.clamp(tangents[i - 1].dot(tangents[i]), -1, 1));
                normals[i].applyMatrix4(mat.makeRotationAxis(vec, theta));
            }
            binormals[i].crossVectors(tangents[i], normals[i]);
        }

        if (closed) {
            var theta:Float = Math.acos(MathUtils.clamp(normals[0].dot(normals[segments]), -1, 1));
            theta /= segments;
            if (tangents[0].dot(vec.crossVectors(normals[0], normals[segments])) > 0) {
                theta = -theta;
            }
            for (i in 1...segments + 1) {
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