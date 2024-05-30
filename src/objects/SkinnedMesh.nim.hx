import Mesh from './Mesh.hx';
import Box3 from '../math/Box3.hx';
import Matrix4 from '../math/Matrix4.hx';
import Sphere from '../math/Sphere.hx';
import Vector3 from '../math/Vector3.hx';
import Vector4 from '../math/Vector4.hx';
import Ray from '../math/Ray.hx';
import AttachedBindMode from '../constants.hx';
import DetachedBindMode from '../constants.hx';

class SkinnedMesh extends Mesh {
    public var isSkinnedMesh:Bool = true;
    public var type:String = 'SkinnedMesh';
    public var bindMode:Int;
    public var bindMatrix:Matrix4;
    public var bindMatrixInverse:Matrix4;
    public var boundingBox:Box3;
    public var boundingSphere:Sphere;

    public function new(geometry:Dynamic, material:Dynamic) {
        super(geometry, material);
        this.bindMode = AttachedBindMode;
        this.bindMatrix = new Matrix4();
        this.bindMatrixInverse = new Matrix4();
    }

    public function computeBoundingBox() {
        var geometry = this.geometry;
        if (this.boundingBox == null) {
            this.boundingBox = new Box3();
        }
        this.boundingBox.makeEmpty();
        var positionAttribute = geometry.getAttribute('position');
        for (i in 0...positionAttribute.count) {
            this.getVertexPosition(i, _vertex);
            this.boundingBox.expandByPoint(_vertex);
        }
    }

    public function computeBoundingSphere() {
        var geometry = this.geometry;
        if (this.boundingSphere == null) {
            this.boundingSphere = new Sphere();
        }
        this.boundingSphere.makeEmpty();
        var positionAttribute = geometry.getAttribute('position');
        for (i in 0...positionAttribute.count) {
            this.getVertexPosition(i, _vertex);
            this.boundingSphere.expandByPoint(_vertex);
        }
    }

    public function copy(source:Dynamic, recursive:Bool) {
        super.copy(source, recursive);
        this.bindMode = source.bindMode;
        this.bindMatrix.copy(source.bindMatrix);
        this.bindMatrixInverse.copy(source.bindMatrixInverse);
        this.skeleton = source.skeleton;
        if (source.boundingBox != null) this.boundingBox = source.boundingBox.clone();
        if (source.boundingSphere != null) this.boundingSphere = source.boundingSphere.clone();
        return this;
    }

    public function raycast(raycaster:Dynamic, intersects:Dynamic) {
        var material = this.material;
        var matrixWorld = this.matrixWorld;
        if (material == null) return;
        if (this.boundingSphere == null) this.computeBoundingSphere();
        _sphere.copy(this.boundingSphere);
        _sphere.applyMatrix4(matrixWorld);
        if (!raycaster.ray.intersectsSphere(_sphere)) return;
        _inverseMatrix.copy(matrixWorld).invert();
        _ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);
        if (this.boundingBox != null) {
            if (!_ray.intersectsBox(this.boundingBox)) return;
        }
        this._computeIntersections(raycaster, intersects, _ray);
    }

    public function getVertexPosition(index:Int, target:Vector3) {
        super.getVertexPosition(index, target);
        this.applyBoneTransform(index, target);
        return target;
    }

    public function bind(skeleton:Dynamic, bindMatrix:Matrix4) {
        this.skeleton = skeleton;
        if (bindMatrix == null) {
            this.updateMatrixWorld(true);
            skeleton.calculateInverses();
            bindMatrix = this.matrixWorld;
        }
        this.bindMatrix.copy(bindMatrix);
        this.bindMatrixInverse.copy(bindMatrix).invert();
    }

    public function pose() {
        this.skeleton.pose();
    }

    public function normalizeSkinWeights() {
        var vector = new Vector4();
        var skinWeight = this.geometry.attributes.skinWeight;
        for (i in 0...skinWeight.count) {
            vector.fromBufferAttribute(skinWeight, i);
            var scale = 1.0 / vector.manhattanLength();
            if (scale != Infinity) {
                vector.multiplyScalar(scale);
            } else {
                vector.set(1, 0, 0, 0);
            }
            skinWeight.setXYZW(i, vector.x, vector.y, vector.z, vector.w);
        }
    }

    public function updateMatrixWorld(force:Bool) {
        super.updateMatrixWorld(force);
        if (this.bindMode == AttachedBindMode) {
            this.bindMatrixInverse.copy(this.matrixWorld).invert();
        } else if (this.bindMode == DetachedBindMode) {
            this.bindMatrixInverse.copy(this.bindMatrix).invert();
        } else {
            trace('THREE.SkinnedMesh: Unrecognized bindMode: ' + this.bindMode);
        }
    }

    public function applyBoneTransform(index:Int, vector:Vector3) {
        var skeleton = this.skeleton;
        var geometry = this.geometry;
        _skinIndex.fromBufferAttribute(geometry.attributes.skinIndex, index);
        _skinWeight.fromBufferAttribute(geometry.attributes.skinWeight, index);
        _basePosition.copy(vector).applyMatrix4(this.bindMatrix);
        vector.set(0, 0, 0);
        for (i in 0...4) {
            var weight = _skinWeight.getComponent(i);
            if (weight != 0) {
                var boneIndex = _skinIndex.getComponent(i);
                _matrix4.multiplyMatrices(skeleton.bones[boneIndex].matrixWorld, skeleton.boneInverses[boneIndex]);
                vector.addScaledVector(_vector3.copy(_basePosition).applyMatrix4(_matrix4), weight);
            }
        }
        return vector.applyMatrix4(this.bindMatrixInverse);
    }
}