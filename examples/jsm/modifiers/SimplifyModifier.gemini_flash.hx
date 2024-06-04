import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.utils.BufferGeometryUtils;

/**
 *	Simplification Geometry Modifier
 *    - based on code and technique
 *	  - by Stan Melax in 1998
 *	  - Progressive Mesh type Polygon Reduction Algorithm
 *    - http://www.melax.com/polychop/
 */

class SimplifyModifier {

	public function new() {}

	public function modify(geometry:BufferGeometry, count:Int):BufferGeometry {

		geometry = geometry.clone();

		// currently morphAttributes are not supported
		delete geometry.morphAttributes.position;
		delete geometry.morphAttributes.normal;
		var attributes = geometry.attributes;

		// this modifier can only process indexed and non-indexed geomtries with at least a position attribute
		for (name in attributes) {
			if (name != "position" && name != "uv" && name != "normal" && name != "tangent" && name != "color") {
				geometry.deleteAttribute(name);
			}
		}

		geometry = BufferGeometryUtils.mergeVertices(geometry);

		//
		// put data of original geometry in different data structures
		//

		var vertices:Array<Vertex> = [];
		var faces:Array<Triangle> = [];

		// add vertices
		var positionAttribute = geometry.getAttribute("position");
		var uvAttribute = geometry.getAttribute("uv");
		var normalAttribute = geometry.getAttribute("normal");
		var tangentAttribute = geometry.getAttribute("tangent");
		var colorAttribute = geometry.getAttribute("color");
		var t:Vector4 = null;
		var v2:Vector2 = null;
		var nor:Vector3 = null;
		var col:three.math.Color = null;
		for (i in 0...positionAttribute.count) {
			var v = new Vector3().fromBufferAttribute(positionAttribute, i);
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
				col = three.math.Color.fromBufferAttribute(colorAttribute, i);
			}
			var vertex = new Vertex(v, v2, nor, t, col);
			vertices.push(vertex);
		}

