package extras;

import three.math.Vector2;

/**
 * Port from https://github.com/mapbox/earcut (v2.2.4)
 */
class Earcut {

	public static function triangulate(data:Array<Float>, holeIndices:Array<Int> = null, dim:Int = 2):Array<Int> {

		var hasHoles = holeIndices != null && holeIndices.length > 0;
		var outerLen = hasHoles ? holeIndices[0] * dim : data.length;
		var outerNode = linkedList(data, 0, outerLen, dim, true);
		var triangles = new Array<Int>();

		if (outerNode == null || outerNode.next == outerNode.prev) return triangles;

		var minX:Float, minY:Float, maxX:Float, maxY:Float, x:Float, y:Float, invSize:Float;

		if (hasHoles) outerNode = eliminateHoles(data, holeIndices, outerNode, dim);

		// if the shape is not too simple, we'll use z-order curve hash later; calculate polygon bbox
		if (data.length > 80 * dim) {

			minX = maxX = data[0];
			minY = maxY = data[1];

			for (i in dim...outerLen) {

				x = data[i];
				y = data[i + 1];
				if (x < minX) minX = x;
				if (y < minY) minY = y;
				if (x > maxX) maxX = x;
				if (y > maxY) maxY = y;

			}

			// minX, minY and invSize are later used to transform coords into integers for z-order calculation
			invSize = Math.max(maxX - minX, maxY - minY);
			invSize = invSize != 0 ? 32767 / invSize : 0;

		}

		earcutLinked(outerNode, triangles, dim, minX, minY, invSize, 0);

		return triangles;

	}

}

// create a circular doubly linked list from polygon points in the specified winding order
function linkedList(data:Array<Float>, start:Int, end:Int, dim:Int, clockwise:Bool):Node {

	var i:Int, last:Node;

	if (clockwise == (signedArea(data, start, end, dim) > 0)) {

		for (i in start...end) last = insertNode(i, data[i], data[i + 1], last);

	} else {

		for (i in (end - dim)...start) last = insertNode(i, data[i], data[i + 1], last);

	}

	if (last != null && equals(last, last.next)) {

		removeNode(last);
		last = last.next;

	}

	return last;

}

// eliminate colinear or duplicate points
function filterPoints(start:Node, end:Node):Node {

	if (start == null) return start;
	if (end == null) end = start;

	var p:Node = start,
		again:Bool;
	do {

		again = false;

		if (!p.steiner && (equals(p, p.next) || area(p.prev, p, p.next) == 0)) {

			removeNode(p);
			p = end = p.prev;
			if (p == p.next) break;
			again = true;

		} else {

			p = p.next;

		}

	} while (again || p != end);

	return end;

}

// main ear slicing loop which triangulates a polygon (given as a linked list)
function earcutLinked(ear:Node, triangles:Array<Int>, dim:Int, minX:Float, minY:Float, invSize:Float, pass:Int) {

	if (ear == null) return;

	// interlink polygon nodes in z-order
	if (pass == 0 && invSize != 0) indexCurve(ear, minX, minY, invSize);

	var stop:Node = ear,
		prev:Node, next:Node;

	// iterate through ears, slicing them one by one
	while (ear.prev != ear.next) {

		prev = ear.prev;
		next = ear.next;

		if (invSize != 0 ? isEarHashed(ear, minX, minY, invSize) : isEar(ear)) {

			// cut off the triangle
			triangles.push(prev.i ~/ dim);
			triangles.push(ear.i ~/ dim);
			triangles.push(next.i ~/ dim);

			removeNode(ear);

			// skipping the next vertex leads to less sliver triangles
			ear = next.next;
			stop = next.next;

			continue;

		}

		ear = next;

		// if we looped through the whole remaining polygon and can't find any more ears
		if (ear == stop) {

			// try filtering points and slicing again
			if (pass == 0) {

				earcutLinked(filterPoints(ear), triangles, dim, minX, minY, invSize, 1);

				// if this didn't work, try curing all small self-intersections locally

			} else if (pass == 1) {

				ear = cureLocalIntersections(filterPoints(ear), triangles, dim);
				earcutLinked(ear, triangles, dim, minX, minY, invSize, 2);

				// as a last resort, try splitting the remaining polygon into two

			} else if (pass == 2) {

				splitEarcut(ear, triangles, dim, minX, minY, invSize);

			}

			break;

		}

	}

}

