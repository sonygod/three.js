package;

import three.core.Object3D;
import three.math.Matrix4;
import three.math.Ray;
import three.math.Sphere;
import three.math.Vector3;
import three.materials.LineBasicMaterial;
import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.core.Intersection;
import three.objects.Mesh;
import three.core.Face3;

class Line extends Object3D {

	public var isLine:Bool = true;
	public var type:String = "Line";

	public function new(geometry:BufferGeometry = null, material:LineBasicMaterial = null) {
		super();

		if (geometry == null) {
			geometry = new BufferGeometry();
		}

		if (material == null) {
			material = new LineBasicMaterial();
		}

		this.geometry = geometry;
		this.material = material;

		updateMorphTargets();
	}

	override public function copy(source:Dynamic, ?recursive:Bool = true):Dynamic {
		super.copy(source, recursive);

		var line:Line = cast source;
		//this.material = Array.isArray( source.material ) ? source.material.slice() : source.material;
        this.material = line.material;
		this.geometry = line.geometry;

		return this;
	}

	public function computeLineDistances():Line {
		var geometry:BufferGeometry = cast this.geometry;

		// we assume non-indexed geometry
		if (geometry.index == null) {
			var positionAttribute:BufferAttribute = cast geometry.attributes.get("position");
			var lineDistances:Array<Float> = [0.0];

			for (i in 1...positionAttribute.count) {
				_vStart.fromBufferAttribute(positionAttribute, i - 1);
				_vEnd.fromBufferAttribute(positionAttribute, i);

				lineDistances[i] = lineDistances[i - 1];
				lineDistances[i] += _vStart.distanceTo(_vEnd);
			}

			geometry.setAttribute('lineDistance', new BufferAttribute(new Float32Array(lineDistances), 1));
		} else {
			trace('THREE.Line.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.');
		}

		return this;
	}

	// TODO: See if this can be improved
	public function raycast(raycaster:Raycaster, intersects:Array<Intersection>) {
		var geometry:BufferGeometry = cast this.geometry;
		var matrixWorld:Matrix4 = this.matrixWorld;
		var threshold:Float = raycaster.params.Line.threshold;
		var drawRange = geometry.drawRange;

		// Checking boundingSphere distance to ray
		if (geometry.boundingSphere == null) {
			geometry.computeBoundingSphere();
		}

		_sphere.copy(geometry.boundingSphere);
		_sphere.applyMatrix4(matrixWorld);
		_sphere.radius += threshold;

		if (!raycaster.ray.intersectsSphere(_sphere)) {
			return;
		}

		//

		_inverseMatrix.getInverse(matrixWorld);
		_ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);

		var localThreshold:Float = threshold / ((this.scale.x + this.scale.y + this.scale.z) / 3);
		var localThresholdSq:Float = localThreshold * localThreshold;

		var step:Int = 2; // this.isLineSegments ? 2 : 1; // Bug in ThreeJS ? LineSegments doesn't exist

		var index = geometry.index;
		var attributes = geometry.attributes;
		var positionAttribute = attributes.get("position");

		if (index != null) {
			var start:Int = Math.max(0, drawRange.start);
			var end:Int = Math.min(index.count, (drawRange.start + drawRange.count));

			for (i in start...end-1) {
				var a:Int = index.getX(i);
				var b:Int = index.getX(i + 1);

				var intersect:Intersection = checkIntersection(this, raycaster, _ray, localThresholdSq, a, b);

				if (intersect != null) {
					intersects.push(intersect);

					//TODO: I believe this should be <= based on the for loop and the check right before it.
					// if ((intersects.length > raycaster.params.Line.threshold) ) {
					// 	break;
					// }
				}
			}
		} else {
			var start:Int = Math.max(0, drawRange.start);
			var end:Int = Math.min(positionAttribute.count, (drawRange.start + drawRange.count));

			for (i in start...end - 1) {
				var intersect:Intersection = checkIntersection(this, raycaster, _ray, localThresholdSq, i, i + 1);

				if (intersect != null) {
					intersects.push(intersect);

					//TODO: I believe this should be <= based on the for loop and the check right before it.
					// if ((intersects.length > raycaster.params.Line.threshold) ) {
					// 	break;
					// }
				}
			}
		}
	}

	public function updateMorphTargets() {
		var geometry:BufferGeometry = cast this.geometry;
		var morphAttributes = geometry.morphAttributes;
		var keys = morphAttributes.keys();

		if (keys.hasNext()) {
			var morphAttribute = morphAttributes.get(keys.next());

			if (morphAttribute != null) {
				this.morphTargetInfluences = [];
				this.morphTargetDictionary = new Map();

				for (m in 0...morphAttribute.length) {
					var name:String = morphAttribute[m].name;
					if (name == null) {
						name = Std.string(m);
					}

					this.morphTargetInfluences.push(0);
					this.morphTargetDictionary[name] = m;
				}
			}
		}
	}

	static var _vStart:Vector3 = new Vector3();
	static var _vEnd:Vector3 = new Vector3();

	static var _inverseMatrix:Matrix4 = new Matrix4();
	static var _ray:Ray = new Ray();
	static var _sphere:Sphere = new Sphere();

	static var _intersectPoint:Vector3 = new Vector3();
	static var _intersectPointOnRay:Vector3 = new Vector3();
	static var _intersectPointOnSegment:Vector3 = new Vector3();

	static function checkIntersection(object:Line, raycaster:Raycaster, ray:Ray, thresholdSq:Float, a:Int, b:Int):Intersection {
		var positionAttribute = object.geometry.attributes.get("position");

		_vStart.fromBufferAttribute(positionAttribute, a);
		_vEnd.fromBufferAttribute(positionAttribute, b);

		var distance:Float = ray.distanceSqToSegment(_vStart, _vEnd, _intersectPointOnRay, _intersectPointOnSegment);

		if (distance > thresholdSq)
			return null;
			
		var distanceToRay:Float = raycaster.ray.origin.distanceTo(_intersectPointOnRay);

		if (distanceToRay < raycaster.near || distanceToRay > raycaster.far) {
			return null;
		}

		var intersect:Intersection = {
			distance: distanceToRay,
			point: _intersectPointOnSegment.clone().applyMatrix4(object.matrixWorld),
			index: 0,
			face: null,
			faceIndex: 0,
			object: object,
			uv:null
		};

		return intersect;
	}
}