import three.math.MathUtils;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Matrix4;

class Curve {
    public var type:String = 'Curve';
    public var arcLengthDivisions:Int = 200;
    public var needsUpdate:Bool = false;
    public var cacheArcLengths:Array<Float> = [];

    public function new() {
    }

    public function getPoint(t:Float, optionalTarget:Dynamic = null):Dynamic {
        trace('THREE.Curve: .getPoint() not implemented.');
        return null;
    }

    public function getPointAt(u:Float, optionalTarget:Dynamic = null):Dynamic {
        var t:Float = this.getUtoTmapping(u);
        return this.getPoint(t, optionalTarget);
    }

    public function getPoints(divisions:Int = 5):Array<Dynamic> {
        var points:Array<Dynamic> = [];

        for (var d:Int in 0...divisions) {
            points.push(this.getPoint(d / divisions));
        }

        return points;
    }

    public function getSpacedPoints(divisions:Int = 5):Array<Dynamic> {
        var points:Array<Dynamic> = [];

        for (var d:Int in 0...divisions) {
            points.push(this.getPointAt(d / divisions));
        }

        return points;
    }

    public function getLength():Float {
        var lengths:Array<Float> = this.getLengths();
        return lengths[lengths.length - 1];
    }

    public function getLengths(divisions:Int = this.arcLengthDivisions):Array<Float> {
        if (this.cacheArcLengths.length == divisions + 1 && !this.needsUpdate) {
            return this.cacheArcLengths;
        }

        this.needsUpdate = false;

        var cache:Array<Float> = [];
        var current:Dynamic;
        var last:Dynamic = this.getPoint(0);
        var sum:Float = 0;

        cache.push(0);

        for (var p:Int in 1...divisions + 1) {
            current = this.getPoint(p / divisions);
            sum += current.distanceTo(last);
            cache.push(sum);
            last = current;
        }

        this.cacheArcLengths = cache;

        return cache;
    }

    public function updateArcLengths():Void {
        this.needsUpdate = true;
        this.getLengths();
    }

    public function getUtoTmapping(u:Float, distance:Float = 0):Float {
        var arcLengths:Array<Float> = this.getLengths();

        var i:Int = 0;
        var il:Int = arcLengths.length;

        var targetArcLength:Float;

        if (distance != 0) {
            targetArcLength = distance;
        } else {
            targetArcLength = u * arcLengths[il - 1];
        }

        var low:Int = 0;
        var high:Int = il - 1;
        var comparison:Float;

        while (low <= high) {
            i = Math.floor((low + high) / 2);

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

    public function getTangent(t:Float, optionalTarget:Dynamic = null):Dynamic {
        var delta:Float = 0.0001;
        var t1:Float = t - delta;
        var t2:Float = t + delta;

        if (t1 < 0) t1 = 0;
        if (t2 > 1) t2 = 1;

        var pt1:Dynamic = this.getPoint(t1);
        var pt2:Dynamic = this.getPoint(t2);

        var tangent:Dynamic = optionalTarget || ((pt1 is Vector2) ? new Vector2() : new Vector3());

        tangent.copy(pt2).sub(pt1).normalize();

        return tangent;
    }

    public function getTangentAt(u:Float, optionalTarget:Dynamic = null):Dynamic {
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

        for (var i:Int in 0...segments + 1) {
            var u:Float = i / segments;

            tangents[i] = this.getTangentAt(u, new Vector3());
        }

        normals[0] = new Vector3();
        binormals[0] = new Vector3();
        var min:Float = Float.MAX_VALUE;
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

        for (var i:Int in 1...segments + 1) {
            normals[i] = normals[i - 1].clone();

            binormals[i] = binormals[i - 1].clone();

            vec.crossVectors(tangents[i - 1], tangents[i]);

            if (vec.length() > Number.EPSILON) {
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

            for (var i:Int in 1...segments + 1) {
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
        return new this.constructor().copy(this);
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