// check whether a polygon node forms a valid ear with adjacent nodes
function isEar(ear:Node):Bool {

	var a:Node = ear.prev,
		b:Node = ear,
		c:Node = ear.next;

	if (area(a, b, c) >= 0) return false; // reflex, can't be an ear

	// now make sure we don't have other points inside the potential ear
	var ax:Float = a.x, bx:Float = b.x, cx:Float = c.x, ay:Float = a.y, by:Float = b.y, cy:Float = c.y;

	// triangle bbox; min & max are calculated like this for speed
	var x0:Float = ax < bx ? (ax < cx ? ax : cx) : (bx < cx ? bx : cx),
		y0:Float = ay < by ? (ay < cy ? ay : cy) : (by < cy ? by : cy),
		x1:Float = ax > bx ? (ax > cx ? ax : cx) : (bx > cx ? bx : cx),
		y1:Float = ay > by ? (ay > cy ? ay : cy) : (by > cy ? by : cy);

	var p:Node = c.next;
	while (p != a) {

		if (p.x >= x0 && p.x <= x1 && p.y >= y0 && p.y <= y1 &&
			pointInTriangle(ax, ay, bx, by, cx, cy, p.x, p.y) &&
			area(p.prev, p, p.next) >= 0) return false;
		p = p.next;

	}

	return true;

}

function isEarHashed(ear:Node, minX:Float, minY:Float, invSize:Float):Bool {

	var a:Node = ear.prev,
		b:Node = ear,
		c:Node = ear.next;

	if (area(a, b, c) >= 0) return false; // reflex, can't be an ear

	var ax:Float = a.x, bx:Float = b.x, cx:Float = c.x, ay:Float = a.y, by:Float = b.y, cy:Float = c.y;

	// triangle bbox; min & max are calculated like this for speed
	var x0:Float = ax < bx ? (ax < cx ? ax : cx) : (bx < cx ? bx : cx),
		y0:Float = ay < by ? (ay < cy ? ay : cy) : (by < cy ? by : cy),
		x1:Float = ax > bx ? (ax > cx ? ax : cx) : (bx > cx ? bx : cx),
		y1:Float = ay > by ? (ay > cy ? ay : cy) : (by > cy ? by : cy);

	// z-order range for the current triangle bbox;
	var minZ:Int = zOrder(x0, y0, minX, minY, invSize),
		maxZ:Int = zOrder(x1, y1, minX, minY, invSize);

	var p:Node = ear.prevZ,
		n:Node = ear.nextZ;

	// look for points inside the triangle in both directions
	while (p != null && p.z >= minZ && n != null && n.z <= maxZ) {

		if (p.x >= x0 && p.x <= x1 && p.y >= y0 && p.y <= y1 && p != a && p != c &&
			pointInTriangle(ax, ay, bx, by, cx, cy, p.x, p.y) && area(p.prev, p, p.next) >= 0) return false;
		p = p.prevZ;

		if (n.x >= x0 && n.x <= x1 && n.y >= y0 && n.y <= y1 && n != a && n != c &&
			pointInTriangle(ax, ay, bx, by, cx, cy, n.x, n.y) && area(n.prev, n, n.next) >= 0) return false;
		n = n.nextZ;

	}

	// look for remaining points in decreasing z-order
	while (p != null && p.z >= minZ) {

		if (p.x >= x0 && p.x <= x1 && p.y >= y0 && p.y <= y1 && p != a && p != c &&
			pointInTriangle(ax, ay, bx, by, cx, cy, p.x, p.y) && area(p.prev, p, p.next) >= 0) return false;
		p = p.prevZ;

	}

	// look for remaining points in increasing z-order
	while (n != null && n.z <= maxZ) {

		if (n.x >= x0 && n.x <= x1 && n.y >= y0 && n.y <= y1 && n != a && n != c &&
			pointInTriangle(ax, ay, bx, by, cx, cy, n.x, n.y) && area(n.prev, n, n.next) >= 0) return false;
		n = n.nextZ;

	}

	return true;

}

// go through all polygon nodes and cure small local self-intersections
function cureLocalIntersections(start:Node, triangles:Array<Int>, dim:Int):Node {

	var p:Node = start;
	do {

		var a:Node = p.prev,
			b:Node = p.next.next;

		if (!equals(a, b) && intersects(a, p, p.next, b) && locallyInside(a, b) && locallyInside(b, a)) {

			triangles.push(a.i ~/ dim);
			triangles.push(p.i ~/ dim);
			triangles.push(b.i ~/ dim);

			// remove two nodes involved
			removeNode(p);
			removeNode(p.next);

			p = start = b;

		}

		p = p.next;

	} while (p != start);

	return filterPoints(p);

}

