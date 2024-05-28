package math;

class Vector2 {
	var x:Float;
	var y:Float;
	public function new(x:Float, y:Float) {
		this.x = x;
		this.y = y;
	}
}

class Vector3 {
	var x:Float;
	var y:Float;
	var z:Float;
	public function new(x:Float, y:Float, z:Float) {
		this.x = x;
		this.y = y;
		this.z = z;
	}
}

class Matrix4 {
	// ...
}

class Triangle {
	// ...
}

class Object3D {
	// ...
}

class BufferGeometry {
	// ...
}

class InterleavedBuffer {
	// ...
}

class InterleavedBufferAttribute {
	// ...
}

class SpriteMaterial {
	// ...
}

class Sprite extends Object3D {
	public var isSprite:Bool;
	public var type:String;
	public var geometry:BufferGeometry;
	public var material:SpriteMaterial;
	public var center:Vector2;

	static var _geometry:BufferGeometry;
	static var _intersectPoint:Vector3;
	static var _worldScale:Vector3;
	static var _mvPosition:Vector3;
	static var _alignedPosition:Vector2;
	static var _rotatedPosition:Vector2;
	static var _viewWorldMatrix:Matrix4;
	static var _vA:Vector3;
	static var _vB:Vector3;
	static var _vC:Vector3;
	static var _uvA:Vector2;
	static var _uvB:Vector2;
	static var _uvC:Vector2;

	public function new(material:SpriteMaterial = null) {
		super();
		isSprite = true;
		type = 'Sprite';
		if (Sprite._geometry == null) {
			Sprite._geometry = new BufferGeometry();
			var float32Array = [
				-0.5, -0.5, 0, 0, 0,
				0.5, -0.5, 0, 1, 0,
				0.5, 0.5, 0, 1, 1,
				-0.5, 0.5, 0, 0, 1
			];
			var interleavedBuffer = new InterleavedBuffer(Float32Array(float32Array), 5);
			Sprite._geometry.setIndex([0, 1, 2, 0, 2, 3]);
			Sprite._geometry.setAttribute('position', new InterleavedBufferAttribute(interleavedBuffer, 3, 0, false));
			Sprite._geometry.setAttribute('uv', new InterleavedBufferAttribute(interleavedBuffer, 2, 3, false));
		}
		geometry = Sprite._geometry;
		material = material != null ? material : new SpriteMaterial();
		center = new Vector2(0.5, 0.5);
	}

	public function raycast(raycaster, intersects) {
		if (raycaster.camera == null) {
			trace('THREE.Sprite: "Raycaster.camera" needs to be set in order to raycast against sprites.');
		}
		_worldScale.setFromMatrixScale(matrixWorld);
		_viewWorldMatrix.copy(raycaster.camera.matrixWorld);
		modelViewMatrix.multiplyMatrices(raycaster.camera.matrixWorldInverse, matrixWorld);
		_mvPosition.setFromMatrixPosition(modelViewMatrix);
		if (raycaster.camera.isPerspectiveCamera && material.sizeAttenuation == false) {
			_worldScale.multiplyScalar(-_mvPosition.z);
		}
		var rotation = material.rotation;
		var sin:Float, cos:Float;
		if (rotation != 0) {
			cos = Math.cos(rotation);
			sin = Math.sin(rotation);
		}
		var center = this.center;
		transformVertex(_vA.set(-0.5, -0.5, 0), _mvPosition, center, _worldScale, sin, cos);
		transformVertex(_vB.set(0.5, -0.5, 0), _mvPosition, center, _worldScale, sin, cos);
		transformVertex(_vC.set(0.5, 0.5, 0), _mvPosition, center, _worldScale, sin, cos);
		_uvA.set(0, 0);
		_uvB.set(1, 0);
		_uvC.set(1, 1);
		var intersect = raycaster.ray.intersectTriangle(_vA, _vB, _vC, false, _intersectPoint);
		if (intersect == null) {
			transformVertex(_vB.set(-0.5, 0.5, 0), _mvPosition, center, _worldScale, sin, cos);
			_uvB.set(0, 1);
			intersect = raycaster.ray.intersectTriangle(_vA, _vC, _vB, false, _intersectPoint);
			if (intersect == null) {
				return;
			}
		}
		var distance = raycaster.ray.origin.distanceTo(_intersectPoint);
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
		if (source.center != null) center.copy(source.center);
		material = source.material;
		return this;
	}
}

function transformVertex(vertexPosition:Vector3, mvPosition:Vector3, center:Vector2, scale:Vector3, sin:Float, cos:Float) {
	_alignedPosition.subVectors(vertexPosition, center).addScalar(0.5).multiply(scale);
	if (sin != null) {
		_rotatedPosition.x = (cos * _alignedPosition.x) - (sin * _alignedPosition.y);
		_rotatedPosition.y = (sin * _alignedPosition.x) + (cos * _alignedPosition.y);
	} else {
		_rotatedPosition.copy(_alignedPosition);
	}
	vertexPosition.copy(mvPosition);
	vertexPosition.x += _rotatedPosition.x;
	vertexPosition.y += _rotatedPosition.y;
	vertexPosition.applyMatrix4(_viewWorldMatrix);
}