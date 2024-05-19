package three.js.examples.jm.math;

class VertexList {
    var head:Vertex = null;
    var tail:Vertex = null;

    public function new() {}

    public function first():Vertex {
        return head;
    }

    public function last():Vertex {
        return tail;
    }

    public function clear():VertexList {
        head = tail = null;
        return this;
    }

    public function insertBefore(target:Vertex, vertex:Vertex):VertexList {
        vertex.prev = target.prev;
        vertex.next = target;
        if (vertex.prev == null) {
            head = vertex;
        } else {
            vertex.prev.next = vertex;
        }
        target.prev = vertex;
        return this;
    }

    public function insertAfter(target:Vertex, vertex:Vertex):VertexList {
        vertex.prev = target;
        vertex.next = target.next;
        if (vertex.next == null) {
            tail = vertex;
        } else {
            vertex.next.prev = vertex;
        }
        target.next = vertex;
        return this;
    }

    public function append(vertex:Vertex):VertexList {
        if (head == null) {
            head = vertex;
        } else {
            tail.next = vertex;
        }
        vertex.prev = tail;
        vertex.next = null; // the tail has no subsequent vertex
        tail = vertex;
        return this;
    }

    public function appendChain(vertex:Vertex):VertexList {
        if (head == null) {
            head = vertex;
        } else {
            tail.next = vertex;
        }
        vertex.prev = tail;
        // ensure that the 'tail' reference points to the last vertex of the chain
        while (vertex.next != null) {
            vertex = vertex.next;
        }
        tail = vertex;
        return this;
    }

    public function remove(vertex:Vertex):VertexList {
        if (vertex.prev == null) {
            head = vertex.next;
        } else {
            vertex.prev.next = vertex.next;
        }
        if (vertex.next == null) {
            tail = vertex.prev;
        } else {
            vertex.next.prev = vertex.prev;
        }
        return this;
    }

    public function removeSubList(a:Vertex, b:Vertex):VertexList {
        if (a.prev == null) {
            head = b.next;
        } else {
            a.prev.next = b.next;
        }
        if (b.next == null) {
            tail = a.prev;
        } else {
            b.next.prev = a.prev;
        }
        return this;
    }

    public function isEmpty():Bool {
        return head == null;
    }
}