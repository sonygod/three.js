import js.html.ArrayBufferView;
import js.html.ArrayBufferViewType;
import js.html.Float32Array;
import js.html.Int32Array;
import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.DynamicDrawUsage;
import three.Material;
import three.Mesh;
import three.Sphere;
import three.Vector3;

class MarchingCubes extends Mesh {
    var geometry: BufferGeometry;
    var vlist: Float32Array;
    var nlist: Float32Array;
    var clist: Float32Array;
    var positionArray: Float32Array;
    var normalArray: Float32Array;
    var uvArray: Float32Array;
    var colorArray: Float32Array;

    public function new(resolution: Int, material: Material, enableUvs: Bool = false, enableColors: Bool = false, maxPolyCount: Int = 10000) {
        geometry = new BufferGeometry();
        super(geometry, material);
        isMarchingCubes = true;

        vlist = new Float32Array(12 * 3);
        nlist = new Float32Array(12 * 3);
        clist = new Float32Array(12 * 3);

        this.enableUvs = enableUvs;
        this.enableColors = enableColors;

        init(resolution);
    }

    public function init(resolution: Int) {
        this.resolution = resolution;
        this.isolation = 80.0;
        this.size = resolution;
        this.size2 = this.size * this.size;
        this.size3 = this.size2 * this.size;
        this.halfsize = this.size / 2.0;
        this.delta = 2.0 / this.size;
        this.yd = this.size;
        this.zd = this.size2;

        this.field = new Float32Array(this.size3);
        this.normal_cache = new Float32Array(this.size3 * 3);
        this.palette = new Float32Array(this.size3 * 3);

        this.count = 0;

        var maxVertexCount = maxPolyCount * 3;

        positionArray = new Float32Array(maxVertexCount * 3);
        var positionAttribute = new BufferAttribute(positionArray, 3);
        positionAttribute.setUsage(DynamicDrawUsage.DynamicDrawUsage_DYNAMIC_DRAW);
        geometry.setAttribute('position', positionAttribute);

        normalArray = new Float32Array(maxVertexCount * 3);
        var normalAttribute = new BufferAttribute(normalArray, 3);
        normalAttribute.setUsage(DynamicDrawUsage.DynamicDrawUsage_DYNAMIC_DRAW);
        geometry.setAttribute('normal', normalAttribute);

        if (enableUvs) {
            uvArray = new Float32Array(maxVertexCount * 2);
            var uvAttribute = new BufferAttribute(uvArray, 2);
            uvAttribute.setUsage(DynamicDrawUsage.DynamicDrawUsage_DYNAMIC_DRAW);
            geometry.setAttribute('uv', uvAttribute);
        }

        if (enableColors) {
            colorArray = new Float32Array(maxVertexCount * 3);
            var colorAttribute = new BufferAttribute(colorArray, 3);
            colorAttribute.setUsage(DynamicDrawUsage.DynamicDrawUsage_DYNAMIC_DRAW);
            geometry.setAttribute('color', colorAttribute);
        }

        geometry.boundingSphere = new Sphere(new Vector3(), 1);
    }

    // ... rest of the methods ...
}

var edgeTable = new Int32Array([
    // ... edgeTable values ...
]);

var triTable = new Int32Array([
    // ... triTable values ...
]);