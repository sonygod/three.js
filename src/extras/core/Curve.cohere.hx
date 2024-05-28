import MathUtils from MathUtils;
import Vector2 from Vector2;
import Vector3 from Vector3;
import Matrix4 from Matrix4;

class Curve {
    public var type:String = "Curve";
    public var arcLengthDivisions:Int = 200;

    public function new() { }

    public function getPoint(t:Float, ?optionalTarget:Dynamic):Dynamic {
        trace("THREE.Curve: .getPoint() not implemented.");
        return null;
    }

    public function getPointAt(u:Float, optionalTarget:Dynamic):Dynamic {
        var t = getUtoTmapping(u);
        return getPoint(t, optionalTarget);
    }

    public function getPoints(divisions:Int = 5):Array<Dynamic> {
        var points = [];
        var d = 0;
        while (d <= divisions) {
            points.push(getPoint(d / divisions));
            d++;
        }
        return points;
    }

    public function getSpacedPoints(divisions:Int = 5):Array<Dynamic> {
        var points = [];
        var d = 0;
        while (d <= divisions) {
            points.push(getPointAt(d / divisions));
            d++;
        }
        return points;
    }

    public function getLength():Float {
        var lengths = getLengths();
        return lengths[lengths.length - 1];
    }

    public function getLengths(divisions:Int = arcLengthDivisions):Array<Float> {
        if (cacheArcLengths != null && cacheArcLengths.length == divisions + 1 && !needsUpdate) {
            return cacheArcLengths;
        }

        needsUpdate = false;
        var cache = [];
        var current:Dynamic, last = getPoint(0);
        var sum:Float = 0.0;

        cache.push(0);

        var p = 1;
        while (p <= divisions) {
            current = getPoint(p / divisions);
            sum += current.distanceTo(last);
            cache.push(sum);
            last = current;
            p++;
        }

        cacheArcLengths = cache;
        return cache; // { sums: cache, sum: sum }; Sum is in the last element.
    }

    public function updateArcLengths() {
        needsUpdate = true;
        getLengths();
    }

    public function getUtoTmapping(u:Float, ?distance:Float):Float {
        var arcLengths = getLengths();

        var i = 0;
        var il = arcLengths.length;

        var targetArcLength:Float; // The targeted u distance value to get

        if (distance != null) {
            targetArcLength = distance;
        } else {
            targetArcLength = u * arcLengths[il - 1];
        }

        // binary search for the index with largest value smaller than target u distance

        var low = 0;
        var high = il - 1;
        var comparison:Float;

        while (low <= high) {
            i = Std.int(low + (high - low) / 2); // less likely to overflow, though probably not issue here, JS doesn't really have integers, all numbers are floats

            comparison = arcLengths[i] - targetArcLength;

            if (comparison < 0) {
                low = i + 1;
            } else if (comparison > 0) {
                high = i - 1;
            } else {
                high = i;
                break; // DONE
            }
        }

        i = high;

        if (arcLengths[i] == targetArcLength) {
            return i / (il - 1);
        }

        // we could get finer grain at lengths, or use simple interpolation between two points

        var lengthBefore = arcLengths[i];
        var lengthAfter = arcLengths[i + 1];

        var segmentLength = lengthAfter - lengthBefore;

        // determine where we are between the 'before' and 'after' points

        var segmentFraction = (targetArcLength - lengthBefore) / segmentLength;

        // add that fractional amount to t

        var t = (i + segmentFraction) / (il - 1);

        return t;
    }

    public function getTangent(t:Float, ?optionalTarget:Dynamic):Dynamic {
        var delta = 0.0001;
        var t1 = t - delta;
        var t2 = t + delta;

        // Capping in case of danger

        if (t1 < 0) t1 = 0;
        if (t2 > 1) t2 = 1;

        var pt1 = getPoint(t1);
        var pt2 = getPoint(t2);

        var tangent = optionalTarget ?? (pt1.isVector2 ? Vector2() : Vector3());

        tangent.copy(pt2).sub(pt1).normalize();

        return tangent;
    }

