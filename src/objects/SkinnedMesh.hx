package objects;

import three.core.Mesh;
import three.math.Box3;
import three.math.Matrix4;
import three.math.Sphere;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Ray;
import three.constants.AttachedBindMode;
import three.constants.DetachedBindMode;

class SkinnedMesh extends Mesh {
    public var isSkinnedMesh:Bool = true;
    public var type:String = 'SkinnedMesh';
    public var bindMode:Int;
    public var bindMatrix:Matrix4;
    public var bindMatrixInverse:Matrix4;
    public var boundingBox:Box3;
    public var boundingSphere:Sphere;
    public var skeleton:Dynamic;

    private var _basePosition:Vector3 = new Vector3();
    private var _skinIndex:Vector4 = new Vector4();
    private var _skinWeight:Vector4 = new Vector4();
    private var _vector3:Vector3 = new Vector3();
    private var _matrix4:Matrix4 = new Matrix4();
    private var _vertex:Vector3 = new Vector3();
    private var _sphere:Sphere = new Sphere();
    private var _inverseMatrix:Matrix4 = new Matrix4();
    private var _ray:Ray = new Ray();

    public function new(geometry:Dynamic, material:Dynamic) {
        super(geometry, material);
        bindMode = AttachedBindMode;
        bindMatrix = new Matrix4();
        bindMatrixInverse = new Matrix4();
        boundingBox = null;
        boundingSphere = null;
    }

    public function computeBoundingBox() {
        var geometry = this.geometry;
        if (boundingBox == null) {
            boundingBox = new Box3();
        }
        boundingBox.makeEmpty();
        var positionAttribute = geometry.getAttribute('position');
        for (i in 0...positionAttribute.count) {
            getVertexPosition(i, _vertex);
            boundingBox.expandByPoint(_vertex);
        }
    }

    public function computeBoundingSphere() {
        var geometry = this.geometry;
        if (boundingSphere == null) {
            boundingSphere = new Sphere();
        }
        boundingSphere.makeEmpty();
        var positionAttribute = geometry.getAttribute('position');
        for (i in 0...positionAttribute.count) {
            getVertexPosition(i, _vertex);
            boundingSphere.expandByPoint(_vertex);
        }
    }

    public function copy(source:SkinnedMesh, recursive:Bool) {
        super.copy(source, recursive);
        bindMode = source.bindMode;
        bindMatrix.copy(source.bindMatrix);
        bindMatrixInverse.copy(source.bindMatrixInverse);
        skeleton = source.skeleton;
        if (source.boundingBox != null) boundingBox = source.boundingBox.clone();
        if (source.boundingSphere != null) boundingSphere = source.boundingSphere.clone();
        return this;
    }

    public function raycast(raycaster:Dynamic, intersects:Array<Dynamic>) {
        var material = this.material;
        var matrixWorld = this.matrixWorld;
        if (material == null) return;
        if (boundingSphere == null) computeBoundingSphere();
        _sphere.copy(boundingSphere);
        _sphere.applyMatrix4(matrixWorld);
        if (!_ray.intersectsSphere(_sphere)) return;
        _inverseMatrix.copy(matrixWorld).invert();
        _ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);
        if (boundingBox != null) {
            if (!_ray.intersectsBox(boundingBox)) return;
        }
        _computeIntersections(raycaster, intersects, _ray);
    }

    public function getVertexPosition(index:Int, target:Vector3) {
        super.getVertexPosition(index, target);
        applyBoneTransform(index, target);
        return target;
    }

    public function bind(skeleton:Dynamic, bindMatrix:Matrix4) {
        this.skeleton = skeleton;
        if (bindMatrix == null) {
            updateMatrixWorld(true);
            skeleton.calculateInverses();
            bindMatrix = matrixWorld;
        }
        bindMatrix.copy(bindMatrix);
        bindMatrixInverse.copy(bindMatrix).invert();
    }

    public function pose() {
        skeleton.pose();
    }

    public function normalizeSkinWeights() {
        var vector = new Vector4();
        var skinWeight = geometry.attributes.skinWeight;
        for (i in 0...skinWeight.count) {
            vector.fromBufferAttribute(skinWeight, i);
            var scale = 1.0 / vector.manhattanLength();
            if (scale != Math.POSITIVE_INFINITY) {
                vector.multiplyScalar(scale);
            } else {
                vector.set(1, 0, 0, 0); // do something reasonable
            }
            skinWeight.setXYZW(i, vector.x, vector.y, vector.z, vector.w);
        }
    }

    public function updateMatrixWorld(force:Bool) {
        super.updateMatrixWorld(force);
        if (bindMode == AttachedBindMode) {
            bindMatrixInverse.copy(matrixWorld).invert();
        } else if (bindMode == DetachedBindMode) {
            bindMatrixInverse.copy(bindMatrix).invert();
        } else {
            trace('THREE.SkinnedMesh: Unrecognized bindMode: ' + bindMode);
        }
    }

    public function applyBoneTransform(index:Int, vector:Vector3) {
        var skeleton = this.skeleton;
        var geometry = this.geometry;
        _skinIndex.fromBufferAttribute(geometry.attributes.skinIndex, index);
        _skinWeight.fromBufferAttribute(geometry.attributes.skinWeight, index);
        _basePosition.copy(vector).applyMatrix4(bindMatrix);
        vector.set(0, 0, 0);
        for (i in 0...4) {
            var weight = _skinWeight.getComponent(i);
            if (weight != 0) {
                var boneIndex = _skinIndex.getComponent(i);
                _matrix4.multiplyMatrices(skeleton.bones[boneIndex].matrixWorld, skeleton.boneInverses[boneIndex]);
                vector.addScaledVector(_vector3.copy(_basePosition).applyMatrix4(_matrix4), weight);
            }
        }
        return vector.applyMatrix4(bindMatrixInverse);
    }
}