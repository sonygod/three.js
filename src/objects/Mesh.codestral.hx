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

	public var geometry: BufferGeometry;
	public var material: Material;
	public var morphTargetInfluences: Array<Float>;
	public var morphTargetDictionary: haxe.ds.StringMap<Int>;

	private var _inverseMatrix: Matrix4 = new Matrix4();
	private var _ray: Ray = new Ray();
	private var _sphere: Sphere = new Sphere();
	private var _sphereHitAt: Vector3 = new Vector3();

	private var _vA: Vector3 = new Vector3();
	private var _vB: Vector3 = new Vector3();
	private var _vC: Vector3 = new Vector3();

	private var _tempA: Vector3 = new Vector3();
	private var _morphA: Vector3 = new Vector3();

	private var _uvA: Vector2 = new Vector2();
	private var _uvB: Vector2 = new Vector2();
	private var _uvC: Vector2 = new Vector2();

	private var _normalA: Vector3 = new Vector3();
	private var _normalB: Vector3 = new Vector3();
	private var _normalC: Vector3 = new Vector3();

	private var _intersectionPoint: Vector3 = new Vector3();
	private var _intersectionPointWorld: Vector3 = new Vector3();

	public function new(geometry: BufferGeometry = null, material: Material = null) {
		super();

		this.isMesh = true;
		this.type = "Mesh";
		this.geometry = geometry != null ? geometry : new BufferGeometry();
		this.material = material != null ? material : new MeshBasicMaterial();
		this.updateMorphTargets();
	}

	public function copy(source: Mesh, recursive: Bool): Mesh {
		super.copy(source, recursive);

		if (source.morphTargetInfluences != null) {
			this.morphTargetInfluences = source.morphTargetInfluences.slice();
		}

		if (source.morphTargetDictionary != null) {
			this.morphTargetDictionary = new haxe.ds.StringMap();
			for (key in source.morphTargetDictionary.keys()) {
				this.morphTargetDictionary.set(key, source.morphTargetDictionary.get(key));
			}
		}

		this.material = Array.isArray(source.material) ? source.material.slice() : source.material;
		this.geometry = source.geometry;

		return this;
	}

	public function updateMorphTargets(): Void {
		var geometry: BufferGeometry = this.geometry;
		var morphAttributes: haxe.ds.StringMap<Array<MorphAttribute>> = geometry.morphAttributes;
		var keys: Array<String> = morphAttributes.keys();

		if (keys.length > 0) {
			var morphAttribute: Array<MorphAttribute> = morphAttributes.get(keys[0]);

			if (morphAttribute != null) {
				this.morphTargetInfluences = [];
				this.morphTargetDictionary = new haxe.ds.StringMap();

				for (i in 0...morphAttribute.length) {
					var name: String = morphAttribute[i].name != null ? morphAttribute[i].name : i.toString();
					this.morphTargetInfluences.push(0.0);
					this.morphTargetDictionary.set(name, i);
				}
			}
		}
	}

	public function getVertexPosition(index: Int, target: Vector3): Vector3 {
		var geometry: BufferGeometry = this.geometry;
		var position: BufferAttribute = geometry.attributes.position;
		var morphPosition: Array<MorphAttribute> = geometry.morphAttributes.position;
		var morphTargetsRelative: Bool = geometry.morphTargetsRelative;

		target.fromBufferAttribute(position, index);

		var morphInfluences: Array<Float> = this.morphTargetInfluences;

		if (morphPosition != null && morphInfluences != null) {
			_morphA.set(0, 0, 0);

			for (i in 0...morphPosition.length) {
				var influence: Float = morphInfluences[i];
				var morphAttribute: MorphAttribute = morphPosition[i];

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

	public function raycast(raycaster: Raycaster, intersects: Array<Intersection>): Void {
		var geometry: BufferGeometry = this.geometry;
		var material: Material = this.material;
		var matrixWorld: Matrix4 = this.matrixWorld;

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

	private function _computeIntersections(raycaster: Raycaster, intersects: Array<Intersection>, rayLocalSpace: Ray): Void {
		var intersection: Intersection;
		var geometry: BufferGeometry = this.geometry;
		var material: Material = this.material;

		var index: BufferAttribute = geometry.index;
		var position: BufferAttribute = geometry.attributes.position;
		var uv: BufferAttribute = geometry.attributes.uv;
		var uv1: BufferAttribute = geometry.attributes.uv1;
		var normal: BufferAttribute = geometry.attributes.normal;
		var groups: Array<BufferGroup> = geometry.groups;
		var drawRange: DrawRange = geometry.drawRange;

		if (index != null) {
			if (Array.isArray(material)) {
				for (i in 0...groups.length) {
					var group: BufferGroup = groups[i];
					var groupMaterial: Material = material[group.materialIndex];

					var start: Int = Math.max(group.start, drawRange.start);
					var end: Int = Math.min(index.count, Math.min(group.start + group.count, drawRange.start + drawRange.count));

					for (j in start...end) {
						if ((j - start) % 3 == 0) {
							var a: Int = index.getX(j);
							var b: Int = index.getX(j + 1);
							var c: Int = index.getX(j + 2);

							intersection = checkGeometryIntersection(this, groupMaterial, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);

							if (intersection != null) {
								intersection.faceIndex = Math.floor(j / 3);
								intersection.face.materialIndex = group.materialIndex;
								intersects.push(intersection);
							}
						}
					}
				}
			} else {
				var start: Int = Math.max(0, drawRange.start);
				var end: Int = Math.min(index.count, drawRange.start + drawRange.count);

				for (i in start...end) {
					if ((i - start) % 3 == 0) {
						var a: Int = index.getX(i);
						var b: Int = index.getX(i + 1);
						var c: Int = index.getX(i + 2);

						intersection = checkGeometryIntersection(this, material, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);

						if (intersection != null) {
							intersection.faceIndex = Math.floor(i / 3);
							intersects.push(intersection);
						}
					}
				}
			}
		} else if (position != null) {
			if (Array.isArray(material)) {
				for (i in 0...groups.length) {
					var group: BufferGroup = groups[i];
					var groupMaterial: Material = material[group.materialIndex];

					var start: Int = Math.max(group.start, drawRange.start);
					var end: Int = Math.min(position.count, Math.min(group.start + group.count, drawRange.start + drawRange.count));

					for (j in start...end) {
						if ((j - start) % 3 == 0) {
							var a: Int = j;
							var b: Int = j + 1;
							var c: Int = j + 2;

							intersection = checkGeometryIntersection(this, groupMaterial, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);

							if (intersection != null) {
								intersection.faceIndex = Math.floor(j / 3);
								intersection.face.materialIndex = group.materialIndex;
								intersects.push(intersection);
							}
						}
					}
				}
			} else {
				var start: Int = Math.max(0, drawRange.start);
				var end: Int = Math.min(position.count, drawRange.start + drawRange.count);

				for (i in start...end) {
					if ((i - start) % 3 == 0) {
						var a: Int = i;
						var b: Int = i + 1;
						var c: Int = i + 2;

						intersection = checkGeometryIntersection(this, material, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);

						if (intersection != null) {
							intersection.faceIndex = Math.floor(i / 3);
							intersects.push(intersection);
						}
					}
				}
			}
		}
	}

	private static function checkIntersection(object: Mesh, material: Material, raycaster: Raycaster, ray: Ray, pA: Vector3, pB: Vector3, pC: Vector3, point: Vector3): Intersection {
		var intersect: Vector3;

		if (material.side == BackSide) {
			intersect = ray.intersectTriangle(pC, pB, pA, true, point);
		} else {
			intersect = ray.intersectTriangle(pA, pB, pC, material.side == FrontSide, point);
		}

		if (intersect == null) return null;

		object._intersectionPointWorld.copy(point);
		object._intersectionPointWorld.applyMatrix4(object.matrixWorld);

		var distance: Float = raycaster.ray.origin.distanceTo(object._intersectionPointWorld);

		if (distance < raycaster.near || distance > raycaster.far) return null;

		return {
			distance: distance,
			point: object._intersectionPointWorld.clone(),
			object: object
		};
	}

	private static function checkGeometryIntersection(object: Mesh, material: Material, raycaster: Raycaster, ray: Ray, uv: BufferAttribute, uv1: BufferAttribute, normal: BufferAttribute, a: Int, b: Int, c: Int): Intersection {
		object.getVertexPosition(a, object._vA);
		object.getVertexPosition(b, object._vB);
		object.getVertexPosition(c, object._vC);

		var intersection: Intersection = checkIntersection(object, material, raycaster, ray, object._vA, object._vB, object._vC, object._intersectionPoint);

		if (intersection != null) {
			if (uv != null) {
				object._uvA.fromBufferAttribute(uv, a);
				object._uvB.fromBufferAttribute(uv, b);
				object._uvC.fromBufferAttribute(uv, c);

				intersection.uv = Triangle.getInterpolation(object._intersectionPoint, object._vA, object._vB, object._vC, object._uvA, object._uvB, object._uvC, new Vector2());
			}

			if (uv1 != null) {
				object._uvA.fromBufferAttribute(uv1, a);
				object._uvB.fromBufferAttribute(uv1, b);
				object._uvC.fromBufferAttribute(uv1, c);

				intersection.uv1 = Triangle.getInterpolation(object._intersectionPoint, object._vA, object._vB, object._vC, object._uvA, object._uvB, object._uvC, new Vector2());
			}

			if (normal != null) {
				object._normalA.fromBufferAttribute(normal, a);
				object._normalB.fromBufferAttribute(normal, b);
				object._normalC.fromBufferAttribute(normal, c);

				intersection.normal = Triangle.getInterpolation(object._intersectionPoint, object._vA, object._vB, object._vC, object._normalA, object._normalB, object._normalC, new Vector3());

				if (intersection.normal.dot(ray.direction) > 0) {
					intersection.normal.multiplyScalar(-1);
				}
			}

			var face: Face = {
				a: a,
				b: b,
				c: c,
				normal: new Vector3(),
				materialIndex: 0
			};

			Triangle.getNormal(object._vA, object._vB, object._vC, face.normal);

			intersection.face = face;
		}

		return intersection;
	}
}