import three.math.Vector3;
import three.math.Line3;
import three.math.Plane;
import three.math.Triangle;

class Visible {
  public static var value:Int = 0;
}

class Deleted {
  public static var value:Int = 1;
}

class ConvexHull {

  public var tolerance:Float = -1;
  public var faces:Array<Face> = []; // the generated faces of the convex hull
  public var newFaces:Array<Face> = []; // this array holds the faces that are generated within a single iteration
  public var assigned:VertexList = new VertexList();
  public var unassigned:VertexList = new VertexList();
  public var vertices:Array<VertexNode> = []; 	// vertices of the hull (internal representation of given geometry data)

  public function new() {

  }

  public function setFromPoints(points:Array<Vector3>):ConvexHull {

    // The algorithm needs at least four points.

    if (points.length >= 4) {

      this.makeEmpty();

      for (i in 0...points.length) {

        this.vertices.push(new VertexNode(points[i]));

      }

      this.compute();

    }

    return this;

  }

  public function setFromObject(object:Dynamic):ConvexHull {

    var points:Array<Vector3> = [];

    object.updateMatrixWorld(true);

    object.traverse(function(node:Dynamic) {

      var geometry:Dynamic = node.geometry;

      if (geometry != null) {

        var attribute:Dynamic = geometry.attributes.position;

        if (attribute != null) {

          for (i in 0...attribute.count) {

            var point:Vector3 = new Vector3();

            point.fromBufferAttribute(attribute, i).applyMatrix4(node.matrixWorld);

            points.push(point);

          }

        }

      }

    });

    return this.setFromPoints(points);

  }

  public function containsPoint(point:Vector3):Bool {

    var faces:Array<Face> = this.faces;

    for (i in 0...faces.length) {

      var face:Face = faces[i];

      // compute signed distance and check on what half space the point lies

      if (face.distanceToPoint(point) > this.tolerance) return false;

    }

    return true;

  }

  public function intersectRay(ray:Line3, target:Vector3):Vector3 {

    // based on "Fast Ray-Convex Polyhedron Intersection" by Eric Haines, GRAPHICS GEMS II

    var faces:Array<Face> = this.faces;

    var tNear:Float = -Math.POSITIVE_INFINITY;
    var tFar:Float = Math.POSITIVE_INFINITY;

    for (i in 0...faces.length) {

      var face:Face = faces[i];

      // interpret faces as planes for the further computation

      var vN:Float = face.distanceToPoint(ray.origin);
      var vD:Float = face.normal.dot(ray.direction);

      // if the origin is on the positive side of a plane (so the plane can "see" the origin) and
      // the ray is turned away or parallel to the plane, there is no intersection

      if (vN > 0 && vD >= 0) return null;

      // compute the distance from the ray’s origin to the intersection with the plane

      var t:Float = (vD != 0) ? (-vN / vD) : 0;

      // only proceed if the distance is positive. a negative distance means the intersection point
      // lies "behind" the origin

      if (t <= 0) continue;

      // now categorized plane as front-facing or back-facing

      if (vD > 0) {

        // plane faces away from the ray, so this plane is a back-face

        tFar = Math.min(t, tFar);

      } else {

        // front-face

        tNear = Math.max(t, tNear);

      }

      if (tNear > tFar) {

        // if tNear ever is greater than tFar, the ray must miss the convex hull

        return null;

      }

    }

    // evaluate intersection point

    // always try tNear first since its the closer intersection point

    if (tNear != -Math.POSITIVE_INFINITY) {

      ray.at(tNear, target);

    } else {

      ray.at(tFar, target);

    }

    return target;

  }

  public function intersectsRay(ray:Line3):Bool {

    return this.intersectRay(ray, new Vector3()) != null;

  }

  public function makeEmpty():ConvexHull {

    this.faces = [];
    this.vertices = [];

    return this;

  }

  // Adds a vertex to the 'assigned' list of vertices and assigns it to the given face

  public function addVertexToFace(vertex:VertexNode, face:Face):ConvexHull {

    vertex.face = face;

    if (face.outside == null) {

      this.assigned.append(vertex);

    } else {

      this.assigned.insertBefore(face.outside, vertex);

    }

    face.outside = vertex;

    return this;

  }

  // Removes a vertex from the 'assigned' list of vertices and from the given face

