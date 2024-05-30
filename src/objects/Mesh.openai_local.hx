import three.math.Vector3;
import three.math.Vector2;
import three.math.Sphere;
import three.math.Ray;
import three.math.Matrix4;
import three.core.Object3D;
import three.math.Triangle;
import three.constants.BackSide;
import three.constants.FrontSide;
import three.materials.MeshBasicMaterial;
import three.core.BufferGeometry;

class Mesh extends Object3D {
	public var isMesh:Bool;
	public var geometry:BufferGeometry;
	public var material:Dynamic; // MeshBasicMaterial or Array<MeshBasicMaterial>
	public var morphTargetInfluences:Array<Float>;
	public var morphTargetDictionary:Map<String, Int>;

	private static var _inverseMatrix:Matrix4 = new Matrix4();
	private static var _ray:Ray = new Ray();
	private static var _sphere:Sphere = new Sphere();
	private static var _sphereHitAt:Vector3 = new Vector3();

	private static var _vA:Vector3 = new Vector3();
	private static var _vB:Vector3 = new Vector3();
	private static var _vC:Vector3 = new Vector3();

	private static var _tempA:Vector3 = new Vector3();
	private static var _morphA:Vector3 = new Vector3();

	private static var _uvA:Vector2 = new Vector2();
	private static var _uvB:Vector2 = new Vector2();
	private static var _uvC:Vector2 = new Vector2();

	private static var _normalA:Vector3 = new Vector3();
	private static var _normalB:Vector3 = new Vector3();
	private static var _normalC:Vector3 = new Vector3();

	private static var _intersectionPoint:Vector3 = new Vector3();
	private static var _intersectionPointWorld:Vector3 = new Vector3();

	public function new(geometry:BufferGeometry = new BufferGeometry(), material:Dynamic = new MeshBasicMaterial()) {
		super();
		this.isMesh = true;
		this.geometry = geometry;
		this.material = material;
		this.updateMorphTargets();
	}

	public function copy(source:Mesh, recursive:Bool):Mesh {
		super.copy(source, recursive);
		if (source.morphTargetInfluences != null) {
			this.morphTargetInfluences = source.morphTargetInfluences.copy();
		}
		if (source.morphTargetDictionary != null) {
			this.morphTargetDictionary = source.morphTargetDictionary.copy();
		}
		this.material = (Std.is(source.material, Array)) ? source.material.copy() : source.material;
		this.geometry = source.geometry;
		return this;
	}

	public function updateMorphTargets():Void {
		var geometry = this.geometry;
		var morphAttributes = geometry.morphAttributes;
		var keys = morphAttributes.keys();
		if (keys.length > 0) {
			var morphAttribute = morphAttributes[keys[0]];
			if (morphAttribute != null) {
				this.morphTargetInfluences = [];
				this.morphTargetDictionary = new Map();
				for (m in 0...morphAttribute.length) {
					var name = morphAttribute[m].name != null ? morphAttribute[m].name : Std.string(m);
					this.morphTargetInfluences.push(0);
					this.morphTargetDictionary.set(name, m);
				}
			}
		}
	}

	public function getVertexPosition(index:Int, target:Vector3):Vector3 {
		var geometry = this.geometry;
		var position = geometry.attributes.position;
		var morphPosition = geometry.morphAttributes.position;
		var morphTargetsRelative = geometry.morphTargetsRelative;

		target.fromBufferAttribute(position, index);

		var morphInfluences = this.morphTargetInfluences;

		if (morphPosition != null && morphInfluences != null) {
			_morphA.set(0, 0, 0);
			for (i in 0...morphPosition.length) {
				var influence = morphInfluences[i];
				var morphAttribute = morphPosition[i];
				if (influence == 0) continue;

				_tempA.fromBufferAttribute(morphAttribute, index);

				if (morphTargetsRelative) {
					_morphA.addScaledVector(_tempA, influence);
				} else {
					_morphA.addScaledVector(_tempA.sub(target), influence);
				}
			}
			target.add(_morphA);
		}

		return target;
	}

	public function raycast(raycaster:Dynamic, intersects:Array<Dynamic>):Void {
		var geometry = this.geometry;
		var material = this.material;
		var matrixWorld = this.matrixWorld;

		if (material == null) return;

		if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

		_sphere.copy(geometry.boundingSphere);
		_sphere.applyMatrix4(matrixWorld);

		_ray.copy(raycaster.ray).recast(raycaster.near);

		if (!_sphere.containsPoint(_ray.origin)) {
			if (_ray.intersectSphere(_sphere, _sphereHitAt) == null) return;
			if (_ray.origin.distanceToSquared(_sphereHitAt) > Math.pow(raycaster.far - raycaster.near, 2)) return;
		}

		_inverseMatrix.copy(matrixWorld).invert();
		_ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);

		if (geometry.boundingBox != null) {
			if (!_ray.intersectsBox(geometry.boundingBox)) return;
		}

