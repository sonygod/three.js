import MathUtils;
import Vector2;
import Vector3;
import Matrix4;

class Curve {

    public var type:String;
    public var arcLengthDivisions:Int;
    private var cacheArcLengths:Array<Float>;
    private var needsUpdate:Bool;

    public function new() {
        this.type = 'Curve';
        this.arcLengthDivisions = 200;
    }

    // Virtual base class method to overwrite and implement in subclasses
    //	- t [0 .. 1]
    public function getPoint(?t:Float, ?optionalTarget:Dynamic):Dynamic {
        trace('THREE.Curve: .getPoint() not implemented.');
        return null;
    }

    // Get point at relative position in curve according to arc length
    // - u [0 .. 1]
    public function getPointAt(u:Float, ?optionalTarget:Dynamic):Dynamic {
        var t = this.getUtoTmapping(u);
        return this.getPoint(t, optionalTarget);
    }

    // Get sequence of points using getPoint(t)
    public function getPoints(?divisions:Int = 5):Array<Dynamic> {
        var points = [];
        for (d in 0...divisions + 1) {
            points.push(this.getPoint(d / divisions));
        }
        return points;
    }

    // Get sequence of points using getPointAt(u)
    public function getSpacedPoints(?divisions:Int = 5):Array<Dynamic> {
        var points = [];
        for (d in 0...divisions + 1) {
            points.push(this.getPointAt(d / divisions));
        }
        return points;
    }

    // Get total curve arc length
    public function getLength():Float {
        var lengths = this.getLengths();
        return lengths[lengths.length - 1];
    }

    // Get list of cumulative segment lengths
    public function getLengths(?divisions:Int = this.arcLengthDivisions):Array<Float> {
        if (this.cacheArcLengths != null &&
            this.cacheArcLengths.length == divisions + 1 &&
            !this.needsUpdate) {
            return this.cacheArcLengths;
        }

        this.needsUpdate = false;

        var cache:Array<Float> = [];
        var current:Dynamic, last = this.getPoint(0);
        var sum = 0.0;

        cache.push(0.0);

        for (p in 1...divisions + 1) {
            current = this.getPoint(p / divisions);
            sum += current.distanceTo(last);
            cache.push(sum);
            last = current;
        }

        this.cacheArcLengths = cache;

        return cache; // { sums: cache, sum: sum }; Sum is in the last element.
    }

    public function updateArcLengths():Void {
        this.needsUpdate = true;
        this.getLengths();
    }

    // Given u (0 .. 1), get a t to find p. This gives you points which are equidistant
    public function getUtoTmapping(u:Float, ?distance:Float):Float {
        var arcLengths = this.getLengths();
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
        var lengthBefore = arcLengths[i];
        var lengthAfter = arcLengths[i + 1];
        var segmentLength = lengthAfter - lengthBefore;

        // determine where we are between the 'before' and 'after' points
        var segmentFraction = (targetArcLength - lengthBefore) / segmentLength;

        // add that fractional amount to t
        var t = (i + segmentFraction) / (il - 1);

        return t;
    }

    // Returns a unit vector tangent at t
    // In case any sub curve does not implement its tangent derivation,
    // 2 points a small delta apart will be used to find its gradient
    // which seems to give a reasonable approximation
    public function getTangent(t:Float, ?optionalTarget:Dynamic):Dynamic {
        var delta = 0.0001;
        var t1 = t - delta;
        var t2 = t + delta;

        // Capping in case of danger
        if (t1 < 0) t1 = 0;
        if (t2 > 1) t2 = 1;

        var pt1 = this.getPoint(t1);
        var pt2 = this.getPoint(t2);

        var tangent = optionalTarget != null ? optionalTarget : (Std.is(pt1, Vector2) ? new Vector2() : new Vector3());

        tangent.copy(pt2).sub(pt1).normalize();

        return tangent;
    }

    public function getTangentAt(u:Float, ?optionalTarget:Dynamic):Dynamic {
        var t = this.getUtoTmapping(u);
        return this.getTangent(t, optionalTarget);
    }

    public function computeFrenetFrames(segments:Int, closed:Bool):Dynamic {
        // see http://www.cs.indiana.edu/pub/techreports/TR425.pdf

        var normal = new Vector3();
        var tangents = [];
        var normals = [];
        var binormals = [];

        var vec = new Vector3();
        var mat = new Matrix4();

        // compute the tangent vectors for each segment on the curve
        for (i in 0...segments + 1) {
            var u = i / segments;
            tangents[i] = this.getTangentAt(u, new Vector3());
        }

        // select an initial normal vector perpendicular to the first tangent vector,
        // and in the direction of the minimum tangent xyz component
        normals[0] = new Vector3();
        binormals[0] = new Vector3();
        var min = Math.POSITIVE_INFINITY;
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
        for (i in 1...segments + 1) {
            normals[i] = normals[i - 1].clone();
            binormals[i] = binormals[i - 1].clone();
            vec.crossVectors(tangents[i - 1], tangents[i]);

            if (vec.length() > Math.EPSILON) {
                vec.normalize();
                var theta = Math.acos(MathUtils.clamp(tangents[i - 1].dot(tangents[i]), -1, 1)); // clamp for floating pt errors
                normals[i].applyMatrix4(mat.makeRotationAxis(vec, theta));
            }

            binormals[i].crossVectors(tangents[i], normals[i]);
        }

        // if the curve is closed, postprocess the vectors so the first and last normal vectors are the same
        if (closed) {
            var theta = Math.acos(MathUtils.clamp(normals[0].dot(normals[segments]), -1, 1));
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

        return { tangents: tangents, normals: normals, binormals: binormals };
    }

    public function clone():Curve {
        return new Curve().copy(this);
    }

    public function copy(source:Curve):Curve {
        this.arcLengthDivisions = source.arcLengthDivisions;
        return this;
    }

    public function toJSON():Dynamic {
        var data = {
            metadata: {
                version: 4.6,
                type: 'Curve',
                generator: 'Curve.toJSON'
            }
        };
        data.arcLengthDivisions = this.arcLengthDivisions;
        data.type = this.type;
        return data;
    }

    public function fromJSON(json:Dynamic):Curve {
        this.arcLengthDivisions = json.arcLengthDivisions;
        return this;
    }
}