  public function removeVertexFromFace(vertex:VertexNode, face:Face):ConvexHull {

    if (vertex == face.outside) {

      // fix face.outside link

      if (vertex.next != null && vertex.next.face == face) {

        // face has at least 2 outside vertices, move the 'outside' reference

        face.outside = vertex.next;

      } else {

        // vertex was the only outside vertex that face had

        face.outside = null;

      }

    }

    this.assigned.remove(vertex);

    return this;

  }

  // Removes all the visible vertices that a given face is able to see which are stored in the 'assigned' vertex list

  public function removeAllVerticesFromFace(face:Face):VertexNode {

    if (face.outside != null) {

      // reference to the first and last vertex of this face

      var start:VertexNode = face.outside;
      var end:VertexNode = face.outside;

      while (end.next != null && end.next.face == face) {

        end = end.next;

      }

      this.assigned.removeSubList(start, end);

      // fix references

      start.prev = end.next = null;
      face.outside = null;

      return start;

    }

  }

  // Removes all the visible vertices that 'face' is able to see

  public function deleteFaceVertices(face:Face, absorbingFace:Face):ConvexHull {

    var faceVertices:VertexNode = this.removeAllVerticesFromFace(face);

    if (faceVertices != null) {

      if (absorbingFace == null) {

        // mark the vertices to be reassigned to some other face

        this.unassigned.appendChain(faceVertices);


      } else {

        // if there's an absorbing face try to assign as many vertices as possible to it

        var vertex:VertexNode = faceVertices;

        do {

          // we need to buffer the subsequent vertex at this point because the 'vertex.next' reference
          // will be changed by upcoming method calls

          var nextVertex:VertexNode = vertex.next;

          var distance:Float = absorbingFace.distanceToPoint(vertex.point);

          // check if 'vertex' is able to see 'absorbingFace'

          if (distance > this.tolerance) {

            this.addVertexToFace(vertex, absorbingFace);

          } else {

            this.unassigned.append(vertex);

          }

          // now assign next vertex

          vertex = nextVertex;

        } while (vertex != null);

      }

    }

    return this;

  }

  // Reassigns as many vertices as possible from the unassigned list to the new faces

  public function resolveUnassignedPoints(newFaces:Array<Face>):ConvexHull {

    if (!this.unassigned.isEmpty()) {

      var vertex:VertexNode = this.unassigned.first();

      do {

        // buffer 'next' reference, see .deleteFaceVertices()

        var nextVertex:VertexNode = vertex.next;

        var maxDistance:Float = this.tolerance;

        var maxFace:Face = null;

        for (i in 0...newFaces.length) {

          var face:Face = newFaces[i];

          if (face.mark == Visible.value) {

            var distance:Float = face.distanceToPoint(vertex.point);

            if (distance > maxDistance) {

              maxDistance = distance;
              maxFace = face;

            }

            if (maxDistance > 1000 * this.tolerance) break;

          }

        }

        // 'maxFace' can be null e.g. if there are identical vertices

        if (maxFace != null) {

          this.addVertexToFace(vertex, maxFace);

        }

        vertex = nextVertex;

      } while (vertex != null);

    }

    return this;

  }

  // Computes the extremes of a simplex which will be the initial hull

  public function computeExtremes():{min:Array<VertexNode>, max:Array<VertexNode>} {

    var min:Vector3 = new Vector3();
    var max:Vector3 = new Vector3();

    var minVertices:Array<VertexNode> = [];
    var maxVertices:Array<VertexNode> = [];

    // initially assume that the first vertex is the min/max

    for (i in 0...3) {

      minVertices[i] = maxVertices[i] = this.vertices[0];

    }

    min.copy(this.vertices[0].point);
    max.copy(this.vertices[0].point);

    // compute the min/max vertex on all six directions

    for (i in 0...this.vertices.length) {

      var vertex:VertexNode = this.vertices[i];
      var point:Vector3 = vertex.point;

      // update the min coordinates

      for (j in 0...3) {

        if (point.getComponent(j) < min.getComponent(j)) {

          min.setComponent(j, point.getComponent(j));
          minVertices[j] = vertex;

        }

      }

      // update the max coordinates

      for (j in 0...3) {

        if (point.getComponent(j) > max.getComponent(j)) {

          max.setComponent(j, point.getComponent(j));
          maxVertices[j] = vertex;

        }

      }

    }

    // use min/max vectors to compute an optimal epsilon

    this.tolerance = 3 * Math.EPSILON * (
      Math.max(Math.abs(min.x), Math.abs(max.x)) +
      Math.max(Math.abs(min.y), Math.abs(max.y)) +
      Math.max(Math.abs(min.z), Math.abs(max.z))
    );

    return {min:minVertices, max:maxVertices};

  }

