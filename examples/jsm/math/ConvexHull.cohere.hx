import js.three.*;

class ConvexHull {
    public var tolerance:F32 = -1.;
    public var faces:Array<Face>;
    public var newFaces:Array<Face>;
    public var assigned:VertexList;
    public var unassigned:VertexList;
    public var vertices:Array<VertexNode>;

    public function new() {
        faces = [];
        newFaces = [];
        assigned = new VertexList();
        unassigned = new VertexList();
        vertices = [];
    }

    public function setFromPoints(points:Array<Vector3>) : ConvexHull {
        if (points.length >= 4) {
            makeEmpty();
            for (i in 0...points.length) {
                vertices.push(new VertexNode(points[i]));
            }
            compute();
        }
        return this;
    }

    public function setFromObject(object:Object3D) : ConvexHull {
        var points = [];
        object.updateMatrixWorld(true);
        object.traverse($->{
            var geometry = cast geometry;
            if (geometry != null) {
                var attribute = geometry.attributes.position;
                if (attribute != null) {
                    for (i in 0...attribute.count) {
                        var point = new Vector3();
                        point.fromBufferAttribute(attribute, i);
                        point.applyMatrix4(object.matrixWorld);
                        points.push(point);
                    }
                }
            }
        });
        return setFromPoints(points);
    }

    public function containsPoint(point:Vector3) : Bool {
        var faces = this.faces;
        for (i in 0...faces.length) {
            var face = faces[i];
            if (face.distanceToPoint(point) > tolerance) {
                return false;
            }
        }
        return true;
    }