		this._computeIntersections(raycaster, intersects, _ray);
	}

	private function _computeIntersections(raycaster:Dynamic, intersects:Array<Dynamic>, rayLocalSpace:Ray):Void {
		var intersection:Dynamic;

		var geometry = this.geometry;
		var material = this.material;

		var index = geometry.index;
		var position = geometry.attributes.position;
		var uv = geometry.attributes.uv;
		var uv1 = geometry.attributes.uv1;
		var normal = geometry.attributes.normal;
		var groups = geometry.groups;
		var drawRange = geometry.drawRange;

		if (index != null) {
			if (Std.is(material, Array)) {
				for (group in groups) {
					var groupMaterial = material[group.materialIndex];
					var start = Math.max(group.start, drawRange.start);
					var end = Math.min(index.count, Math.min(group.start + group.count, drawRange.start + drawRange.count));
					for (j in start...end step 3) {
						var a = index.getX(j);
						var b = index.getX(j + 1);
						var c = index.getX(j + 2);
						intersection = checkGeometryIntersection(this, groupMaterial, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);
						if (intersection != null) {
							intersection.faceIndex = Math.floor(j / 3);
							intersection.face.materialIndex = group.materialIndex;
							intersects.push(intersection);
						}
					}
				}
			} else {
				var start = Math.max(0, drawRange.start);
				var end = Math.min(index.count, drawRange.start + drawRange.count);
				for (i in start...end step 3) {
					var a = index.getX(i);
					var b = index.getX(i + 1);
					var c = index.getX(i + 2);
					intersection = checkGeometryIntersection(this, material, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);
					if (intersection != null) {
						intersection.faceIndex = Math.floor(i / 3);
						intersects.push(intersection);
					}
				}
			}
		} else if (position != null) {
			if (Std.is(material, Array)) {
				for (group in groups) {
					var groupMaterial = material[group.materialIndex];
					var start = Math.max(group.start, drawRange.start);
					var end = Math.min(position.count, Math.min(group.start + group.count, drawRange.start + drawRange.count));
					for (j in start...end step 3) {
						var a = j;
						var b = j + 1;
						var c = j + 2;
						intersection = checkGeometryIntersection(this, groupMaterial, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);
						if (intersection != null) {
							intersection.faceIndex = Math.floor(j / 3);
							intersection.face.materialIndex = group.materialIndex;
							intersects.push(intersection);
						}
					}
				}
			} else {
				var start = Math.max(0, drawRange.start);
				var end = Math.min(position.count, drawRange.start + drawRange.count);
				for (i in start...end step 3) {
					var a = i;
					var b = i + 1;
					var c = i + 2;
					intersection = checkGeometryIntersection(this, material, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);
					if (intersection != null) {
						intersection.faceIndex = Math.floor(i / 3);
						intersects.push(intersection);
					}
				}
			}
		}
	}

	private static function checkIntersection(object:Mesh, material:Dynamic, raycaster:Dynamic, ray:Ray, pA:Vector3, pB:Vector3, pC:Vector3, point:Vector3):Dynamic {
		var intersect = if (material.side == BackSide) {
			ray.intersectTriangle(pC, pB, pA, true, point);
		} else {
			ray.intersectTriangle(pA, pB, pC, material.side == FrontSide, point);
		}

		if (intersect == null) return null;

		_intersectionPointWorld.copy(point);
		_intersectionPointWorld.applyMatrix4(object.matrixWorld);

		var distance = raycaster.ray.origin.distanceTo(_intersectionPointWorld);
		if (distance < raycaster.near || distance > raycaster.far) return null;

		return {
			distance: distance,
			point: _intersectionPointWorld.clone(),
			object: object
		};
	}

	private static function checkGeometryIntersection(object:Mesh, material:Dynamic, raycaster:Dynamic, ray:Ray, uv:BufferAttribute, uv1:BufferAttribute, normal:BufferAttribute, a:Int, b:Int, c:Int):Dynamic {
		object.getVertexPosition(a, _vA);
		object.getVertexPosition(b, _vB);
		object.getVertexPosition(c, _vC);

		var intersection = checkIntersection(object, material, raycaster, ray, _vA, _vB, _vC, _intersectionPoint);
		if (intersection != null) {
			if (uv != null) {
				_uvA.fromBufferAttribute(uv, a);
				_uvB.fromBufferAttribute(uv, b);
				_uvC.fromBufferAttribute(uv, c);
				intersection.uv = Triangle.getInterpolation(_intersectionPoint, _vA, _vB, _vC, _uvA, _uvB, _uvC, new Vector2());
			}
			if (uv1 != null) {
				_uvA.fromBufferAttribute(uv1, a);
				_uvB.fromBufferAttribute(uv1, b);
				_uvC.fromBufferAttribute(uv1, c);
				intersection.uv1 = Triangle.getInterpolation(_intersectionPoint, _vA, _vB, _vC, _uvA, _uvB, _uvC, new Vector2());
			}
			if (normal != null) {
				_normalA.fromBufferAttribute(normal, a);
				_normalB.fromBufferAttribute(normal, b);
				_normalC.fromBufferAttribute(normal, c);
				intersection.normal = Triangle.getInterpolation(_intersectionPoint, _vA, _vB, _vC, _normalA, _normalB, _normalC, new Vector3());
				if (intersection.normal.dot(ray.direction) > 0) {
					intersection.normal.multiplyScalar(-1);
				}
			}

			var face = {
				a: a,
				b: b,
				c: c,
				normal: new Vector3(),
				materialIndex: 0
			};
			Triangle.getNormal(_vA, _vB, _vC, face.normal);
			intersection.face = face;
		}
		return intersection;
	}
}