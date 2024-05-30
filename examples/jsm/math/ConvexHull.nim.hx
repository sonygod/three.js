import three.math.Vector3;
import three.math.Line3;
import three.math.Plane;
import three.math.Triangle;

class ConvexHull {
    public var tolerance:Float = -1;
    public var faces:Array<Face>;
    public var newFaces:Array<Face>;
    public var assigned:VertexList;
    public var unassigned:VertexList;
    public var vertices:Array<VertexNode>;

    public function new() {
        this.faces = [];
        this.newFaces = [];
        this.assigned = new VertexList();
        this.unassigned = new VertexList();
        this.vertices = [];
    }

    public function setFromPoints(points:Array<Vector3>) {
        if (points.length >= 4) {
            this.makeEmpty();
            for (i in 0...points.length) {
                this.vertices.push(new VertexNode(points[i]));
            }
            this.compute();
        }
        return this;
    }

    public function setFromObject(object) {
        var points:Array<Vector3> = [];
        object.updateMatrixWorld(true);
        object.traverse(function(node) {
            var geometry = node.geometry;
            if (geometry != null) {
                var attribute = geometry.attributes.position;
                if (attribute != null) {
                    for (i in 0...attribute.count) {
                        var point = new Vector3();
                        point.fromBufferAttribute(attribute, i).applyMatrix4(node.matrixWorld);
                        points.push(point);
                    }
                }
            }
        });
        return this.setFromPoints(points);
    }

    public function containsPoint(point:Vector3):Bool {
        for (face in this.faces) {
            if (face.distanceToPoint(point) > this.tolerance) {
                return false;
            }
        }
        return true;
    }

    public function intersectRay(ray:Line3, target:Vector3):Vector3 {
        // based on "Fast Ray-Convex Polyhedron Intersection" by Eric Haines, GRAPHICS GEMS II
        var tNear = -Infinity;
        var tFar = Infinity;
        for (face in this.faces) {
            var vN = face.distanceToPoint(ray.origin);
            var vD = face.normal.dot(ray.direction);
            if (vN > 0 && vD >= 0) {
                return null;
            }
            var t = (vD != 0) ? (-vN / vD) : 0;
            if (t <= 0) {
                continue;
            }
            if (vD > 0) {
                tFar = Math.min(t, tFar);
            } else {
                tNear = Math.max(t, tNear);
            }
            if (tNear > tFar) {
                return null;
            }
        }
        if (tNear != -Infinity) {
            ray.at(tNear, target);
        } else {
            ray.at(tFar, target);
        }
        return target;
    }

    public function intersectsRay(ray:Line3):Bool {
        return this.intersectRay(ray, new Vector3()) != null;
    }

    public function makeEmpty() {
        this.faces = [];
        this.vertices = [];
        return this;
    }

    public function addVertexToFace(vertex:VertexNode, face:Face) {
        vertex.face = face;
        if (face.outside == null) {
            this.assigned.append(vertex);
        } else {
            this.assigned.insertBefore(face.outside, vertex);
        }
        face.outside = vertex;
        return this;
    }

    public function removeVertexFromFace(vertex:VertexNode, face:Face) {
        if (vertex == face.outside) {
            if (vertex.next != null && vertex.next.face == face) {
                face.outside = vertex.next;
            } else {
                face.outside = null;
            }
        }
        this.assigned.remove(vertex);
        return this;
    }

    public function removeAllVerticesFromFace(face:Face):VertexNode {
        if (face.outside != null) {
            var start = face.outside;
            var end = face.outside;
            while (end.next != null && end.next.face == face) {
                end = end.next;
            }
            this.assigned.removeSubList(start, end);
            start.prev = end.next = null;
            face.outside = null;
            return start;
        }
        return null;
    }

    public function deleteFaceVertices(face:Face, absorbingFace:Face) {
        var faceVertices = this.removeAllVerticesFromFace(face);
        if (faceVertices != null) {
            if (absorbingFace == null) {
                this.unassigned.appendChain(faceVertices);
            } else {
                var vertex = faceVertices;
                do {
                    var nextVertex = vertex.next;
                    var distance = absorbingFace.distanceToPoint(vertex.point);
                    if (distance > this.tolerance) {
                        this.addVertexToFace(vertex, absorbingFace);
                    } else {
                        this.unassigned.append(vertex);
                    }
                    vertex = nextVertex;
                } while (vertex != null);
            }
        }
        return this;
    }

