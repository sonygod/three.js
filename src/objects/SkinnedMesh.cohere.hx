import js.three.Box3;
import js.three.Matrix4;
import js.three.Mesh;
import js.three.Ray;
import js.three.Sphere;
import js.three.Vector3;
import js.three.Vector4;

class SkinnedMesh extends Mesh {
    public var isSkinnedMesh:Bool;
    public var type:String;
    public var bindMode:Int;
    public var bindMatrix:Matrix4;
    public var bindMatrixInverse:Matrix4;
    public var boundingBox:Box3;
    public var boundingSphere:Sphere;

    public function new(geometry:Dynamic, material:Dynamic) {
        super(geometry, material);
        isSkinnedMesh = true;
        type = 'SkinnedMesh';
        bindMode = AttachedBindMode;
        bindMatrix = new Matrix4();
        bindMatrixInverse = new Matrix4();
        boundingBox = null;
        boundingSphere = null;
    }

    public function computeBoundingBox():Void {
        var geometry = this.geometry;
        if (boundingBox == null) {
            boundingBox = new Box3();
        }
        boundingBox.makeEmpty();
        var positionAttribute = geometry.getAttribute('position');
        var _vertex = new Vector3();
        for (i in 0...positionAttribute.count) {
            getVertexPosition(i, _vertex);
            boundingBox.expandByPoint(_vertex);
        }
    }

    public function computeBoundingSphere():Void {
        var geometry = this.geometry;
        if (boundingSphere == null) {
            boundingSphere = new Sphere();
        }
        boundingSphere.makeEmpty();
        var positionAttribute = geometry.getAttribute('position');
        var _vertex = new Vector3();
        for (i in 0...positionAttribute.count) {
            getVertexPosition(i, _vertex);
            boundingSphere.expandByPoint(_vertex);
        }
    }

    public function copy(source:SkinnedMesh, recursive:Bool):SkinnedMesh {
        super.copy(source, recursive);
        bindMode = source.bindMode;
        bindMatrix.copy(source.bindMatrix);
        bindMatrixInverse.copy(source.bindMatrixInverse);
        skeleton = source.skeleton;
        if (source.boundingBox != null) boundingBox = source.boundingBox.clone();
        if (source.boundingSphere != null) boundingSphere = source.boundingSphere.clone();
        return this;
    }

    public function raycast(raycaster:Dynamic, intersects:Dynamic):Void {
        var material = this.material;
        var matrixWorld = this.matrixWorld;
        if (material == null) return;
        if (boundingSphere == null) computeBoundingSphere();
        var _sphere = new Sphere();
        _sphere.copy(boundingSphere);
        _sphere.applyMatrix4(matrixWorld);
        if (!raycaster.ray.intersectsSphere(_sphere)) return;
        var _inverseMatrix = new Matrix4();
        _inverseMatrix.copy(matrixWorld).invert();
        var _ray = new Ray();
        _ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);
        if (boundingBox != null && !_ray.intersectsBox(boundingBox)) return;
        _computeIntersections(raycaster, intersects, _ray);
    }

    public function getVertexPosition(index:Int, target:Vector3):Vector3 {
        super.getVertexPosition(index, target);
        applyBoneTransform(index, target);
        return target;
    }

    public function bind(skeleton:Dynamic, bindMatrix:Matrix4):Void {
        this.skeleton = skeleton;
        if (bindMatrix == null) {
            updateMatrixWorld(true);
            skeleton.calculateInverses();
            bindMatrix = this.matrixWorld;
        }
        this.bindMatrix.copy(bindMatrix);
        this.bindMatrixInverse.copy(bindMatrix).invert();
    }

    public function pose():Void {
        skeleton.pose();
    }

    public function normalizeSkinWeights():Void {
        var vector = new Vector4();
        var skinWeight = geometry.attributes.skinWeight;
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

    public override function updateMatrixWorld(force:Bool):Void {
        super.updateMatrixWorld(force);
        if (bindMode == AttachedBindMode) {
            bindMatrixInverse.copy(matrixWorld).invert();
        } else if (bindMode == DetachedBindMode) {
            bindMatrixInverse.copy(bindMatrix).invert();
        } else {
            trace('THREE.SkinnedMesh: Unrecognized bindMode: ' + bindMode);
        }
    }

    public function applyBoneTransform(index:Int, vector:Vector3):Vector3 {
        var skeleton = this.skeleton;
        var geometry = this.geometry;
        var _skinIndex = new Vector4();
        _skinIndex.fromBufferAttribute(geometry.attributes.skinIndex, index);
        var _skinWeight = new Vector4();
        _skinWeight.fromBufferAttribute(geometry.attributes.skinWeight, index);
        var _basePosition = new Vector3();
        _basePosition.copy(vector).applyMatrix4(bindMatrix);
        vector.set(0, 0, 0);
        var _matrix4 = new Matrix4();
        var _vector3 = new Vector3();
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