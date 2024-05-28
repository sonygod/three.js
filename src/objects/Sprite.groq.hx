package three.objects;

import three.math.Vector2;
import three.math.Vector3;
import three.math.Matrix4;
import three.math.Triangle;
import three.core.Object3D;
import three.core.BufferGeometry;
import three.core.InterleavedBuffer;
import three.core.InterleavedBufferAttribute;
import three.materials.SpriteMaterial;

class Sprite extends Object3D {
    public var isSprite:Bool = true;
    public var type:String = 'Sprite';

    private static var _geometry:BufferGeometry;
    private static var _intersectPoint:Vector3 = new Vector3();
    private static var _worldScale:Vector3 = new Vector3();
    private static var _mvPosition:Vector3 = new Vector3();
    private static var _alignedPosition:Vector2 = new Vector2();
    private static var _rotatedPosition:Vector2 = new Vector2();
    private static var _viewWorldMatrix:Matrix4 = new Matrix4();
    private static var _vA:Vector3 = new Vector3();
    private static var _vB:Vector3 = new Vector3();
    private static var _vC:Vector3 = new Vector3();
    private static var _uvA:Vector2 = new Vector2();
    private static var _uvB:Vector2 = new Vector2();
    private static var _uvC:Vector2 = new Vector2();

    public function new(?material:SpriteMaterial) {
        super();
        if (material == null) material = new SpriteMaterial();
        this.geometry = _geometry;
        this.material = material;
        this.center = new Vector2(0.5, 0.5);
        if (_geometry == null) {
            _geometry = new BufferGeometry();
            var float32Array:Array<Float> = [-0.5, -0.5, 0, 0, 0, 0.5, -0.5, 0, 1, 0, 0.5, 0.5, 0, 1, 1, -0.5, 0.5, 0, 0, 1];
            var interleavedBuffer:InterleavedBuffer = new InterleavedBuffer(float32Array, 5);
            _geometry.setIndex([0, 1, 2, 0, 2, 3]);
            _geometry.setAttribute('position', new InterleavedBufferAttribute(interleavedBuffer, 3, 0, false));
            _geometry.setAttribute('uv', new InterleavedBufferAttribute(interleavedBuffer, 2, 3, false));
        }
    }

    override public function raycast(raycaster:Raycaster, intersects:Array<RaycastHit>) : Void {
        if (raycaster.camera == null) {
            trace("THREE.Sprite: \"Raycaster.camera\" needs to be set in order to raycast against sprites.");
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
        var intersect:Vector3 = raycaster.ray.intersectTriangle(_vA, _vB, _vC, false, _intersectPoint);
        if (intersect == null) {
            transformVertex(_vB.set(-0.5, 0.5, 0), _mvPosition, center, _worldScale, sin, cos);
            _uvB.set(0, 1);
            intersect = raycaster.ray.intersectTriangle(_vA, _vC, _vB, false, _intersectPoint);
            if (intersect == null) return;
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

    override public function copy(source:Object3D, recursive:Bool) : Sprite {
        super.copy(source, recursive);
        if (source.center != null) this.center.copy(source.center);
        this.material = source.material;
        return this;
    }

    private static function transformVertex(vertexPosition:Vector3, mvPosition:Vector3, center:Vector2, scale:Vector3, sin:Float, cos:Float) : Void {
        _alignedPosition.subVectors(vertexPosition, center).addScalar(0.5).multiply(scale);
        if (sin != 0) {
            _rotatedPosition.x = cos * _alignedPosition.x - sin * _alignedPosition.y;
            _rotatedPosition.y = sin * _alignedPosition.x + cos * _alignedPosition.y;
        } else {
            _rotatedPosition.copy(_alignedPosition);
        }
        vertexPosition.copy(mvPosition);
        vertexPosition.x += _rotatedPosition.x;
        vertexPosition.y += _rotatedPosition.y;
        vertexPosition.applyMatrix4(_viewWorldMatrix);
    }
}