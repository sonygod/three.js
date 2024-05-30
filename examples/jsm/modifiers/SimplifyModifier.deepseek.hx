import three.BufferGeometry;
import three.Float32BufferAttribute;
import three.Vector2;
import three.Vector3;
import three.Vector4;
import three.BufferGeometryUtils;

class SimplifyModifier {

    static var _cb = new Vector3();
    static var _ab = new Vector3();

    public function modify(geometry:BufferGeometry, count:Int):BufferGeometry {

        geometry = geometry.clone();

        delete geometry.morphAttributes.position;
        delete geometry.morphAttributes.normal;
        var attributes = geometry.attributes;

        for (name in attributes) {

            if (name !== 'position' && name !== 'uv' && name !== 'normal' && name !== 'tangent' && name !== 'color') geometry.deleteAttribute(name);

        }

        geometry = BufferGeometryUtils.mergeVertices(geometry);

        var vertices = [];
        var faces = [];

        var positionAttribute = geometry.getAttribute('position');
        var uvAttribute = geometry.getAttribute('uv');
        var normalAttribute = geometry.getAttribute('normal');
        var tangentAttribute = geometry.getAttribute('tangent');
        var colorAttribute = geometry.getAttribute('color');

        var t = null;
        var v2 = null;
        var nor = null;
        var col = null;

        for (var i = 0; i < positionAttribute.count; i ++) {

            var v = new Vector3().fromBufferAttribute(positionAttribute, i);
            if (uvAttribute) {

                v2 = new Vector2().fromBufferAttribute(uvAttribute, i);

            }

            if (normalAttribute) {

                nor = new Vector3().fromBufferAttribute(normalAttribute, i);

            }

            if (tangentAttribute) {

                t = new Vector4().fromBufferAttribute(tangentAttribute, i);

            }

            if (colorAttribute) {

                col = new Color().fromBufferAttribute(colorAttribute, i);

            }

            var vertex = new Vertex(v, v2, nor, t, col);
            vertices.push(vertex);

        }

        var index = geometry.getIndex();

        if (index !== null) {

            for (var i = 0; i < index.count; i += 3) {

                var a = index.getX(i);
                var b = index.getX(i + 1);
                var c = index.getX(i + 2);

                var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
                faces.push(triangle);

            }

        } else {

            for (var i = 0; i < positionAttribute.count; i += 3) {

                var a = i;
                var b = i + 1;
                var c = i + 2;

                var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
                faces.push(triangle);

            }

        }

        for (var i = 0, il = vertices.length; i < il; i ++) {

            computeEdgeCostAtVertex(vertices[i]);

        }

        var nextVertex;

        var z = count;

        while (z --) {

            nextVertex = minimumCostEdge(vertices);

            if (! nextVertex) {

                trace('THREE.SimplifyModifier: No next vertex');
                break;

            }

            collapse(vertices, faces, nextVertex, nextVertex.collapseNeighbor);

        }

        var simplifiedGeometry = new BufferGeometry();
        var position = [];
        var uv = [];
        var normal = [];
        var tangent = [];
        var color = [];

        index = [];

        for (var i = 0; i < vertices.length; i ++) {

            var vertex = vertices[i];
            position.push(vertex.position.x, vertex.position.y, vertex.position.z);
            if (vertex.uv) {

                uv.push(vertex.uv.x, vertex.uv.y);

            }

            if (vertex.normal) {

                normal.push(vertex.normal.x, vertex.normal.y, vertex.normal.z);

            }

            if (vertex.tangent) {

                tangent.push(vertex.tangent.x, vertex.tangent.y, vertex.tangent.z, vertex.tangent.w);

            }

            if (vertex.color) {

                color.push(vertex.color.r, vertex.color.g, vertex.color.b);

            }

            vertex.id = i;

        }

        for (var i = 0; i < faces.length; i ++) {

            var face = faces[i];
            index.push(face.v1.id, face.v2.id, face.v3.id);

        }

        simplifiedGeometry.setAttribute('position', new Float32BufferAttribute(position, 3));
        if (uv.length > 0) simplifiedGeometry.setAttribute('uv', new Float32BufferAttribute(uv, 2));
        if (normal.length > 0) simplifiedGeometry.setAttribute('normal', new Float32BufferAttribute(normal, 3));
        if (tangent.length > 0) simplifiedGeometry.setAttribute('tangent', new Float32BufferAttribute(tangent, 4));
        if (color.length > 0) simplifiedGeometry.setAttribute('color', new Float32BufferAttribute(color, 3));

        simplifiedGeometry.setIndex(index);

        return simplifiedGeometry;

    }

}

