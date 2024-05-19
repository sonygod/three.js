package three.js.examples.jsm.math;

class VertexNode {
    public var point:Dynamic;
    public var prev:VertexNode;
    public var next:VertexNode;
    public var face:Dynamic; // the face that is able to see this vertex

    public function new(point:Dynamic) {
        this.point = point;
        this.prev = null;
        this.next = null;
        this.face = null;
    }
}