    public function resolveUnassignedPoints(newFaces:Array<Face>) {
        if (!this.unassigned.isEmpty()) {
            var vertex = this.unassigned.first();
            do {
                var nextVertex = vertex.next;
                var maxDistance = this.tolerance;
                var maxFace = null;
                for (i in 0...newFaces.length) {
                    var face = newFaces[i];
                    if (face.mark == Visible) {
                        var distance = face.distanceToPoint(vertex.point);
                        if (distance > maxDistance) {
                            maxDistance = distance;
                            maxFace = face;
                        }
                        if (maxDistance > 1000 * this.tolerance) {
                            break;
                        }
                    }
                }
                if (maxFace != null) {
                    this.addVertexToFace(vertex, maxFace);
                }
                vertex = nextVertex;
            } while (vertex != null);
        }
        return this;
    }

    public function computeExtremes() {
        var min = new Vector3();
        var max = new Vector3();
        var minVertices:Array<VertexNode> = [];
        var maxVertices:Array<VertexNode> = [];
        for (i in 0...3) {
            minVertices[i] = maxVertices[i] = this.vertices[0];
        }
        min.copy(this.vertices[0].point);
        max.copy(this.vertices[0].point);
        for (i in 0...this.vertices.length) {
            var vertex = this.vertices[i];
            var point = vertex.point;
            for (j in 0...3) {
                if (point.getComponent(j) < min.getComponent(j)) {
                    min.setComponent(j, point.getComponent(j));
                    minVertices[j] = vertex;
                }
            }
            for (j in 0...3) {
                if (point.getComponent(j) > max.getComponent(j)) {
                    max.setComponent(j, point.getComponent(j));
                    maxVertices[j] = vertex;
                }
            }
        }
        this.tolerance = 3 * Number.EPSILON * (
            Math.max(Math.abs(min.x), Math.abs(max.x)) +
            Math.max(Math.abs(min.y), Math.abs(max.y)) +
            Math.max(Math.abs(min.z), Math.abs(max.z))
        );
        return {min: minVertices, max: maxVertices};
    }

    public function computeInitialHull() {
        var vertices = this.vertices;
        var extremes = this.computeExtremes();
        var min = extremes.min;
        var max = extremes.max;
        var maxDistance = 0;
        var index = 0;
        for (i in 0...3) {
            var distance = max[i].point.getComponent(i) - min[i].point.getComponent(i);
            if (distance > maxDistance) {
                maxDistance = distance;
                index = i;
            }
        }
        var v0 = min[index];
        var v1 = max[index];
        var v2;
        var v3;
        maxDistance = 0;
        var line3 = new Line3();
        line3.set(v0.point, v1.point);
        for (i in 0...this.vertices.length) {
            var vertex = vertices[i];
            if (vertex != v0 && vertex != v1) {
                var closestPoint = new Vector3();
                line3.closestPointToPoint(vertex.point, true, closestPoint);
                var distance = closestPoint.distanceToSquared(vertex.point);
                if (distance > maxDistance) {
                    maxDistance = distance;
                    v2 = vertex;
                }
            }
        }
        maxDistance = -1;
        var plane = new Plane();
        plane.setFromCoplanarPoints(v0.point, v1.point, v2.point);
        for (i in 0...this.vertices.length) {
            var vertex = vertices[i];
            if (vertex != v0 && vertex != v1 && vertex != v2) {
                var distance = Math.abs(plane.distanceToPoint(vertex.point));
                if (distance > maxDistance) {
                    maxDistance = distance;
                    v3 = vertex;
                }
            }
        }
        var faces:Array<Face> = [];
        if (plane.distanceToPoint(v3.point) < 0) {
            faces.push(
                Face.create(v0, v1, v2),
                Face.create(v3, v1, v0),
                Face.create(v3, v2, v1),
                Face.create(v3, v0, v2)
            );
            for (i in 0...3) {
                var j = (i + 1) % 3;
                faces[i + 1].getEdge(2).setTwin(faces[0].getEdge(j));
                faces[i + 1].getEdge(1).setTwin(faces[j + 1].getEdge(0));
            }
        } else {
            faces.push(
                Face.create(v0, v2, v1),
                Face.create(v3, v0, v1),
                Face.create(v3, v1, v2),
                Face.create(v3, v2, v0)
            );
            for (i in 0...3) {
                var j = (i + 1) % 3;
                faces[i + 1].getEdge(2).setTwin(faces[0].getEdge((3 - i) % 3));
                faces[i + 1].getEdge(0).setTwin(faces[j + 1].getEdge(1));
            }
        }
        for (i in 0...4) {
            this.faces.push(faces[i]);
        }
        for (i in 0...this.vertices.length) {
            var vertex = vertices[i];
            if (vertex != v0 && vertex != v1 && vertex != v2 && vertex != v3) {
                maxDistance = this.tolerance;
                var maxFace = null;
                for (j in 0...4) {
                    var distance = this.faces[j].distanceToPoint(vertex.point);
                    if (distance > maxDistance) {
                        maxDistance = distance;
                        maxFace = this.faces[j];
                    }
                }
                if (maxFace != null) {
                    this.addVertexToFace(vertex, maxFace);
                }
            }
        }
        return this;
    }

