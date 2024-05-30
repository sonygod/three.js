import three.math.MathUtils;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Matrix4;

class Curve {

    public var type:String;
    public var arcLengthDivisions:Int;
    private var cacheArcLengths:Array<Float>;
    private var needsUpdate:Bool;

    public function new() {
        this.type = 'Curve';
        this.arcLengthDivisions = 200;
        this.needsUpdate = false;
    }

    // Virtual base class method to overwrite and implement in subclasses
    // - t [0 .. 1]

    public function getPoint(t:Float, ?optionalTarget:Dynamic):Dynamic {
        trace('THREE.Curve: .getPoint() not implemented.');
        return null;
    }

    // Get point at relative position in curve according to arc length
    // - u [0 .. 1]

    public function getPointAt(u:Float, ?optionalTarget:Dynamic):Dynamic {
        var t:Float = this.getUtoTmapping(u);
        return this.getPoint(t, optionalTarget);
    }

    // Get sequence of points using getPoint(t)

    public function getPoints(divisions:Int = 5):Array<Dynamic> {
        var points:Array<Dynamic> = [];

        for (i in 0...divisions + 1) {
            points.push(this.getPoint(i / divisions));
        }

        return points;
    }

    // Get sequence of points using getPointAt(u)

    public function getSpacedPoints(divisions:Int = 5):Array<Dynamic> {
        var points:Array<Dynamic> = [];

        for (i in 0...divisions + 1) {
            points.push(this.getPointAt(i / divisions));
        }

        return points;
    }

    // Get total curve arc length

    public function getLength():Float {
        var lengths = this.getLengths();
        return lengths[lengths.length - 1];
    }

    // Get list of cumulative segment lengths

    public function getLengths(divisions:Int = this.arcLengthDivisions):Array<Float> {
        if (this.cacheArcLengths != null && this.cacheArcLengths.length == divisions + 1 && !this.needsUpdate) {
            return this.cacheArcLengths;
        }

        this.needsUpdate = false;
        var cache:Array<Float> = [];
        var current:Dynamic, last:Dynamic = this.getPoint(0);
        var sum:Float = 0;

        cache.push(0);

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
        var arcLengths:Array<Float> = this.getLengths();
        var i:Int = 0;
        var il:Int = arcLengths.length;
        var targetArcLength:Float; // The targeted u distance value to get

        if (distance != null) {
            targetArcLength = distance;
        } else {
            targetArcLength = u * arcLengths[il - 1];
        }

        // binary search for the index with largest value smaller than target u distance

        var low:Int = 0, high:Int = il - 1, comparison:Float;

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

    // Returns a unit vector tangent at t
    // In case any sub curve does not implement its tangent derivation,
    // 2 points a small delta apart will be used to find its gradient
    // which seems to give a reasonable approximation

    public function getTangent(t:Float, ?optionalTarget:Dynamic):Dynamic {
        var delta:Float = 0.0001;
        var t1:Float = t - delta;
        var t2:Float = t + delta;

        if (t1 < 0) t1 = 0;
        if (t2 > 1) t2 = 1;

        var pt1:Dynamic = this.getPoint(t1);
        var pt2:Dynamic = this.getPoint(t2);
        var tangent:Dynamic = optionalTarget != null ? optionalTarget : (pt1.isVector2 ? new Vector2() : new Vector3());

        tangent.copy(pt2).sub(pt1).normalize();
        return tangent;
    }

    public function getTangentAt(u:Float, ?optionalTarget:Dynamic):Dynamic {
        var t:Float = this.getUtoTmapping(u);
        return this.getTangent(t, optionalTarget);
    }

    public function computeFrenetFrames(segments:Int, closed:Bool):Dynamic {
        var normal:Vector3 = new Vector3();
        var tangents:Array<Vector3> = [];
        var normals:Array<Vector3> = [];
        var binormals:Array<Vector3> = [];

        var vec:Vector3 = new Vector3();
        var mat:Matrix4 = new Matrix4();

        for (i in 0...segments + 1) {
            var u:Float = i / segments;
            tangents[i] = this.getTangentAt(u, new Vector3());
        }

        normals[0] = new Vector3();
        binormals[0] = new Vector3();
        var min:Float = Math.MAX_VALUE;
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

            if (vec.length() > Math.EPSILON) {
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
        var data:Dynamic = {
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