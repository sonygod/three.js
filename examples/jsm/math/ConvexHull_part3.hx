package three.js.examples.jsm.math;

class HalfEdge {

    public var vertex:Vertex;
    public var prev:HalfEdge;
    public var next:HalfEdge;
    public var twin:HalfEdge;
    public var face:Face;

    public function new(vertex:Vertex, face:Face) {
        this.vertex = vertex;
        this.prev = null;
        this.next = null;
        this.twin = null;
        this.face = face;
    }

    public function head():Vertex {
        return this.vertex;
    }

    public function tail():Vertex {
        return prev != null ? prev.vertex : null;
    }

    public function length():Float {
        var head:Vertex = head();
        var tail:Vertex = tail();
        return tail != null ? tail.point.distanceTo(head.point) : -1;
    }

    public function lengthSquared():Float {
        var head:Vertex = head();
        var tail:Vertex = tail();
        return tail != null ? tail.point.distanceToSquared(head.point) : -1;
    }

    public function setTwin(edge:HalfEdge):HalfEdge {
        this.twin = edge;
        edge.twin = this;
        return this;
    }
}