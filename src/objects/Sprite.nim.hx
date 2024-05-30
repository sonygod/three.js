import Vector2.{Vector2, vector2}
import Vector3.{Vector3, vector3}
import Matrix4.{Matrix4, matrix4}
import Triangle.{Triangle, triangle}
import Object3D.{Object3D, object3D}
import BufferGeometry.{BufferGeometry, bufferGeometry}
import InterleavedBuffer.{InterleavedBuffer, interleavedBuffer}
import InterleavedBufferAttribute.{InterleavedBufferAttribute, interleavedBufferAttribute}
import SpriteMaterial.{SpriteMaterial, spriteMaterial}

var _geometry:BufferGeometry;

var _intersectPoint:Vector3 = Vector3.create();
var _worldScale:Vector3 = Vector3.create();
var _mvPosition:Vector3 = Vector3.create();

var _alignedPosition:Vector2 = Vector2.create();
var _rotatedPosition:Vector2 = Vector2.create();
var _viewWorldMatrix:Matrix4 = Matrix4.create();

var _vA:Vector3 = Vector3.create();
var _vB:Vector3 = Vector3.create();
var _vC:Vector3 = Vector3.create();

var _uvA:Vector2 = Vector2.create();
var _uvB:Vector2 = Vector2.create();
var _uvC:Vector2 = Vector2.create();

class Sprite extends Object3D {

	public function new(material:SpriteMaterial = spriteMaterial()) {

		super();

		this.isSprite = true;

		this.type = 'Sprite';

		if (_geometry == null) {

			_geometry = new BufferGeometry();

			var float32Array:Float32Array = new Float32Array([
				-0.5, -0.5, 0, 0, 0,
				0.5, -0.5, 0, 1, 0,
				0.5, 0.5, 0, 1, 1,
				-0.5, 0.5, 0, 0, 1
			]);

			var interleavedBuffer:InterleavedBuffer = new InterleavedBuffer(float32Array, 5);

			_geometry.setIndex([0, 1, 2, 0, 2, 3]);
			_geometry.setAttribute('position', new InterleavedBufferAttribute(interleavedBuffer, 3, 0, false));
			_geometry.setAttribute('uv', new InterleavedBufferAttribute(interleavedBuffer, 2, 3, false));

		}

		this.geometry = _geometry;
		this.material = material;

		this.center = new Vector2(0.5, 0.5);

	}

	public function raycast(raycaster:Raycaster, intersects:Array<Dynamic>) {

		if (raycaster.camera == null) {

			throw 'THREE.Sprite: "Raycaster.camera" needs to be set in order to raycast against sprites.';

		}

		_worldScale.setFromMatrixScale(this.matrixWorld);

		_viewWorldMatrix.copy(raycaster.camera.matrixWorld);
		this.modelViewMatrix.multiplyMatrices(raycaster.camera.matrixWorldInverse, this.matrixWorld);

		_mvPosition.setFromMatrixPosition(this.modelViewMatrix);

		if (raycaster.camera.isPerspectiveCamera && this.material.sizeAttenuation == false) {

			_worldScale.multiplyScalar(-_mvPosition.z);

		}

		var rotation:Float = this.material.rotation;
		var sin:Float, cos:Float;

		if (rotation != 0) {

			cos = Math.cos(rotation);
			sin = Math.sin(rotation);

		}

		var center:Vector2 = this.center;

		transformVertex(_vA.set(-0.5, -0.5, 0), _mvPosition, center, _worldScale, sin, cos);
		transformVertex(_vB.set(0.5, -0.5, 0), _mvPosition, center, _worldScale, sin, cos);
		transformVertex(_vC.set(0.5, 0.5, 0), _mvPosition, center, _worldScale, sin, cos);

		_uvA.set(0, 0);
		_uvB.set(1, 0);
		_uvC.set(1, 1);

		// check first triangle
		var intersect:Dynamic = raycaster.ray.intersectTriangle(_vA, _vB, _vC, false, _intersectPoint);

		if (intersect == null) {

			// check second triangle
			transformVertex(_vB.set(-0.5, 0.5, 0), _mvPosition, center, _worldScale, sin, cos);
			_uvB.set(0, 1);

			intersect = raycaster.ray.intersectTriangle(_vA, _vC, _vB, false, _intersectPoint);
			if (intersect == null) {

				return;

			}

		}

		var distance:Float = raycaster.ray.origin.distanceTo(_intersectPoint);

		if (distance < raycaster.near || distance > raycaster.far) return;

		intersects.push({

			distance: distance,
			point: _intersectPoint.clone(),
			uv: Triangle.getInterpolation(_intersectPoint, _vA, _vB, _vC, _uvA, _uvB, _uvC, new Vector2()),
			face: null,
			object: this

		});

	}

	public function copy(source:Sprite, recursive:Bool) {

		super.copy(source, recursive);

		if (source.center != null) this.center.copy(source.center);

		this.material = source.material;

		return this;

	}

}

function transformVertex(vertexPosition:Vector3, mvPosition:Vector3, center:Vector2, scale:Vector3, sin:Float, cos:Float) {

	// compute position in camera space
	_alignedPosition.subVectors(vertexPosition, center).addScalar(0.5).multiply(scale);

	// to check if rotation is not zero
	if (sin != null) {

		_rotatedPosition.x = (cos * _alignedPosition.x) - (sin * _alignedPosition.y);
		_rotatedPosition.y = (sin * _alignedPosition.x) + (cos * _alignedPosition.y);

	} else {

		_rotatedPosition.copy(_alignedPosition);

	}

	vertexPosition.copy(mvPosition);
	vertexPosition.x += _rotatedPosition.x;
	vertexPosition.y += _rotatedPosition.y;

	// transform to world space
	vertexPosition.applyMatrix4(_viewWorldMatrix);

}