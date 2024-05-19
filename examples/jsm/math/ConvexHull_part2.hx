package three.js.examples.jsm.math;

class Face {
    public var normal:Vector3;
    public var midpoint:Vector3;
    public var area:Float;
    public var constant:Float;
    public var outside:Null<Vertex>;
    public var mark:Visible;
    public var edge:HalfEdge;

    public function new() {
        normal = new Vector3();
        midpoint = new Vector3();
        area = 0;
        constant = 0;
        outside = null;
        mark = Visible;
        edge = null;
    }

    public static function create(a:Vertex, b:Vertex, c:Vertex):Face {
        var face = new Face();
        var e0 = new HalfEdge(a, face);
        var e1 = new HalfEdge(b, face);
        var e2 = new HalfEdge(c, face);

        // join edges
        e0.next = e2.prev = e1;
        e1.next = e0.prev = e2;
        e2.next = e1.prev = e0;

        // main half edge reference
        face.edge = e0;

        return face.compute();
    }

    public function getEdge(i:Int):HalfEdge {
        var edge = edge;
        while (i > 0) {
            edge = edge.next;
            i--;
        }
        while (i < 0) {
            edge = edge.prev;
            i++;
        }
        return edge;
    }

    public function compute():Face {
        var a = edge.tail();
        var b = edge.head();
        var c = edge.next.head();

        _triangle.set(a.point, b.point, c.point);

        _triangle.getNormal(normal);
        _triangle.getMidpoint(midpoint);
        area = _triangle.getArea();

        constant = normal.dot(midpoint);

        return this;
    }

    public function distanceToPoint(point:Vector3):Float {
        return normal.dot(point) - constant;
    }
}