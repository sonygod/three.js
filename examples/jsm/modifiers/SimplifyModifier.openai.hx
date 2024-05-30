package three.js.examples.jsm.modifiers;

import three.js.BufferGeometry;
import three.js.BufferAttribute;
import three.js.Vector2;
import three.js.Vector3;
import three.js.Vector4;
import three.js.utils.BufferGeometryUtils;

/**
 * Simplification Geometry Modifier
 * Based on code and technique by Stan Melax in 1998
 * Progressive Mesh type Polygon Reduction Algorithm
 * http://www.melax.com/polychop/
 */

class SimplifyModifier {
    private static var _cb:Vector3 = new Vector3();
    private static var _ab:Vector3 = new Vector3();

    public function modify(geometry:BufferGeometry, count:Int):BufferGeometry {
        geometry = geometry.clone();

        // currently morphAttributes are not supported
        geometry.morphAttributes.delete("position");
        geometry.morphAttributes.delete("normal");
        var attributes:BufferGeometryAttributes = geometry.attributes;

        // this modifier can only process indexed and non-indexed geometries with at least a position attribute

        for (name in attributes.keys()) {
            if (name != "position" && name != "uv" && name != "normal" && name != "tangent" && name != "color") {
                geometry.deleteAttribute(name);
            }
        }

        geometry = BufferGeometryUtils.mergeVertices(geometry);

        // put data of original geometry in different data structures

        var vertices:Array<Vertex> = [];
        var faces:Array<Triangle> = [];

        // add vertices

        var positionAttribute:BufferAttribute = geometry.getAttribute("position");
        var uvAttribute:BufferAttribute = geometry.getAttribute("uv");
        var normalAttribute:BufferAttribute = geometry.getAttribute("normal");
        var tangentAttribute:BufferAttribute = geometry.getAttribute("tangent");
        var colorAttribute:BufferAttribute = geometry.getAttribute("color");

        var t:Vector4 = null;
        var v2:Vector2 = null;
        var nor:Vector3 = null;
        var col:Color = null;

        for (i in 0...positionAttribute.count) {
            var v:Vector3 = new Vector3().fromBufferAttribute(positionAttribute, i);
            if (uvAttribute != null) {
                v2 = new Vector2().fromBufferAttribute(uvAttribute, i);
            }

            if (normalAttribute != null) {
                nor = new Vector3().fromBufferAttribute(normalAttribute, i);
            }

            if (tangentAttribute != null) {
                t = new Vector4().fromBufferAttribute(tangentAttribute, i);
            }

            if (colorAttribute != null) {
                col = new Color().fromBufferAttribute(colorAttribute, i);
            }

            var vertex:Vertex = new Vertex(v, v2, nor, t, col);
            vertices.push(vertex);
        }

        // add faces

        var index:BufferAttribute = geometry.getIndex();

        if (index != null) {
            for (i in 0...index.count step 3) {
                var a:Int = index.getX(i);
                var b:Int = index.getX(i + 1);
                var c:Int = index.getX(i + 2);

                var triangle:Triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
                faces.push(triangle);
            }
        } else {
            for (i in 0...positionAttribute.count step 3) {
                var a:Int = i;
                var b:Int = i + 1;
                var c:Int = i + 2;

                var triangle:Triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
                faces.push(triangle);
            }
        }

        // compute all edge collapse costs

        for (i in 0...vertices.length) {
            computeEdgeCostAtVertex(vertices[i]);
        }

        var nextVertex:Vertex;

        var z:Int = count;

        while (z-- > 0) {
            nextVertex = minimumCostEdge(vertices);

            if (nextVertex == null) {
                trace("THREE.SimplifyModifier: No next vertex");
                break;
            }

            collapse(vertices, faces, nextVertex, nextVertex.collapseNeighbor);
        }

        // create simplified geometry

        var simplifiedGeometry:BufferGeometry = new BufferGeometry();
        var position:Array<Float> = [];
        var uv:Array<Float> = [];
        var normal:Array<Float> = [];
        var tangent:Array<Float> = [];
        var color:Array<Float> = [];

        var index:Array<Int> = [];

        for (i in 0...vertices.length) {
            var vertex:Vertex = vertices[i];
            position.push(vertex.position.x, vertex.position.y, vertex.position.z);

            if (vertex.uv != null) {
                uv.push(vertex.uv.x, vertex.uv.y);
            }

            if (vertex.normal != null) {
                normal.push(vertex.normal.x, vertex.normal.y, vertex.normal.z);
            }

            if (vertex.tangent != null) {
                tangent.push(vertex.tangent.x, vertex.tangent.y, vertex.tangent.z, vertex.tangent.w);
            }

            if (vertex.color != null) {
                color.push(vertex.color.r, vertex.color.g, vertex.color.b);
            }
        }

        for (i in 0...faces.length) {
            var face:Triangle = faces[i];
            index.push(face.v1.id, face.v2.id, face.v3.id);
        }

        simplifiedGeometry.setAttribute("position", new Float32BufferAttribute(position, 3));
        if (uv.length > 0) simplifiedGeometry.setAttribute("uv", new Float32BufferAttribute(uv, 2));
        if (normal.length > 0) simplifiedGeometry.setAttribute("normal", new Float32BufferAttribute(normal, 3));
        if (tangent.length > 0) simplifiedGeometry.setAttribute("tangent", new Float32BufferAttribute(tangent, 4));
        if (color.length > 0) simplifiedGeometry.setAttribute("color", new Float32BufferAttribute(color, 3));

        simplifiedGeometry.setIndex(index);

        return simplifiedGeometry;
    }
}