// try splitting polygon into two and triangulate them independently
function splitEarcut(start:Node, triangles:Array<Int>, dim:Int, minX:Float, minY:Float, invSize:Float) {

	// look for a valid diagonal that divides the polygon into two
	var a:Node = start;
	do {

		var b:Node = a.next.next;
		while (b != a.prev) {

			if (a.i != b.i && isValidDiagonal(a, b)) {

				// split the polygon in two by the diagonal
				var c:Node = splitPolygon(a, b);

				// filter colinear points around the cuts
				a = filterPoints(a, a.next);
				c = filterPoints(c, c.next);

				// run earcut on each half
				earcutLinked(a, triangles, dim, minX, minY, invSize, 0);
				earcutLinked(c, triangles, dim, minX, minY, invSize, 0);
				return;

			}

			b = b.next;

		}

		a = a.next;

	} while (a != start);

}

// link every hole into the outer loop, producing a single-ring polygon without holes
function eliminateHoles(data:Array<Float>, holeIndices:Array<Int>, outerNode:Node, dim:Int):Node {

	var queue = new Array<Node>();
	var i:Int, len:Int, start:Int, end:Int, list:Node;

	for (i in 0...holeIndices.length) {

		start = holeIndices[i] * dim;
		end = i < holeIndices.length - 1 ? holeIndices[i + 1] * dim : data.length;
		list = linkedList(data, start, end, dim, false);
		if (list == list.next) list.steiner = true;
		queue.push(getLeftmost(list));

	}

	queue.sort(compareX);

	// process holes from left to right
	for (i in 0...queue.length) {

		outerNode = eliminateHole(queue[i], outerNode);

	}

	return outerNode;

}

function compareX(a:Node, b:Node):Int {

	return (a.x - b.x).toInt();

}

// find a bridge between vertices that connects hole with an outer ring and link it
function eliminateHole(hole:Node, outerNode:Node):Node {

	var bridge:Node = findHoleBridge(hole, outerNode);
	if (bridge == null) {

		return outerNode;

	}

	var bridgeReverse:Node = splitPolygon(bridge, hole);

	// filter collinear points around the cuts
	filterPoints(bridgeReverse, bridgeReverse.next);
	return filterPoints(bridge, bridge.next);

}

// David Eberly's algorithm for finding a bridge between hole and outer polygon
function findHoleBridge(hole:Node, outerNode:Node):Node {

	var p:Node = outerNode,
		qx:Float = -Math.POSITIVE_INFINITY,
		m:Node;

	var hx:Float = hole.x, hy:Float = hole.y;

	// find a segment intersected by a ray from the hole's leftmost point to the left;
	// segment's endpoint with lesser x will be potential connection point
	do {

		if (hy <= p.y && hy >= p.next.y && p.next.y != p.y) {

			var x:Float = p.x + (hy - p.y) * (p.next.x - p.x) / (p.next.y - p.y);
			if (x <= hx && x > qx) {

				qx = x;
				m = p.x < p.next.x ? p : p.next;
				if (x == hx) return m; // hole touches outer segment; pick leftmost endpoint

			}

		}

		p = p.next;

	} while (p != outerNode);

	if (m == null) return null;

	// look for points inside the triangle of hole point, segment intersection and endpoint;
	// if there are no points found, we have a valid connection;
	// otherwise choose the point of the minimum angle with the ray as connection point

	var stop:Node = m,
		mx:Float = m.x,
		my:Float = m.y;
	var tanMin:Float = Math.POSITIVE_INFINITY, tan:Float;

	p = m;

	do {

		if (hx >= p.x && p.x >= mx && hx != p.x &&
				pointInTriangle(hy < my ? hx : qx, hy, mx, my, hy < my ? qx : hx, hy, p.x, p.y)) {

			tan = Math.abs(hy - p.y) / (hx - p.x); // tangential

			if (locallyInside(p, hole) && (tan < tanMin || (tan == tanMin && (p.x > m.x || (p.x == m.x && sectorContainsSector(m, p)))))) {

				m = p;
				tanMin = tan;

			}

		}

		p = p.next;

	} while (p != stop);

	return m;

}