    public function intersectRay(ray:Ray, target:Vector3) : Vector3 {
        var faces = this.faces;
        var tNear = -Infinity;
        var tFar = Infinity;
        for (i in 0...faces.length) {
            var face = faces[i];
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
                tFar = min(t, tFar);
            } else {
                tNear = max(t, tNear);
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

    public function intersectsRay(ray:Ray) : Bool {
        return intersectRay(ray, _v1) != null;
    }

    public function makeEmpty() : ConvexHull {
        faces = [];
        vertices = [];
        return this;
    }

    public function addVertexToFace(vertex:VertexNode, face:Face) : ConvexHull {
        vertex.face = face;
        if (face.outside == null) {
            assigned.append(vertex);
        } else {
            assigned.insertBefore(face.outside, vertex);
        }
        face.outside = vertex;
        return this;
    }

    public function removeVertexFromFace(vertex:VertexNode, face:Face) : ConvexHull {
        if (vertex == face.outside) {
            if (vertex.next != null && vertex.next.face == face) {
                face.outside = vertex.next;
            } else {
                face.outside = null;
            }
        }
        assigned.remove(vertex);
        return this;
    }

    public function removeAllVerticesFromFace(face:Face) : VertexNode {
        if (face.outside != null) {
            var start = face.outside;
            var end = face.outside;
            while (end.next != null && end.next.face == face) {
                end = end.next;
            }
            assigned.removeSubList(start, end);
            start.prev = end.next = null;
            face.outside = null;
            return start;
        }
        return null;
    }

    public function deleteFaceVertices(face:Face, absorbingFace:Face) : ConvexHull {
        var faceVertices = removeAllVerticesFromFace(face);
        if (faceVertices != null) {
            if (absorbingFace == null) {
                unassigned.appendChain(faceVertices);
            } else {
                var vertex = faceVertices;
                do {
                    var nextVertex = vertex.next;
                    var distance = absorbingFace.distanceToPoint(vertex.point);
                    if (distance > tolerance) {
                        addVertexToFace(vertex, absorbingFace);
                    } else {
                        unassigned.append(vertex);
                    }
                    vertex = nextVertex;
                } while (vertex != null);
            }
        }
        return this;
    }

    public function resolveUnassignedPoints(newFaces:Array<Face>) : ConvexHull {
        if (!unassigned.isEmpty()) {
            var vertex = unassigned.first();
            do {
                var nextVertex = vertex.next;
                var maxDistance = tolerance;
                var maxFace:Face = null;
                for (i in 0...newFaces.length) {
                    var face = newFaces[i];
                    if (face.mark == Visible) {
                        var distance = face.distanceToPoint(vertex.point);
                        if (distance > maxDistance) {
                            maxDistance = distance;
                            maxFace = face;
                        }
                        if (maxDistance > 1000 * tolerance) {
                            break;
                        }
                    }
                }
                if (maxFace != null) {
                    addVertexToFace(vertex, maxFace);
                }
                vertex = nextVertex;
            } while (vertex != null);
        }
        return this;
    }

    public function computeExtremes() : {min:Array<VertexNode>, max:Array<VertexNode>} {
        var min = new Vector3();
        var max = new Vector3();
        var minVertices = [];
        var maxVertices = [];
        for (i in 0...3) {
            minVertices[i] = maxVertices[i] = vertices[0];
        }
        min.copy(vertices[0].point);
        max.copy(vertices[0].point);
        for (i in 0...vertices.length) {
            var vertex = vertices[i];
            var point = vertex.point;
            for (j in 0...3) {
                if (point.getComponent(j) < min.getComponent(j)) {
                    min.setComponent(j, point.getComponent(j));
                    minVertices[j] = vertex;
                }
                if (point.getComponent(j) > max.getComponent(j)) {
                    max.setComponent(j, point.getComponent(j));
                    maxVertices[j] = vertex;
                }
            }
        }
        tolerance = 3 * Number.EPSILON * (
            max(abs(min.x), abs(max.x)) +
            max(abs(min.y), abs(max.y)) +
            max(abs(min.z), abs(max.z))
        );
        return {min: minVertices, max: maxVertices};
    }

    public function computeInitialHull() : ConvexHull {
        var vertices = this.vertices;
        var extremes = computeExtremes();
        var min = extremes.min;
        var max = extremes.max;
        var maxDistance = 0.;
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
        var v2:VertexNode;
        var v3:VertexNode;
        maxDistance = 0.;
        var _line3 = new Line3(v0.point, v1.point);
        for (i in 0...vertices.length) {
            var vertex = vertices[i];
            if (vertex != v0 && vertex != v1) {
                _line3.closestPointToPoint(vertex.point, true, _closestPoint);
                var distance = _closestPoint.distanceToSquared(vertex.point);
                if (distance > maxDistance) {
                    maxDistance = distance;
                    v2 = vertex;
                }
            }
        }
        maxDistance = -1.;
        var _plane = new Plane();
        _plane.setFromCoplanarPoints(v0.point, v1.point, v2.point);
        for (i in 0...vertices.length) {
            var vertex = vertices[i];
            if (vertex != v0 && vertex != v1 && vertex != v2) {
                var distance = _plane.distanceToPoint(vertex.point);
                if (distance > maxDistance) {
                    maxDistance = distance;
                    v3 = vertex;
                }
            }
        }
        var faces = [];
        if (_plane.distanceToPoint(v3.point) < 0) {
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
                faces[i + 1].getEdge(2).setTwin(faces[0].getEdge(3 - i));
                faces[i + 1].getEdge(0).setTwin(faces[j + 1].getEdge(1));
            }
        }
        for (i in 0...4) {
            this.faces.push(faces[i]);
        }
        for (i in 0...vertices.length) {
            var vertex = vertices[i];
            if (vertex != v0 && vertex != v1 && vertex != v2 && vertex != v3) {
                var maxDistance = tolerance;
                var maxFace:Face = null;
                for (j in 0...4) {
                    var distance = this.faces[j].distanceToPoint(vertex.point);
                    if (distance > maxDistance) {
                        maxDistance = distance;
                        maxFace = this.faces[j];
                    }
                }
                if (maxFace != null) {
                    addVertexToFace(vertex, maxFace);
                }
            }
        }
        return this;
    }

    public function reindexFaces() : ConvexHull {
        var activeFaces = [];
        for (i in 0...faces.length) {
            var face = faces[i];
            if (face.mark == Visible) {
                activeFaces.push(face);
            }
        }
        faces = activeFaces;
        return this;
    }

    public function nextVertexToAdd() : VertexNode {
        if (!assigned.isEmpty()) {
            var eyeVertex:VertexNode;
            var maxDistance = 0.;
            var eyeFace = assigned.first().face;
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

    public function computeHorizon(eyePoint:Vector3, crossEdge:HalfEdge, face:Face, horizon:Array<HalfEdge>) : ConvexHull {
        deleteFaceVertices(face);
        face.mark = Deleted;
        var edge:HalfEdge;
        if (crossEdge == null) {
            edge = crossEdge = face.getEdge(0);
        } else {
            edge = crossEdge.next;
        }
        do {
            var twinEdge = edge.twin;
            var oppositeFace = twinEdge.face;
            if (oppositeFace.mark == Visible) {
                if (oppositeFace.distanceToPoint(eyePoint) > tolerance) {
                    computeHorizon(eyePoint, twinEdge, oppositeFace, horizon);
                } else {
                    horizon.push(edge);
                }
            }
            edge = edge.next;
        } while (edge != crossEdge);
        return this;
    }

    public function addAdjoiningFace(eyeVertex:VertexNode, horizonEdge:HalfEdge) : Face {
        var face = Face.create(eyeVertex, horizonEdge.tail(), horizonEdge.head());
        faces.push(face);
        face.getEdge(-1).setTwin(horizonEdge.twin);
        return face.getEdge(0);
    }

    public function addNewFaces(eyeVertex:VertexNode, horizon:Array<HalfEdge>) : ConvexHull {
        newFaces = [];
        var firstSideEdge:HalfEdge = null;
        var previousSideEdge:HalfEdge = null;
        for (i in 0...horizon.length) {
            var horizonEdge = horizon[i];
            var sideEdge = addAdjoiningFace(eyeVertex, horizonEdge);
            if (firstSideEdge == null) {
                firstSideEdge = sideEdge;
            } else {
                sideEdge.next.setTwin(previousSideEdge);
            }
            newFaces.push(sideEdge.face);
            previousSideEdge = sideEdge;
        }
        firstSideEdge.next.setTwin(previousSideEdge);
        return this;
    }

    public function addVertexToHull(eyeVertex:VertexNode) : ConvexHull {
        var horizon = [];
        unassigned.clear();
        removeVertexFromFace(eyeVertex, eyeVertex.face);
        computeHorizon(eyeVertex.point, null, eyeVertex.face, horizon);
        addNewFaces(eyeVertex, horizon);
        resolveUnassignedPoints(newFaces);
        return this;
    }

    public function cleanup() : ConvexHull {
        assigned.clear();
        unassigned.clear();
        newFaces = [];
        return this;
    }

    public function compute() : ConvexHull {
        computeInitialHull();
        var vertex:VertexNode;
        while ((vertex = nextVertexToAdd()) != null) {
            addVertexToHull(vertex);
        }
        reindexFaces();
        cleanup();
        return this;
    }
}

class Face {
    public var normal = new Vector3();
    public var midpoint = new Vector3();
    public var area = 0.;
    public var constant = 0.;
    public var outside:VertexNode;
    public var mark = Visible;
    public var edge:HalfEdge;

    public function compute() : Face {
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

    public function distanceToPoint(point:Vector3) : F32 {
        return normal.dot(point) - constant;
    }

    public static function create(a:VertexNode, b:VertexNode, c:VertexNode) : Face {
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

    public function getEdge(i:Int) : HalfEdge {
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
}

class HalfEdge {
    public var vertex:VertexNode;
    public var prev:HalfEdge;
    public var next:HalfEdge;
    public var twin:HalfEdge;
    public var face:Face;

    public function head() : VertexNode {
        return vertex;
    }

    public function tail() : VertexNode {
        return prev != null ? prev.vertex : null;
    }

    public function length() : F32 {
        var head = head();
        var tail = tail();
        if (tail != null) {
            return tail.point.distanceTo(head.point);
        }
        return -1.;
    }

    public function lengthSquared() : F32 {
        var head = head();
        var tail = tail();
        if (tail != null) {
            return tail.point.distanceToSquared(head.point);
        }
        return -1.;
    }

    public function setTwin(edge:HalfEdge) : HalfEdge {
        twin = edge;
        edge.twin = this;
        return this;
    }
}

class VertexNode {
    public var point:Vector3;
    public var prev:VertexNode;
    public var
next:VertexNode;
    public var face:Face;

    public function new(point:Vector3) {
        this.point = point;
    }
}

class VertexList {
    public var head:VertexNode;
    public var tail:VertexNode;

    public function first() : VertexNode {
        return head;
    }

    public function last() : VertexNode {
        return tail;
    }

    public function clear() : VertexList {
        head = tail = null;
        return this;
    }

    public function insertBefore(target:VertexNode, vertex:VertexNode) : VertexList {
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

    public function insertAfter(target:VertexNode, vertex:VertexNode) : VertexList {
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

    public function append(vertex:VertexNode) : VertexList {
        if (head == null) {
            head = vertex;
        } else {
            tail.next = vertex;
        }
        vertex.prev = tail;
        vertex.next = null;
        tail = vertex;
        return this;
    }

    public function appendChain(vertex:VertexNode) : VertexList {
        if (head == null) {
            head = vertex;
        } else {
            tail.next = vertex;
        }
        vertex.prev = tail;
        while (vertex.next != null) {
            vertex = vertex.next;
        }
        tail = vertex;
        return this;
    }

    public function remove(vertex:VertexNode) : VertexList {
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

    public function removeSubList(a:VertexNode, b:VertexNode) : VertexList {
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

    public function isEmpty() : Bool {
        return head == null;
    }
}