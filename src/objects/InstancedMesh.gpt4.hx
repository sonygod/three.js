import three.core.InstancedBufferAttribute;
import three.objects.Mesh;
import three.math.Box3;
import three.math.Matrix4;
import three.math.Sphere;
import three.textures.DataTexture;
import three.constants.FloatType;
import three.constants.RedFormat;

class InstancedMesh extends Mesh {

    public var isInstancedMesh:Bool;
    public var instanceMatrix:InstancedBufferAttribute;
    public var instanceColor:InstancedBufferAttribute;
    public var morphTexture:DataTexture;
    public var count:Int;
    public var boundingBox:Box3;
    public var boundingSphere:Sphere;

    private static var _instanceLocalMatrix = new Matrix4();
    private static var _instanceWorldMatrix = new Matrix4();
    private static var _instanceIntersects = [];
    private static var _box3 = new Box3();
    private static var _identity = new Matrix4();
    private static var _mesh = new Mesh(null, null);
    private static var _sphere = new Sphere();

    public function new(geometry, material, count:Int) {
        super(geometry, material);

        this.isInstancedMesh = true;
        this.instanceMatrix = new InstancedBufferAttribute(new haxe.io.Float32Array(count * 16), 16);
        this.instanceColor = null;
        this.morphTexture = null;
        this.count = count;
        this.boundingBox = null;
        this.boundingSphere = null;

        for (i in 0...count) {
            this.setMatrixAt(i, _identity);
        }
    }

    public function computeBoundingBox():Void {
        var geometry = this.geometry;
        var count = this.count;

        if (this.boundingBox == null) {
            this.boundingBox = new Box3();
        }

        if (geometry.boundingBox == null) {
            geometry.computeBoundingBox();
        }

        this.boundingBox.makeEmpty();

        for (i in 0...count) {
            this.getMatrixAt(i, _instanceLocalMatrix);
            _box3.copy(geometry.boundingBox).applyMatrix4(_instanceLocalMatrix);
            this.boundingBox.union(_box3);
        }
    }

    public function computeBoundingSphere():Void {
        var geometry = this.geometry;
        var count = this.count;

        if (this.boundingSphere == null) {
            this.boundingSphere = new Sphere();
        }

        if (geometry.boundingSphere == null) {
            geometry.computeBoundingSphere();
        }

        this.boundingSphere.makeEmpty();

        for (i in 0...count) {
            this.getMatrixAt(i, _instanceLocalMatrix);
            _sphere.copy(geometry.boundingSphere).applyMatrix4(_instanceLocalMatrix);
            this.boundingSphere.union(_sphere);
        }
    }

    public function copy(source:InstancedMesh, recursive:Bool):InstancedMesh {
        super.copy(source, recursive);

        this.instanceMatrix.copy(source.instanceMatrix);
        if (source.morphTexture != null) this.morphTexture = source.morphTexture.clone();
        if (source.instanceColor != null) this.instanceColor = source.instanceColor.clone();

        this.count = source.count;

        if (source.boundingBox != null) this.boundingBox = source.boundingBox.clone();
        if (source.boundingSphere != null) this.boundingSphere = source.boundingSphere.clone();

        return this;
    }

    public function getColorAt(index:Int, color):Void {
        color.fromArray(this.instanceColor.array, index * 3);
    }

    public function getMatrixAt(index:Int, matrix):Void {
        matrix.fromArray(this.instanceMatrix.array, index * 16);
    }

    public function getMorphAt(index:Int, object):Void {
        var objectInfluences = object.morphTargetInfluences;
        var array = this.morphTexture.source.data.data;
        var len = objectInfluences.length + 1;
        var dataIndex = index * len + 1;

        for (i in 0...objectInfluences.length) {
            objectInfluences[i] = array[dataIndex + i];
        }
    }

    public function raycast(raycaster, intersects):Void {
        var matrixWorld = this.matrixWorld;
        var raycastTimes = this.count;

        _mesh.geometry = this.geometry;
        _mesh.material = this.material;

        if (_mesh.material == null) return;

        if (this.boundingSphere == null) this.computeBoundingSphere();
        _sphere.copy(this.boundingSphere).applyMatrix4(matrixWorld);

        if (!raycaster.ray.intersectsSphere(_sphere)) return;

        for (instanceId in 0...raycastTimes) {
            this.getMatrixAt(instanceId, _instanceLocalMatrix);
            _instanceWorldMatrix.multiplyMatrices(matrixWorld, _instanceLocalMatrix);

            _mesh.matrixWorld = _instanceWorldMatrix;
            _mesh.raycast(raycaster, _instanceIntersects);

            for (intersect in _instanceIntersects) {
                intersect.instanceId = instanceId;
                intersect.object = this;
                intersects.push(intersect);
            }

            _instanceIntersects = [];
        }
    }

    public function setColorAt(index:Int, color):Void {
        if (this.instanceColor == null) {
            this.instanceColor = new InstancedBufferAttribute(new haxe.io.Float32Array(this.instanceMatrix.count * 3), 3);
        }

        color.toArray(this.instanceColor.array, index * 3);
    }

    public function setMatrixAt(index:Int, matrix):Void {
        matrix.toArray(this.instanceMatrix.array, index * 16);
    }

    public function setMorphAt(index:Int, object):Void {
        var objectInfluences = object.morphTargetInfluences;
        var len = objectInfluences.length + 1;

        if (this.morphTexture == null) {
            this.morphTexture = new DataTexture(new haxe.io.Float32Array(len * this.count), len, this.count, RedFormat, FloatType);
        }

        var array = this.morphTexture.source.data.data;
        var morphInfluencesSum = 0;

        for (i in 0...objectInfluences.length) {
            morphInfluencesSum += objectInfluences[i];
        }

        var morphBaseInfluence = this.geometry.morphTargetsRelative ? 1 : 1 - morphInfluencesSum;
        var dataIndex = len * index;

        array[dataIndex] = morphBaseInfluence;
        array.set(objectInfluences, dataIndex + 1);
    }

    public function updateMorphTargets():Void {
        // No implementation needed as per the original code
    }

    public function dispose():InstancedMesh {
        this.dispatchEvent({ type: 'dispose' });

        if (this.morphTexture != null) {
            this.morphTexture.dispose();
            this.morphTexture = null;
        }

        return this;
    }
}