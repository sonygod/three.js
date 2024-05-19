import three.math.MathUtils;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Matrix4;

class Curve {

	var type:String;
	var arcLengthDivisions:Int;
	var cacheArcLengths:Array<Float>;
	var needsUpdate:Bool;

	public function new() {
		type = 'Curve';
		arcLengthDivisions = 200;
	}

	public function getPoint(t:Float, optionalTarget:Vector3):Vector3 {
		trace('THREE.Curve: .getPoint() not implemented.');
		return null;
	}

	public function getPointAt(u:Float, optionalTarget:Vector3):Vector3 {
		var t = getUtoTmapping(u);
		return getPoint(t, optionalTarget);
	}

	public function getPoints(divisions:Int = 5):Array<Vector3> {
		var points = [];
		for (d in 0...divisions+1) {
			points.push(getPoint(d / divisions));
		}
		return points;
	}

	public function getSpacedPoints(divisions:Int = 5):Array<Vector3> {
		var points = [];
		for (d in 0...divisions+1) {
			points.push(getPointAt(d / divisions));
		}
		return points;
	}

	public function getLength():Float {
		var lengths = getLengths();
		return lengths[lengths.length - 1];
	}

	public function getLengths(divisions:Int = this.arcLengthDivisions):Array<Float> {
		if (cacheArcLengths != null &&
			(cacheArcLengths.length == divisions + 1) &&
			!needsUpdate) {
			return cacheArcLengths;
		}
		needsUpdate = false;
		var cache = [];
		var current:Vector3;
		var last = getPoint(0);
		var sum = 0.0;
		cache.push(0);
		for (p in 1...divisions+1) {
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

	public function getUtoTmapping(u:Float, distance:Float = -1.0):Float {
		var arcLengths = getLengths();
		var i = 0;
		var il = arcLengths.length;
		var targetArcLength:Float;
		if (distance < 0.0) {
			targetArcLength = u * arcLengths[il - 1];
		} else {
			targetArcLength = distance;
		}
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
		var lengthBefore = arcLengths[i];
		var lengthAfter = arcLengths[i + 1];
		var segmentLength = lengthAfter - lengthBefore;
		var segmentFraction = (targetArcLength - lengthBefore) / segmentLength;
		var t = (i + segmentFraction) / (il - 1);
		return t;
	}

	public function getTangent(t:Float, optionalTarget:Vector3):Vector3 {
		var delta = 0.0001;
		var t1 = t - delta;
		var t2 = t + delta;
		if (t1 < 0) t1 = 0;
		if (t2 > 1) t2 = 1;
		var pt1 = getPoint(t1);
		var pt2 = getPoint(t2);
		var tangent = optionalTarget ? optionalTarget : (pt1.isVector2 ? new Vector2() : new Vector3());
		tangent.copy(pt2).sub(pt1).normalize();
		return tangent;
	}

	public function getTangentAt(u:Float, optionalTarget:Vector3):Vector3 {
		var t = getUtoTmapping(u);
		return getTangent(t, optionalTarget);
	}

	public function computeFrenetFrames(segments:Int, closed:Bool):{tangents:Array<Vector3>, normals:Array<Vector3>, binormals:Array<Vector3>} {
		var normal = new Vector3();
		var tangents = [];
		var normals = [];
		var binormals = [];
		var vec = new Vector3();
		var mat = new Matrix4();
		for (i in 0...segments+1) {
			var u = i / segments;
			tangents[i] = getTangentAt(u, new Vector3());
		}
		var min = Number.MAX_VALUE;
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
		normals[0] = new Vector3();
		binormals[0] = new Vector3();
		normals[0].crossVectors(tangents[0], vec);
		binormals[0].crossVectors(tangents[0], normals[0]);
		for (i in 1...segments+1) {
			normals[i] = normals[i - 1].clone();
			binormals[i] = binormals[i - 1].clone();
			vec.crossVectors(tangents[i - 1], tangents[i]);
			if (vec.length() > Number.EPSILON) {
				vec.normalize();
				var theta = Math.acos(MathUtils.clamp(tangents[i - 1].dot(tangents[i]), -1, 1));
				normals[i].applyMatrix4(mat.makeRotationAxis(vec, theta));
			}
			binormals[i].crossVectors(tangents[i], normals[i]);
		}
		if (closed) {
			var theta = Math.acos(MathUtils.clamp(normals[0].dot(normals[segments]), -1, 1));
			theta /= segments;
			if (tangents[0].dot(vec.crossVectors(normals[0], normals[segments])) > 0) {
				theta = -theta;
			}
			for (i in 1...segments+1) {
				normals[i].applyMatrix4(mat.makeRotationAxis(tangents[i], theta * i));
				binormals[i].crossVectors(tangents[i], normals[i]);
			}
		}
		return {tangents: tangents, normals: normals, binormals: binormals};
	}

	public function clone():Curve {
		return cast new this.constructor().copy(this);
	}

	public function copy(source:Curve):Curve {
		arcLengthDivisions = source.arcLengthDivisions;
		return this;
	}

	public function toJSON():{metadata:{version:Float, type:String, generator:String}, arcLengthDivisions:Int, type:String} {
		var data = {
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

	public function fromJSON(json:{metadata:{version:Float, type:String, generator:String}, arcLengthDivisions:Int, type:String}):Curve {
		arcLengthDivisions = json.arcLengthDivisions;
		return this;
	}

}