// whether sector in vertex m contains sector in vertex p in the same coordinates
function sectorContainsSector(m:Node, p:Node):Bool {

	return area(m.prev, m, p.prev) < 0 && area(p.next, m, m.next) < 0;

}

// interlink polygon nodes in z-order
function indexCurve(start:Node, minX:Float, minY:Float, invSize:Float) {

	var p:Node = start;
	do {

		if (p.z == 0) p.z = zOrder(p.x, p.y, minX, minY, invSize);
		p.prevZ = p.prev;
		p.nextZ = p.next;
		p = p.next;

	} while (p != start);

	p.prevZ.nextZ = null;
	p.prevZ = null;

	sortLinked(p);

}

// Simon Tatham's linked list merge sort algorithm
// http://www.chiark.greenend.org.uk/~sgtatham/algorithms/listsort.html
function sortLinked(list:Node):Node {

	var i:Int, p:Node, q:Node, e:Node, tail:Node, numMerges:Int, pSize:Int, qSize:Int,
		inSize:Int = 1;

	do {

		p = list;
		list = null;
		tail = null;
		numMerges = 0;

		while (p != null) {

			numMerges++;
			q = p;
			pSize = 0;
			for (i in 0...inSize) {

				pSize++;
				q = q.nextZ;
				if (q == null) break;

			}

			qSize = inSize;

			while (pSize > 0 || (qSize > 0 && q != null)) {

				if (pSize != 0 && (qSize == 0 || q == null || p.z <= q.z)) {

					e = p;
					p = p.nextZ;
					pSize--;

				} else {

					e = q;
					q = q.nextZ;
					qSize--;

				}

				if (tail != null) tail.nextZ = e;
				else list = e;

				e.prevZ = tail;
				tail = e;

			}

			p = q;

		}

		tail.nextZ = null;
		inSize *= 2;

	} while (numMerges > 1);

	return list;

}

// z-order of a point given coords and inverse of the longer side of data bbox
function zOrder(x:Float, y:Float, minX:Float, minY:Float, invSize:Float):Int {

	// coords are transformed into non-negative 15-bit integer range
	x = (x - minX) * invSize | 0;
	y = (y - minY) * invSize | 0;

	x = (x | (x << 8)) & 0x00FF00FF;
	x = (x | (x << 4)) & 0x0F0F0F0F;
	x = (x | (x << 2)) & 0x33333333;
	x = (x | (x << 1)) & 0x55555555;

	y = (y | (y << 8)) & 0x00FF00FF;
	y = (y | (y << 4)) & 0x0F0F0F0F;
	y = (y | (y << 2)) & 0x33333333;
	y = (y | (y << 1)) & 0x55555555;

	return x | (y << 1);

}

// find the leftmost node of a polygon ring
function getLeftmost(start:Node):Node {

	var p:Node = start,
		leftmost:Node = start;
	do {

		if (p.x < leftmost.x || (p.x == leftmost.x && p.y < leftmost.y)) leftmost = p;
		p = p.next;

	} while (p != start);

	return leftmost;

}

// check if a point lies within a convex triangle
function pointInTriangle(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float, px:Float, py:Float):Bool {

	return (cx - px) * (ay - py) >= (ax - px) * (cy - py) &&
           (ax - px) * (by - py) >= (bx - px) * (ay - py) &&
           (bx - px) * (cy - py) >= (cx - px) * (by - py);

}

// check if a diagonal between two polygon nodes is valid (lies in polygon interior)
function isValidDiagonal(a:Node, b:Node):Bool {

	return a.next.i != b.i && a.prev.i != b.i && !intersectsPolygon(a, b) && // dones't intersect other edges
           (locallyInside(a, b) && locallyInside(b, a) && middleInside(a, b) && // locally visible
            (area(a.prev, a, b.prev) || area(a, b.prev, b)) || // does not create opposite-facing sectors
            equals(a, b) && area(a.prev, a, a.next) > 0 && area(b.prev, b, b.next) > 0); // special zero-length case

}

// signed area of a triangle
function area(p:Node, q:Node, r:Node):Float {

	return (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);

}

// check if two points are equal
function equals(p1:Node, p2:Node):Bool {

	return p1.x == p2.x && p1.y == p2.y;

}