class Triangle {
    public var v1:Vertex;
    public var v2:Vertex;
    public var v3:Vertex;
    public var a:Int;
    public var b:Int;
    public var c:Int;

    public var normal:Vector3;

    public function new(v1:Vertex, v2:Vertex, v3:Vertex, a:Int, b:Int, c:Int) {
        this.v1 = v1;
        this.v2 = v2;
        this.v3 = v3;
        this.a = a;
        this.b = b;
        this.c = c;

        normal = new Vector3();

        computeNormal();

        v1.faces.push(this);
        v1.addUniqueNeighbor(v2);
        v1.addUniqueNeighbor(v3);

        v2.faces.push(this);
        v2.addUniqueNeighbor(v1);
        v2.addUniqueNeighbor(v3);

        v3.faces.push(this);
        v3.addUniqueNeighbor(v1);
        v3.addUniqueNeighbor(v2);
    }

    public function computeNormal():Void {
        var vA:Vector3 = v1.position;
        var vB:Vector3 = v2.position;
        var vC:Vector3 = v3.position;

        _cb.subVectors(vC, vB);
        _ab.subVectors(vA, vB);
        _cb.cross(_ab).normalize();

        normal.copy(_cb);
    }

    public function hasVertex(v:Vertex):Bool {
        return v == v1 || v == v2 || v == v3;
    }