    public function getTangentAt(u:Float, ?optionalTarget:Dynamic):Dynamic {
        var t = getUtoTmapping(u);
        return getTangent(t, optionalTarget);
    }

    public function computeFrenetFrames(segments:Int, closed:Bool):Dynamic {
        // see http://www.cs.indiana.edu/pub/techreports/TR425.pdf

        var normal = Vector3();

        var tangents = [];
        var normals = [];
        var binormals = [];

        var vec = Vector3();
        var mat = Matrix4();

        // compute the tangent vectors for each segment on the curve

        var i = 0;
        while (i <= segments) {
            var u = i / segments;

            tangents[i] = getTangentAt(u, Vector3());

            i++;
        }

        // select an initial normal vector perpendicular to the first tangent vector,
        // and in the direction of the minimum tangent xyz component

        normals[0] = Vector3();
        binormals[0] = Vector3();
        var min = Float.POSITIVE_INFINITY;
        var tx = Math.abs(tangents[0].x);
        var ty = Math.abs(tangents[0].y);
        var tz = Math.abs(tangents[0].z);

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

        i = 1;
        while (i <= segments) {
            normals[i] = normals[i - 1].clone();

            binormals[i] = binormals[i - 1].clone();

            vec.crossVectors(tangents[i - 1], tangents[i]);

            if (vec.length() > Number.EPSILON) {
                vec.normalize();

                var theta = Math.acos(MathUtils.clamp(tangents[i - 1].dot(tangents[i]), -1, 1)); // clamp for floating pt errors

                normals[i].applyMatrix4(mat.makeRotationAxis(vec, theta));
            }

            binormals[i].crossVectors(tangents[i], normals[i]);

            i++;
        }

        // if the curve is closed, postprocess the vectors so the first and last normal vectors are the same

        if (closed) {
            var theta = Math.acos(MathUtils.clamp(normals[0].dot(normals[segments]), -1, 1));
            theta /= segments;

            if (tangents[0].dot(vec.crossVectors(normals[0], normals[segments])) > 0) {
                theta = -theta;
            }

            i = 1;
            while (i <= segments) {
                // twist a little...
                normals[i].applyMatrix4(mat.makeRotationAxis(tangents[i], theta * i));
                binormals[i].crossVectors(tangents[i], normals[i]);

                i++;
            }
        }

        return { tangents: tangents, normals: normals, binormals: binormals };
    }

    public function clone():Curve {
        return new this.constructor().copy(this);
    }

    public function copy(source:Curve):Curve {
        arcLengthDivisions = source.arcLengthDivisions;
        return this;
    }

    public function toJSON():Dynamic {
        var data = {
            metadata: {
                version: 4.6,
                type: "Curve",
                generator: "Curve.toJSON"
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

class Vector2 {
    public function distanceTo(p:Dynamic):Float {
        return 0.0;
    }
}

class Vector3 {
    public function distanceTo(p:Dynamic):Float {
        return 0.0;
    }

    public function crossVectors(a:Dynamic, b:Dynamic):Dynamic {
        return null;
    }

    public function normalize():Dynamic {
        return null;
    }

    public function applyMatrix4(m:Dynamic):Dynamic {
        return null;
    }

    public function clone():Dynamic {
        return null;
    }

    public function copy(v:Dynamic):Dynamic {
        return null;
    }

    public function set(x:Float, y:Float, z:Float):Dynamic {
        return null;
    }

    public function sub(v:Dynamic):Dynamic {
        return null;
    }

    public var isVector2:Bool;
}

class Matrix4 {
    public function makeRotationAxis(axis:Dynamic, angle:Float):Dynamic {
        return null;
    }
}

class MathUtils {
    public static function clamp(value:Float, min:Float, max:Float):Float {
        return 0.0;
    }
}