// check if two segments intersect
function intersects(p1:Node, q1:Node, p2:Node, q2:Node):Bool {

	var o1:Int = sign(area(p1, q1, p2));
	var o2:Int = sign(area(p1, q1, q2));
	var o3:Int = sign(area(p2, q2, p1));
	var o4:Int = sign(area(p2, q2, q1));

	if (o1 != o2 && o3 != o4) return true; // general case

	if (o1 == 0 && onSegment(p1, p2, q1)) return true; // p1, q1 and p2 are collinear and p2 lies on p1q1
	if (o2 == 0 && onSegment(p1, q2, q1)) return true; // p1, q1 and q2 are collinear and q2 lies on p1q1
	if (o3 == 0 && onSegment(p2, p1, q2)) return true; // p2, q2 and p1 are collinear and p1 lies on p2q2
	if (o4 == 0 && onSegment(p2, q1, q2)) return true; // p2, q2 and q1 are collinear and q1 lies on p2q2

	return false;

}

// for collinear points p, q, r, check if point q lies on segment pr
function onSegment(p:Node, q:Node, r:Node):Bool {

	return q.x <= Math.max(p.x, r.x) && q.x >= Math.min(p.x, r.x) && q.y <= Math.max(p.y, r.y) && q.y >= Math.min(p.y, r.y);

}

function sign(num:Float):Int {

	return if (num > 0) 1 else if (num < 0) -1 else 0;

}

// check if a polygon diagonal intersects any polygon segments
function intersectsPolygon(a:Node, b:Node):Bool {

	var p:Node = a;
	do {

		if (p.i != a.i && p.next.i != a.i && p.i != b.i && p.next.i != b.i &&
			intersects(p, p.next, a, b)) return true;
		p = p.next;

	} while (p != a);

	return false;

}

// check if a polygon diagonal is locally inside the polygon
function locallyInside(a:Node, b:Node):Bool {

	return area(a.prev, a, a.next) < 0 ?
		area(a, b, a.next) >= 0 && area(a, a.prev, b) >= 0 :
		area(a, b, a.prev) < 0 || area(a, a.next, b) < 0;

}

// check if the middle point of a polygon diagonal is inside the polygon
function middleInside(a:Node, b:Node):Bool {

	var p:Node = a,
		inside:Bool = false;
	var px:Float = (a.x + b.x) / 2,
		py:Float = (a.y + b.y) / 2;
	do {

		if ( ( (p.y > py) != (p.next.y > py) ) && p.next.y != p.y &&
			(px < (p.next.x - p.x) * (py - p.y) / (p.next.y - p.y) + p.x))
			inside = !inside;
		p = p.next;

	} while (p != a);

	return inside;

}

// link two polygon vertices with a bridge; if the vertices belong to the same ring, it splits polygon into two;
// if one belongs to the outer ring and another to a hole, it merges it into a single ring
function splitPolygon(a:Node, b:Node):Node {

	var a2:Node = new Node(a.i, a.x, a.y),
		b2:Node = new Node(b.i, b.x, b.y),
		an:Node = a.next,
		bp:Node = b.prev;

	a.next = b;
	b.prev = a;

	a2.next = an;
	an.prev = a2;

	b2.next = a2;
	a2.prev = b2;

	bp.next = b2;
	b2.prev = bp;

	return b2;

}

// create a node and optionally link it with previous one (in a circular doubly linked list)
function insertNode(i:Int, x:Float, y:Float, last:Node):Node {

	var p:Node = new Node(i, x, y);

	if (last == null) {

		p.prev = p;
		p.next = p;

	} else {

		p.next = last.next;
		p.prev = last;
		last.next.prev = p;
		last.next = p;

	}

	return p;

}

function removeNode(p:Node) {

	p.next.prev = p.prev;
	p.prev.next = p.next;

	if (p.prevZ != null) p.prevZ.nextZ = p.nextZ;
	if (p.nextZ != null) p.nextZ.prevZ = p.prevZ;

}

class Node {

	public var i:Int;
	public var x:Float;
	public var y:Float;
	public var prev:Node;
	public var next:Node;
	public var z:Int;
	public var prevZ:Node;
	public var nextZ:Node;
	public var steiner:Bool;

	public function new(i:Int, x:Float, y:Float) {
		this.i = i;
		this.x = x;
		this.y = y;
		this.prev = null;
		this.next = null;
		this.z = 0;
		this.prevZ = null;
		this.nextZ = null;
		this.steiner = false;
	}

}

function signedArea(data:Array<Float>, start:Int, end:Int, dim:Int):Float {

	var sum:Float = 0;
	for (i in start...end) {

		sum += (data[i + dim - 1] - data[i]) * (data[i + 1] + data[i + dim]);

	}

	return sum;

}