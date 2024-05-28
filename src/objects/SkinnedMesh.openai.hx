package three.objects;

import drei.math.Box3;
import drei.math.Matrix4;
import drei.math.Ray;
import drei.math.Sphere;
import drei.math.Vector3;
import drei.math.Vector4;
import drei.constants.AttachedBindMode;
import drei.constants.DetachedBindMode;

class SkinnedMesh extends Mesh {

    public var isSkinnedMesh:Bool = true;
    public var type:String = 'SkinnedMesh';
    public var bindMode:Int;
    public var bindMatrix:Matrix4;
    public var bindMatrixInverse:Matrix4;
    public var boundingBox:Box3;
    public var boundingSphere:Sphere;
    public var skeleton:Skeleton;

    private var _basePosition:Vector3;
    private var _skinIndex:Vector4;
    private var _skinWeight:Vector4;
    private var _vector3:Vector3;
    private var _matrix4:Matrix4;
    private var _vertex:Vector3;
    private var _sphere:Sphere;
    private var _inverseMatrix:Matrix4;
    private var _ray:Ray;

    public function new(geometry:Geometry, material:Material) {
        super(geometry, material);

        bindMatrix = new Matrix4();
        bindMatrixInverse = new Matrix4();
        _basePosition = new Vector3();
        _skinIndex = new Vector4();
        _skinWeight = new Vector4();
        _vector3 = new Vector3();
        _matrix4 = new Matrix4();
        _vertex = new Vector3();
        _sphere = new Sphere();
        _inverseMatrix = new Matrix4();
        _ray = new Ray();
    }

    public function computeBoundingBox():Void {
        var geometry:Geometry = this.geometry;
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

    public function computeBoundingSphere():Void {
        var geometry:Geometry = this.geometry;
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

    public function copy(source:SkinnedMesh, recursive:Bool):SkinnedMesh {
        super.copy(source, recursive);
        bindMode = source.bindMode;
        bindMatrix.copyFrom(source.bindMatrix);
        bindMatrixInverse.copyFrom(source.bindMatrixInverse);
        skeleton = source.skeleton;
        if (source.boundingBox != null) {
            boundingBox = source.boundingBox.clone();
        }
        if (source.boundingSphere != null) {
            boundingSphere = source.boundingSphere.clone();
        }
        return this;
    }

    public function raycast(raycaster:Raycaster, intersects:Array<RaycastIntersection>):Void {
        var material:Material = this.material;
        var matrixWorld:Matrix4 = this.matrixWorld;
        if (material == null) return;

        if (boundingSphere == null) computeBoundingSphere();

        _sphere.copyFrom(boundingSphere);
        _sphere.applyMatrix4(matrixWorld);

        if (!_raycaster.ray.intersectsSphere(_sphere)) return;

        _inverseMatrix.copyFrom(matrixWorld).invert();
        _ray.copyFrom(raycaster.ray).applyMatrix4(_inverseMatrix);

        if (boundingBox != null && !_ray.intersectsBox(boundingBox)) return;

        _computeIntersections(raycaster, intersects, _ray);
    }

    public function getVertexPosition(index:Int, target:Vector3):Vector3 {
        super.getVertexPosition(index, target);
        applyBoneTransform(index, target);
        return target;
    }

    public function bind(skeleton:Skeleton, bindMatrix:Matrix4):Void {
        this.skeleton = skeleton;
        if (bindMatrix == null) {
            updateMatrixWorld(true);
            skeleton.calculateInverses();
            bindMatrix = matrixWorld;
        }
        this.bindMatrix.copyFrom(bindMatrix);
        this.bindMatrixInverse.copyFrom(bindMatrix).invert();
    }

    public function pose():Void {
        skeleton.pose();
    }

    public function normalizeSkinWeights():Void {
        var vector:Vector4 = new Vector4();
        var skinWeight:VertexAttribute = geometry.attributes.skinWeight;
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
        if (bindMode == AttachedBindMode) {
            bindMatrixInverse.copyFrom(matrixWorld).invert();
        } else if (bindMode == DetachedBindMode) {
            bindMatrixInverse.copyFrom(bindMatrix).invert();
        } else {
            trace('THREE.SkinnedMesh: Unrecognized bindMode: ' + bindMode);
        }
    }

    public function applyBoneTransform(index:Int, vector:Vector3):Vector3 {
        var skeleton:Skeleton = this.skeleton;
        var geometry:Geometry = this.geometry;
        _skinIndex.fromBufferAttribute(geometry.attributes.skinIndex, index);
        _skinWeight.fromBufferAttribute(geometry.attributes.skinWeight, index);
        _basePosition.copyFrom(vector).applyMatrix4(bindMatrix);
        vector.set(0, 0, 0);
        for (i in 0...4) {
            var weight:Float = _skinWeight.getComponent(i);
            if (weight != 0) {
                var boneIndex:Int = _skinIndex.getComponent(i);
                _matrix4.multiplyMatrices(skeleton.bones[boneIndex].matrixWorld, skeleton.boneInverses[boneIndex]);
                vector.addScaledVector(_vector3.copy(_basePosition).applyMatrix4(_matrix4), weight);
            }
        }
        return vector.applyMatrix4(bindMatrixInverse);
    }
}