		// add faces
		var index = geometry.getIndex();
		if (index != null) {
			for (i in 0...index.count) {
				if (i % 3 == 0) {
					var a = index.getX(i);
					var b = index.getX(i + 1);
					var c = index.getX(i + 2);
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		} else {
			for (i in 0...positionAttribute.count) {
				if (i % 3 == 0) {
					var a = i;
					var b = i + 1;
					var c = i + 2;
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		}

		// compute all edge collapse costs
		for (i in 0...vertices.length) {
			computeEdgeCostAtVertex(vertices[i]);
		}

		var nextVertex:Vertex;
		var z = count;
		while (z > 0) {
			nextVertex = minimumCostEdge(vertices);
			if (nextVertex == null) {
				trace("THREE.SimplifyModifier: No next vertex");
				break;
			}
			collapse(vertices, faces, nextVertex, nextVertex.collapseNeighbor);
			z--;
		}

		//

		var simplifiedGeometry = new BufferGeometry();
		var position:Array<Float> = [];
		var uv:Array<Float> = [];
		var normal:Array<Float> = [];
		var tangent:Array<Float> = [];
		var color:Array<Float> = [];
		var index:Array<Int> = [];

		//

		for (i in 0...vertices.length) {
			var vertex = vertices[i];
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


			// cache final index to GREATLY speed up faces reconstruction
			vertex.id = i;
		}

		//

		for (i in 0...faces.length) {
			var face = faces[i];
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

function pushIfUnique(array:Array<Dynamic>, object:Dynamic) {
	if (array.indexOf(object) == -1) array.push(object);
}

function removeFromArray(array:Array<Dynamic>, object:Dynamic) {
	var k = array.indexOf(object);
	if (k > -1) array.splice(k, 1);
}

function computeEdgeCollapseCost(u:Vertex, v:Vertex) {
	// if we collapse edge uv by moving u to v then how
	// much different will the model change, i.e. the "error".

	var edgelength = v.position.distanceTo(u.position);
	var curvature = 0;

	var sideFaces:Array<Triangle> = [];

	// find the "sides" triangles that are on the edge uv
	for (i in 0...u.faces.length) {
		var face = u.faces[i];
		if (face.hasVertex(v)) {
			sideFaces.push(face);
		}
	}

	// use the triangle facing most away from the sides
	// to determine our curvature term
	for (i in 0...u.faces.length) {
		var minCurvature = 1;
		var face = u.faces[i];
		for (j in 0...sideFaces.length) {
			var sideFace = sideFaces[j];
			// use dot product of face normals.
			var dotProd = face.normal.dot(sideFace.normal);
			minCurvature = Math.min(minCurvature, (1.001 - dotProd) / 2);
		}
		curvature = Math.max(curvature, minCurvature);
	}

	// crude approach in attempt to preserve borders
	// though it seems not to be totally correct
	var borders = 0;
	if (sideFaces.length < 2) {
		// we add some arbitrary cost for borders,
		// borders += 10;
		curvature = 1;
	}

	var amt = edgelength * curvature + borders;
	return amt;
}

function computeEdgeCostAtVertex(v:Vertex) {
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

	v.collapseCost = 100000;
	v.collapseNeighbor = null;

	// search all neighboring edges for "least cost" edge
	for (i in 0...v.neighbors.length) {
		var collapseCost = computeEdgeCollapseCost(v, v.neighbors[i]);
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

function removeVertex(v:Vertex, vertices:Array<Vertex>) {
	trace("removeVertex " + v);
	assert(v.faces.length == 0);
	while (v.neighbors.length > 0) {
		var n = v.neighbors.pop();
		removeFromArray(n.neighbors, v);
	}
	removeFromArray(vertices, v);
}

function removeFace(f:Triangle, faces:Array<Triangle>) {
	trace("removeFace " + f);
	removeFromArray(faces, f);
	if (f.v1 != null) removeFromArray(f.v1.faces, f);
	if (f.v2 != null) removeFromArray(f.v2.faces, f);
	if (f.v3 != null) removeFromArray(f.v3.faces, f);

	// TODO optimize this!
	var vs:Array<Vertex> = [f.v1, f.v2, f.v3];
	for (i in 0...3) {
		var v1 = vs[i];
		var v2 = vs[(i + 1) % 3];
		if (v1 == null || v2 == null) continue;
		v1.removeIfNonNeighbor(v2);
		v2.removeIfNonNeighbor(v1);
	}
}

function collapse(vertices:Array<Vertex>, faces:Array<Triangle>, u:Vertex, v:Vertex) {
	// Collapse the edge uv by moving vertex u onto v
	trace("collapse " + u + " " + v);
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
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null && u.faces[i].hasVertex(v)) {
			removeFace(u.faces[i], faces);
		}
	}

	// update remaining triangles to have v instead of u
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null) u.faces[i].replaceVertex(u, v);
	}

	removeVertex(u, vertices);

	// recompute the edge collapse costs in neighborhood
	for (i in 0...tmpVertices.length) {
		computeEdgeCostAtVertex(tmpVertices[i]);
	}
}

function minimumCostEdge(vertices:Array<Vertex>) {
	// O(n * n) approach. TODO optimize this
	var least = vertices[0];
	for (i in 0...vertices.length) {
		if (vertices[i].collapseCost < least.collapseCost) {
			least = vertices[i];
		}
	}
	return least;
}

// we use a triangle class to represent structure of face slightly differently
class Triangle {

	public var a:Int;
	public var b:Int;
	public var c:Int;

	public var v1:Vertex;
	public var v2:Vertex;
	public var v3:Vertex;

	public var normal:Vector3;

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

	public function computeNormal() {
		var vA = this.v1.position;
		var vB = this.v2.position;
		var vC = this.v3.position;
		var _cb = new Vector3();
		var _ab = new Vector3();
		_cb.subVectors(vC, vB);
		_ab.subVectors(vA, vB);
		_cb.cross(_ab).normalize();
		this.normal.copy(_cb);
	}

	public function hasVertex(v:Vertex) {
		return v == this.v1 || v == this.v2 || v == this.v3;
	}

	public function replaceVertex(oldv:Vertex, newv:Vertex) {
		trace("replaceVertex " + oldv + " " + newv);
		if (oldv == this.v1) this.v1 = newv;
		else if (oldv == this.v2) this.v2 = newv;
		else if (oldv == this.v3) this.v3 = newv;

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

	public var position:Vector3;
	public var uv:Vector2;
	public var normal:Vector3;
	public var tangent:Vector4;
	public var color:three.math.Color;

	public var id:Int = -1; // external use position in vertices list (for e.g. face generation)
	public var faces:Array<Triangle> = []; // faces vertex is connected
	public var neighbors:Array<Vertex> = []; // neighbouring vertices aka "adjacentVertices"

	// these will be computed in computeEdgeCostAtVertex()
	public var collapseCost:Float = 0; // cost of collapsing this vertex, the less the better. aka objdist
	public var collapseNeighbor:Vertex = null; // best candinate for collapsing
	public var minCost:Float = 0;
	public var totalCost:Float = 0;
	public var costCount:Int = 0;

	public function new(v:Vector3, uv:Vector2, normal:Vector3, tangent:Vector4, color:three.math.Color) {
		this.position = v;
		this.uv = uv;
		this.normal = normal;
		this.tangent = tangent;
		this.color = color;
	}

	public function addUniqueNeighbor(vertex:Vertex) {
		pushIfUnique(this.neighbors, vertex);
	}

	public function removeIfNonNeighbor(n:Vertex) {
		var neighbors = this.neighbors;
		var faces = this.faces;
		var offset = neighbors.indexOf(n);
		if (offset == -1) return;
		for (i in 0...faces.length) {
			if (faces[i].hasVertex(n)) return;
		}
		neighbors.splice(offset, 1);
	}

	public function toString() {
		return "Vertex(${position})";
	}
}

class SimplifyModifier {

	public function new() {}

	public function modify(geometry:BufferGeometry, count:Int):BufferGeometry {

		geometry = geometry.clone();

		// currently morphAttributes are not supported
		delete geometry.morphAttributes.position;
		delete geometry.morphAttributes.normal;
		var attributes = geometry.attributes;

		// this modifier can only process indexed and non-indexed geomtries with at least a position attribute
		for (name in attributes) {
			if (name != "position" && name != "uv" && name != "normal" && name != "tangent" && name != "color") {
				geometry.deleteAttribute(name);
			}
		}

		geometry = BufferGeometryUtils.mergeVertices(geometry);

		//
		// put data of original geometry in different data structures
		//

		var vertices:Array<Vertex> = [];
		var faces:Array<Triangle> = [];

		// add vertices
		var positionAttribute = geometry.getAttribute("position");
		var uvAttribute = geometry.getAttribute("uv");
		var normalAttribute = geometry.getAttribute("normal");
		var tangentAttribute = geometry.getAttribute("tangent");
		var colorAttribute = geometry.getAttribute("color");
		var t:Vector4 = null;
		var v2:Vector2 = null;
		var nor:Vector3 = null;
		var col:three.math.Color = null;
		for (i in 0...positionAttribute.count) {
			var v = new Vector3().fromBufferAttribute(positionAttribute, i);
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
				col = three.math.Color.fromBufferAttribute(colorAttribute, i);
			}
			var vertex = new Vertex(v, v2, nor, t, col);
			vertices.push(vertex);
		}

		// add faces
		var index = geometry.getIndex();
		if (index != null) {
			for (i in 0...index.count) {
				if (i % 3 == 0) {
					var a = index.getX(i);
					var b = index.getX(i + 1);
					var c = index.getX(i + 2);
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		} else {
			for (i in 0...positionAttribute.count) {
				if (i % 3 == 0) {
					var a = i;
					var b = i + 1;
					var c = i + 2;
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		}

		// compute all edge collapse costs
		for (i in 0...vertices.length) {
			computeEdgeCostAtVertex(vertices[i]);
		}

		var nextVertex:Vertex;
		var z = count;
		while (z > 0) {
			nextVertex = minimumCostEdge(vertices);
			if (nextVertex == null) {
				trace("THREE.SimplifyModifier: No next vertex");
				break;
			}
			collapse(vertices, faces, nextVertex, nextVertex.collapseNeighbor);
			z--;
		}

		//

		var simplifiedGeometry = new BufferGeometry();
		var position:Array<Float> = [];
		var uv:Array<Float> = [];
		var normal:Array<Float> = [];
		var tangent:Array<Float> = [];
		var color:Array<Float> = [];
		var index:Array<Int> = [];

		//

		for (i in 0...vertices.length) {
			var vertex = vertices[i];
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

			// cache final index to GREATLY speed up faces reconstruction
			vertex.id = i;
		}

		//

		for (i in 0...faces.length) {
			var face = faces[i];
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

function pushIfUnique(array:Array<Dynamic>, object:Dynamic) {
	if (array.indexOf(object) == -1) array.push(object);
}

function removeFromArray(array:Array<Dynamic>, object:Dynamic) {
	var k = array.indexOf(object);
	if (k > -1) array.splice(k, 1);
}

function computeEdgeCollapseCost(u:Vertex, v:Vertex) {
	// if we collapse edge uv by moving u to v then how
	// much different will the model change, i.e. the "error".

	var edgelength = v.position.distanceTo(u.position);
	var curvature = 0;

	var sideFaces:Array<Triangle> = [];

	// find the "sides" triangles that are on the edge uv
	for (i in 0...u.faces.length) {
		var face = u.faces[i];
		if (face.hasVertex(v)) {
			sideFaces.push(face);
		}
	}

	// use the triangle facing most away from the sides
	// to determine our curvature term
	for (i in 0...u.faces.length) {
		var minCurvature = 1;
		var face = u.faces[i];
		for (j in 0...sideFaces.length) {
			var sideFace = sideFaces[j];
			// use dot product of face normals.
			var dotProd = face.normal.dot(sideFace.normal);
			minCurvature = Math.min(minCurvature, (1.001 - dotProd) / 2);
		}
		curvature = Math.max(curvature, minCurvature);
	}

	// crude approach in attempt to preserve borders
	// though it seems not to be totally correct
	var borders = 0;
	if (sideFaces.length < 2) {
		// we add some arbitrary cost for borders,
		// borders += 10;
		curvature = 1;
	}

	var amt = edgelength * curvature + borders;
	return amt;
}

function computeEdgeCostAtVertex(v:Vertex) {
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

	v.collapseCost = 100000;
	v.collapseNeighbor = null;

	// search all neighboring edges for "least cost" edge
	for (i in 0...v.neighbors.length) {
		var collapseCost = computeEdgeCollapseCost(v, v.neighbors[i]);
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

function removeVertex(v:Vertex, vertices:Array<Vertex>) {
	trace("removeVertex " + v);
	assert(v.faces.length == 0);
	while (v.neighbors.length > 0) {
		var n = v.neighbors.pop();
		removeFromArray(n.neighbors, v);
	}
	removeFromArray(vertices, v);
}

function removeFace(f:Triangle, faces:Array<Triangle>) {
	trace("removeFace " + f);
	removeFromArray(faces, f);
	if (f.v1 != null) removeFromArray(f.v1.faces, f);
	if (f.v2 != null) removeFromArray(f.v2.faces, f);
	if (f.v3 != null) removeFromArray(f.v3.faces, f);

	// TODO optimize this!
	var vs:Array<Vertex> = [f.v1, f.v2, f.v3];
	for (i in 0...3) {
		var v1 = vs[i];
		var v2 = vs[(i + 1) % 3];
		if (v1 == null || v2 == null) continue;
		v1.removeIfNonNeighbor(v2);
		v2.removeIfNonNeighbor(v1);
	}
}

function collapse(vertices:Array<Vertex>, faces:Array<Triangle>, u:Vertex, v:Vertex) {
	// Collapse the edge uv by moving vertex u onto v
	trace("collapse " + u + " " + v);
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
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null && u.faces[i].hasVertex(v)) {
			removeFace(u.faces[i], faces);
		}
	}

	// update remaining triangles to have v instead of u
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null) u.faces[i].replaceVertex(u, v);
	}

	removeVertex(u, vertices);

	// recompute the edge collapse costs in neighborhood
	for (i in 0...tmpVertices.length) {
		computeEdgeCostAtVertex(tmpVertices[i]);
	}
}

function minimumCostEdge(vertices:Array<Vertex>) {
	// O(n * n) approach. TODO optimize this
	var least = vertices[0];
	for (i in 0...vertices.length) {
		if (vertices[i].collapseCost < least.collapseCost) {
			least = vertices[i];
		}
	}
	return least;
}

// we use a triangle class to represent structure of face slightly differently
class Triangle {

	public var a:Int;
	public var b:Int;
	public var c:Int;

	public var v1:Vertex;
	public var v2:Vertex;
	public var v3:Vertex;

	public var normal:Vector3;

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

	public function computeNormal() {
		var vA = this.v1.position;
		var vB = this.v2.position;
		var vC = this.v3.position;
		var _cb = new Vector3();
		var _ab = new Vector3();
		_cb.subVectors(vC, vB);
		_ab.subVectors(vA, vB);
		_cb.cross(_ab).normalize();
		this.normal.copy(_cb);
	}

	public function hasVertex(v:Vertex) {
		return v == this.v1 || v == this.v2 || v == this.v3;
	}

	public function replaceVertex(oldv:Vertex, newv:Vertex) {
		trace("replaceVertex " + oldv + " " + newv);
		if (oldv == this.v1) this.v1 = newv;
		else if (oldv == this.v2) this.v2 = newv;
		else if (oldv == this.v3) this.v3 = newv;

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

	public var position:Vector3;
	public var uv:Vector2;
	public var normal:Vector3;
	public var tangent:Vector4;
	public var color:three.math.Color;

	public var id:Int = -1; // external use position in vertices list (for e.g. face generation)
	public var faces:Array<Triangle> = []; // faces vertex is connected
	public var neighbors:Array<Vertex> = []; // neighbouring vertices aka "adjacentVertices"

	// these will be computed in computeEdgeCostAtVertex()
	public var collapseCost:Float = 0; // cost of collapsing this vertex, the less the better. aka objdist
	public var collapseNeighbor:Vertex = null; // best candinate for collapsing
	public var minCost:Float = 0;
	public var totalCost:Float = 0;
	public var costCount:Int = 0;

	public function new(v:Vector3, uv:Vector2, normal:Vector3, tangent:Vector4, color:three.math.Color) {
		this.position = v;
		this.uv = uv;
		this.normal = normal;
		this.tangent = tangent;
		this.color = color;
	}

	public function addUniqueNeighbor(vertex:Vertex) {
		pushIfUnique(this.neighbors, vertex);
	}

	public function removeIfNonNeighbor(n:Vertex) {
		var neighbors = this.neighbors;
		var faces = this.faces;
		var offset = neighbors.indexOf(n);
		if (offset == -1) return;
		for (i in 0...faces.length) {
			if (faces[i].hasVertex(n)) return;
		}
		neighbors.splice(offset, 1);
	}

	public function toString() {
		return "Vertex(${position})";
	}
}

class SimplifyModifier {

	public function new() {}

	public function modify(geometry:BufferGeometry, count:Int):BufferGeometry {

		geometry = geometry.clone();

		// currently morphAttributes are not supported
		delete geometry.morphAttributes.position;
		delete geometry.morphAttributes.normal;
		var attributes = geometry.attributes;

		// this modifier can only process indexed and non-indexed geomtries with at least a position attribute
		for (name in attributes) {
			if (name != "position" && name != "uv" && name != "normal" && name != "tangent" && name != "color") {
				geometry.deleteAttribute(name);
			}
		}

		geometry = BufferGeometryUtils.mergeVertices(geometry);

		//
		// put data of original geometry in different data structures
		//

		var vertices:Array<Vertex> = [];
		var faces:Array<Triangle> = [];

		// add vertices
		var positionAttribute = geometry.getAttribute("position");
		var uvAttribute = geometry.getAttribute("uv");
		var normalAttribute = geometry.getAttribute("normal");
		var tangentAttribute = geometry.getAttribute("tangent");
		var colorAttribute = geometry.getAttribute("color");
		var t:Vector4 = null;
		var v2:Vector2 = null;
		var nor:Vector3 = null;
		var col:three.math.Color = null;
		for (i in 0...positionAttribute.count) {
			var v = new Vector3().fromBufferAttribute(positionAttribute, i);
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
				col = three.math.Color.fromBufferAttribute(colorAttribute, i);
			}
			var vertex = new Vertex(v, v2, nor, t, col);
			vertices.push(vertex);
		}

		// add faces
		var index = geometry.getIndex();
		if (index != null) {
			for (i in 0...index.count) {
				if (i % 3 == 0) {
					var a = index.getX(i);
					var b = index.getX(i + 1);
					var c = index.getX(i + 2);
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		} else {
			for (i in 0...positionAttribute.count) {
				if (i % 3 == 0) {
					var a = i;
					var b = i + 1;
					var c = i + 2;
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		}

		// compute all edge collapse costs
		for (i in 0...vertices.length) {
			computeEdgeCostAtVertex(vertices[i]);
		}

		var nextVertex:Vertex;
		var z = count;
		while (z > 0) {
			nextVertex = minimumCostEdge(vertices);
			if (nextVertex == null) {
				trace("THREE.SimplifyModifier: No next vertex");
				break;
			}
			collapse(vertices, faces, nextVertex, nextVertex.collapseNeighbor);
			z--;
		}

		//

		var simplifiedGeometry = new BufferGeometry();
		var position:Array<Float> = [];
		var uv:Array<Float> = [];
		var normal:Array<Float> = [];
		var tangent:Array<Float> = [];
		var color:Array<Float> = [];
		var index:Array<Int> = [];

		//

		for (i in 0...vertices.length) {
			var vertex = vertices[i];
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

			// cache final index to GREATLY speed up faces reconstruction
			vertex.id = i;
		}

		//

		for (i in 0...faces.length) {
			var face = faces[i];
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

function pushIfUnique(array:Array<Dynamic>, object:Dynamic) {
	if (array.indexOf(object) == -1) array.push(object);
}

function removeFromArray(array:Array<Dynamic>, object:Dynamic) {
	var k = array.indexOf(object);
	if (k > -1) array.splice(k, 1);
}

function computeEdgeCollapseCost(u:Vertex, v:Vertex) {
	// if we collapse edge uv by moving u to v then how
	// much different will the model change, i.e. the "error".

	var edgelength = v.position.distanceTo(u.position);
	var curvature = 0;

	var sideFaces:Array<Triangle> = [];

	// find the "sides" triangles that are on the edge uv
	for (i in 0...u.faces.length) {
		var face = u.faces[i];
		if (face.hasVertex(v)) {
			sideFaces.push(face);
		}
	}

	// use the triangle facing most away from the sides
	// to determine our curvature term
	for (i in 0...u.faces.length) {
		var minCurvature = 1;
		var face = u.faces[i];
		for (j in 0...sideFaces.length) {
			var sideFace = sideFaces[j];
			// use dot product of face normals.
			var dotProd = face.normal.dot(sideFace.normal);
			minCurvature = Math.min(minCurvature, (1.001 - dotProd) / 2);
		}
		curvature = Math.max(curvature, minCurvature);
	}

	// crude approach in attempt to preserve borders
	// though it seems not to be totally correct
	var borders = 0;
	if (sideFaces.length < 2) {
		// we add some arbitrary cost for borders,
		// borders += 10;
		curvature = 1;
	}

	var amt = edgelength * curvature + borders;
	return amt;
}

function computeEdgeCostAtVertex(v:Vertex) {
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

	v.collapseCost = 100000;
	v.collapseNeighbor = null;

	// search all neighboring edges for "least cost" edge
	for (i in 0...v.neighbors.length) {
		var collapseCost = computeEdgeCollapseCost(v, v.neighbors[i]);
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

function removeVertex(v:Vertex, vertices:Array<Vertex>) {
	trace("removeVertex " + v);
	assert(v.faces.length == 0);
	while (v.neighbors.length > 0) {
		var n = v.neighbors.pop();
		removeFromArray(n.neighbors, v);
	}
	removeFromArray(vertices, v);
}

function removeFace(f:Triangle, faces:Array<Triangle>) {
	trace("removeFace " + f);
	removeFromArray(faces, f);
	if (f.v1 != null) removeFromArray(f.v1.faces, f);
	if (f.v2 != null) removeFromArray(f.v2.faces, f);
	if (f.v3 != null) removeFromArray(f.v3.faces, f);

	// TODO optimize this!
	var vs:Array<Vertex> = [f.v1, f.v2, f.v3];
	for (i in 0...3) {
		var v1 = vs[i];
		var v2 = vs[(i + 1) % 3];
		if (v1 == null || v2 == null) continue;
		v1.removeIfNonNeighbor(v2);
		v2.removeIfNonNeighbor(v1);
	}
}

function collapse(vertices:Array<Vertex>, faces:Array<Triangle>, u:Vertex, v:Vertex) {
	// Collapse the edge uv by moving vertex u onto v
	trace("collapse " + u + " " + v);
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
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null && u.faces[i].hasVertex(v)) {
			removeFace(u.faces[i], faces);
		}
	}

	// update remaining triangles to have v instead of u
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null) u.faces[i].replaceVertex(u, v);
	}

	removeVertex(u, vertices);

	// recompute the edge collapse costs in neighborhood
	for (i in 0...tmpVertices.length) {
		computeEdgeCostAtVertex(tmpVertices[i]);
	}
}

function minimumCostEdge(vertices:Array<Vertex>) {
	// O(n * n) approach. TODO optimize this
	var least = vertices[0];
	for (i in 0...vertices.length) {
		if (vertices[i].collapseCost < least.collapseCost) {
			least = vertices[i];
		}
	}
	return least;
}

// we use a triangle class to represent structure of face slightly differently
class Triangle {

	public var a:Int;
	public var b:Int;
	public var c:Int;

	public var v1:Vertex;
	public var v2:Vertex;
	public var v3:Vertex;

	public var normal:Vector3;

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

	public function computeNormal() {
		var vA = this.v1.position;
		var vB = this.v2.position;
		var vC = this.v3.position;
		var _cb = new Vector3();
		var _ab = new Vector3();
		_cb.subVectors(vC, vB);
		_ab.subVectors(vA, vB);
		_cb.cross(_ab).normalize();
		this.normal.copy(_cb);
	}

	public function hasVertex(v:Vertex) {
		return v == this.v1 || v == this.v2 || v == this.v3;
	}

	public function replaceVertex(oldv:Vertex, newv:Vertex) {
		trace("replaceVertex " + oldv + " " + newv);
		if (oldv == this.v1) this.v1 = newv;
		else if (oldv == this.v2) this.v2 = newv;
		else if (oldv == this.v3) this.v3 = newv;

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

	public var position:Vector3;
	public var uv:Vector2;
	public var normal:Vector3;
	public var tangent:Vector4;
	public var color:three.math.Color;

	public var id:Int = -1; // external use position in vertices list (for e.g. face generation)
	public var faces:Array<Triangle> = []; // faces vertex is connected
	public var neighbors:Array<Vertex> = []; // neighbouring vertices aka "adjacentVertices"

	// these will be computed in computeEdgeCostAtVertex()
	public var collapseCost:Float = 0; // cost of collapsing this vertex, the less the better. aka objdist
	public var collapseNeighbor:Vertex = null; // best candinate for collapsing
	public var minCost:Float = 0;
	public var totalCost:Float = 0;
	public var costCount:Int = 0;

	public function new(v:Vector3, uv:Vector2, normal:Vector3, tangent:Vector4, color:three.math.Color) {
		this.position = v;
		this.uv = uv;
		this.normal = normal;
		this.tangent = tangent;
		this.color = color;
	}

	public function addUniqueNeighbor(vertex:Vertex) {
		pushIfUnique(this.neighbors, vertex);
	}

	public function removeIfNonNeighbor(n:Vertex) {
		var neighbors = this.neighbors;
		var faces = this.faces;
		var offset = neighbors.indexOf(n);
		if (offset == -1) return;
		for (i in 0...faces.length) {
			if (faces[i].hasVertex(n)) return;
		}
		neighbors.splice(offset, 1);
	}

	public function toString() {
		return "Vertex(${position})";
	}
}

class SimplifyModifier {

	public function new() {}

	public function modify(geometry:BufferGeometry, count:Int):BufferGeometry {

		geometry = geometry.clone();

		// currently morphAttributes are not supported
		delete geometry.morphAttributes.position;
		delete geometry.morphAttributes.normal;
		var attributes = geometry.attributes;

		// this modifier can only process indexed and non-indexed geomtries with at least a position attribute
		for (name in attributes) {
			if (name != "position" && name != "uv" && name != "normal" && name != "tangent" && name != "color") {
				geometry.deleteAttribute(name);
			}
		}

		geometry = BufferGeometryUtils.mergeVertices(geometry);

		//
		// put data of original geometry in different data structures
		//

		var vertices:Array<Vertex> = [];
		var faces:Array<Triangle> = [];

		// add vertices
		var positionAttribute = geometry.getAttribute("position");
		var uvAttribute = geometry.getAttribute("uv");
		var normalAttribute = geometry.getAttribute("normal");
		var tangentAttribute = geometry.getAttribute("tangent");
		var colorAttribute = geometry.getAttribute("color");
		var t:Vector4 = null;
		var v2:Vector2 = null;
		var nor:Vector3 = null;
		var col:three.math.Color = null;
		for (i in 0...positionAttribute.count) {
			var v = new Vector3().fromBufferAttribute(positionAttribute, i);
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
				col = three.math.Color.fromBufferAttribute(colorAttribute, i);
			}
			var vertex = new Vertex(v, v2, nor, t, col);
			vertices.push(vertex);
		}

		// add faces
		var index = geometry.getIndex();
		if (index != null) {
			for (i in 0...index.count) {
				if (i % 3 == 0) {
					var a = index.getX(i);
					var b = index.getX(i + 1);
					var c = index.getX(i + 2);
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		} else {
			for (i in 0...positionAttribute.count) {
				if (i % 3 == 0) {
					var a = i;
					var b = i + 1;
					var c = i + 2;
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		}

		// compute all edge collapse costs
		for (i in 0...vertices.length) {
			computeEdgeCostAtVertex(vertices[i]);
		}

		var nextVertex:Vertex;
		var z = count;
		while (z > 0) {
			nextVertex = minimumCostEdge(vertices);
			if (nextVertex == null) {
				trace("THREE.SimplifyModifier: No next vertex");
				break;
			}
			collapse(vertices, faces, nextVertex, nextVertex.collapseNeighbor);
			z--;
		}

		//

		var simplifiedGeometry = new BufferGeometry();
		var position:Array<Float> = [];
		var uv:Array<Float> = [];
		var normal:Array<Float> = [];
		var tangent:Array<Float> = [];
		var color:Array<Float> = [];
		var index:Array<Int> = [];

		//

		for (i in 0...vertices.length) {
			var vertex = vertices[i];
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

			// cache final index to GREATLY speed up faces reconstruction
			vertex.id = i;
		}

		//

		for (i in 0...faces.length) {
			var face = faces[i];
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

function pushIfUnique(array:Array<Dynamic>, object:Dynamic) {
	if (array.indexOf(object) == -1) array.push(object);
}

function removeFromArray(array:Array<Dynamic>, object:Dynamic) {
	var k = array.indexOf(object);
	if (k > -1) array.splice(k, 1);
}

function computeEdgeCollapseCost(u:Vertex, v:Vertex) {
	// if we collapse edge uv by moving u to v then how
	// much different will the model change, i.e. the "error".

	var edgelength = v.position.distanceTo(u.position);
	var curvature = 0;

	var sideFaces:Array<Triangle> = [];

	// find the "sides" triangles that are on the edge uv
	for (i in 0...u.faces.length) {
		var face = u.faces[i];
		if (face.hasVertex(v)) {
			sideFaces.push(face);
		}
	}

	// use the triangle facing most away from the sides
	// to determine our curvature term
	for (i in 0...u.faces.length) {
		var minCurvature = 1;
		var face = u.faces[i];
		for (j in 0...sideFaces.length) {
			var sideFace = sideFaces[j];
			// use dot product of face normals.
			var dotProd = face.normal.dot(sideFace.normal);
			minCurvature = Math.min(minCurvature, (1.001 - dotProd) / 2);
		}
		curvature = Math.max(curvature, minCurvature);
	}

	// crude approach in attempt to preserve borders
	// though it seems not to be totally correct
	var borders = 0;
	if (sideFaces.length < 2) {
		// we add some arbitrary cost for borders,
		// borders += 10;
		curvature = 1;
	}

	var amt = edgelength * curvature + borders;
	return amt;
}

function computeEdgeCostAtVertex(v:Vertex) {
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

	v.collapseCost = 100000;
	v.collapseNeighbor = null;

	// search all neighboring edges for "least cost" edge
	for (i in 0...v.neighbors.length) {
		var collapseCost = computeEdgeCollapseCost(v, v.neighbors[i]);
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

function removeVertex(v:Vertex, vertices:Array<Vertex>) {
	trace("removeVertex " + v);
	assert(v.faces.length == 0);
	while (v.neighbors.length > 0) {
		var n = v.neighbors.pop();
		removeFromArray(n.neighbors, v);
	}
	removeFromArray(vertices, v);
}

function removeFace(f:Triangle, faces:Array<Triangle>) {
	trace("removeFace " + f);
	removeFromArray(faces, f);
	if (f.v1 != null) removeFromArray(f.v1.faces, f);
	if (f.v2 != null) removeFromArray(f.v2.faces, f);
	if (f.v3 != null) removeFromArray(f.v3.faces, f);

	// TODO optimize this!
	var vs:Array<Vertex> = [f.v1, f.v2, f.v3];
	for (i in 0...3) {
		var v1 = vs[i];
		var v2 = vs[(i + 1) % 3];
		if (v1 == null || v2 == null) continue;
		v1.removeIfNonNeighbor(v2);
		v2.removeIfNonNeighbor(v1);
	}
}

function collapse(vertices:Array<Vertex>, faces:Array<Triangle>, u:Vertex, v:Vertex) {
	// Collapse the edge uv by moving vertex u onto v
	trace("collapse " + u + " " + v);
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
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null && u.faces[i].hasVertex(v)) {
			removeFace(u.faces[i], faces);
		}
	}

	// update remaining triangles to have v instead of u
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null) u.faces[i].replaceVertex(u, v);
	}

	removeVertex(u, vertices);

	// recompute the edge collapse costs in neighborhood
	for (i in 0...tmpVertices.length) {
		computeEdgeCostAtVertex(tmpVertices[i]);
	}
}

function minimumCostEdge(vertices:Array<Vertex>) {
	// O(n * n) approach. TODO optimize this
	var least = vertices[0];
	for (i in 0...vertices.length) {
		if (vertices[i].collapseCost < least.collapseCost) {
			least = vertices[i];
		}
	}
	return least;
}

// we use a triangle class to represent structure of face slightly differently
class Triangle {

	public var a:Int;
	public var b:Int;
	public var c:Int;

	public var v1:Vertex;
	public var v2:Vertex;
	public var v3:Vertex;

	public var normal:Vector3;

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

	public function computeNormal() {
		var vA = this.v1.position;
		var vB = this.v2.position;
		var vC = this.v3.position;
		var _cb = new Vector3();
		var _ab = new Vector3();
		_cb.subVectors(vC, vB);
		_ab.subVectors(vA, vB);
		_cb.cross(_ab).normalize();
		this.normal.copy(_cb);
	}

	public function hasVertex(v:Vertex) {
		return v == this.v1 || v == this.v2 || v == this.v3;
	}

	public function replaceVertex(oldv:Vertex, newv:Vertex) {
		trace("replaceVertex " + oldv + " " + newv);
		if (oldv == this.v1) this.v1 = newv;
		else if (oldv == this.v2) this.v2 = newv;
		else if (oldv == this.v3) this.v3 = newv;

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

	public var position:Vector3;
	public var uv:Vector2;
	public var normal:Vector3;
	public var tangent:Vector4;
	public var color:three.math.Color;

	public var id:Int = -1; // external use position in vertices list (for e.g. face generation)
	public var faces:Array<Triangle> = []; // faces vertex is connected
	public var neighbors:Array<Vertex> = []; // neighbouring vertices aka "adjacentVertices"

	// these will be computed in computeEdgeCostAtVertex()
	public var collapseCost:Float = 0; // cost of collapsing this vertex, the less the better. aka objdist
	public var collapseNeighbor:Vertex = null; // best candinate for collapsing
	public var minCost:Float = 0;
	public var totalCost:Float = 0;
	public var costCount:Int = 0;

	public function new(v:Vector3, uv:Vector2, normal:Vector3, tangent:Vector4, color:three.math.Color) {
		this.position = v;
		this.uv = uv;
		this.normal = normal;
		this.tangent = tangent;
		this.color = color;
	}

	public function addUniqueNeighbor(vertex:Vertex) {
		pushIfUnique(this.neighbors, vertex);
	}

	public function removeIfNonNeighbor(n:Vertex) {
		var neighbors = this.neighbors;
		var faces = this.faces;
		var offset = neighbors.indexOf(n);
		if (offset == -1) return;
		for (i in 0...faces.length) {
			if (faces[i].hasVertex(n)) return;
		}
		neighbors.splice(offset, 1);
	}

	public function toString() {
		return "Vertex(${position})";
	}
}

class SimplifyModifier {

	public function new() {}

	public function modify(geometry:BufferGeometry, count:Int):BufferGeometry {

		geometry = geometry.clone();

		// currently morphAttributes are not supported
		delete geometry.morphAttributes.position;
		delete geometry.morphAttributes.normal;
		var attributes = geometry.attributes;

		// this modifier can only process indexed and non-indexed geomtries with at least a position attribute
		for (name in attributes) {
			if (name != "position" && name != "uv" && name != "normal" && name != "tangent" && name != "color") {
				geometry.deleteAttribute(name);
			}
		}

		geometry = BufferGeometryUtils.mergeVertices(geometry);

		//
		// put data of original geometry in different data structures
		//

		var vertices:Array<Vertex> = [];
		var faces:Array<Triangle> = [];

		// add vertices
		var positionAttribute = geometry.getAttribute("position");
		var uvAttribute = geometry.getAttribute("uv");
		var normalAttribute = geometry.getAttribute("normal");
		var tangentAttribute = geometry.getAttribute("tangent");
		var colorAttribute = geometry.getAttribute("color");
		var t:Vector4 = null;
		var v2:Vector2 = null;
		var nor:Vector3 = null;
		var col:three.math.Color = null;
		for (i in 0...positionAttribute.count) {
			var v = new Vector3().fromBufferAttribute(positionAttribute, i);
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
				col = three.math.Color.fromBufferAttribute(colorAttribute, i);
			}
			var vertex = new Vertex(v, v2, nor, t, col);
			vertices.push(vertex);
		}

		// add faces
		var index = geometry.getIndex();
		if (index != null) {
			for (i in 0...index.count) {
				if (i % 3 == 0) {
					var a = index.getX(i);
					var b = index.getX(i + 1);
					var c = index.getX(i + 2);
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		} else {
			for (i in 0...positionAttribute.count) {
				if (i % 3 == 0) {
					var a = i;
					var b = i + 1;
					var c = i + 2;
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		}

		// compute all edge collapse costs
		for (i in 0...vertices.length) {
			computeEdgeCostAtVertex(vertices[i]);
		}

		var nextVertex:Vertex;
		var z = count;
		while (z > 0) {
			nextVertex = minimumCostEdge(vertices);
			if (nextVertex == null) {
				trace("THREE.SimplifyModifier: No next vertex");
				break;
			}
			collapse(vertices, faces, nextVertex, nextVertex.collapseNeighbor);
			z--;
		}

		//

		var simplifiedGeometry = new BufferGeometry();
		var position:Array<Float> = [];
		var uv:Array<Float> = [];
		var normal:Array<Float> = [];
		var tangent:Array<Float> = [];
		var color:Array<Float> = [];
		var index:Array<Int> = [];

		//

		for (i in 0...vertices.length) {
			var vertex = vertices[i];
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

			// cache final index to GREATLY speed up faces reconstruction
			vertex.id = i;
		}

		//

		for (i in 0...faces.length) {
			var face = faces[i];
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

function pushIfUnique(array:Array<Dynamic>, object:Dynamic) {
	if (array.indexOf(object) == -1) array.push(object);
}

function removeFromArray(array:Array<Dynamic>, object:Dynamic) {
	var k = array.indexOf(object);
	if (k > -1) array.splice(k, 1);
}

function computeEdgeCollapseCost(u:Vertex, v:Vertex) {
	// if we collapse edge uv by moving u to v then how
	// much different will the model change, i.e. the "error".

	var edgelength = v.position.distanceTo(u.position);
	var curvature = 0;

	var sideFaces:Array<Triangle> = [];

	// find the "sides" triangles that are on the edge uv
	for (i in 0...u.faces.length) {
		var face = u.faces[i];
		if (face.hasVertex(v)) {
			sideFaces.push(face);
		}
	}

	// use the triangle facing most away from the sides
	// to determine our curvature term
	for (i in 0...u.faces.length) {
		var minCurvature = 1;
		var face = u.faces[i];
		for (j in 0...sideFaces.length) {
			var sideFace = sideFaces[j];
			// use dot product of face normals.
			var dotProd = face.normal.dot(sideFace.normal);
			minCurvature = Math.min(minCurvature, (1.001 - dotProd) / 2);
		}
		curvature = Math.max(curvature, minCurvature);
	}

	// crude approach in attempt to preserve borders
	// though it seems not to be totally correct
	var borders = 0;
	if (sideFaces.length < 2) {
		// we add some arbitrary cost for borders,
		// borders += 10;
		curvature = 1;
	}

	var amt = edgelength * curvature + borders;
	return amt;
}

function computeEdgeCostAtVertex(v:Vertex) {
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

	v.collapseCost = 100000;
	v.collapseNeighbor = null;

	// search all neighboring edges for "least cost" edge
	for (i in 0...v.neighbors.length) {
		var collapseCost = computeEdgeCollapseCost(v, v.neighbors[i]);
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

function removeVertex(v:Vertex, vertices:Array<Vertex>) {
	trace("removeVertex " + v);
	assert(v.faces.length == 0);
	while (v.neighbors.length > 0) {
		var n = v.neighbors.pop();
		removeFromArray(n.neighbors, v);
	}
	removeFromArray(vertices, v);
}

function removeFace(f:Triangle, faces:Array<Triangle>) {
	trace("removeFace " + f);
	removeFromArray(faces, f);
	if (f.v1 != null) removeFromArray(f.v1.faces, f);
	if (f.v2 != null) removeFromArray(f.v2.faces, f);
	if (f.v3 != null) removeFromArray(f.v3.faces, f);

	// TODO optimize this!
	var vs:Array<Vertex> = [f.v1, f.v2, f.v3];
	for (i in 0...3) {
		var v1 = vs[i];
		var v2 = vs[(i + 1) % 3];
		if (v1 == null || v2 == null) continue;
		v1.removeIfNonNeighbor(v2);
		v2.removeIfNonNeighbor(v1);
	}
}

function collapse(vertices:Array<Vertex>, faces:Array<Triangle>, u:Vertex, v:Vertex) {
	// Collapse the edge uv by moving vertex u onto v
	trace("collapse " + u + " " + v);
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
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null && u.faces[i].hasVertex(v)) {
			removeFace(u.faces[i], faces);
		}
	}

	// update remaining triangles to have v instead of u
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null) u.faces[i].replaceVertex(u, v);
	}

	removeVertex(u, vertices);

	// recompute the edge collapse costs in neighborhood
	for (i in 0...tmpVertices.length) {
		computeEdgeCostAtVertex(tmpVertices[i]);
	}
}

function minimumCostEdge(vertices:Array<Vertex>) {
	// O(n * n) approach. TODO optimize this
	var least = vertices[0];
	for (i in 0...vertices.length) {
		if (vertices[i].collapseCost < least.collapseCost) {
			least = vertices[i];
		}
	}
	return least;
}

// we use a triangle class to represent structure of face slightly differently
class Triangle {

	public var a:Int;
	public var b:Int;
	public var c:Int;

	public var v1:Vertex;
	public var v2:Vertex;
	public var v3:Vertex;

	public var normal:Vector3;

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

	public function computeNormal() {
		var vA = this.v1.position;
		var vB = this.v2.position;
		var vC = this.v3.position;
		var _cb = new Vector3();
		var _ab = new Vector3();
		_cb.subVectors(vC, vB);
		_ab.subVectors(vA, vB);
		_cb.cross(_ab).normalize();
		this.normal.copy(_cb);
	}

	public function hasVertex(v:Vertex) {
		return v == this.v1 || v == this.v2 || v == this.v3;
	}

	public function replaceVertex(oldv:Vertex, newv:Vertex) {
		trace("replaceVertex " + oldv + " " + newv);
		if (oldv == this.v1) this.v1 = newv;
		else if (oldv == this.v2) this.v2 = newv;
		else if (oldv == this.v3) this.v3 = newv;

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

	public var position:Vector3;
	public var uv:Vector2;
	public var normal:Vector3;
	public var tangent:Vector4;
	public var color:three.math.Color;

	public var id:Int = -1; // external use position in vertices list (for e.g. face generation)
	public var faces:Array<Triangle> = []; // faces vertex is connected
	public var neighbors:Array<Vertex> = []; // neighbouring vertices aka "adjacentVertices"

	// these will be computed in computeEdgeCostAtVertex()
	public var collapseCost:Float = 0; // cost of collapsing this vertex, the less the better. aka objdist
	public var collapseNeighbor:Vertex = null; // best candinate for collapsing
	public var minCost:Float = 0;
	public var totalCost:Float = 0;
	public var costCount:Int = 0;

	public function new(v:Vector3, uv:Vector2, normal:Vector3, tangent:Vector4, color:three.math.Color) {
		this.position = v;
		this.uv = uv;
		this.normal = normal;
		this.tangent = tangent;
		this.color = color;
	}

	public function addUniqueNeighbor(vertex:Vertex) {
		pushIfUnique(this.neighbors, vertex);
	}

	public function removeIfNonNeighbor(n:Vertex) {
		var neighbors = this.neighbors;
		var faces = this.faces;
		var offset = neighbors.indexOf(n);
		if (offset == -1) return;
		for (i in 0...faces.length) {
			if (faces[i].hasVertex(n)) return;
		}
		neighbors.splice(offset, 1);
	}

	public function toString() {
		return "Vertex(${position})";
	}
}

class SimplifyModifier {

	public function new() {}

	public function modify(geometry:BufferGeometry, count:Int):BufferGeometry {

		geometry = geometry.clone();

		// currently morphAttributes are not supported
		delete geometry.morphAttributes.position;
		delete geometry.morphAttributes.normal;
		var attributes = geometry.attributes;

		// this modifier can only process indexed and non-indexed geomtries with at least a position attribute
		for (name in attributes) {
			if (name != "position" && name != "uv" && name != "normal" && name != "tangent" && name != "color") {
				geometry.deleteAttribute(name);
			}
		}

		geometry = BufferGeometryUtils.mergeVertices(geometry);

		//
		// put data of original geometry in different data structures
		//

		var vertices:Array<Vertex> = [];
		var faces:Array<Triangle> = [];

		// add vertices
		var positionAttribute = geometry.getAttribute("position");
		var uvAttribute = geometry.getAttribute("uv");
		var normalAttribute = geometry.getAttribute("normal");
		var tangentAttribute = geometry.getAttribute("tangent");
		var colorAttribute = geometry.getAttribute("color");
		var t:Vector4 = null;
		var v2:Vector2 = null;
		var nor:Vector3 = null;
		var col:three.math.Color = null;
		for (i in 0...positionAttribute.count) {
			var v = new Vector3().fromBufferAttribute(positionAttribute, i);
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
				col = three.math.Color.fromBufferAttribute(colorAttribute, i);
			}
			var vertex = new Vertex(v, v2, nor, t, col);
			vertices.push(vertex);
		}

		// add faces
		var index = geometry.getIndex();
		if (index != null) {
			for (i in 0...index.count) {
				if (i % 3 == 0) {
					var a = index.getX(i);
					var b = index.getX(i + 1);
					var c = index.getX(i + 2);
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		} else {
			for (i in 0...positionAttribute.count) {
				if (i % 3 == 0) {
					var a = i;
					var b = i + 1;
					var c = i + 2;
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		}

		// compute all edge collapse costs
		for (i in 0...vertices.length) {
			computeEdgeCostAtVertex(vertices[i]);
		}

		var nextVertex:Vertex;
		var z = count;
		while (z > 0) {
			nextVertex = minimumCostEdge(vertices);
			if (nextVertex == null) {
				trace("THREE.SimplifyModifier: No next vertex");
				break;
			}
			collapse(vertices, faces, nextVertex, nextVertex.collapseNeighbor);
			z--;
		}

		//

		var simplifiedGeometry = new BufferGeometry();
		var position:Array<Float> = [];
		var uv:Array<Float> = [];
		var normal:Array<Float> = [];
		var tangent:Array<Float> = [];
		var color:Array<Float> = [];
		var index:Array<Int> = [];

		//

		for (i in 0...vertices.length) {
			var vertex = vertices[i];
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

			// cache final index to GREATLY speed up faces reconstruction
			vertex.id = i;
		}

		//

		for (i in 0...faces.length) {
			var face = faces[i];
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

function pushIfUnique(array:Array<Dynamic>, object:Dynamic) {
	if (array.indexOf(object) == -1) array.push(object);
}

function removeFromArray(array:Array<Dynamic>, object:Dynamic) {
	var k = array.indexOf(object);
	if (k > -1) array.splice(k, 1);
}

function computeEdgeCollapseCost(u:Vertex, v:Vertex) {
	// if we collapse edge uv by moving u to v then how
	// much different will the model change, i.e. the "error".

	var edgelength = v.position.distanceTo(u.position);
	var curvature = 0;

	var sideFaces:Array<Triangle> = [];

	// find the "sides" triangles that are on the edge uv
	for (i in 0...u.faces.length) {
		var face = u.faces[i];
		if (face.hasVertex(v)) {
			sideFaces.push(face);
		}
	}

	// use the triangle facing most away from the sides
	// to determine our curvature term
	for (i in 0...u.faces.length) {
		var minCurvature = 1;
		var face = u.faces[i];
		for (j in 0...sideFaces.length) {
			var sideFace = sideFaces[j];
			// use dot product of face normals.
			var dotProd = face.normal.dot(sideFace.normal);
			minCurvature = Math.min(minCurvature, (1.001 - dotProd) / 2);
		}
		curvature = Math.max(curvature, minCurvature);
	}

	// crude approach in attempt to preserve borders
	// though it seems not to be totally correct
	var borders = 0;
	if (sideFaces.length < 2) {
		// we add some arbitrary cost for borders,
		// borders += 10;
		curvature = 1;
	}

	var amt = edgelength * curvature + borders;
	return amt;
}

function computeEdgeCostAtVertex(v:Vertex) {
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

	v.collapseCost = 100000;
	v.collapseNeighbor = null;

	// search all neighboring edges for "least cost" edge
	for (i in 0...v.neighbors.length) {
		var collapseCost = computeEdgeCollapseCost(v, v.neighbors[i]);
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

function removeVertex(v:Vertex, vertices:Array<Vertex>) {
	trace("removeVertex " + v);
	assert(v.faces.length == 0);
	while (v.neighbors.length > 0) {
		var n = v.neighbors.pop();
		removeFromArray(n.neighbors, v);
	}
	removeFromArray(vertices, v);
}

function removeFace(f:Triangle, faces:Array<Triangle>) {
	trace("removeFace " + f);
	removeFromArray(faces, f);
	if (f.v1 != null) removeFromArray(f.v1.faces, f);
	if (f.v2 != null) removeFromArray(f.v2.faces, f);
	if (f.v3 != null) removeFromArray(f.v3.faces, f);

	// TODO optimize this!
	var vs:Array<Vertex> = [f.v1, f.v2, f.v3];
	for (i in 0...3) {
		var v1 = vs[i];
		var v2 = vs[(i + 1) % 3];
		if (v1 == null || v2 == null) continue;
		v1.removeIfNonNeighbor(v2);
		v2.removeIfNonNeighbor(v1);
	}
}

function collapse(vertices:Array<Vertex>, faces:Array<Triangle>, u:Vertex, v:Vertex) {
	// Collapse the edge uv by moving vertex u onto v
	trace("collapse " + u + " " + v);
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
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null && u.faces[i].hasVertex(v)) {
			removeFace(u.faces[i], faces);
		}
	}

	// update remaining
	}

	// delete triangles on edge uv:
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null && u.faces[i].hasVertex(v)) {
			removeFace(u.faces[i], faces);
		}
	}

	// update remaining triangles to have v instead of u
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null) u.faces[i].replaceVertex(u, v);
	}

	removeVertex(u, vertices);

	// recompute the edge collapse costs in neighborhood
	for (i in 0...tmpVertices.length) {
		computeEdgeCostAtVertex(tmpVertices[i]);
	}
}

function minimumCostEdge(vertices:Array<Vertex>) {
	// O(n * n) approach. TODO optimize this
	var least = vertices[0];
	for (i in 0...vertices.length) {
		if (vertices[i].collapseCost < least.collapseCost) {
			least = vertices[i];
		}
	}
	return least;
}

// we use a triangle class to represent structure of face slightly differently
class Triangle {

	public var a:Int;
	public var b:Int;
	public var c:Int;

	public var v1:Vertex;
	public var v2:Vertex;
	public var v3:Vertex;

	public var normal:Vector3;

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

	public function computeNormal() {
		var vA = this.v1.position;
		var vB = this.v2.position;
		var vC = this.v3.position;
		var _cb = new Vector3();
		var _ab = new Vector3();
		_cb.subVectors(vC, vB);
		_ab.subVectors(vA, vB);
		_cb.cross(_ab).normalize();
		this.normal.copy(_cb);
	}

	public function hasVertex(v:Vertex) {
		return v == this.v1 || v == this.v2 || v == this.v3;
	}

	public function replaceVertex(oldv:Vertex, newv:Vertex) {
		trace("replaceVertex " + oldv + " " + newv);
		if (oldv == this.v1) this.v1 = newv;
		else if (oldv == this.v2) this.v2 = newv;
		else if (oldv == this.v3) this.v3 = newv;

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

	public var position:Vector3;
	public var uv:Vector2;
	public var normal:Vector3;
	public var tangent:Vector4;
	public var color:three.math.Color;

	public var id:Int = -1; // external use position in vertices list (for e.g. face generation)
	public var faces:Array<Triangle> = []; // faces vertex is connected
	public var neighbors:Array<Vertex> = []; // neighbouring vertices aka "adjacentVertices"

	// these will be computed in computeEdgeCostAtVertex()
	public var collapseCost:Float = 0; // cost of collapsing this vertex, the less the better. aka objdist
	public var collapseNeighbor:Vertex = null; // best candinate for collapsing
	public var minCost:Float = 0;
	public var totalCost:Float = 0;
	public var costCount:Int = 0;

	public function new(v:Vector3, uv:Vector2, normal:Vector3, tangent:Vector4, color:three.math.Color) {
		this.position = v;
		this.uv = uv;
		this.normal = normal;
		this.tangent = tangent;
		this.color = color;
	}

	public function addUniqueNeighbor(vertex:Vertex) {
		pushIfUnique(this.neighbors, vertex);
	}

	public function removeIfNonNeighbor(n:Vertex) {
		var neighbors = this.neighbors;
		var faces = this.faces;
		var offset = neighbors.indexOf(n);
		if (offset == -1) return;
		for (i in 0...faces.length) {
			if (faces[i].hasVertex(n)) return;
		}
		neighbors.splice(offset, 1);
	}

	public function toString() {
		return "Vertex(${position})";
	}
}

class SimplifyModifier {

	public function new() {}

	public function modify(geometry:BufferGeometry, count:Int):BufferGeometry {

		geometry = geometry.clone();

		// currently morphAttributes are not supported
		delete geometry.morphAttributes.position;
		delete geometry.morphAttributes.normal;
		var attributes = geometry.attributes;

		// this modifier can only process indexed and non-indexed geomtries with at least a position attribute
		for (name in attributes) {
			if (name != "position" && name != "uv" && name != "normal" && name != "tangent" && name != "color") {
				geometry.deleteAttribute(name);
			}
		}

		geometry = BufferGeometryUtils.mergeVertices(geometry);

		//
		// put data of original geometry in different data structures
		//

		var vertices:Array<Vertex> = [];
		var faces:Array<Triangle> = [];

		// add vertices
		var positionAttribute = geometry.getAttribute("position");
		var uvAttribute = geometry.getAttribute("uv");
		var normalAttribute = geometry.getAttribute("normal");
		var tangentAttribute = geometry.getAttribute("tangent");
		var colorAttribute = geometry.getAttribute("color");
		var t:Vector4 = null;
		var v2:Vector2 = null;
		var nor:Vector3 = null;
		var col:three.math.Color = null;
		for (i in 0...positionAttribute.count) {
			var v = new Vector3().fromBufferAttribute(positionAttribute, i);
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
				col = three.math.Color.fromBufferAttribute(colorAttribute, i);
			}
			var vertex = new Vertex(v, v2, nor, t, col);
			vertices.push(vertex);
		}

		// add faces
		var index = geometry.getIndex();
		if (index != null) {
			for (i in 0...index.count) {
				if (i % 3 == 0) {
					var a = index.getX(i);
					var b = index.getX(i + 1);
					var c = index.getX(i + 2);
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		} else {
			for (i in 0...positionAttribute.count) {
				if (i % 3 == 0) {
					var a = i;
					var b = i + 1;
					var c = i + 2;
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		}

		// compute all edge collapse costs
		for (i in 0...vertices.length) {
			computeEdgeCostAtVertex(vertices[i]);
		}

		var nextVertex:Vertex;
		var z = count;
		while (z > 0) {
			nextVertex = minimumCostEdge(vertices);
			if (nextVertex == null) {
				trace("THREE.SimplifyModifier: No next vertex");
				break;
			}
			collapse(vertices, faces, nextVertex, nextVertex.collapseNeighbor);
			z--;
		}

		//

		var simplifiedGeometry = new BufferGeometry();
		var position:Array<Float> = [];
		var uv:Array<Float> = [];
		var normal:Array<Float> = [];
		var tangent:Array<Float> = [];
		var color:Array<Float> = [];
		var index:Array<Int> = [];

		//

		for (i in 0...vertices.length) {
			var vertex = vertices[i];
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

			// cache final index to GREATLY speed up faces reconstruction
			vertex.id = i;
		}

		//

		for (i in 0...faces.length) {
			var face = faces[i];
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

function pushIfUnique(array:Array<Dynamic>, object:Dynamic) {
	if (array.indexOf(object) == -1) array.push(object);
}

function removeFromArray(array:Array<Dynamic>, object:Dynamic) {
	var k = array.indexOf(object);
	if (k > -1) array.splice(k, 1);
}

function computeEdgeCollapseCost(u:Vertex, v:Vertex) {
	// if we collapse edge uv by moving u to v then how
	// much different will the model change, i.e. the "error".

	var edgelength = v.position.distanceTo(u.position);
	var curvature = 0;

	var sideFaces:Array<Triangle> = [];

	// find the "sides" triangles that are on the edge uv
	for (i in 0...u.faces.length) {
		var face = u.faces[i];
		if (face.hasVertex(v)) {
			sideFaces.push(face);
		}
	}

	// use the triangle facing most away from the sides
	// to determine our curvature term
	for (i in 0...u.faces.length) {
		var minCurvature = 1;
		var face = u.faces[i];
		for (j in 0...sideFaces.length) {
			var sideFace = sideFaces[j];
			// use dot product of face normals.
			var dotProd = face.normal.dot(sideFace.normal);
			minCurvature = Math.min(minCurvature, (1.001 - dotProd) / 2);
		}
		curvature = Math.max(curvature, minCurvature);
	}

	// crude approach in attempt to preserve borders
	// though it seems not to be totally correct
	var borders = 0;
	if (sideFaces.length < 2) {
		// we add some arbitrary cost for borders,
		// borders += 10;
		curvature = 1;
	}

	var amt = edgelength * curvature + borders;
	return amt;
}

function computeEdgeCostAtVertex(v:Vertex) {
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

	v.collapseCost = 100000;
	v.collapseNeighbor = null;

	// search all neighboring edges for "least cost" edge
	for (i in 0...v.neighbors.length) {
		var collapseCost = computeEdgeCollapseCost(v, v.neighbors[i]);
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

function removeVertex(v:Vertex, vertices:Array<Vertex>) {
	trace("removeVertex " + v);
	assert(v.faces.length == 0);
	while (v.neighbors.length > 0) {
		var n = v.neighbors.pop();
		removeFromArray(n.neighbors, v);
	}
	removeFromArray(vertices, v);
}

function removeFace(f:Triangle, faces:Array<Triangle>) {
	trace("removeFace " + f);
	removeFromArray(faces, f);
	if (f.v1 != null) removeFromArray(f.v1.faces, f);
	if (f.v2 != null) removeFromArray(f.v2.faces, f);
	if (f.v3 != null) removeFromArray(f.v3.faces, f);

	// TODO optimize this!
	var vs:Array<Vertex> = [f.v1, f.v2, f.v3];
	for (i in 0...3) {
		var v1 = vs[i];
		var v2 = vs[(i + 1) % 3];
		if (v1 == null || v2 == null) continue;
		v1.removeIfNonNeighbor(v2);
		v2.removeIfNonNeighbor(v1);
	}
}

function collapse(vertices:Array<Vertex>, faces:Array<Triangle>, u:Vertex, v:Vertex) {
	// Collapse the edge uv by moving vertex u onto v
	trace("collapse " + u + " " + v);
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
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null && u.faces[i].hasVertex(v)) {
			removeFace(u.faces[i], faces);
		}
	}

	// update remaining triangles to have v instead of u
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null) u.faces[i].replaceVertex(u, v);
	}

	removeVertex(u, vertices);

	// recompute the edge collapse costs in neighborhood
	for (i in 0...tmpVertices.length) {
		computeEdgeCostAtVertex(tmpVertices[i]);
	}
}

function minimumCostEdge(vertices:Array<Vertex>) {
	// O(n * n) approach. TODO optimize this
	var least = vertices[0];
	for (i in 0...vertices.length) {
		if (vertices[i].collapseCost < least.collapseCost) {
			least = vertices[i];
		}
	}
	return least;
}

// we use a triangle class to represent structure of face slightly differently
class Triangle {

	public var a:Int;
	public var b:Int;
	public var c:Int;

	public var v1:Vertex;
	public var v2:Vertex;
	public var v3:Vertex;

	public var normal:Vector3;

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

	public function computeNormal() {
		var vA = this.v1.position;
		var vB = this.v2.position;
		var vC = this.v3.position;
		var _cb = new Vector3();
		var _ab = new Vector3();
		_cb.subVectors(vC, vB);
		_ab.subVectors(vA, vB);
		_cb.cross(_ab).normalize();
		this.normal.copy(_cb);
	}

	public function hasVertex(v:Vertex) {
		return v == this.v1 || v == this.v2 || v == this.v3;
	}

	public function replaceVertex(oldv:Vertex, newv:Vertex) {
		trace("replaceVertex " + oldv + " " + newv);
		if (oldv == this.v1) this.v1 = newv;
		else if (oldv == this.v2) this.v2 = newv;
		else if (oldv == this.v3) this.v3 = newv;

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

	public var position:Vector3;
	public var uv:Vector2;
	public var normal:Vector3;
	public var tangent:Vector4;
	public var color:three.math.Color;

	public var id:Int = -1; // external use position in vertices list (for e.g. face generation)
	public var faces:Array<Triangle> = []; // faces vertex is connected
	public var neighbors:Array<Vertex> = []; // neighbouring vertices aka "adjacentVertices"

	// these will be computed in computeEdgeCostAtVertex()
	public var collapseCost:Float = 0; // cost of collapsing this vertex, the less the better. aka objdist
	public var collapseNeighbor:Vertex = null; // best candinate for collapsing
	public var minCost:Float = 0;
	public var totalCost:Float = 0;
	public var costCount:Int = 0;

	public function new(v:Vector3, uv:Vector2, normal:Vector3, tangent:Vector4, color:three.math.Color) {
		this.position = v;
		this.uv = uv;
		this.normal = normal;
		this.tangent = tangent;
		this.color = color;
	}

	public function addUniqueNeighbor(vertex:Vertex) {
		pushIfUnique(this.neighbors, vertex);
	}

	public function removeIfNonNeighbor(n:Vertex) {
		var neighbors = this.neighbors;
		var faces = this.faces;
		var offset = neighbors.indexOf(n);
		if (offset == -1) return;
		for (i in 0...faces.length) {
			if (faces[i].hasVertex(n)) return;
		}
		neighbors.splice(offset, 1);
	}

	public function toString() {
		return "Vertex(${position})";
	}
}

class SimplifyModifier {

	public function new() {}

	public function modify(geometry:BufferGeometry, count:Int):BufferGeometry {

		geometry = geometry.clone();

		// currently morphAttributes are not supported
		delete geometry.morphAttributes.position;
		delete geometry.morphAttributes.normal;
		var attributes = geometry.attributes;

		// this modifier can only process indexed and non-indexed geomtries with at least a position attribute
		for (name in attributes) {
			if (name != "position" && name != "uv" && name != "normal" && name != "tangent" && name != "color") {
				geometry.deleteAttribute(name);
			}
		}

		geometry = BufferGeometryUtils.mergeVertices(geometry);

		//
		// put data of original geometry in different data structures
		//

		var vertices:Array<Vertex> = [];
		var faces:Array<Triangle> = [];

		// add vertices
		var positionAttribute = geometry.getAttribute("position");
		var uvAttribute = geometry.getAttribute("uv");
		var normalAttribute = geometry.getAttribute("normal");
		var tangentAttribute = geometry.getAttribute("tangent");
		var colorAttribute = geometry.getAttribute("color");
		var t:Vector4 = null;
		var v2:Vector2 = null;
		var nor:Vector3 = null;
		var col:three.math.Color = null;
		for (i in 0...positionAttribute.count) {
			var v = new Vector3().fromBufferAttribute(positionAttribute, i);
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
				col = three.math.Color.fromBufferAttribute(colorAttribute, i);
			}
			var vertex = new Vertex(v, v2, nor, t, col);
			vertices.push(vertex);
		}

		// add faces
		var index = geometry.getIndex();
		if (index != null) {
			for (i in 0...index.count) {
				if (i % 3 == 0) {
					var a = index.getX(i);
					var b = index.getX(i + 1);
					var c = index.getX(i + 2);
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		} else {
			for (i in 0...positionAttribute.count) {
				if (i % 3 == 0) {
					var a = i;
					var b = i + 1;
					var c = i + 2;
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		}

		// compute all edge collapse costs
		for (i in 0...vertices.length) {
			computeEdgeCostAtVertex(vertices[i]);
		}

		var nextVertex:Vertex;
		var z = count;
		while (z > 0) {
			nextVertex = minimumCostEdge(vertices);
			if (nextVertex == null) {
				trace("THREE.SimplifyModifier: No next vertex");
				break;
			}
			collapse(vertices, faces, nextVertex, nextVertex.collapseNeighbor);
			z--;
		}

		//

		var simplifiedGeometry = new BufferGeometry();
		var position:Array<Float> = [];
		var uv:Array<Float> = [];
		var normal:Array<Float> = [];
		var tangent:Array<Float> = [];
		var color:Array<Float> = [];
		var index:Array<Int> = [];

		//

		for (i in 0...vertices.length) {
			var vertex = vertices[i];
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

			// cache final index to GREATLY speed up faces reconstruction
			vertex.id = i;
		}

		//

		for (i in 0...faces.length) {
			var face = faces[i];
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

function pushIfUnique(array:Array<Dynamic>, object:Dynamic) {
	if (array.indexOf(object) == -1) array.push(object);
}

function removeFromArray(array:Array<Dynamic>, object:Dynamic) {
	var k = array.indexOf(object);
	if (k > -1) array.splice(k, 1);
}

function computeEdgeCollapseCost(u:Vertex, v:Vertex) {
	// if we collapse edge uv by moving u to v then how
	// much different will the model change, i.e. the "error".

	var edgelength = v.position.distanceTo(u.position);
	var curvature = 0;

	var sideFaces:Array<Triangle> = [];

	// find the "sides" triangles that are on the edge uv
	for (i in 0...u.faces.length) {
		var face = u.faces[i];
		if (face.hasVertex(v)) {
			sideFaces.push(face);
		}
	}

	// use the triangle facing most away from the sides
	// to determine our curvature term
	for (i in 0...u.faces.length) {
		var minCurvature = 1;
		var face = u.faces[i];
		for (j in 0...sideFaces.length) {
			var sideFace = sideFaces[j];
			// use dot product of face normals.
			var dotProd = face.normal.dot(sideFace.normal);
			minCurvature = Math.min(minCurvature, (1.001 - dotProd) / 2);
		}
		curvature = Math.max(curvature, minCurvature);
	}

	// crude approach in attempt to preserve borders
	// though it seems not to be totally correct
	var borders = 0;
	if (sideFaces.length < 2) {
		// we add some arbitrary cost for borders,
		// borders += 10;
		curvature = 1;
	}

	var amt = edgelength * curvature + borders;
	return amt;
}

function computeEdgeCostAtVertex(v:Vertex) {
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

	v.collapseCost = 100000;
	v.collapseNeighbor = null;

	// search all neighboring edges for "least cost" edge
	for (i in 0...v.neighbors.length) {
		var collapseCost = computeEdgeCollapseCost(v, v.neighbors[i]);
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

function removeVertex(v:Vertex, vertices:Array<Vertex>) {
	trace("removeVertex " + v);
	assert(v.faces.length == 0);
	while (v.neighbors.length > 0) {
		var n = v.neighbors.pop();
		removeFromArray(n.neighbors, v);
	}
	removeFromArray(vertices, v);
}

function removeFace(f:Triangle, faces:Array<Triangle>) {
	trace("removeFace " + f);
	removeFromArray(faces, f);
	if (f.v1 != null) removeFromArray(f.v1.faces, f);
	if (f.v2 != null) removeFromArray(f.v2.faces,
		removeFromArray(n.neighbors, v);
	}
	removeFromArray(vertices, v);
}

function removeFace(f:Triangle, faces:Array<Triangle>) {
	trace("removeFace " + f);
	removeFromArray(faces, f);
	if (f.v1 != null) removeFromArray(f.v1.faces, f);
	if (f.v2 != null) removeFromArray(f.v2.faces, f);
	if (f.v3 != null) removeFromArray(f.v3.faces, f);

	// TODO optimize this!
	var vs:Array<Vertex> = [f.v1, f.v2, f.v3];
	for (i in 0...3) {
		var v1 = vs[i];
		var v2 = vs[(i + 1) % 3];
		if (v1 == null || v2 == null) continue;
		v1.removeIfNonNeighbor(v2);
		v2.removeIfNonNeighbor(v1);
	}
}

function collapse(vertices:Array<Vertex>, faces:Array<Triangle>, u:Vertex, v:Vertex) {
	// Collapse the edge uv by moving vertex u onto v
	trace("collapse " + u + " " + v);
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
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null && u.faces[i].hasVertex(v)) {
			removeFace(u.faces[i], faces);
		}
	}

	// update remaining triangles to have v instead of u
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null) u.faces[i].replaceVertex(u, v);
	}

	removeVertex(u, vertices);

	// recompute the edge collapse costs in neighborhood
	for (i in 0...tmpVertices.length) {
		computeEdgeCostAtVertex(tmpVertices[i]);
	}
}

function minimumCostEdge(vertices:Array<Vertex>) {
	// O(n * n) approach. TODO optimize this
	var least = vertices[0];
	for (i in 0...vertices.length) {
		if (vertices[i].collapseCost < least.collapseCost) {
			least = vertices[i];
		}
	}
	return least;
}

// we use a triangle class to represent structure of face slightly differently
class Triangle {

	public var a:Int;
	public var b:Int;
	public var c:Int;

	public var v1:Vertex;
	public var v2:Vertex;
	public var v3:Vertex;

	public var normal:Vector3;

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

	public function computeNormal() {
		var vA = this.v1.position;
		var vB = this.v2.position;
		var vC = this.v3.position;
		var _cb = new Vector3();
		var _ab = new Vector3();
		_cb.subVectors(vC, vB);
		_ab.subVectors(vA, vB);
		_cb.cross(_ab).normalize();
		this.normal.copy(_cb);
	}

	public function hasVertex(v:Vertex) {
		return v == this.v1 || v == this.v2 || v == this.v3;
	}

	public function replaceVertex(oldv:Vertex, newv:Vertex) {
		trace("replaceVertex " + oldv + " " + newv);
		if (oldv == this.v1) this.v1 = newv;
		else if (oldv == this.v2) this.v2 = newv;
		else if (oldv == this.v3) this.v3 = newv;

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

	public var position:Vector3;
	public var uv:Vector2;
	public var normal:Vector3;
	public var tangent:Vector4;
	public var color:three.math.Color;

	public var id:Int = -1; // external use position in vertices list (for e.g. face generation)
	public var faces:Array<Triangle> = []; // faces vertex is connected
	public var neighbors:Array<Vertex> = []; // neighbouring vertices aka "adjacentVertices"

	// these will be computed in computeEdgeCostAtVertex()
	public var collapseCost:Float = 0; // cost of collapsing this vertex, the less the better. aka objdist
	public var collapseNeighbor:Vertex = null; // best candinate for collapsing
	public var minCost:Float = 0;
	public var totalCost:Float = 0;
	public var costCount:Int = 0;

	public function new(v:Vector3, uv:Vector2, normal:Vector3, tangent:Vector4, color:three.math.Color) {
		this.position = v;
		this.uv = uv;
		this.normal = normal;
		this.tangent = tangent;
		this.color = color;
	}

	public function addUniqueNeighbor(vertex:Vertex) {
		pushIfUnique(this.neighbors, vertex);
	}

	public function removeIfNonNeighbor(n:Vertex) {
		var neighbors = this.neighbors;
		var faces = this.faces;
		var offset = neighbors.indexOf(n);
		if (offset == -1) return;
		for (i in 0...faces.length) {
			if (faces[i].hasVertex(n)) return;
		}
		neighbors.splice(offset, 1);
	}

	public function toString() {
		return "Vertex(${position})";
	}
}

class SimplifyModifier {

	public function new() {}

	public function modify(geometry:BufferGeometry, count:Int):BufferGeometry {

		geometry = geometry.clone();

		// currently morphAttributes are not supported
		delete geometry.morphAttributes.position;
		delete geometry.morphAttributes.normal;
		var attributes = geometry.attributes;

		// this modifier can only process indexed and non-indexed geomtries with at least a position attribute
		for (name in attributes) {
			if (name != "position" && name != "uv" && name != "normal" && name != "tangent" && name != "color") {
				geometry.deleteAttribute(name);
			}
		}

		geometry = BufferGeometryUtils.mergeVertices(geometry);

		//
		// put data of original geometry in different data structures
		//

		var vertices:Array<Vertex> = [];
		var faces:Array<Triangle> = [];

		// add vertices
		var positionAttribute = geometry.getAttribute("position");
		var uvAttribute = geometry.getAttribute("uv");
		var normalAttribute = geometry.getAttribute("normal");
		var tangentAttribute = geometry.getAttribute("tangent");
		var colorAttribute = geometry.getAttribute("color");
		var t:Vector4 = null;
		var v2:Vector2 = null;
		var nor:Vector3 = null;
		var col:three.math.Color = null;
		for (i in 0...positionAttribute.count) {
			var v = new Vector3().fromBufferAttribute(positionAttribute, i);
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
				col = three.math.Color.fromBufferAttribute(colorAttribute, i);
			}
			var vertex = new Vertex(v, v2, nor, t, col);
			vertices.push(vertex);
		}

		// add faces
		var index = geometry.getIndex();
		if (index != null) {
			for (i in 0...index.count) {
				if (i % 3 == 0) {
					var a = index.getX(i);
					var b = index.getX(i + 1);
					var c = index.getX(i + 2);
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		} else {
			for (i in 0...positionAttribute.count) {
				if (i % 3 == 0) {
					var a = i;
					var b = i + 1;
					var c = i + 2;
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		}

		// compute all edge collapse costs
		for (i in 0...vertices.length) {
			computeEdgeCostAtVertex(vertices[i]);
		}

		var nextVertex:Vertex;
		var z = count;
		while (z > 0) {
			nextVertex = minimumCostEdge(vertices);
			if (nextVertex == null) {
				trace("THREE.SimplifyModifier: No next vertex");
				break;
			}
			collapse(vertices, faces, nextVertex, nextVertex.collapseNeighbor);
			z--;
		}

		//

		var simplifiedGeometry = new BufferGeometry();
		var position:Array<Float> = [];
		var uv:Array<Float> = [];
		var normal:Array<Float> = [];
		var tangent:Array<Float> = [];
		var color:Array<Float> = [];
		var index:Array<Int> = [];

		//

		for (i in 0...vertices.length) {
			var vertex = vertices[i];
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

			// cache final index to GREATLY speed up faces reconstruction
			vertex.id = i;
		}

		//

		for (i in 0...faces.length) {
			var face = faces[i];
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

function pushIfUnique(array:Array<Dynamic>, object:Dynamic) {
	if (array.indexOf(object) == -1) array.push(object);
}

function removeFromArray(array:Array<Dynamic>, object:Dynamic) {
	var k = array.indexOf(object);
	if (k > -1) array.splice(k, 1);
}

function computeEdgeCollapseCost(u:Vertex, v:Vertex) {
	// if we collapse edge uv by moving u to v then how
	// much different will the model change, i.e. the "error".

	var edgelength = v.position.distanceTo(u.position);
	var curvature = 0;

	var sideFaces:Array<Triangle> = [];

	// find the "sides" triangles that are on the edge uv
	for (i in 0...u.faces.length) {
		var face = u.faces[i];
		if (face.hasVertex(v)) {
			sideFaces.push(face);
		}
	}

	// use the triangle facing most away from the sides
	// to determine our curvature term
	for (i in 0...u.faces.length) {
		var minCurvature = 1;
		var face = u.faces[i];
		for (j in 0...sideFaces.length) {
			var sideFace = sideFaces[j];
			// use dot product of face normals.
			var dotProd = face.normal.dot(sideFace.normal);
			minCurvature = Math.min(minCurvature, (1.001 - dotProd) / 2);
		}
		curvature = Math.max(curvature, minCurvature);
	}

	// crude approach in attempt to preserve borders
	// though it seems not to be totally correct
	var borders = 0;
	if (sideFaces.length < 2) {
		// we add some arbitrary cost for borders,
		// borders += 10;
		curvature = 1;
	}

	var amt = edgelength * curvature + borders;
	return amt;
}

function computeEdgeCostAtVertex(v:Vertex) {
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

	v.collapseCost = 100000;
	v.collapseNeighbor = null;

	// search all neighboring edges for "least cost" edge
	for (i in 0...v.neighbors.length) {
		var collapseCost = computeEdgeCollapseCost(v, v.neighbors[i]);
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

function removeVertex(v:Vertex, vertices:Array<Vertex>) {
	trace("removeVertex " + v);
	assert(v.faces.length == 0);
	while (v.neighbors.length > 0) {
		var n = v.neighbors.pop();
		removeFromArray(n.neighbors, v);
	}
	removeFromArray(vertices, v);
}

function removeFace(f:Triangle, faces:Array<Triangle>) {
	trace("removeFace " + f);
	removeFromArray(faces, f);
	if (f.v1 != null) removeFromArray(f.v1.faces, f);
	if (f.v2 != null) removeFromArray(f.v2.faces, f);
	if (f.v3 != null) removeFromArray(f.v3.faces, f);

	// TODO optimize this!
	var vs:Array<Vertex> = [f.v1, f.v2, f.v3];
	for (i in 0...3) {
		var v1 = vs[i];
		var v2 = vs[(i + 1) % 3];
		if (v1 == null || v2 == null) continue;
		v1.removeIfNonNeighbor(v2);
		v2.removeIfNonNeighbor(v1);
	}
}

function collapse(vertices:Array<Vertex>, faces:Array<Triangle>, u:Vertex, v:Vertex) {
	// Collapse the edge uv by moving vertex u onto v
	trace("collapse " + u + " " + v);
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
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null && u.faces[i].hasVertex(v)) {
			removeFace(u.faces[i], faces);
		}
	}

	// update remaining triangles to have v instead of u
	for (i in 0...u.faces.length) {
		if (u.faces[i] != null) u.faces[i].replaceVertex(u, v);
	}

	removeVertex(u, vertices);

	// recompute the edge collapse costs in neighborhood
	for (i in 0...tmpVertices.length) {
		computeEdgeCostAtVertex(tmpVertices[i]);
	}
}

function minimumCostEdge(vertices:Array<Vertex>) {
	// O(n * n) approach. TODO optimize this
	var least = vertices[0];
	for (i in 0...vertices.length) {
		if (vertices[i].collapseCost < least.collapseCost) {
			least = vertices[i];
		}
	}
	return least;
}

// we use a triangle class to represent structure of face slightly differently
class Triangle {

	public var a:Int;
	public var b:Int;
	public var c:Int;

	public var v1:Vertex;
	public var v2:Vertex;
	public var v3:Vertex;

	public var normal:Vector3;

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

	public function computeNormal() {
		var vA = this.v1.position;
		var vB = this.v2.position;
		var vC = this.v3.position;
		var _cb = new Vector3();
		var _ab = new Vector3();
		_cb.subVectors(vC, vB);
		_ab.subVectors(vA, vB);
		_cb.cross(_ab).normalize();
		this.normal.copy(_cb);
	}

	public function hasVertex(v:Vertex) {
		return v == this.v1 || v == this.v2 || v == this.v3;
	}

	public function replaceVertex(oldv:Vertex, newv:Vertex) {
		trace("replaceVertex " + oldv + " " + newv);
		if (oldv == this.v1) this.v1 = newv;
		else if (oldv == this.v2) this.v2 = newv;
		else if (oldv == this.v3) this.v3 = newv;

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

	public var position:Vector3;
	public var uv:Vector2;
	public var normal:Vector3;
	public var tangent:Vector4;
	public var color:three.math.Color;

	public var id:Int = -1; // external use position in vertices list (for e.g. face generation)
	public var faces:Array<Triangle> = []; // faces vertex is connected
	public var neighbors:Array<Vertex> = []; // neighbouring vertices aka "adjacentVertices"

	// these will be computed in computeEdgeCostAtVertex()
	public var collapseCost:Float = 0; // cost of collapsing this vertex, the less the better. aka objdist
	public var collapseNeighbor:Vertex = null; // best candinate for collapsing
	public var minCost:Float = 0;
	public var totalCost:Float = 0;
	public var costCount:Int = 0;

	public function new(v:Vector3, uv:Vector2, normal:Vector3, tangent:Vector4, color:three.math.Color) {
		this.position = v;
		this.uv = uv;
		this.normal = normal;
		this.tangent = tangent;
		this.color = color;
	}

	public function addUniqueNeighbor(vertex:Vertex) {
		pushIfUnique(this.neighbors, vertex);
	}

	public function removeIfNonNeighbor(n:Vertex) {
		var neighbors = this.neighbors;
		var faces = this.faces;
		var offset = neighbors.indexOf(n);
		if (offset == -1) return;
		for (i in 0...faces.length) {
			if (faces[i].hasVertex(n)) return;
		}
		neighbors.splice(offset, 1);
	}

	public function toString() {
		return "Vertex(${position})";
	}
}

class SimplifyModifier {

	public function new() {}

	public function modify(geometry:BufferGeometry, count:Int):BufferGeometry {

		geometry = geometry.clone();

		// currently morphAttributes are not supported
		delete geometry.morphAttributes.position;
		delete geometry.morphAttributes.normal;
		var attributes = geometry.attributes;

		// this modifier can only process indexed and non-indexed geomtries with at least a position attribute
		for (name in attributes) {
			if (name != "position" && name != "uv" && name != "normal" && name != "tangent" && name != "color") {
				geometry.deleteAttribute(name);
			}
		}

		geometry = BufferGeometryUtils.mergeVertices(geometry);

		//
		// put data of original geometry in different data structures
		//

		var vertices:Array<Vertex> = [];
		var faces:Array<Triangle> = [];

		// add vertices
		var positionAttribute = geometry.getAttribute("position");
		var uvAttribute = geometry.getAttribute("uv");
		var normalAttribute = geometry.getAttribute("normal");
		var tangentAttribute = geometry.getAttribute("tangent");
		var colorAttribute = geometry.getAttribute("color");
		var t:Vector4 = null;
		var v2:Vector2 = null;
		var nor:Vector3 = null;
		var col:three.math.Color = null;
		for (i in 0...positionAttribute.count) {
			var v = new Vector3().fromBufferAttribute(positionAttribute, i);
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
				col = three.math.Color.fromBufferAttribute(colorAttribute, i);
			}
			var vertex = new Vertex(v, v2, nor, t, col);
			vertices.push(vertex);
		}

		// add faces
		var index = geometry.getIndex();
		if (index != null) {
			for (i in 0...index.count) {
				if (i % 3 == 0) {
					var a = index.getX(i);
					var b = index.getX(i + 1);
					var c = index.getX(i + 2);
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		} else {
			for (i in 0...positionAttribute.count) {
				if (i % 3 == 0) {
					var a = i;
					var b = i + 1;
					var c = i + 2;
					var triangle = new Triangle(vertices[a], vertices[b], vertices[c], a, b, c);
					faces.push(triangle);
				}
			}
		}

		// compute all edge collapse costs
		for (i in 0...vertices.length) {
			computeEdgeCostAtVertex(vertices[i]);
		}

		var nextVertex:Vertex;
		var z = count;
		while (z > 0) {
			nextVertex = minimumCostEdge(vertices);
			if (nextVertex == null) {
				trace("THREE.SimplifyModifier: No next vertex");
				break;
			}
			collapse(vertices, faces, nextVertex, nextVertex.collapseNeighbor);
			z--;
		}

		//

		var simplifiedGeometry = new BufferGeometry();
		var position:Array<Float> = [];
		var uv:Array<Float> = [];
		var normal:Array<Float> = [];
		var tangent:Array<Float> = [];
		var color:Array<Float> = [];
		var index:Array<Int> = [];

		//

		for (i in 0...vertices.length) {
			var vertex = vertices[i];
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

			// cache final index to GREATLY speed up faces reconstruction
			vertex.id = i;
		}

		//

		for (i in 0...faces.length) {
			var face = faces[i];
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

function pushIfUnique(array:Array<Dynamic>, object:Dynamic) {
	if (array.indexOf(object) == -1) array.push(object);
}

function removeFromArray(array:Array<Dynamic>, object:Dynamic) {
	var k = array.indexOf(object);
	if (k > -1) array.splice(k, 1);
}

function computeEdgeCollapseCost(u:Vertex, v:Vertex) {
	// if we collapse edge uv by moving u to v then how
	// much different will the model change, i.e. the "error".

	var edgelength = v.position.distanceTo(u.position);
	var curvature = 0;

	var sideFaces:Array<Triangle> = [];

	// find the "sides" triangles that are on the edge uv
	for (i in 0...u.faces.length) {
		var face = u.faces[i];
		if (face.hasVertex(v)) {
			sideFaces.push(face);
		}
	}

	// use the triangle facing most away from the sides
	// to determine our curvature term
	for (i in 0...u.faces.length) {
		var minCurvature = 1;
		var face = u.faces[i];
		for (j in 0...sideFaces.length) {
			var sideFace = sideFaces[j];
			// use dot product of face normals.
			var dotProd = face.normal.dot(sideFace.normal);
			minCurvature = Math.min(minCurvature, (1.001 - dotProd) / 2);
		}
		curvature = Math.max(curvature, minCurvature);
	}

	// crude approach in attempt to preserve borders
	// though it seems not to be totally correct
	var borders = 0;
	if (sideFaces.length < 2) {
		// we add some arbitrary cost for borders,
		// borders += 10;
		curvature = 1;
	}

	var amt = edgelength * curvature + borders;
	return amt;
}

function computeEdgeCostAtVertex(v:Vertex) {
	// compute the edge collapse cost for all edges that start
	// from vertex v.  Since we are only interested in reducing
	// the object by selecting the min cost edge at each step, we
	// only cache the cost of the least cost edge at this vertex
	// (in member variable collapse) as well as the value of the
	// cost (in member variable collapseCost