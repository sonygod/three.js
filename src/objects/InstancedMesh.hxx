package three.js.src.objects;

import three.js.src.core.InstancedBufferAttribute;
import three.js.src.math.Box3;
import three.js.src.math.Matrix4;
import three.js.src.math.Sphere;
import three.js.src.textures.DataTexture;
import three.js.src.constants.FloatType;
import three.js.src.constants.RedFormat;
import three.js.src.objects.Mesh;

class InstancedMesh extends Mesh {

    static var _instanceLocalMatrix:Matrix4 = new Matrix4();
    static var _instanceWorldMatrix:Matrix4 = new Matrix4();
    static var _instanceIntersects:Array<Dynamic> = [];
    static var _box3:Box3 = new Box3();
    static var _identity:Matrix4 = new Matrix4();
    static var _mesh:Mesh = new Mesh();
    static var _sphere:Sphere = new Sphere();

    public var instanceMatrix:InstancedBufferAttribute;
    public var instanceColor:InstancedBufferAttribute;
    public var morphTexture:DataTexture;
    public var count:Int;
    public var boundingBox:Box3;
    public var boundingSphere:Sphere;

    public function new(geometry:Dynamic, material:Dynamic, count:Int) {
        super(geometry, material);
        this.isInstancedMesh = true;
        this.instanceMatrix = new InstancedBufferAttribute(new Float32Array(count * 16), 16);
        this.instanceColor = null;
        this.morphTexture = null;
        this.count = count;
        this.boundingBox = null;
        this.boundingSphere = null;
        for (i in 0...count) {
            this.setMatrixAt(i, _identity);
        }
    }

    public function computeBoundingBox() {
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

    public function computeBoundingSphere() {
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

    public function copy(source:InstancedMesh, recursive:Bool) {
        super.copy(source, recursive);
        this.instanceMatrix.copy(source.instanceMatrix);
        if (source.morphTexture != null) this.morphTexture = source.morphTexture.clone();
        if (source.instanceColor != null) this.instanceColor = source.instanceColor.clone();
        this.count = source.count;
        if (source.boundingBox != null) this.boundingBox = source.boundingBox.clone();
        if (source.boundingSphere != null) this.boundingSphere = source.boundingSphere.clone();
        return this;
    }

    public function getColorAt(index:Int, color:Dynamic) {
        color.fromArray(this.instanceColor.array, index * 3);
    }

    public function getMatrixAt(index:Int, matrix:Matrix4) {
        matrix.fromArray(this.instanceMatrix.array, index * 16);
    }

    public function getMorphAt(index:Int, object:Dynamic) {
        var objectInfluences = object.morphTargetInfluences;
        var array = this.morphTexture.source.data.data;
        var len = objectInfluences.length + 1;
        var dataIndex = index * len + 1;
        for (i in 0...objectInfluences.length) {
            objectInfluences[i] = array[dataIndex + i];
        }
    }

    public function raycast(raycaster:Dynamic, intersects:Array<Dynamic>) {
        var matrixWorld = this.matrixWorld;
        var raycastTimes = this.count;
        _mesh.geometry = this.geometry;
        _mesh.material = this.material;
        if (_mesh.material == null) return;
        if (this.boundingSphere == null) this.computeBoundingSphere();
        _sphere.copy(this.boundingSphere);
        _sphere.applyMatrix4(matrixWorld);
        if (raycaster.ray.intersectsSphere(_sphere) == false) return;
        for (instanceId in 0...raycastTimes) {
            this.getMatrixAt(instanceId, _instanceLocalMatrix);
            _instanceWorldMatrix.multiplyMatrices(matrixWorld, _instanceLocalMatrix);
            _mesh.matrixWorld = _instanceWorldMatrix;
            _mesh.raycast(raycaster, _instanceIntersects);
            for (i in 0..._instanceIntersects.length) {
                var intersect = _instanceIntersects[i];
                intersect.instanceId = instanceId;
                intersect.object = this;
                intersects.push(intersect);
            }
            _instanceIntersects.length = 0;
        }
    }

    public function setColorAt(index:Int, color:Dynamic) {
        if (this.instanceColor == null) {
            this.instanceColor = new InstancedBufferAttribute(new Float32Array(this.instanceMatrix.count * 3), 3);
        }
        color.toArray(this.instanceColor.array, index * 3);
    }

    public function setMatrixAt(index:Int, matrix:Matrix4) {
        matrix.toArray(this.instanceMatrix.array, index * 16);
    }

    public function setMorphAt(index:Int, object:Dynamic) {
        var objectInfluences = object.morphTargetInfluences;
        var len = objectInfluences.length + 1;
        if (this.morphTexture == null) {
            this.morphTexture = new DataTexture(new Float32Array(len * this.count), len, this.count, RedFormat, FloatType);
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

    public function updateMorphTargets() {
    }

    public function dispose() {
        this.dispatchEvent({type: 'dispose'});
        if (this.morphTexture != null) {
            this.morphTexture.dispose();
            this.morphTexture = null;
        }
        return this;
    }
}