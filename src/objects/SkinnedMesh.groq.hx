package three.objects;

import three.math.Box3;
import three.math.Matrix4;
import three.math.Sphere;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Ray;

import three.constants.AttachedBindMode;
import three.constants.DetachedBindMode;

class SkinnedMesh extends Mesh {
    private var _basePosition:Vector3 = new Vector3();
    private var _skinIndex:Vector4 = new Vector4();
    private var _skinWeight:Vector4 = new Vector4();
    private var _vector3:Vector3 = new Vector3();
    private var _matrix4:Matrix4 = new Matrix4();
    private var _vertex:Vector3 = new Vector3();
    private var _sphere:Sphere = new Sphere();
    private var _inverseMatrix:Matrix4 = new Matrix4();
    private var _ray:Ray = new Ray();

    public function new(geometry:Geometry, material:Material) {
        super(geometry, material);
        this.isSkinnedMesh = true;
        this.type = 'SkinnedMesh';
        this.bindMode = AttachedBindMode;
        this.bindMatrix = new Matrix4();
        this.bindMatrixInverse = new Matrix4();
        this.boundingBox = null;
        this.boundingSphere = null;
    }

    public function computeBoundingBox():Void {
        var geometry:Geometry = this.geometry;
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

    public function computeBoundingSphere():Void {
        var geometry:Geometry = this.geometry;
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

    public function copy(source:SkinnedMesh, recursive:Bool):SkinnedMesh {
        super.copy(source, recursive);
        this.bindMode = source.bindMode;
        this.bindMatrix.copyFrom(source.bindMatrix);
        this.bindMatrixInverse.copyFrom(source.bindMatrixInverse);
        this.skeleton = source.skeleton;
        if (source.boundingBox != null) {
            this.boundingBox = source.boundingBox.clone();
        }
        if (source.boundingSphere != null) {
            this.boundingSphere = source.boundingSphere.clone();
        }
        return this;
    }

    public function raycast(raycaster:Raycaster, intersects:Array<RaycastHit>):Void {
        var material:Material = this.material;
        var matrixWorld:Matrix4 = this.matrixWorld;
        if (material == null) return;
        if (this.boundingSphere == null) {
            this.computeBoundingSphere();
        }
        _sphere.copy(this.boundingSphere);
        _sphere.applyMatrix4(matrixWorld);
        if (!_ray.intersectsSphere(_sphere)) return;
        _inverseMatrix.copy(matrixWorld).invert();
        _ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);
        if (this.boundingBox != null) {
            if (!_ray.intersectsBox(this.boundingBox)) return;
        }
        this._computeIntersections(raycaster, intersects, _ray);
    }

    public function getVertexPosition(index:Int, target:Vector3):Vector3 {
        super.getVertexPosition(index, target);
        this.applyBoneTransform(index, target);
        return target;
    }

    public function bind(skeleton:Skeleton, bindMatrix:Matrix4):Void {
        this.skeleton = skeleton;
        if (bindMatrix == null) {
            this.updateMatrixWorld(true);
            skeleton.calculateInverses();
            bindMatrix = this.matrixWorld;
        }
        this.bindMatrix.copyFrom(bindMatrix);
        this.bindMatrixInverse.copyFrom(bindMatrix).invert();
    }

    public function pose():Void {
        this.skeleton.pose();
    }

    public function normalizeSkinWeights():Void {
        var vector:Vector4 = new Vector4();
        var skinWeight:BufferAttribute = this.geometry.attributes.skinWeight;
        for (i in 0...skinWeight.count) {
            vector.fromBufferAttribute(skinWeight, i);
            var scale:Float = 1.0 / vector.manhattanLength();
            if (scale != Math.POSITIVE_INFINITY) {
                vector.multiplyScalar(scale);
            } else {
                vector.set(1, 0, 0, 0); // do something reasonable
            }
            skinWeight.setXYZW(i, vector.x, vector.y, vector.z, vector.w);
        }
    }

    public function updateMatrixWorld(force:Bool):Void {
        super.updateMatrixWorld(force);
        if (this.bindMode == AttachedBindMode) {
            this.bindMatrixInverse.copyFrom(this.matrixWorld).invert();
        } else if (this.bindMode == DetachedBindMode) {
            this.bindMatrixInverse.copyFrom(this.bindMatrix).invert();
        } else {
            trace('THREE.SkinnedMesh: Unrecognized bindMode: ' + this.bindMode);
        }
    }

    public function applyBoneTransform(index:Int, vector:Vector3):Vector3 {
        var skeleton:Skeleton = this.skeleton;
        var geometry:Geometry = this.geometry;
        _skinIndex.fromBufferAttribute(geometry.attributes.skinIndex, index);
        _skinWeight.fromBufferAttribute(geometry.attributes.skinWeight, index);
        _basePosition.copy(vector).applyMatrix4(this.bindMatrix);
        vector.set(0, 0, 0);
        for (i in 0...4) {
            var weight:Float = _skinWeight.getComponent(i);
            if (weight != 0) {
                var boneIndex:Int = _skinIndex.getComponent(i);
                _matrix4.multiplyMatrices(skeleton.bones[boneIndex].matrixWorld, skeleton.boneInverses[boneIndex]);
                vector.addScaledVector(_vector3.copy(_basePosition).applyMatrix4(_matrix4), weight);
            }
        }
        return vector.applyMatrix4(this.bindMatrixInverse);
    }
}