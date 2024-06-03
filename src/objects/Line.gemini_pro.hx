import three.math.Sphere;
import three.math.Ray;
import three.math.Matrix4;
import three.core.Object3D;
import three.math.Vector3;
import three.materials.LineBasicMaterial;
import three.core.BufferGeometry;
import three.core.BufferAttribute;

class Line extends Object3D {

	public var isLine:Bool = true;
	public var type:String = "Line";
	public var geometry:BufferGeometry;
	public var material:LineBasicMaterial;

	public function new(?geometry:BufferGeometry = null, ?material:LineBasicMaterial = null) {
		super();
		this.geometry = geometry != null ? geometry : new BufferGeometry();
		this.material = material != null ? material : new LineBasicMaterial();
		this.updateMorphTargets();
	}

	public function copy(source:Line, recursive:Bool):Line {
		super.copy(source, recursive);
		this.material = source.material;
		this.geometry = source.geometry;
		return this;
	}

	public function computeLineDistances():Line {
		var geometry = this.geometry;

		if (geometry.index == null) {
			var positionAttribute = geometry.attributes.position;
			var lineDistances = [0];
			for (i in 1...positionAttribute.count) {
				_vStart.fromBufferAttribute(positionAttribute, i - 1);
				_vEnd.fromBufferAttribute(positionAttribute, i);

				lineDistances[i] = lineDistances[i - 1] + _vStart.distanceTo(_vEnd);
			}

			geometry.setAttribute('lineDistance', new Float32BufferAttribute(lineDistances, 1));
		} else {
			console.warn('THREE.Line.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.');
		}

		return this;
	}

	public function raycast(raycaster:Dynamic, intersects:Array<Dynamic>):Void {
		var geometry = this.geometry;
		var matrixWorld = this.matrixWorld;
		var threshold = raycaster.params.Line.threshold;
		var drawRange = geometry.drawRange;

		if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

		_sphere.copy(geometry.boundingSphere);
		_sphere.applyMatrix4(matrixWorld);
		_sphere.radius += threshold;

		if (!raycaster.ray.intersectsSphere(_sphere)) return;

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
				if (i % step != 0) continue;
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
				if (i % step != 0) continue;
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
				this.morphTargetDictionary = new Map<String, Int>();

				for (m in 0...morphAttribute.length) {
					var name = morphAttribute[m].name != null ? morphAttribute[m].name : Std.string(m);

					this.morphTargetInfluences.push(0);
					this.morphTargetDictionary.set(name, m);
				}
			}
		}
	}
}

private static var _vStart:Vector3 = new Vector3();
private static var _vEnd:Vector3 = new Vector3();
private static var _inverseMatrix:Matrix4 = new Matrix4();
private static var _ray:Ray = new Ray();
private static var _sphere:Sphere = new Sphere();
private static var _intersectPointOnRay:Vector3 = new Vector3();
private static var _intersectPointOnSegment:Vector3 = new Vector3();

private static function checkIntersection(object:Line, raycaster:Dynamic, ray:Ray, thresholdSq:Float, a:Int, b:Int):Dynamic {
	var positionAttribute = object.geometry.attributes.position;

	_vStart.fromBufferAttribute(positionAttribute, a);
	_vEnd.fromBufferAttribute(positionAttribute, b);

	var distSq = ray.distanceSqToSegment(_vStart, _vEnd, _intersectPointOnRay, _intersectPointOnSegment);

	if (distSq > thresholdSq) return null;

	_intersectPointOnRay.applyMatrix4(object.matrixWorld);
	var distance = raycaster.ray.origin.distanceTo(_intersectPointOnRay);

	if (distance < raycaster.near || distance > raycaster.far) return null;

	return {
		distance: distance,
		point: _intersectPointOnSegment.clone().applyMatrix4(object.matrixWorld),
		index: a,
		face: null,
		faceIndex: null,
		object: object
	};
}