function pushIfUnique(array:Array<Dynamic>, object:Dynamic):Void {

    if (array.indexOf(object) === - 1) array.push(object);

}

function removeFromArray(array:Array<Dynamic>, object:Dynamic):Void {

    var k = array.indexOf(object);
    if (k > - 1) array.splice(k, 1);

}

function computeEdgeCollapseCost(u:Vertex, v:Vertex):Float {

    var edgelength = v.position.distanceTo(u.position);
    var curvature = 0;

    var sideFaces = [];

    for (var i = 0, il = u.faces.length; i < il; i ++) {

        var face = u.faces[i];

        if (face.hasVertex(v)) {

            sideFaces.push(face);

        }

    }

    for (var i = 0, il = u.faces.length; i < il; i ++) {

        var minCurvature = 1;
        var face = u.faces[i];

        for (var j = 0; j < sideFaces.length; j ++) {

            var sideFace = sideFaces[j];
            var dotProd = face.normal.dot(sideFace.normal);
            minCurvature = Math.min(minCurvature, (1.001 - dotProd) / 2);

        }

        curvature = Math.max(curvature, minCurvature);

    }

    var borders = 0;

    if (sideFaces.length < 2) {

        curvature = 1;

    }

    var amt = edgelength * curvature + borders;

    return amt;

}

function computeEdgeCostAtVertex(v:Vertex):Void {

    if (v.neighbors.length === 0) {

        v.collapseNeighbor = null;
        v.collapseCost = - 0.01;

        return;

    }

    v.collapseCost = 100000;
    v.collapseNeighbor = null;

    for (var i = 0; i < v.neighbors.length; i ++) {

        var collapseCost = computeEdgeCollapseCost(v, v.neighbors[i]);

        if (! v.collapseNeighbor) {

            v.collapseNeighbor = v.neighbors[i];
            v.collapseCost = collapseCost;
            v.minCost = collapseCost;
            v.totalCost = 0;
            v.costCount = 0;

        }

        v.costCount ++;
        v.totalCost += collapseCost;

        if (collapseCost < v.minCost) {

            v.collapseNeighbor = v.neighbors[i];
            v.minCost = collapseCost;

        }

    }

    v.collapseCost = v.totalCost / v.costCount;

}

function removeVertex(v:Vertex, vertices:Array<Vertex>):Void {

    assert(v.faces.length === 0);

    while (v.neighbors.length) {

        var n = v.neighbors.pop();
        removeFromArray(n.neighbors, v);

    }

    removeFromArray(vertices, v);

}

function removeFace(f:Triangle, faces:Array<Triangle>):Void {

    removeFromArray(faces, f);

    if (f.v1) removeFromArray(f.v1.faces, f);
    if (f.v2) removeFromArray(f.v2.faces, f);
    if (f.v3) removeFromArray(f.v3.faces, f);

    var vs = [f.v1, f.v2, f.v3];

    for (var i = 0; i < 3; i ++) {

        var v1 = vs[i];
        var v2 = vs[(i + 1) % 3];

        if (! v1 || ! v2) continue;

        v1.removeIfNonNeighbor(v2);
        v2.removeIfNonNeighbor(v1);

    }

}

