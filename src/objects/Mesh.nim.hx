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

	public var isMesh:Bool = true;
	public var type:String = 'Mesh';
	public var geometry:BufferGeometry;
	public var material:MeshBasicMaterial;
	public var morphTargetInfluences:Array<Float>;
	public var morphTargetDictionary:Map<String, Int>;

	public function new(geometry:BufferGeometry = new BufferGeometry(), material:MeshBasicMaterial = new MeshBasicMaterial()) {

		super();

		this.geometry = geometry;
		this.material = material;

		this.updateMorphTargets();

	}

	public function copy(source:Mesh, recursive:Bool):Mesh {

		super.copy(source, recursive);

		if (source.morphTargetInfluences != null) {
			this.morphTargetInfluences = source.morphTargetInfluences.slice();
		}

		if (source.morphTargetDictionary != null) {
			this.morphTargetDictionary = source.morphTargetDictionary.clone();
		}

		this.material = Array.isArray(source.material) ? source.material.slice() : source.material;
		this.geometry = source.geometry;

		return this;

	}

	public function updateMorphTargets() {

		const geometry = this.geometry;
		const morphAttributes = geometry.morphAttributes;
		const keys = Reflect.fields(morphAttributes);

		if (keys.length > 0) {

			const morphAttribute = morphAttributes[keys[0]];

			if (morphAttribute != null) {

				this.morphTargetInfluences = [];
				this.morphTargetDictionary = new Map<String, Int>();

				for (m <- 0...morphAttribute.length) {

					const name = morphAttribute[m].name ?? Std.string(m);

					this.morphTargetInfluences.push(0);
					this.morphTargetDictionary.set(name, m);

				}

			}

		}

	}

	public function getVertexPosition(index:Int, target:Vector3):Vector3 {

		const geometry = this.geometry;
		const position = geometry.attributes.position;
		const morphPosition = geometry.morphAttributes.position;
		const morphTargetsRelative = geometry.morphTargetsRelative;

		target.fromBufferAttribute(position, index);

		const morphInfluences = this.morphTargetInfluences;

		if (morphPosition != null && morphInfluences != null) {

			_morphA.set(0, 0, 0);

			for (i <- 0...morphPosition.length) {

				const influence = morphInfluences[i];
				const morphAttribute = morphPosition[i];

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

	public function raycast(raycaster:Raycaster, intersects:Array<Dynamic>):Void {

		const geometry = this.geometry;
		const material = this.material;
		const matrixWorld = this.matrixWorld;

		if (material == null) return;

		// test with bounding sphere in world space

		if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

		_sphere.copy(geometry.boundingSphere);
		_sphere.applyMatrix4(matrixWorld);

		// check distance from ray origin to bounding sphere

		_ray.copy(raycaster.ray).recast(raycaster.near);

		if (_sphere.containsPoint(_ray.origin) == false) {

			if (_ray.intersectSphere(_sphere, _sphereHitAt) == null) return;

			if (_ray.origin.distanceToSquared(_sphereHitAt) > (raycaster.far - raycaster.near) ** 2) return;

		}

		// convert ray to local space of mesh

		_inverseMatrix.copy(matrixWorld).invert();
		_ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);

		// test with bounding box in local space

		if (geometry.boundingBox != null) {

			if (_ray.intersectsBox(geometry.boundingBox) == false) return;

		}

		// test for intersections with geometry

		this._computeIntersections(raycaster, intersects, _ray);

	}

	private function _computeIntersections(raycaster:Raycaster, intersects:Array<Dynamic>, rayLocalSpace:Ray):Void {

		let intersection:Dynamic;

		const geometry = this.geometry;
		const material = this.material;

		const index = geometry.index;
		const position = geometry.attributes.position;
		const uv = geometry.attributes.uv;
		const uv1 = geometry.attributes.uv1;
		const normal = geometry.attributes.normal;
		const groups = geometry.groups;
		const drawRange = geometry.drawRange;

		if (index != null) {

			// indexed buffer geometry

			if (Array.isArray(material)) {

				for (i <- 0...groups.length) {

					const group = groups[i];
					const groupMaterial = material[group.materialIndex];

					const start = Math.max(group.start, drawRange.start);
					const end = Math.min(index.count, Math.min((group.start + group.count), (drawRange.start + drawRange.count)));

					for (j <- start...end by 3) {

						const a = index.getX(j);
						const b = index.getX(j + 1);
						const c = index.getX(j + 2);

						intersection = checkGeometryIntersection(this, groupMaterial, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);

						if (intersection != null) {

							intersection.faceIndex = Math.floor(j / 3); // triangle number in indexed buffer semantics
							intersection.face.materialIndex = group.materialIndex;
							intersects.push(intersection);

						}

					}

				}

			} else {

				const start = Math.max(0, drawRange.start);
				const end = Math.min(index.count, (drawRange.start + drawRange.count));

				for (i <- start...end by 3) {

					const a = index.getX(i);
					const b = index.getX(i + 1);
					const c = index.getX(i + 2);

					intersection = checkGeometryIntersection(this, material, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);

					if (intersection != null) {

						intersection.faceIndex = Math.floor(i / 3); // triangle number in indexed buffer semantics
						intersects.push(intersection);

					}

				}

			}

		} else if (position != null) {

			// non-indexed buffer geometry

			if (Array.isArray(material)) {

				for (i <- 0...groups.length) {

					const group = groups[i];
					const groupMaterial = material[group.materialIndex];

					const start = Math.max(group.start, drawRange.start);
					const end = Math.min(position.count, Math.min((group.start + group.count), (drawRange.start + drawRange.count)));

					for (j <- start...end by 3) {

						const a = j;
						const b = j + 1;
						const c = j + 2;

						intersection = checkGeometryIntersection(this, groupMaterial, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);

						if (intersection != null) {

							intersection.faceIndex = Math.floor(j / 3); // triangle number in non-indexed buffer semantics
							intersection.face.materialIndex = group.materialIndex;
							intersects.push(intersection);

						}

					}

				}

			} else {

				const start = Math.max(0, drawRange.start);
				const end = Math.min(position.count, (drawRange.start + drawRange.count));

				for (i <- start...end by 3) {

					const a = i;
					const b = i + 1;
					const c = i + 2;

					intersection = checkGeometryIntersection(this, material, raycaster, rayLocalSpace, uv, uv1, normal, a, b, c);

					if (intersection != null) {

						intersection.faceIndex = Math.floor(i / 3); // triangle number in non-indexed buffer semantics
						intersects.push(intersection);

					}

				}

			}

		}

	}

}

function checkIntersection(object:Mesh, material:MeshBasicMaterial, raycaster:Raycaster, ray:Ray, pA:Vector3, pB:Vector3, pC:Vector3, point:Vector3):Dynamic {

	let intersect:Dynamic;

	if (material.side == BackSide) {

		intersect = ray.intersectTriangle(pC, pB, pA, true, point);

	} else {

		intersect = ray.intersectTriangle(pA, pB, pC, (material.side == FrontSide), point);

	}

	if (intersect == null) return null;

	_intersectionPointWorld.copy(point);
	_intersectionPointWorld.applyMatrix4(object.matrixWorld);

	const distance = raycaster.ray.origin.distanceTo(_intersectionPointWorld);

	if (distance < raycaster.near || distance > raycaster.far) return null;

	return {
		distance: distance,
		point: _intersectionPointWorld.clone(),
		object: object
	};

}

function checkGeometryIntersection(object:Mesh, material:MeshBasicMaterial, raycaster:Raycaster, ray:Ray, uv:Vector2, uv1:Vector2, normal:Vector3, a:Int, b:Int, c:Int):Dynamic {

	object.getVertexPosition(a, _vA);
	object.getVertexPosition(b, _vB);
	object.getVertexPosition(c, _vC);

	const intersection = checkIntersection(object, material, raycaster, ray, _vA, _vB, _vC, _intersectionPoint);

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

		const face = {
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