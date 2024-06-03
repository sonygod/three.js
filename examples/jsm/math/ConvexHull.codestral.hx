import js.html.compat.Vector3;
import js.html.compat.Line3;
import js.html.compat.Plane;
import js.html.compat.Triangle;

class ConvexHull {
    private var tolerance:Float = -1;
    private var faces:Array<Face> = [];
    private var newFaces:Array<Face> = [];
    private var assigned:VertexList = new VertexList();
    private var unassigned:VertexList = new VertexList();
    private var vertices:Array<VertexNode> = [];

    public function setFromPoints(points:Array<Vector3>):ConvexHull {
        if (points.length >= 4) {
            makeEmpty();
            for (point in points) {
                vertices.push(new VertexNode(point));
            }
            compute();
        }
        return this;
    }

    public function setFromObject(object:Dynamic):ConvexHull {
        var points:Array<Vector3> = [];
        object.updateMatrixWorld(true);
        object.traverse(function (node:Dynamic) {
            var geometry:Dynamic = node.geometry;
            if (geometry !== undefined) {
                var attribute:Dynamic = geometry.attributes.position;
                if (attribute !== undefined) {
                    for (i in 0...attribute.count) {
                        var point:Vector3 = new Vector3();
                        point.fromBufferAttribute(attribute, i).applyMatrix4(node.matrixWorld);
                        points.push(point);
                    }
                }
            }
        });
        return setFromPoints(points);
    }

    public function containsPoint(point:Vector3):Bool {
        for (face in faces) {
            if (face.distanceToPoint(point) > tolerance) return false;
        }
        return true;
    }

    public function intersectRay(ray:Dynamic, target:Vector3):Vector3 {
        var tNear:Float = -Float.POSITIVE_INFINITY;
        var tFar:Float = Float.POSITIVE_INFINITY;
        for (face in faces) {
            var vN:Float = face.distanceToPoint(ray.origin);
            var vD:Float = face.normal.dot(ray.direction);
            if (vN > 0 && vD >= 0) return null;
            var t:Float = (vD !== 0) ? (-vN / vD) : 0;
            if (t <= 0) continue;
            if (vD > 0) {
                tFar = Math.min(t, tFar);
            } else {
                tNear = Math.max(t, tNear);
            }
            if (tNear > tFar) {
                return null;
            }
        }
        if (tNear !== -Float.POSITIVE_INFINITY) {
            ray.at(tNear, target);
        } else {
            ray.at(tFar, target);
        }
        return target;
    }

    public function intersectsRay(ray:Dynamic):Bool {
        return intersectRay(ray, new Vector3()) !== null;
    }

    private function makeEmpty():ConvexHull {
        faces = [];
        vertices = [];
        return this;
    }

    private function addVertexToFace(vertex:VertexNode, face:Face):ConvexHull {
        vertex.face = face;
        if (face.outside === null) {
            assigned.append(vertex);
        } else {
            assigned.insertBefore(face.outside, vertex);
        }
        face.outside = vertex;
        return this;
    }

    private function removeVertexFromFace(vertex:VertexNode, face:Face):ConvexHull {
        if (vertex === face.outside) {
            if (vertex.next !== null && vertex.next.face === face) {
                face.outside = vertex.next;
            } else {
                face.outside = null;
            }
        }
        assigned.remove(vertex);
        return this;
    }

    private function removeAllVerticesFromFace(face:Face):VertexNode {
        if (face.outside !== null) {
            var start:VertexNode = face.outside;
            var end:VertexNode = face.outside;
            while (end.next !== null && end.next.face === face) {
                end = end.next;
            }
            assigned.removeSubList(start, end);
            start.prev = end.next = null;
            face.outside = null;
            return start;
        }
    }

    private function deleteFaceVertices(face:Face, absorbingFace:Face):ConvexHull {
        var faceVertices:VertexNode = removeAllVerticesFromFace(face);
        if (faceVertices !== undefined) {
            if (absorbingFace === undefined) {
                unassigned.appendChain(faceVertices);
            } else {
                var vertex:VertexNode = faceVertices;
                do {
                    var nextVertex:VertexNode = vertex.next;
                    var distance:Float = absorbingFace.distanceToPoint(vertex.point);
                    if (distance > tolerance) {
                        addVertexToFace(vertex, absorbingFace);
                    } else {
                        unassigned.append(vertex);
                    }
                    vertex = nextVertex;
                } while (vertex !== null);
            }
        }
        return this;
    }