function collapse(vertices:Array<Vertex>, faces:Array<Triangle>, u:Vertex, v:Vertex):Void {

    if (! v) {

        removeVertex(u, vertices);
        return;

    }

    if (v.uv) {

        u.uv.copy(v.uv);

    }

    if (v.normal) {

        v.normal.add(u.normal).normalize();

    }

    if (v.tangent) {

        v.tangent.add(u.tangent).normalize();

    }

    var tmpVertices = [];

    for (var i = 0; i < u.neighbors.length; i ++) {

        tmpVertices.push(u.neighbors[i]);

    }

    for (var i = u.faces.length - 1; i >= 0; i --) {

        if (u.faces[i] && u.faces[i].hasVertex(v)) {

            removeFace(u.faces[i], faces);

        }

    }

    for (var i = u.faces.length - 1; i >= 0; i --) {

        u.faces[i].replaceVertex(u, v);

    }

    removeVertex(u, vertices);

    for (var i = 0; i < tmpVertices.length; i ++) {

        computeEdgeCostAtVertex(tmpVertices[i]);

    }

}

function minimumCostEdge(vertices:Array<Vertex>):Vertex {

    var least = vertices[0];

    for (var i = 0; i < vertices.length; i ++) {

        if (vertices[i].collapseCost < least.collapseCost) {

            least = vertices[i];

        }

    }

    return least;

}

class Triangle {

    public function new(v1:Vertex, v2:Vertex, v3:Vertex, a:Int, b:Int, c:Int) {

        this.a = a;
        this.b = b;
        this.c = c;

        this.v1 = v1;
        this.v2 = v2;
        this.v3 = v3;

        this.normal = new Vector3();

        this.computeNormal();

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

        var vA = this.v1.position;
        var vB = this.v2.position;
        var vC = this.v3.position;

        _cb.subVectors(vC, vB);
        _ab.subVectors(vA, vB);
        _cb.cross(_ab).normalize();

        this.normal.copy(_cb);

    }

    public function hasVertex(v:Vertex):Bool {

        return v === this.v1 || v === this.v2 || v === this.v3;

    }

    public function replaceVertex(oldv:Vertex, newv:Vertex):Void {

        if (oldv === this.v1) this.v1 = newv;
        else if (oldv === this.v2) this.v2 = newv;
        else if (oldv === this.v3) this.v3 = newv;

        removeFromArray(oldv.faces, this);
        newv.faces.push(this);

        oldv.removeIfNonNeighbor(this.v1);
        this.v1.removeIfNonNeighbor(oldv);

        oldv.removeIfNonNeighbor(this.v2);
        this.v2.removeIfNonNeighbor(oldv);

        oldv.removeIfNonNeighbor(this.v3);
        this.v3.removeIfNonNeighbor(oldv);

        this.v1.addUniqueNeighbor(this.v2);
        this.v1.addUniqueNeighbor(this.v3);

        this.v2.addUniqueNeighbor(this.v1);
        this.v2.addUniqueNeighbor(this.v3);

        this.v3.addUniqueNeighbor(this.v1);
        this.v3.addUniqueNeighbor(this.v2);

        this.computeNormal();

    }

}

class Vertex {

    public function new(v:Vector3, uv:Vector2, normal:Vector3, tangent:Vector4, color:Color) {

        this.position = v;
        this.uv = uv;
        this.normal = normal;
        this.tangent = tangent;
        this.color = color;

        this.id = - 1;

        this.faces = [];
        this.neighbors = [];

        this.collapseCost = 0;
        this.collapseNeighbor = null;

    }

    public function addUniqueNeighbor(vertex:Vertex):Void {

        pushIfUnique(this.neighbors, vertex);

    }

    public function removeIfNonNeighbor(n:Vertex):Void {

        var neighbors = this.neighbors;
        var faces = this.faces;

        var offset = neighbors.indexOf(n);

        if (offset === - 1) return;

        for (var i = 0; i < faces.length; i ++) {

            if (faces[i].hasVertex(n)) return;

        }

        neighbors.splice(offset, 1);

    }

}