    public function replaceVertex(oldv:Vertex, newv:Vertex):Void {
        if (oldv == v1) v1 = newv;
        else if (oldv == v2) v2 = newv;
        else if (oldv == v3) v3 = newv;

        removeFromArray(oldv.faces, this);
        newv.faces.push(this);

        oldv.removeIfNonNeighbor(v1);
        v1.removeIfNonNeighbor(oldv);

        oldv.removeIfNonNeighbor(v2);
        v2.removeIfNonNeighbor(oldv);

        oldv.removeIfNonNeighbor(v3);
        v3.removeIfNonNeighbor(oldv);

        v1.addUniqueNeighbor(v2);
        v1.addUniqueNeighbor(v3);

        v2.addUniqueNeighbor(v1);
        v2.addUniqueNeighbor(v3);

        v3.addUniqueNeighbor(v1);
        v3.addUniqueNeighbor(v2);

        computeNormal();
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
    public var minCost:Float;
    public var totalCost:Float;
    public var costCount:Int;

    public function new(v:Vector3, uv:Vector2, normal:Vector3, tangent:Vector4, color:Color) {
        position = v;
        this.uv = uv;
        this.normal = normal;
        this.tangent = tangent;
        this.color = color;

        id = -1;

        faces = [];
        neighbors = [];

        collapseCost = 0;
        collapseNeighbor = null;
        minCost = Math.POSITIVE_INFINITY;
        totalCost = 0;
        costCount = 0;
    }

    public function addUniqueNeighbor(vertex:Vertex):Void {
        if (!Lambda.has(neighbors, vertex)) {
            neighbors.push(vertex);
        }
    }

    public function removeIfNonNeighbor(n:Vertex):Void {
        var neighbors:Array<Vertex> = this.neighbors;
        var faces:Array<Triangle> = this.faces;

        var offset:Int = Lambda.indexOf(neighbors, n);

        if (offset == -1) return;

        for (i in 0...faces.length) {
            if (faces[i].hasVertex(n)) return;
        }

        neighbors.splice(offset, 1);
    }
}

function pushIfUnique(array:Array<Dynamic>, object:Dynamic):Void {
    if (Lambda.indexOf(array, object) == -1) {
        array.push(object);
    }
}

function removeFromArray(array:Array<Dynamic>, object:Dynamic):Void {
    var offset:Int = Lambda.indexOf(array, object);

    if (offset > -1) {
        array.splice(offset, 1);
    }
}

function computeEdgeCollapseCost(u:Vertex, v:Vertex):Float {
    // if we collapse edge uv by moving u to v then how
    // much different will the model change, i.e. the "error".

    var edgelength:Float = v.position.distanceTo(u.position);
    var curvature:Float = 0;

    var sideFaces:Array<Triangle> = [];

    // find the "sides" triangles that are on the edge uv
    for (i in 0...u.faces.length) {
        var face:Triangle = u.faces[i];

        if (face.hasVertex(v)) {
            sideFaces.push(face);
        }
    }

    // use the triangle facing most away from the sides
    // to determine our curvature term
    for (i in 0...u.faces.length) {
        var face:Triangle = u.faces[i];

        for (j in 0...sideFaces.length) {
            var sideFace:Triangle = sideFaces[j];
            // use dot product of face normals.
            var dotProd:Float = face.normal.dot(sideFace.normal);
            curvature = Math.max(curvature, (1.001 - dotProd) / 2);
        }
    }

    // crude approach in attempt to preserve borders
    // though it seems not to be totally correct
    var borders:Int = 0;

    if (sideFaces.length < 2) {
        // we add some arbitrary cost for borders,
        // borders += 10;
        curvature = 1;
    }

    var amt:Float = edgelength * curvature + borders;

    return amt;
}

function computeEdgeCostAtVertex(v:Vertex):Void {
    // compute the edge collapse cost for all edges that start
    // from vertex v.  Since we are only interested in reducing
    // the object by selecting the min cost edge at each step, we
    // only cache the cost of the least cost edge at this vertex
    // (in member variable collapse) as well as the value of the
    // cost (in member variable collapseCost).

    if (v.neighbors.length == 0) {
        // collapse if no neighbors.
        v.collapseNeighbor = null;
        v.collapseCost = -0.01;
        return;
    }

    v.collapseCost = Math.POSITIVE_INFINITY;
    v.collapseNeighbor = null;

    // search all neighboring edges for "least cost" edge
    for (i in 0...v.neighbors.length) {
        var collapseCost:Float = computeEdgeCollapseCost(v, v.neighbors[i]);

        if (v.collapseNeighbor == null) {
            v.collapseNeighbor = v.neighbors[i];
            v.collapseCost = collapseCost;
            v.minCost = collapseCost;
            v.totalCost = 0;
            v.costCount = 0;
        }

        v.costCount++;
        v.totalCost += collapseCost;

        if (collapseCost < v.minCost) {
            v.collapseNeighbor = v.neighbors[i];
            v.minCost = collapseCost;
        }
    }

    // we average the cost of collapsing at this vertex
    v.collapseCost = v.totalCost / v.costCount;
    // v.collapseCost = v.minCost;
}

function removeVertex(v:Vertex, vertices:Array<Vertex>):Void {
    console.assert(v.faces.length == 0);

    while (v.neighbors.length > 0) {
        var n:Vertex = v.neighbors.pop();
        removeFromArray(n.neighbors, v);
    }

    removeFromArray(vertices, v);
}

function removeFace(f:Triangle, faces:Array<Triangle>):Void {
    removeFromArray(faces, f);

    if (f.v1 != null) removeFromArray(f.v1.faces, f);
    if (f.v2 != null) removeFromArray(f.v2.faces, f);
    if (f.v3 != null) removeFromArray(f.v3.faces, f);

    // TODO optimize this!
    var vs:Array<Vertex> = [f.v1, f.v2, f.v3];

    for (i in 0...3) {
        var v1:Vertex = vs[i];
        var v2:Vertex = vs[(i + 1) % 3];

        if (v1 == null || v2 == null) continue;

        v1.removeIfNonNeighbor(v2);
        v2.removeIfNonNeighbor(v1);
    }
}

function collapse(vertices:Array<Vertex>, faces:Array<Triangle>, u:Vertex, v:Vertex):Void {
    // Collapse the edge uv by moving vertex u onto v

    if (v == null) {
        // u is a vertex all by itself so just delete it..
        removeVertex(u, vertices);
        return;
    }

    if (v.uv != null) {
        u.uv.copy(v.uv);
    }

    if (v.normal != null) {
        v.normal.add(u.normal).normalize();
    }

    if (v.tangent != null) {
        v.tangent.add(u.tangent).normalize();
    }

    var tmpVertices:Array<Vertex> = [];

    for (i in 0...u.neighbors.length) {
        tmpVertices.push(u.neighbors[i]);
    }

    // delete triangles on edge uv:
    for (i in u.faces.length - 1; i >= 0; i--) {
        if (u.faces[i] != null && u.faces[i].hasVertex(v)) {
            removeFace(u.faces[i], faces);
        }
    }

    // update remaining triangles to have v instead of u
    for (i in u.faces.length - 1; i >= 0; i--) {
        u.faces[i].replaceVertex(u, v);
    }

    removeVertex(u, vertices);

    // recompute the edge collapse costs in neighborhood
    for (i in 0...tmpVertices.length) {
        computeEdgeCostAtVertex(tmpVertices[i]);
    }
}

function minimumCostEdge(vertices:Array<Vertex>):Vertex {
    // O(n * n) approach. TODO optimize this

    var least:Vertex = vertices[0];

    for (i in 1...vertices.length) {
        if (vertices[i].collapseCost < least.collapseCost) {
            least = vertices[i];
        }
    }

    return least;
}