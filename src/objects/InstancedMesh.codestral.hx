import three.core.InstancedBufferAttribute;
import three.objects.Mesh;
import three.math.Box3;
import three.math.Matrix4;
import three.math.Sphere;
import three.textures.DataTexture;
import three.constants.FloatType;
import three.constants.RedFormat;

class InstancedMesh extends Mesh {
    private var _instanceLocalMatrix:Matrix4 = new Matrix4();
    private var _instanceWorldMatrix:Matrix4 = new Matrix4();
    private var _instanceIntersects:Array<any> = [];
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

    public function new(geometry:any, material:any, count:Int) {
        super(geometry, material);
        this.isInstancedMesh = true;

        this.instanceMatrix = new InstancedBufferAttribute(new Float32Array(count * 16), 16);
        this.instanceColor = null;
        this.morphTexture = null;

        this.count = count;

        this.boundingBox = null;
        this.boundingSphere = null;

        for (var i:Int = 0; i < count; i++) {
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

        for (var i:Int = 0; i < count; i++) {
            this.getMatrixAt(i, _instanceLocalMatrix);
            _box3.copy(geometry.boundingBox).applyMatrix4(_instanceLocalMatrix);
            this.boundingBox.union(_box3);
        }
    }

    // rest of the functions can be translated in similar manner
}