    public function reindexFaces() {
        var activeFaces:Array<Face> = [];
        for (face in this.faces) {
            if (face.mark == Visible) {
                activeFaces.push(face);
            }
        }
        this.faces = activeFaces;
        return this;
    }

    public function nextVertexToAdd():VertexNode {
        if (!this.assigned.isEmpty()) {
            var eyeVertex:VertexNode;
            var maxDistance = 0;
            var eyeFace = this.assigned.first().face;
            var vertex = eyeFace.outside;
            do {
                var distance = eyeFace.distanceToPoint(vertex.point);
                if (distance > maxDistance) {
                    maxDistance = distance;
                    eyeVertex = vertex;
                }
                vertex = vertex.next;
            } while (vertex != null && vertex.face == eyeFace);
            return eyeVertex;
        }
        return null;
    }

    public function computeHorizon(eyePoint:Vector3, crossEdge:HalfEdge, face:Face, horizon:Array<HalfEdge>) {
        this.deleteFaceVertices(face);
        face.mark = Deleted;
        var edge;
        if (crossEdge == null) {
            edge = crossEdge = face.getEdge(0);
        } else {
            edge = crossEdge.next;
        }
        do {
            var twinEdge = edge.twin;
            var oppositeFace = twinEdge.face;
            if (oppositeFace.mark == Visible) {
                if (oppositeFace.distanceToPoint(eyePoint) > this.tolerance) {
                    this.computeHorizon(eyePoint, twinEdge, oppositeFace, horizon);
                } else {
                    horizon.push(edge);
                }
            }
            edge = edge.next;
        } while (edge != crossEdge);
        return this;
    }

    public function addAdjoiningFace(eyeVertex:VertexNode, horizonEdge:HalfEdge):HalfEdge {
        var face = Face.create(eyeVertex, horizonEdge.tail(), horizonEdge.head());
        this.faces.push(face);
        face.getEdge(-1).setTwin(horizonEdge.twin);
        return face.getEdge(0);
    }

    public function addNewFaces(eyeVertex:VertexNode, horizon:Array<HalfEdge>) {
        this.newFaces = [];
        var firstSideEdge:HalfEdge;
        var previousSideEdge:HalfEdge;
        for (i in 0...horizon.length) {
            var horizonEdge = horizon[i];
            var sideEdge = this.addAdjoiningFace(eyeVertex, horizonEdge);
            if (firstSideEdge == null) {
                firstSideEdge = sideEdge;
            } else {
                sideEdge.next.setTwin(previousSideEdge);
            }
            this.newFaces.push(sideEdge.face);
            previousSideEdge = sideEdge;
        }
        firstSideEdge.next.setTwin(previousSideEdge);
        return this;
    }

    public function addVertexToHull(eyeVertex:VertexNode) {
        var horizon:Array<HalfEdge> = [];
        this.unassigned.clear();
        this.removeVertexFromFace(eyeVertex, eyeVertex.face);
        this.computeHorizon(eyeVertex.point, null, eyeVertex.face, horizon);
        this.addNewFaces(eyeVertex, horizon);
        this.resolveUnassignedPoints(this.newFaces);
        return this;
    }

    public function cleanup() {
        this.assigned.clear();
        this.unassigned.clear();
        this.newFaces = [];
        return this;
    }

    public function compute() {
        var vertex:VertexNode;
        this.computeInitialHull();
        while ((vertex = this.nextVertexToAdd()) != null) {
            this.addVertexToHull(vertex);
        }
        this.reindexFaces();
        this.cleanup();
        return this;
    }
}

class Face {
    public var normal:Vector3;
    public var midpoint:Vector3;
    public var area:Float;
    public var constant:Float;
    public var outside:VertexNode;
    public var mark:Int;
    public var edge:HalfEdge;

    public function new() {
        this.normal = new Vector3();
        this.midpoint = new Vector3();
        this.area = 0;
        this.constant = 0;
        this.outside = null;
        this.mark = Visible;
        this.edge = null;
    }

