import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;
import three.math.Vector2;

class PolyhedronGeometry extends BufferGeometry {

    public var vertices:Array<Float> = [];
    public var indices:Array<Int> = [];
    public var radius:Float = 1.0;
    public var detail:Int = 0;

    public function new(?vertices:Array<Float>, ?indices:Array<Int>, ?radius:Float, ?detail:Int) {
        super();

        this.type = 'PolyhedronGeometry';

        if (vertices != null) this.vertices = vertices;
        if (indices != null) this.indices = indices;
        if (radius != null) this.radius = radius;
        if (detail != null) this.detail = detail;

        // default buffer data
        var vertexBuffer:Array<Float> = [];
        var uvBuffer:Array<Float> = [];

        // the subdivision creates the vertex buffer data
        subdivide(detail);

        // all vertices should lie on a conceptual sphere with a given radius
        applyRadius(radius);

        // finally, create the uv data
        generateUVs();

        // build non-indexed geometry
        this.setAttribute('position', new BufferAttribute(vertexBuffer, 3));
        this.setAttribute('normal', new BufferAttribute(vertexBuffer.slice(), 3));
        this.setAttribute('uv', new BufferAttribute(uvBuffer, 2));

        if (detail == 0) {
            this.computeVertexNormals(); // flat normals
        } else {
            this.normalizeNormals(); // smooth normals
        }
    }

    // ... rest of the class methods ...
}