  // Computes the initial simplex assigning to its faces all the points
  // that are candidates to form part of the hull

  public function computeInitialHull():ConvexHull {

    var vertices:Array<VertexNode> = this.vertices;
    var extremes:Dynamic = this.computeExtremes();
    var min:Array<VertexNode> = extremes.min;
    var max:Array<VertexNode> = extremes.max;

    // 1. Find the two vertices 'v0' and 'v1' with the greatest 1d separation
    // (max.x - min.x)
    // (max.y - min.y)
    // (max.z - min.z)

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

    // 2. The next vertex 'v2' is the one farthest to the line formed by 'v0' and 'v1'

    maxDistance = 0;
    var _line3:Line3 = new Line3(v0.point, v1.point);

    for (i in 0...this.vertices.length) {

      var vertex:VertexNode = vertices[i];

      if (vertex != v0 && vertex != v1) {

        _line3.closestPointToPoint(vertex.point, true, new Vector3());

        var distance:Float = _closestPoint.distanceToSquared(vertex.point);

        if (distance > maxDistance) {

          maxDistance = distance;
          v2 = vertex;

        }

      }

    }

    // 3. The next vertex 'v3' is the one farthest to the plane 'v0', 'v1', 'v2'

    maxDistance = -1;
    var _plane:Plane = new Plane().setFromCoplanarPoints(v0.point, v1.point, v2.point);

    for (i in 0...this.vertices.length) {

      var vertex:VertexNode = vertices[i];

      if (vertex != v0 && vertex != v1 && vertex != v2) {

        var distance:Float = Math.abs(_plane.distanceToPoint(vertex.point));

        if (distance > maxDistance) {

          maxDistance = distance;
          v3 = vertex;

        }

      }

    }

    var faces:Array<Face> = [];

    if (_plane.distanceToPoint(v3.point) < 0) {

      // the face is not able to see the point so 'plane.normal' is pointing outside the tetrahedron

      faces.push(
        Face.create(v0, v1, v2),
        Face.create(v3, v1, v0),
        Face.create(v3, v2, v1),
        Face.create(v3, v0, v2)
      );

      // set the twin edge

      for (i in 0...3) {

        var j:Int = (i + 1) % 3;

        // join face[ i ] i > 0, with the first face

        faces[i + 1].getEdge(2).setTwin(faces[0].getEdge(j));

        // join face[ i ] with face[ i + 1 ], 1 <= i <= 3

        faces[i + 1].getEdge(1).setTwin(faces[j + 1].getEdge(0));

      }

    } else {

      // the face is able to see the point so 'plane.normal' is pointing inside the tetrahedron

      faces.push(
        Face.create(v0, v2, v1),
        Face.create(v3, v0, v1),
        Face.create(v3, v1, v2),
        Face.create(v3, v2, v0)
      );

      // set the twin edge

      for (i in 0...3) {

        var j:Int = (i + 1) % 3;

        // join face[ i ] i > 0, with the first face

        faces[i + 1].getEdge(2).setTwin(faces[0].getEdge((3 - i) % 3));

        // join face[ i ] with face[ i + 1 ]

        faces[i + 1].getEdge(0).setTwin(faces[j + 1].getEdge(1));

      }

    }

    // the initial hull is the tetrahedron

    for (i in 0...4) {

      this.faces.push(faces[i]);

    }

    // initial assignment of vertices to the faces of the tetrahedron

    for (i in 0...vertices.length) {

      var vertex:VertexNode = vertices[i];

      if (vertex != v0 && vertex != v1 && vertex != v2 && vertex != v3) {

        maxDistance = this.tolerance;
        var maxFace:Face = null;

        for (j in 0...4) {

          var distance:Float = this.faces[j].distanceToPoint(vertex.point);

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

  // Removes inactive faces

  public function reindexFaces():ConvexHull {

    var activeFaces:Array<Face> = [];

    for (i in 0...this.faces.length) {

      var face:Face = this.faces[i];

      if (face.mark == Visible.value) {

        activeFaces.push(face);

      }

    }

    this.faces = activeFaces;

    return this;

  }

  // Finds the next vertex to create faces with the current hull

  public function nextVertexToAdd():VertexNode {

    // if the 'assigned' list of vertices is empty, no vertices are left. return with 'undefined'

    if (!this.assigned.isEmpty()) {

      var eyeVertex:VertexNode;
      var maxDistance:Float = 0;

      // grap the first available face and start with the first visible vertex of that face

      var eyeFace:Face = this.assigned.first().face;
      var vertex:VertexNode = eyeFace.outside;

      // now calculate the farthest vertex that face can see

      do {

        var distance:Float = eyeFace.distanceToPoint(vertex.point);

        if (distance > maxDistance) {

          maxDistance = distance;
          eyeVertex = vertex;

        }

        vertex = vertex.next;

      } while (vertex != null && vertex.face == eyeFace);

      return eyeVertex;

    }

  }

  // Computes a chain of half edges in CCW order called the 'horizon'.
  // For an edge to be part of the horizon it must join a face that can see
  // 'eyePoint' and a face that cannot see 'eyePoint'.

  public function computeHorizon(eyePoint:Vector3, crossEdge:HalfEdge, face:Face, horizon:Array<HalfEdge>):ConvexHull {

    // moves face's vertices to the 'unassigned' vertex list

    this.deleteFaceVertices(face);

    face.mark = Deleted.value;

    var edge:HalfEdge;

    if (crossEdge == null) {

      edge = crossEdge = face.getEdge(0);

    } else {

      // start from the next edge since 'crossEdge' was already analyzed
      // (actually 'crossEdge.twin' was the edge who called this method recursively)

      edge = crossEdge.next;

    }

    do {

      var twinEdge:HalfEdge = edge.twin;
      var oppositeFace:Face = twinEdge.face;

      if (oppositeFace.mark == Visible.value) {

        if (oppositeFace.distanceToPoint(eyePoint) > this.tolerance) {

          // the opposite face can see the vertex, so proceed with next edge

          this.computeHorizon(eyePoint, twinEdge, oppositeFace, horizon);

        } else {

          // the opposite face can't see the vertex, so this edge is part of the horizon

          horizon.push(edge);

        }

      }

      edge = edge.next;

    } while (edge != crossEdge);

    return this;

  }

  // Creates a face with the vertices 'eyeVertex.point', 'horizonEdge.tail' and 'horizonEdge.head' in CCW order

  public function addAdjoiningFace(eyeVertex:VertexNode, horizonEdge:HalfEdge):HalfEdge {

    // all the half edges are created in ccw order thus the face is always pointing outside the hull

    var face:Face = Face.create(eyeVertex, horizonEdge.tail(), horizonEdge.head());

    this.faces.push(face);

    // join face.getEdge( - 1 ) with the horizon's opposite edge face.getEdge( - 1 ) = face.getEdge( 2 )

    face.getEdge(-1).setTwin(horizonEdge.twin);

    return face.getEdge(0); // the half edge whose vertex is the eyeVertex


  }

  //  Adds 'horizon.length' faces to the hull, each face will be linked with the
  //  horizon opposite face and the face on the left/right

  public function addNewFaces(eyeVertex:VertexNode, horizon:Array<HalfEdge>):ConvexHull {

    this.newFaces = [];

    var firstSideEdge:HalfEdge = null;
    var previousSideEdge:HalfEdge = null;

    for (i in 0...horizon.length) {

      var horizonEdge:HalfEdge = horizon[i];

      // returns the right side edge

      var sideEdge:HalfEdge = this.addAdjoiningFace(eyeVertex, horizonEdge);

      if (firstSideEdge == null) {

        firstSideEdge = sideEdge;

      } else {

        // joins face.getEdge( 1 ) with previousFace.getEdge( 0 )

        sideEdge.next.setTwin(previousSideEdge);

      }

      this.newFaces.push(sideEdge.face);
      previousSideEdge = sideEdge;

    }

    // perform final join of new faces

    firstSideEdge.next.setTwin(previousSideEdge);

    return this;

  }

  // Adds a vertex to the hull

  public function addVertexToHull(eyeVertex:VertexNode):ConvexHull {

    var horizon:Array<HalfEdge> = [];

    this.unassigned.clear();

    // remove 'eyeVertex' from 'eyeVertex.face' so that it can't be added to the 'unassigned' vertex list

    this.removeVertexFromFace(eyeVertex, eyeVertex.face);

    this.computeHorizon(eyeVertex.point, null, eyeVertex.face, horizon);

    this.addNewFaces(eyeVertex, horizon);

    // reassign 'unassigned' vertices to the new faces

    this.resolveUnassignedPoints(this.newFaces);

    return this;

  }

  public function cleanup():ConvexHull {

    this.assigned.clear();
    this.unassigned.clear();
    this.newFaces = [];

    return this;

  }

  public function compute():ConvexHull {

    var vertex:VertexNode;

    this.computeInitialHull();

    // add all available vertices gradually to the hull

    while ((vertex = this.nextVertexToAdd()) != null) {

      this.addVertexToHull(vertex);

    }

    this.reindexFaces();

    this.cleanup();

    return this;

  }

}

//

class Face {

  public var normal:Vector3 = new Vector3();
  public var midpoint:Vector3 = new Vector3();
  public var area:Float = 0;
  public var constant:Float = 0; // signed distance from face to the origin
  public var outside:VertexNode; // reference to a vertex in a vertex list this face can see
  public var mark:Int = Visible.value;
  public var edge:HalfEdge;

  public function new() {

  }

  public static function create(a:VertexNode, b:VertexNode, c:VertexNode):Face {

    var face:Face = new Face();

    var e0:HalfEdge = new HalfEdge(a, face);
    var e1:HalfEdge = new HalfEdge(b, face);
    var e2:HalfEdge = new HalfEdge(c, face);

    // join edges

    e0.next = e2.prev = e1;
    e1.next = e0.prev = e2;
    e2.next = e1.prev = e0;

    // main half edge reference

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

    var a:VertexNode = this.edge.tail();
    var b:VertexNode = this.edge.head();
    var c:VertexNode = this.edge.next.head();

    var _triangle:Triangle = new Triangle(a.point, b.point, c.point);

    _triangle.getNormal(this.normal);
    _triangle.getMidpoint(this.midpoint);
    this.area = _triangle.getArea();

    this.constant = this.normal.dot(this.midpoint);

    return this;

  }

  public function distanceToPoint(point:Vector3):Float {

    return this.normal.dot(point) - this.constant;

  }

}

// Entity for a Doubly-Connected Edge List (DCEL).

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

    var head:VertexNode = this.head();
    var tail:VertexNode = this.tail();

    if (tail != null) {

      return tail.point.distanceTo(head.point);

    }

    return -1;

  }

  public function lengthSquared():Float {

    var head:VertexNode = this.head();
    var tail:VertexNode = this.tail();

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

// A vertex as a double linked list node.

class VertexNode {

  public var point:Vector3;
  public var prev:VertexNode;
  public var next:VertexNode;
  public var face:Face; // the face that is able to see this vertex

  public function new(point:Vector3) {

    this.point = point;
    this.prev = null;
    this.next = null;
    this.face = null;

  }

}

// A double linked list that contains vertex nodes.

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

  public function clear():VertexList {

    this.head = this.tail = null;

    return this;

  }

  // Inserts a vertex before the target vertex

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

  // Inserts a vertex after the target vertex

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

  // Appends a vertex to the end of the linked list

  public function append(vertex:VertexNode):VertexList {

    if (this.head == null) {

      this.head = vertex;

    } else {

      this.tail.next = vertex;

    }

    vertex.prev = this.tail;
    vertex.next = null; // the tail has no subsequent vertex

    this.tail = vertex;

    return this;

  }

  // Appends a chain of vertices where 'vertex' is the head.

  public function appendChain(vertex:VertexNode):VertexList {

    if (this.head == null) {

      this.head = vertex;

    } else {

      this.tail.next = vertex;

    }

    vertex.prev = this.tail;

    // ensure that the 'tail' reference points to the last vertex of the chain

    while (vertex.next != null) {

      vertex = vertex.next;

    }

    this.tail = vertex;

    return this;

  }

  // Removes a vertex from the linked list

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

  // Removes a list of vertices whose 'head' is 'a' and whose 'tail' is b

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