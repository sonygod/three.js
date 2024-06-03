import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.textures.DataTexture;
import three.constants.FloatType;
import three.math.Matrix4;
import three.objects.Mesh;
import three.constants.RGBAFormat;
import three.math.ColorManagement;
import three.math.Box3;
import three.math.Sphere;
import three.math.Frustum;
import three.math.Vector3;

class MultiDrawRenderList {
    public var index:Int = 0;
    public var pool:Array<Dynamic> = [];
    public var list:Array<Dynamic> = [];

    public function push(drawRange:Dynamic, z:Float) {
        if (this.index >= this.pool.length) {
            this.pool.push({
                start: -1,
                count: -1,
                z: -1,
            });
        }

        var item = this.pool[this.index];
        this.list.push(item);
        this.index++;

        item.start = drawRange.start;
        item.count = drawRange.count;
        item.z = z;
    }

    public function reset() {
        this.list.length = 0;
        this.index = 0;
    }
}

class BatchedMesh extends Mesh {
    private var ID_ATTR_NAME:String = "batchId";
    private var _matrix:Matrix4 = new Matrix4();
    private var _invMatrixWorld:Matrix4 = new Matrix4();
    private var _identityMatrix:Matrix4 = new Matrix4();
    private var _projScreenMatrix:Matrix4 = new Matrix4();
    private var _frustum:Frustum = new Frustum();
    private var _box:Box3 = new Box3();
    private var _sphere:Sphere = new Sphere();
    private var _vector:Vector3 = new Vector3();
    private var _renderList:MultiDrawRenderList = new MultiDrawRenderList();
    private var _mesh:Mesh = new Mesh(new BufferGeometry(), null);
    private var _batchIntersects:Array<Dynamic> = [];

    // ... rest of the class code
}