    private function resolveUnassignedPoints(newFaces:Array<Face>):ConvexHull {
        if (!unassigned.isEmpty()) {
            var vertex:VertexNode = unassigned.first();
            do {
                var nextVertex:VertexNode = vertex.next;
                var maxDistance:Float = tolerance;
                var maxFace:Face = null;
                for (face in newFaces) {
                    if (face.mark === Visible) {
                        var distance:Float = face.distanceToPoint(vertex.point);
                        if (distance > maxDistance) {
                            maxDistance = distance;
                            maxFace = face;
                        }
                        if (maxDistance > 1000 * tolerance) break;
                    }
                }
                if (maxFace !== null) {
                    addVertexToFace(vertex, maxFace);
                }
                vertex = nextVertex;
            } while (vertex !== null);
        }
        return this;
    }

    private function computeExtremes():Dynamic {
        var min:Vector3 = new Vector3();
        var max:Vector3 = new Vector3();
        var minVertices:Array<VertexNode> = [];
        var maxVertices:Array<VertexNode> = [];
        for (i in 0...3) {
            minVertices[i] = maxVertices[i] = vertices[0];
        }
        min.copy(vertices[0].point);
        max.copy(vertices[0].point);
        for (vertex in vertices) {
            var point:Vector3 = vertex.point;
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
        tolerance = 3 * Float.EPSILON * (
            Math.max(Math.abs(min.x), Math.abs(max.x)) +
            Math.max(Math.abs(min.y), Math.abs(max.y)) +
            Math.max(Math.abs(min.z), Math.abs(max.z))
        );
        return { min: minVertices, max: maxVertices };
    }

    private function computeInitialHull():ConvexHull {
        var extremes:Dynamic = computeExtremes();
        var min:Array<VertexNode> = extremes.min;
        var max:Array<VertexNode> = extremes.max;
        var maxDistance:Float = 0;
        var index:Int = 0;
        for (i in 0...3) {
            var distance:Float = max[i].point.getComponent(i) - min[i].point.getComponent(i);
            if (distance > maxDistance) {
                maxDistance = distance;
                index = i;
            }
        }
        var v0:VertexNode = min[index];
        var v1:VertexNode = max[index];
        var v2:VertexNode;
        var v3:VertexNode;
        maxDistance = 0;
        var line3:Line3 = new Line3().set(v0.point, v1.point);
        for (vertex in vertices) {
            if (vertex !== v0 && vertex !== v1) {
                var closestPoint:Vector3 = new Vector3();
                line3.closestPointToPoint(vertex.point, true, closestPoint);
                var distance:Float = closestPoint.distanceToSquared(vertex.point);
                if (distance > maxDistance) {
                    maxDistance = distance;
                    v2 = vertex;
                }
            }
        }
        maxDistance = -1;
        var plane:Plane = new Plane().setFromCoplanarPoints(v0.point, v1.point, v2.point);
        for (vertex in vertices) {
            if (vertex !== v0 && vertex !== v1 && vertex !== v2) {
                var distance:Float = Math.abs(plane.distanceToPoint(vertex.point));
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
                var j:Int = (i + 1) % 3;
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
                var j:Int = (i + 1) % 3;
                faces[i + 1].getEdge(2).setTwin(faces[0].getEdge((3 - i) % 3));
                faces[i + 1].getEdge(0).setTwin(faces[j + 1].getEdge(1));
            }
        }
        for (i in 0...4) {
            faces.push(faces[i]);
        }
        for (vertex in vertices) {
            if (vertex !== v0 && vertex !== v1 && vertex !== v2 && vertex !== v3) {
                maxDistance = tolerance;
                var maxFace:Face = null;
                for (j in 0...4) {
                    var distance:Float = faces[j].distanceToPoint(vertex.point);
                    if (distance > maxDistance) {
                        maxDistance = distance;
                        maxFace = faces[j];
                    }
                }
                if (maxFace !== null) {
                    addVertexToFace(vertex, maxFace);
                }
            }
        }
        return this;
    }

    private function reindexFaces():ConvexHull {
        var activeFaces:Array<Face> = [];
        for (face in faces) {
            if (face.mark === Visible) {
                activeFaces.push(face);
            }
        }
        faces = activeFaces;
        return this;
    }

    private function nextVertexToAdd():VertexNode {
        if (!assigned.isEmpty()) {
            var maxDistance:Float = 0;
            var eyeFace:Face = assigned.first().face;
            var vertex:VertexNode = eyeFace.outside;
            do {
                var distance:Float = eyeFace.distanceToPoint(vertex.point);
                if (distance > maxDistance) {
                    maxDistance = distance;
                    eyeVertex = vertex;
                }
                vertex = vertex.next;
            } while (vertex !== null && vertex.face === eyeFace);
            return eyeVertex;
        }
    }

    private function computeHorizon(eyePoint:Vector3, crossEdge:HalfEdge, face:Face, horizon:Array<HalfEdge>):ConvexHull {
        deleteFaceVertices(face);
        face.mark = Deleted;
        var edge:HalfEdge;
        if (crossEdge === null) {
            edge = crossEdge = face.getEdge(0);
        } else {
            edge = crossEdge.next;
        }
        do {
            var twinEdge:HalfEdge = edge.twin;
            var oppositeFace:Face = twinEdge.face;
            if (oppositeFace.mark === Visible) {
                if (oppositeFace.distanceToPoint(eyePoint) > tolerance) {
                    computeHorizon(eyePoint, twinEdge, oppositeFace, horizon);
                } else {
                    horizon.push(edge);
                }
            }
            edge = edge.next;
        } while (edge !== crossEdge);
        return this;
    }

    private function addAdjoiningFace(eyeVertex:VertexNode, horizonEdge:HalfEdge):HalfEdge {
        var face:Face = Face.create(eyeVertex, horizonEdge.tail(), horizonEdge.head());
        faces.push(face);
        face.getEdge(-1).setTwin(horizonEdge.twin);
        return face.getEdge(0);
    }

    private function addNewFaces(eyeVertex:VertexNode, horizon:Array<HalfEdge>):ConvexHull {
        newFaces = [];
        var firstSideEdge:HalfEdge = null;
        var previousSideEdge:HalfEdge = null;
        for (horizonEdge in horizon) {
            var sideEdge:HalfEdge = addAdjoiningFace(eyeVertex, horizonEdge);
            if (firstSideEdge === null) {
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

    private function addVertexToHull(eyeVertex:VertexNode):ConvexHull {
        var horizon:Array<HalfEdge> = [];
        unassigned.clear();
        removeVertexFromFace(eyeVertex, eyeVertex.face);
        computeHorizon(eyeVertex.point, null, eyeVertex.face, horizon);
        addNewFaces(eyeVertex, horizon);
        resolveUnassignedPoints(newFaces);
        return this;
    }

    private function cleanup():ConvexHull {
        assigned.clear();
        unassigned.clear();
        newFaces = [];
        return this;
    }

    private function compute():ConvexHull {
        var vertex:VertexNode;
        computeInitialHull();
        while ((vertex = nextVertexToAdd()) !== undefined) {
            addVertexToHull(vertex);
        }
        reindexFaces();
        cleanup();
        return this;
    }
}

class Face {
    public var normal:Vector3 = new Vector3();
    public var midpoint:Vector3 = new Vector3();
    public var area:Float = 0;
    public var constant:Float = 0;
    public var outside:VertexNode = null;
    public var mark:Int = Visible;
    public var edge:HalfEdge = null;

    public static function create(a:VertexNode, b:VertexNode, c:VertexNode):Face {
        var face:Face = new Face();
        var e0:HalfEdge = new HalfEdge(a, face);
        var e1:HalfEdge = new HalfEdge(b, face);
        var e2:HalfEdge = new HalfEdge(c, face);
        e0.next = e2.prev = e1;
        e1.next = e0.prev = e2;
        e2.next = e1.prev = e0;
        face.edge = e0;
        return face.compute();
    }

    public function getEdge(i:Int):HalfEdge {
        var edge:HalfEdge = this.edge;
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
        var a:VertexNode = edge.tail();
        var b:VertexNode = edge.head();
        var c:VertexNode = edge.next.head();
        var triangle:Triangle = new Triangle().set(a.point, b.point, c.point);
        triangle.getNormal(normal);
        triangle.getMidpoint(midpoint);
        area = triangle.getArea();
        constant = normal.dot(midpoint);
        return this;
    }

    public function distanceToPoint(point:Vector3):Float {
        return normal.dot(point) - constant;
    }
}

class HalfEdge {
    public var vertex:VertexNode;
    public var prev:HalfEdge = null;
    public var next:HalfEdge = null;
    public var twin:HalfEdge = null;
    public var face:Face;

    public function new(vertex:VertexNode, face:Face) {
        this.vertex = vertex;
        this.face = face;
    }

    public function head():VertexNode {
        return vertex;
    }

    public function tail():VertexNode {
        return prev !== null ? prev.vertex : null;
    }

    public function length():Float {
        var head:VertexNode = this.head();
        var tail:VertexNode = this.tail();
        if (tail !== null) {
            return tail.point.distanceTo(head.point);
        }
        return -1;
    }

    public function lengthSquared():Float {
        var head:VertexNode = this.head();
        var tail:VertexNode = this.tail();
        if (tail !== null) {
            return tail.point.distanceToSquared(head.point);
        }
        return -1;
    }

    public function setTwin(edge:HalfEdge):HalfEdge {
        twin = edge;
        edge.twin = this;
        return this;
    }
}

class VertexNode {
    public var point:Vector3;
    public var prev:VertexNode = null;
    public var next:VertexNode = null;
    public var face:Face = null;

    public function new(point:Vector3) {
        this.point = point;
    }
}

class VertexList {
    private var head:VertexNode = null;
    private var tail:VertexNode = null;

    public function first():VertexNode {
        return head;
    }

    public function last():VertexNode {
        return tail;
    }

    public function clear():VertexList {
        head = tail = null;
        return this;
    }

    public function insertBefore(target:VertexNode, vertex:VertexNode):VertexList {
        vertex.prev = target.prev;
        vertex.next = target;
        if (vertex.prev === null) {
            head = vertex;
        } else {
            vertex.prev.next = vertex;
        }
        target.prev = vertex;
        return this;
    }

    public function insertAfter(target:VertexNode, vertex:VertexNode):VertexList {
        vertex.prev = target;
        vertex.next = target.next;
        if (vertex.next === null) {
            tail = vertex;
        } else {
            vertex.next.prev = vertex;
        }
        target.next = vertex;
        return this;
    }

    public function append(vertex:VertexNode):VertexList {
        if (head === null) {
            head = vertex;
        } else {
            tail.next = vertex;
        }
        vertex.prev = tail;
        vertex.next = null;
        tail = vertex;
        return this;
    }

    public function appendChain(vertex:VertexNode):VertexList {
        if (head === null) {
            head = vertex;
        } else {
            tail.next = vertex;
        }
        vertex.prev = tail;
        while (vertex.next !== null) {
            vertex = vertex.next;
        }
        tail = vertex;
        return this;
    }

    public function remove(vertex:VertexNode):VertexList {
        if (vertex.prev === null) {
            head = vertex.next;
        } else {
            vertex.prev.next = vertex.next;
        }
        if (vertex.next === null) {
            tail = vertex.prev;
        } else {
            vertex.next.prev = vertex.prev;
        }
        return this;
    }

    public function removeSubList(a:VertexNode, b:VertexNode):VertexList {
        if (a.prev === null) {
            head = b.next;
        } else {
            a.prev.next = b.next;
        }
        if (b.next === null) {
            tail = a.prev;
        } else {
            b.next.prev = a.prev;
        }
        return this;
    }

    public function isEmpty():Bool {
        return head === null;
    }
}

abstract Visible(0);
abstract Deleted(1);