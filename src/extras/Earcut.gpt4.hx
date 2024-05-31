Here's the Haxe version of the provided JavaScript code, considering the context and file path `three.js/src/extras/Earcut.js`:

```haxe
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

            for (i in dim...outerLen step dim) {
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

    // create a circular doubly linked list from polygon points in the specified winding order
    static function linkedList(data:Array<Float>, start:Int, end:Int, dim:Int, clockwise:Bool):Node {
        var last:Node = null;

        if (clockwise == (signedArea(data, start, end, dim) > 0)) {
            for (i in start...end step dim) last = insertNode(i, data[i], data[i + 1], last);
        } else {
            for (i in end - dim...start - 1 step -dim) last = insertNode(i, data[i], data[i + 1], last);
        }

        if (last != null && equals(last, last.next)) {
            removeNode(last);
            last = last.next;
        }

        return last;
    }

    // eliminate colinear or duplicate points
    static function filterPoints(start:Node, end:Node = null):Node {
        if (start == null) return start;
        if (end == null) end = start;

        var p = start;
        var again:Bool;
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
    static function earcutLinked(ear:Node, triangles:Array<Int>, dim:Int, minX:Float, minY:Float, invSize:Float, pass:Int):Void {
        if (ear == null) return;

        // interlink polygon nodes in z-order
        if (pass == 0 && invSize != 0) indexCurve(ear, minX, minY, invSize);

        var stop = ear;
        var prev:Node, next:Node;

        // iterate through ears, slicing them one by one
        while (ear.prev != ear.next) {
            prev = ear.prev;
            next = ear.next;

            if (invSize != 0 ? isEarHashed(ear, minX, minY, invSize) : isEar(ear)) {
                // cut off the triangle
                triangles.push(prev.i / dim | 0);
                triangles.push(ear.i / dim | 0);
                triangles.push(next.i / dim | 0);

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
    static function isEar(ear:Node):Bool {
        var a = ear.prev;
        var b = ear;
        var c = ear.next;

        if (area(a, b, c) >= 0) return false; // reflex, can't be an ear

        // now make sure we don't have other points inside the potential ear
        var ax = a.x, bx = b.x, cx = c.x, ay = a.y, by = b.y, cy = c.y;

        // triangle bbox; min & max are calculated like this for speed
        var x0 = Math.min(ax, bx, cx);
        var y0 = Math.min(ay, by, cy);
        var x1 = Math.max(ax, bx, cx);
        var y1 = Math.max(ay, by, cy);

        var p = c.next;
        while (p != a) {
            if (p.x >= x0 && p.x <= x1 && p.y >= y0 && p.y <= y1 &&
                pointInTriangle(ax, ay, bx, by, cx, cy, p.x, p.y) &&
                area(p.prev, p, p.next) >= 0) return false;
            p = p.next;
        }

        return true;
    }

    static function isEarHashed(ear:Node, minX:Float, minY:Float, invSize:Float):Bool {
        var a = ear.prev;
        var b = ear;
        var c = ear.next;

        if (area(a, b, c) >= 0) return false; // reflex, can't be an ear

        var ax = a.x, bx = b.x, cx = c.x, ay = a.y, by = b.y, cy = c.y;

        // triangle bbox; min & max are calculated like this for speed
        var x0 = Math.min(ax, bx, cx);
        var y0 = Math.min(ay, by, cy);
        var x1 = Math.max(ax, bx, cx);
        var y1 = Math.max(ay, by, cy);

        // z-order range for the current triangle bbox;
        var minZ = zOrder(x0, y0, minX, minY, invSize);
        var maxZ = zOrder(x1, y1, minX, minY, invSize);

        var p = ear.prevZ;
        var n = ear.nextZ;

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
    static function cureLocalIntersections(start:Node, triangles:Array<Int>, dim:Int):Node {
        var p = start;
        do {
            var a = p.prev;
            var b = p.next.next;

            if (!equals(a, b) && intersects(a, p, p.next, b) && locallyInside(a, b) && locallyInside(b, a)) {
                triangles.push(a.i / dim | 0);
                triangles.push(p.i / dim | 0);
                triangles.push(b.i / dim | 0);

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
    static function splitEarcut(start:Node, triangles:Array<Int>, dim:Int, minX:Float, minY:Float, invSize:Float):Void {
        // look for a valid diagonal that divides the polygon into two
        var a = start;
        do {
            var b = a.next.next;
            while (b != a.prev) {
                if (a.i != b.i && isValidDiagonal(a, b)) {
                    // split the polygon in two by the diagonal
                    var c = splitPolygon(a, b);

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
    static function eliminateHoles(data:Array<Float>, holeIndices:Array<Int>, outerNode:Node, dim:Int):Node {
        var queue = new Array<Node>();
        var i:Int, len:Int, start:Int, end:Int, list:Node;

        for (i in 0...holeIndices.length) {
            start = holeIndices[i] * dim;
            end = if (i < holeIndices.length - 1) holeIndices[i + 1] * dim else data.length;
            list = linkedList(data, start, end, dim, false);
            if (list == list.next) list.steiner = true;
            queue.push(getLeftmost(list));
        }

        queue.sort(compareX);

        // process holes from left to right
        for (i in 0...queue.length) {
            eliminateHole(queue[i], outerNode);
            outerNode = filterPoints(outerNode, outerNode.next);
        }

        return outerNode;
    }

    // find a bridge between vertices that connects hole with an outer ring and and link it
    static function eliminateHole(hole:Node, outerNode:Node):Void {
        outerNode = findHoleBridge(hole, outerNode);
        if (outerNode != null) {
            var b = splitPolygon(outerNode, hole);

            // filter collinear points around the cuts
            filterPoints(outerNode, outerNode.next);
            filterPoints(b, b.next);
        }
    }

    // David Eberly's algorithm for finding a bridge between hole and outer polygon
    static function findHoleBridge(hole:Node, outerNode:Node):Node {
        var p = outerNode;
        var hx = hole.x;
        var hy = hole.y;
        var qx = -Float.MAX_VALUE;
        var m:Node, mx:Float, my:Float;

        // find a segment intersected by a ray from the hole's leftmost point to the left;
        // segment's endpoint with lesser x will be potential connection point
        do {
            if (hy <= p.y && hy >= p.next.y) {
                var x = p.x + (hy - p.y) * (p.next.x - p.x) / (p.next.y - p.y);
                if (x <= hx && x > qx) {
                    qx = x;
                    if (x == hx) {
                        if (hy == p.y) return p;
                        if (hy == p.next.y) return p.next;
                    }
                    m = if (p.x < p.next.x) p else p.next;
                    mx = p.x;
                    my = p.y;
                }
            }
            p = p.next;
        } while (p != outerNode);

        if (m == null) return null;

        if (hx == qx) return m.prev;

        // look for points inside the triangle of hole point, segment intersection and endpoint;
        // if there are no points found, we have a valid connection;
        // otherwise choose the point of the maximum intersection
        var stop = m;
        var tanMin = Float.MAX_VALUE;
        p = m.next;

        while (p != stop) {
            if (hx >= p.x && p.x >= mx && hx != p.x &&
                pointInTriangle(if (hx < p.x) hx else mx, hy, qx, hy, if (hx < p.x) mx else hx, my, p.x, p.y)) {
                var tan = Math.abs(hy - p.y) / (hx - p.x); // tangential
                if (tan < tanMin) {
                    m = p;
                    tanMin = tan;
                }
            }
            p = p.next;
        }

        return m;
    }

    // interlink polygon nodes in z-order
    static function indexCurve(start:Node, minX:Float, minY:Float, invSize:Float):Void {
        var p = start;
        do {
            if (p.z == -1) p.z = zOrder(p.x, p.y, minX, minY, invSize);
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
    static function sortLinked(list:Node):Node {
        var p:Node, q:Node, e:Node, tail:Node, numMerges:Int, pSize:Int, qSize:Int, i:Int;
        var insize = 1;

        do {
            p = list;
            list = null;
            tail = null;
            numMerges = 0;

            while (p != null) {
                numMerges++;
                q = p;
                pSize = 0;
                for (i in 0...insize) {
                    pSize++;
                    q = q.nextZ;
                    if (q == null) break;
                }
                qSize = insize;

                while (pSize > 0 || (qSize > 0 && q != null)) {
                    if (pSize == 0) {
                        e = q;
                        q = q.nextZ;
                        qSize--;
                    } else if (qSize == 0 || q == null) {
                        e = p;
                        p = p.nextZ;
                        pSize--;
                    } else if (p.z <= q.z) {
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
            insize *= 2;

        } while (numMerges > 1);

        return list;
    }

    // z-order of a point given coords and inverse of the longer side of data bbox
    static function zOrder(x:Float, y:Float, minX:Float, minY:Float, invSize:Float):Int {
        var zx = (x - minX) * invSize | 0;
        var zy = (y - minY) * invSize | 0;

        zx = (zx | (zx << 8)) & 0x00FF00FF;
        zx = (zx | (zx << 4)) & 0x0F0F0F0F;
        zx = (zx | (zx << 2)) & 0x33333333;
        zx = (zx | (zx << 1)) & 0x55555555;

        zy = (zy |