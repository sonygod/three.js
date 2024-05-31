package ;

import three.core.InstancedBufferAttribute;
import three.objects.Mesh;
import three.math.Box3;
import three.math.Matrix4;
import three.math.Sphere;
import three.textures.DataTexture;
import three.constants.FloatType;
import three.constants.RedFormat;

class InstancedMesh extends Mesh {

    public var instanceMatrix(default, null) : InstancedBufferAttribute;
    public var instanceColor(default, null) : Null<InstancedBufferAttribute>;
    public var morphTexture(default, null) : Null<DataTexture>;
    public var count(default, null) : Int;

    static var _instanceLocalMatrix = new Matrix4();
    static var _instanceWorldMatrix = new Matrix4();

    static var _instanceIntersects : Array<Dynamic> = []; // Intersection[] in the original code

    static var _box3 = new Box3();
    static var _identity = new Matrix4();
    static var _mesh = new Mesh();
    static var _sphere = new Sphere();

    public function new(geometry, material, count) {
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

    override public function copy(source : InstancedMesh, ?recursive : Bool) : Mesh {
        super.copy(source, recursive);

        this.instanceMatrix.copy(source.instanceMatrix);

        if (source.morphTexture != null) this.morphTexture = source.morphTexture.clone();
        if (source.instanceColor != null) this.instanceColor = source.instanceColor.clone();

        this.count = source.count;

        if (source.boundingBox != null) this.boundingBox = source.boundingBox.clone();
        if (source.boundingSphere != null) this.boundingSphere = source.boundingSphere.clone();

        return this;
    }

    public function getColorAt(index : Int, color : three.math.Color) {
        color.fromArray(this.instanceColor.array, index * 3);
    }

    public function getMatrixAt(index : Int, matrix : Matrix4) {
        matrix.fromArray(this.instanceMatrix.array, index * 16);
    }

    public function getMorphAt(index : Int, object : { var morphTargetInfluences : Array<Float> }) { // Ideally, create a MorphTargetInfluences interface
        var objectInfluences = object.morphTargetInfluences;

        var array = this.morphTexture.source.data.data;

        var len = objectInfluences.length + 1; // All influences + the baseInfluenceSum

        var dataIndex = index * len + 1; // Skip the baseInfluenceSum at the beginning

        for (i in 0...objectInfluences.length) {
            objectInfluences[i] = array[dataIndex + i];
        }
    }

    // Hypothetical Raycaster type for demonstration
    public function raycast(raycaster : Dynamic, intersects : Array<Dynamic>) { // Ideally, use proper type for intersects
        var matrixWorld = this.matrixWorld;
        var raycastTimes = this.count;

        _mesh.geometry = this.geometry;
        _mesh.material = this.material;

        if (_mesh.material == null) return;

        // test with bounding sphere first

        if (this.boundingSphere == null) this.computeBoundingSphere();

        _sphere.copy(this.boundingSphere);
        _sphere.applyMatrix4(matrixWorld);

        if (!raycaster.ray.intersectsSphere(_sphere)) return;

        // now test each instance

        for (instanceId in 0...raycastTimes) {
            // calculate the world matrix for each instance

            this.getMatrixAt(instanceId, _instanceLocalMatrix);

            _instanceWorldMatrix.multiplyMatrices(matrixWorld, _instanceLocalMatrix);

            // the mesh represents this single instance

            _mesh.matrixWorld = _instanceWorldMatrix;

            _mesh.raycast(raycaster, _instanceIntersects);

            // process the result of raycast

            for (i in 0..._instanceIntersects.length) {
                var intersect = _instanceIntersects[i];
                // Assuming intersect has properties like instanceId and object
                intersect.instanceId = instanceId;
                intersect.object = this;
                intersects.push(intersect);
            }

            _instanceIntersects.length = 0;
        }
    }

    public function setColorAt(index : Int, color : three.math.Color) {
        if (this.instanceColor == null) {
            this.instanceColor = new InstancedBufferAttribute(new Float32Array(this.instanceMatrix.count * 3), 3);
        }

        color.toArray(this.instanceColor.array, index * 3);
    }

    public function setMatrixAt(index : Int, matrix : Matrix4) {
        matrix.toArray(this.instanceMatrix.array, index * 16);
    }

    public function setMorphAt(index : Int, object : { var morphTargetInfluences : Array<Float> }) { // Ideally, create a MorphTargetInfluences interface
        var objectInfluences = object.morphTargetInfluences;

        var len = objectInfluences.length + 1; // morphBaseInfluence + all influences

        if (this.morphTexture == null) {
            this.morphTexture = new DataTexture(new Float32Array(len * this.count), len, this.count, RedFormat, FloatType);
        }

        var array = this.morphTexture.source.data.data;

        var morphInfluencesSum = 0.0;

        for (i in 0...objectInfluences.length) {
            morphInfluencesSum += objectInfluences[i];
        }

        var morphBaseInfluence = (this.geometry.morphTargetsRelative) ? 1 : 1 - morphInfluencesSum;

        var dataIndex = len * index;

        array[dataIndex] = morphBaseInfluence;

        // array.set is not available in Haxe's Float32Array, so we need to copy manually
        for (i in 0...objectInfluences.length) {
            array[dataIndex + 1 + i] = objectInfluences[i];
        }
    }

    override public function updateMorphTargets() {
        // This method is intentionally left blank.
    }

    override public function dispose() {
        super.dispose();

        if (this.morphTexture != null) {
            this.morphTexture.dispose();
            this.morphTexture = null;
        }

        return this;
    }
}