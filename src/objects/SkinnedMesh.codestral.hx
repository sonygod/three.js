import three.math.Box3;
import three.math.Matrix4;
import three.math.Sphere;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Ray;
import three.objects.Mesh;
import three.core.Object3D;
import three.core.Geometry;
import three.constants.AttachedBindMode;
import three.constants.DetachedBindMode;

class SkinnedMesh extends Mesh {

    public var isSkinnedMesh:Bool = true;
    public var type:String = 'SkinnedMesh';
    public var bindMode:Int;
    public var bindMatrix:Matrix4;
    public var bindMatrixInverse:Matrix4;
    public var boundingBox:Null<Box3>;
    public var boundingSphere:Null<Sphere>;
    public var skeleton:Null<Object3D>;

    public function new(geometry:Geometry, material:Null<Material>) {
        super(geometry, material);

        this.bindMode = AttachedBindMode;
        this.bindMatrix = new Matrix4();
        this.bindMatrixInverse = new Matrix4();
        this.boundingBox = null;
        this.boundingSphere = null;
    }

    public function computeBoundingBox():Void {
        if (this.boundingBox == null) {
            this.boundingBox = new Box3();
        }

        this.boundingBox.makeEmpty();
        var positionAttribute = this.geometry.getAttribute('position');

        var i = 0;
        while (i < positionAttribute.count) {
            var vertex = new Vector3();
            this.getVertexPosition(i, vertex);
            this.boundingBox.expandByPoint(vertex);
            i++;
        }
    }

    public function computeBoundingSphere():Void {
        if (this.boundingSphere == null) {
            this.boundingSphere = new Sphere();
        }

        this.boundingSphere.makeEmpty();
        var positionAttribute = this.geometry.getAttribute('position');

        var i = 0;
        while (i < positionAttribute.count) {
            var vertex = new Vector3();
            this.getVertexPosition(i, vertex);
            this.boundingSphere.expandByPoint(vertex);
            i++;
        }
    }

    public function copy(source:SkinnedMesh, recursive:Bool):SkinnedMesh {
        super.copy(source, recursive);

        this.bindMode = source.bindMode;
        this.bindMatrix.copy(source.bindMatrix);
        this.bindMatrixInverse.copy(source.bindMatrixInverse);
        this.skeleton = source.skeleton;

        if (source.boundingBox != null) this.boundingBox = source.boundingBox.clone();
        if (source.boundingSphere != null) this.boundingSphere = source.boundingSphere.clone();

        return this;
    }

    public function raycast(raycaster:Raycaster, intersects:Array<Intersection>) {
        var material = this.material;
        var matrixWorld = this.matrixWorld;

        if (material == null) return;

        if (this.boundingSphere == null) this.computeBoundingSphere();

        var sphere = new Sphere();
        sphere.copy(this.boundingSphere);
        sphere.applyMatrix4(matrixWorld);

        if (raycaster.ray.intersectsSphere(sphere) == false) return;

        var inverseMatrix = new Matrix4();
        inverseMatrix.copy(matrixWorld).invert();

        var ray = new Ray();
        ray.copy(raycaster.ray).applyMatrix4(inverseMatrix);

        if (this.boundingBox != null) {
            if (ray.intersectsBox(this.boundingBox) == false) return;
        }

        this._computeIntersections(raycaster, intersects, ray);
    }

    public function getVertexPosition(index:Int, target:Vector3):Vector3 {
        super.getVertexPosition(index, target);
        this.applyBoneTransform(index, target);
        return target;
    }

    public function bind(skeleton:Object3D, bindMatrix:Null<Matrix4> = null) {
        this.skeleton = skeleton;

        if (bindMatrix == null) {
            this.updateMatrixWorld(true);
            this.skeleton.calculateInverses();
            bindMatrix = this.matrixWorld;
        }

        this.bindMatrix.copy(bindMatrix);
        this.bindMatrixInverse.copy(bindMatrix).invert();
    }

    public function pose() {
        if (this.skeleton != null) this.skeleton.pose();
    }

    public function normalizeSkinWeights() {
        var vector = new Vector4();
        var skinWeight = this.geometry.attributes.skinWeight;

        var i = 0;
        while (i < skinWeight.count) {
            vector.fromBufferAttribute(skinWeight, i);
            var scale = 1.0 / vector.manhattanLength();

            if (scale != Double.POSITIVE_INFINITY) {
                vector.multiplyScalar(scale);
            } else {
                vector.set(1, 0, 0, 0);
            }

            skinWeight.setXYZW(i, vector.x, vector.y, vector.z, vector.w);
            i++;
        }
    }

    public function updateMatrixWorld(force:Bool):Void {
        super.updateMatrixWorld(force);

        if (this.bindMode == AttachedBindMode) {
            this.bindMatrixInverse.copy(this.matrixWorld).invert();
        } else if (this.bindMode == DetachedBindMode) {
            this.bindMatrixInverse.copy(this.bindMatrix).invert();
        } else {
            trace('THREE.SkinnedMesh: Unrecognized bindMode: ' + this.bindMode);
        }
    }

    public function applyBoneTransform(index:Int, vector:Vector3):Vector3 {
        if (this.skeleton == null) return vector;

        var skeleton = this.skeleton;
        var geometry = this.geometry;

        var skinIndex = new Vector4();
        var skinWeight = new Vector4();
        var basePosition = new Vector3();
        var matrix4 = new Matrix4();
        var _vector = new Vector3();

        skinIndex.fromBufferAttribute(geometry.attributes.skinIndex, index);
        skinWeight.fromBufferAttribute(geometry.attributes.skinWeight, index);
        basePosition.copy(vector).applyMatrix4(this.bindMatrix);
        vector.set(0, 0, 0);

        var i = 0;
        while (i < 4) {
            var weight = skinWeight.getComponent(i);

            if (weight != 0) {
                var boneIndex = skinIndex.getComponent(i);
                matrix4.multiplyMatrices(skeleton.bones[boneIndex].matrixWorld, skeleton.boneInverses[boneIndex]);
                vector.addScaledVector(_vector.copy(basePosition).applyMatrix4(matrix4), weight);
            }

            i++;
        }

        return vector.applyMatrix4(this.bindMatrixInverse);
    }
}