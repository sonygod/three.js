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
    public var instanceMatrix:InstancedBufferAttribute;
    public var instanceColor:InstancedBufferAttribute;
    public var morphTexture:DataTexture;
    public var count:Int;
    public var boundingBox:Box3;
    public var boundingSphere:Sphere;

    public function new(geometry:Geometry, material:Material, count:Int) {
        super(geometry, material);
        this.count = count;
        this.instanceMatrix = new InstancedBufferAttribute(new Float32Array(count * 16), 16);
        for (i in 0...count) {
            setMatrixAt(i, _identity);
        }
    }

    private function computeBoundingBox():Void {
        var geometry:Geometry = this.geometry;
        if (boundingBox == null) {
            boundingBox = new Box3();
        }
        if (geometry.boundingBox == null) {
            geometry.computeBoundingBox();
        }
        boundingBox.makeEmpty();
        for (i in 0...count) {
            getMatrixAt(i, _instanceLocalMatrix);
            _box3.copy(geometry.boundingBox).applyMatrix4(_instanceLocalMatrix);
            boundingBox.union(_box3);
        }
    }

    private function computeBoundingSphere():Void {
        var geometry:Geometry = this.geometry;
        if (boundingSphere == null) {
            boundingSphere = new Sphere();
        }
        if (geometry.boundingSphere == null) {
            geometry.computeBoundingSphere();
        }
        boundingSphere.makeEmpty();
        for (i in 0...count) {
            getMatrixAt(i, _instanceLocalMatrix);
            _sphere.copy(geometry.boundingSphere).applyMatrix4(_instanceLocalMatrix);
            boundingSphere.union(_sphere);
        }
    }

    public function copy(source:InstancedMesh, recursive:Bool):InstancedMesh {
        super.copy(source, recursive);
        instanceMatrix.copy(source.instanceMatrix);
        if (source.morphTexture != null) {
            morphTexture = source.morphTexture.clone();
        }
        if (source.instanceColor != null) {
            instanceColor = source.instanceColor.clone();
        }
        count = source.count;
        if (source.boundingBox != null) {
            boundingBox = source.boundingBox.clone();
        }
        if (source.boundingSphere != null) {
            boundingSphere = source.boundingSphere.clone();
        }
        return this;
    }

    public function getColorAt(index:Int, color:Vector3):Void {
        color.fromArray(instanceColor.array, index * 3);
    }

    public function getMatrixAt(index:Int, matrix:Matrix4):Void {
        matrix.fromArray(instanceMatrix.array, index * 16);
    }

    public function getMorphAt(index:Int, object:Object3D):Void {
        var objectInfluences:Array<Float> = object.morphTargetInfluences;
        var array:Array<Float> = morphTexture.source.data.data;
        var len:Int = objectInfluences.length + 1; // All influences + the baseInfluenceSum
        var dataIndex:Int = index * len + 1; // Skip the baseInfluenceSum at the beginning
        for (i in 0...objectInfluences.length) {
            objectInfluences[i] = array[dataIndex + i];
        }
    }

    public function raycast(raycaster:Raycaster, intersects:Array<RaycastIntersection>):Void {
        var matrixWorld:Matrix4 = this.matrixWorld;
        var raycastTimes:Int = this.count;
        _mesh.geometry = this.geometry;
        _mesh.material = this.material;
        if (_mesh.material == null) return;
        if (boundingSphere == null) {
            computeBoundingSphere();
        }
        _sphere.copy(boundingSphere);
        _sphere.applyMatrix4(matrixWorld);
        if (!raycaster.ray.intersectsSphere(_sphere)) return;
        for (instanceId in 0...raycastTimes) {
            getMatrixAt(instanceId, _instanceLocalMatrix);
            _instanceWorldMatrix.multiplyMatrices(matrixWorld, _instanceLocalMatrix);
            _mesh.matrixWorld = _instanceWorldMatrix;
            _mesh.raycast(raycaster, _instanceIntersects);
            for (i in 0..._instanceIntersects.length) {
                var intersect:RaycastIntersection = _instanceIntersects[i];
                intersect.instanceId = instanceId;
                intersect.object = this;
                intersects.push(intersect);
            }
            _instanceIntersects.length = 0;
        }
    }

    public function setColorAt(index:Int, color:Vector3):Void {
        if (instanceColor == null) {
            instanceColor = new InstancedBufferAttribute(new Float32Array(count * 3), 3);
        }
        color.toArray(instanceColor.array, index * 3);
    }

    public function setMatrixAt(index:Int, matrix:Matrix4):Void {
        matrix.toArray(instanceMatrix.array, index * 16);
    }

    public function setMorphAt(index:Int, object:Object3D):Void {
        var objectInfluences:Array<Float> = object.morphTargetInfluences;
        var len:Int = objectInfluences.length + 1; // morphBaseInfluence + all influences
        if (morphTexture == null) {
            morphTexture = new DataTexture(new Float32Array(len * count), len, count, RedFormat, FloatType);
        }
        var array:Array<Float> = morphTexture.source.data.data;
        var morphInfluencesSum:Float = 0;
        for (i in 0...objectInfluences.length) {
            morphInfluencesSum += objectInfluences[i];
        }
        var morphBaseInfluence:Float = geometry.morphTargetsRelative ? 1 : 1 - morphInfluencesSum;
        var dataIndex:Int = len * index;
        array[dataIndex] = morphBaseInfluence;
        array.set(objectInfluences, dataIndex + 1);
    }

    public function updateMorphTargets():Void {
        // todo
    }

    public function dispose():InstancedMesh {
        dispatchEvent({ type: 'dispose' });
        if (morphTexture != null) {
            morphTexture.dispose();
            morphTexture = null;
        }
        return this;
    }

    static var _instanceLocalMatrix:Matrix4 = new Matrix4();
    static var _instanceWorldMatrix:Matrix4 = new Matrix4();
    static var _instanceIntersects:Array<RaycastIntersection> = [];
    static var _box3:Box3 = new Box3();
    static var _identity:Matrix4 = new Matrix4();
    static var _mesh:Mesh = new Mesh();
    static var _sphere:Sphere = new Sphere();
}