    public static function create(a:VertexNode, b:VertexNode, c:VertexNode):Face {
        var face = new Face();
        var e0 = new HalfEdge(a, face);
        var e1 = new HalfEdge(b, face);
        var e2 = new HalfEdge(c, face);
        e0.next = e2.prev = e1;
        e1.next = e0.prev = e2;
        e2.next = e1.prev = e0;
        face.edge = e0;
        return face.compute();
    }

    public function getEdge(i:Int):HalfEdge {
        var edge = this.edge;
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
        var a = this.edge.tail();
        var b = this.edge.head();
        var c = this.edge.next.head();
        var triangle = new Triangle(a.point, b.point, c.point);
        triangle.getNormal(this.normal);
        triangle.getMidpoint(this.midpoint);
        this.area = triangle.getArea();
        this.constant = this.normal.dot(this.midpoint);
        return this;
    }

    public function distanceToPoint(point:Vector3):Float {
        return this.normal.dot(point) - this.constant;
    }
}

class HalfEdge {
    public var vertex:VertexNode;
    public var prev:HalfEdge;
    public var next:HalfEdge;
    public var twin:HalfEdge;
    public var face:Face;

    public function new(vertex:VertexNode, face:Face) {
        this.vertex = vertex;
        this.prev = null;
        this.next = null;
        this.twin = null;
        this.face = face;
    }

    public function head():VertexNode {
        return this.vertex;
    }

    public function tail():VertexNode {
        return this.prev != null ? this.prev.vertex : null;
    }

    public function length():Float {
        var head = this.head();
        var tail = this.tail();
        if (tail != null) {
            return tail.point.distanceTo(head.point);
        }
        return -1;
    }

    public function lengthSquared():Float {
        var head = this.head();
        var tail = this.tail();
        if (tail != null) {
            return tail.point.distanceToSquared(head.point);
        }
        return -1;
    }

    public function setTwin(edge:HalfEdge):HalfEdge {
        this.twin = edge;
        edge.twin = this;
        return this;
    }
}

class VertexNode {
    public var point:Vector3;
    public var prev:VertexNode;
    public var next:VertexNode;
    public var face:Face;

    public function new(point:Vector3) {
        this.point = point;
        this.prev = null;
        this.next = null;
        this.face = null;
    }
}

class VertexList {
    public var head:VertexNode;
    public var tail:VertexNode;

    public function new() {
        this.head = null;
        this.tail = null;
    }

    public function first():VertexNode {
        return this.head;
    }

    public function last():VertexNode {
        return this.tail;
    }

    public function clear() {
        this.head = this.tail = null;
    }

    public function insertBefore(target:VertexNode, vertex:VertexNode):VertexList {
        vertex.prev = target.prev;
        vertex.next = target;
        if (vertex.prev == null) {
            this.head = vertex;
        } else {
            vertex.prev.next = vertex;
        }
        target.prev = vertex;
        return this;
    }

    public function insertAfter(target:VertexNode, vertex:VertexNode):VertexList {
        vertex.prev = target;
        vertex.next = target.next;
        if (vertex.next == null) {
            this.tail = vertex;
        } else {
            vertex.next.prev = vertex;
        }
        target.next = vertex;
        return this;
    }

    public function append(vertex:VertexNode):VertexList {
        if (this.head == null) {
            this.head = vertex;
        } else {
            this.tail.next = vertex;
        }
        vertex.prev = this.tail;
        vertex.next = null;
        this.tail = vertex;
        return this;
    }

    public function appendChain(vertex:VertexNode):VertexList {
        if (this.head == null) {
            this.head = vertex;
        } else {
            this.tail.next = vertex;
        }
        vertex.prev = this.tail;
        while (vertex.next != null) {
            vertex = vertex.next;
        }
        this.tail = vertex;
        return this;
    }

    public function remove(vertex:VertexNode):VertexList {
        if (vertex.prev == null) {
            this.head = vertex.next;
        } else {
            vertex.prev.next = vertex.next;
        }
        if (vertex.next == null) {
            this.tail = vertex.prev;
        } else {
            vertex.next.prev = vertex.prev;
        }
        return this;
    }

    public function removeSubList(a:VertexNode, b:VertexNode):VertexList {
        if (a.prev == null) {
            this.head = b.next;
        } else {
            a.prev.next = b.next;
        }
        if (b.next == null) {
            this.tail = a.prev;
        } else {
            b.next.prev = a.prev;
        }
        return this;
    }

    public function isEmpty():Bool {
        return this.head == null;
    }
}