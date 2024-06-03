class SimplifyModifier {

    public function modify(geometry:Geometry, count:Int):Geometry {
        // The implementation of this method depends on the specifics of the Geometry and BufferGeometry classes,
        // which are not defined in the provided code.
        return null;
    }

}

class Triangle {

    public var v1:Vertex;
    public var v2:Vertex;
    public var v3:Vertex;

    public var normal:Vector3;

    public function new(v1:Vertex, v2:Vertex, v3:Vertex) {
        this.v1 = v1;
        this.v2 = v2;
        this.v3 = v3;

        this.normal = new Vector3();
        this.computeNormal();
    }

    public function computeNormal() {
        // The implementation of this method depends on the specifics of the Vector3 class,
        // which is not defined in the provided code.
    }

    public function hasVertex(v:Vertex):Bool {
        return v === this.v1 || v === this.v2 || v === this.v3;
    }

    public function replaceVertex(oldv:Vertex, newv:Vertex) {
        // The implementation of this method depends on the specifics of the Vector3 class,
        // which is not defined in the provided code.
    }

}

class Vertex {

    public var position:Vector3;
    public var uv:Vector2;
    public var normal:Vector3;
    public var tangent:Vector4;
    public var color:Color;

    public var id:Int;

    public var faces:Array<Triangle>;
    public var neighbors:Array<Vertex>;

    public var collapseCost:Float;
    public var collapseNeighbor:Vertex;

    public function new(v:Vector3, uv:Vector2, normal:Vector3, tangent:Vector4, color:Color) {
        this.position = v;
        this.uv = uv;
        this.normal = normal;
        this.tangent = tangent;
        this.color = color;

        this.id = -1;

        this.faces = [];
        this.neighbors = [];

        this.collapseCost = 0;
        this.collapseNeighbor = null;
    }

    public function addUniqueNeighbor(vertex:Vertex) {
        if (!this.neighbors.contains(vertex)) {
            this.neighbors.push(vertex);
        }
    }

    public function removeIfNonNeighbor(n:Vertex) {
        var offset = this.neighbors.indexOf(n);

        if (offset === -1) return;

        for (i in 0...this.faces.length) {
            if (this.faces[i].hasVertex(n)) return;
        }

        this.neighbors.splice(offset, 1);
    }

}