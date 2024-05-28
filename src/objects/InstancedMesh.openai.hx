package three.objects;

import three.core.InstancedBufferAttribute;
import three.mesh.Mesh;
import three.math.Box3;
import three.math.Matrix4;
import three.math.Sphere;
import three.textures.DataTexture;
import three.constants.FloatType;
import three.constants.RedFormat;

class InstancedMesh extends Mesh {
    public var isInstancedMesh:Bool = true;

    private var _instanceLocalMatrix:Matrix4 = new Matrix4();
    private var _instanceWorldMatrix:Matrix4 = new Matrix4();

    private var _instanceIntersects:Array<{}> = [];

    private var _box3:Box3 = new Box3();
    private var _identity:Matrix4 = new Matrix4();
    private var _mesh:Mesh = new Mesh();
    private var _sphere:Sphere = new Sphere();

    public var instanceMatrix:InstancedBufferAttribute;
    public var instanceColor:InstancedBufferAttribute;
    public var morphTexture:DataTexture;
    public var count:Int;
    public var boundingBox:Box3;
    public var boundingSphere:Sphere;

    public function new(geometry:Geometry, material:Material, count:Int) {
        super(geometry, material);

        this.instanceMatrix = new InstancedBufferAttribute(new Float32Array(count * 16), 16);
        this.count = count;

        for (i in 0...count) {
            this.setMatrixAt(i, _identity);
        }
    }

    public function computeBoundingBox():Void {
        var geometry:Geometry = this.geometry;
        if (this.boundingBox == null) {
            this.boundingBox = new Box3();
        }

        if (geometry.boundingBox == null) {
            geometry.computeBoundingBox();
        }

        this.boundingBox.makeEmpty();

        for (i in 0...this.count) {
            this.getMatrixAt(i, _instanceLocalMatrix);
            _box3.copy(geometry.boundingBox).applyMatrix4(_instanceLocalMatrix);
            this.boundingBox.union(_box3);
        }
    }

    public function computeBoundingSphere():Void {
        var geometry:Geometry = this.geometry;
        if (this.boundingSphere == null) {
            this.boundingSphere = new Sphere();
        }

        if (geometry.boundingSphere == null) {
            geometry.computeBoundingSphere();
        }

        this.boundingSphere.makeEmpty();

        for (i in 0...this.count) {
            this.getMatrixAt(i, _instanceLocalMatrix);
            _sphere.copy(geometry.boundingSphere).applyMatrix4(_instanceLocalMatrix);
            this.boundingSphere.union(_sphere);
        }
    }

    public function copy(source:InstancedMesh, recursive:Bool):InstancedMesh {
        super.copy(source, recursive);

        this.instanceMatrix.copy(source.instanceMatrix);

        if (source.morphTexture != null) {
            this.morphTexture = source.morphTexture.clone();
        }
        if (source.instanceColor != null) {
            this.instanceColor = source.instanceColor.clone();
        }

        this.count = source.count;

        if (source.boundingBox != null) {
            this.boundingBox = source.boundingBox.clone();
        }
        if (source.boundingSphere != null) {
            this.boundingSphere = source.boundingSphere.clone();
        }

        return this;
    }

    public function getColorAt(index:Int, color:Color):Void {
        color.fromArray(this.instanceColor.array, index * 3);
    }

    public function getMatrixAt(index:Int, matrix:Matrix4):Void {
        matrix.fromArray(this.instanceMatrix.array, index * 16);
    }

    public function getMorphAt(index:Int, object:Object):Void {
        var objectInfluences:Array<Float> = object.morphTargetInfluences;
        var array:Array<Float> = this.morphTexture.source.data.data;
        var len:Int = objectInfluences.length + 1;
        var dataIndex:Int = index * len + 1;

        for (i in 0...objectInfluences.length) {
            objectInfluences[i] = array[dataIndex + i];
        }
    }

    public function raycast(raycaster:Raycaster, intersects:Array<{}>):Void {
        var matrixWorld:Matrix4 = this.matrixWorld;
        var raycastTimes:Int = this.count;

        _mesh.geometry = this.geometry;
        _mesh.material = this.material;

        if (_mesh.material == null) return;

        if (this.boundingSphere == null) {
            this.computeBoundingSphere();
        }

        _sphere.copy(this.boundingSphere);
        _sphere.applyMatrix4(matrixWorld);

        if (!raycaster.ray.intersectsSphere(_sphere)) return;

        for (instanceId in 0...raycastTimes) {
            this.getMatrixAt(instanceId, _instanceLocalMatrix);
            _instanceWorldMatrix.multiplyMatrices(matrixWorld, _instanceLocalMatrix);

            _mesh.matrixWorld = _instanceWorldMatrix;
            _mesh.raycast(raycaster, _instanceIntersects);

            for (i in 0..._instanceIntersects.length) {
                var intersect:{} = _instanceIntersects[i];
                intersect.instanceId = instanceId;
                intersect.object = this;
                intersects.push(intersect);
            }

            _instanceIntersects.length = 0;
        }
    }

    public function setColorAt(index:Int, color:Color):Void {
        if (this.instanceColor == null) {
            this.instanceColor = new InstancedBufferAttribute(new Float32Array(this.instanceMatrix.count * 3), 3);
        }

        color.toArray(this.instanceColor.array, index * 3);
    }

    public function setMatrixAt(index:Int, matrix:Matrix4):Void {
        matrix.toArray(this.instanceMatrix.array, index * 16);
    }

    public function setMorphAt(index:Int, object:Object):Void {
        var objectInfluences:Array<Float> = object.morphTargetInfluences;

        var len:Int = objectInfluences.length + 1;
        if (this.morphTexture == null) {
            this.morphTexture = new DataTexture(new Float32Array(len * this.count), len, this.count, RedFormat, FloatType);
        }

        var array:Array<Float> = this.morphTexture.source.data.data;

        var dataIndex:Int = len * index;
        array[dataIndex] = object.morphTargetInfluencesSum;

        array.set(objectInfluences, dataIndex + 1);
    }

    public function updateMorphTargets():Void {
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