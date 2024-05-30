以下是转换后的 Haxe 代码:

```haxe
/**
 * Port from https://github.com/mapbox/earcut (v2.2.4)
 */

class Earcut {

    public static function triangulate(data:Array<Float>, holeIndices:Array<Int>, dim:Int = 2):Array<Int> {
        var hasHoles:Bool = holeIndices != null && holeIndices.length > 0;
        var outerLen:Int = hasHoles ? holeIndices[0] * dim : data.length;
        var outerNode:Node = linkedList(data, 0, outerLen, dim, true);
        var triangles:Array<Int> = [];

        if (outerNode == null || outerNode.next == outerNode.prev) return triangles;

        var minX:Float, minY:Float, maxX:Float, maxY:Float, x:Float, y:Float, invSize:Float;

        if (hasHoles) outerNode = eliminateHoles(data, holeIndices, outerNode, dim);

        // if the shape is not too simple, we'll use z-order curve hash later; calculate polygon bbox
        if (data.length > 80 * dim) {
            minX = maxX = data[0];
            minY = maxY = data[1];

            for (i in dim...outerLen by dim) {
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

    static function linkedList(data:Array<Float>, start:Int, end:Int, dim:Int, clockwise:Bool):Node {
        var i:Int, last:Node;

        if (clockwise == (signedArea(data, start, end, dim) > 0)) {
            for (i in start...end by dim) last = insertNode(i, data[i], data[i + 1], last);
        } else {
            for (i in end - dim...start - 1 by -dim) last = insertNode(i, data[i], data[i + 1], last);
        }

        if (last != null && equals(last, last.next)) {
            removeNode(last);
            last = last.next;
        }

        return last;
    }

    static function filterPoints(start:Node, ?end:Node):Node {
        if (start == null) return start;
        if (end == null) end = start;

        var p:Node = start;
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

    static function earcutLinked(ear:Node, triangles:Array<Int>, dim:Int, minX:Float, minY:Float, invSize:Float, pass:Int):Void {
        if (ear == null) return;

        // interlink polygon nodes in z-order
        if (pass == 0 && invSize != 0) indexCurve(ear, minX, minY, invSize);

        var stop:Node = ear;
        var prev:Node, next:Node;

        // iterate through ears, slicing them one by one
        while (ear.prev != ear.next) {
            prev = ear.prev;
            next = ear.next;

            if (invSize != 0 ? isEarHashed(ear, minX, minY, invSize) : isEar(ear)) {
                // cut off the triangle
                triangles.push(Math.floor(prev.i / dim));
                triangles.push(Math.floor(ear.i / dim));
                triangles.push(Math.floor(next.i / dim));

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

    static function isEar(ear:Node):Bool {
        var a:Node = ear.prev;
        var b:Node = ear;
        var c:Node = ear.next;

        if (area(a, b, c) >= 0) return false; // reflex, can't be an ear

        // now make sure we don't have other points inside the potential ear
        var ax:Float = a.x, bx:Float = b.x, cx:Float = c.x, ay:Float = a.y, by:Float = b.y, cy:Float = c.y;

        // triangle bbox; min & max are calculated like this for speed
        var x0:Float = Math.min(ax, Math.min(bx, cx));
        var y0:Float = Math.min(ay, Math.min(by, cy));
        var x1:Float = Math.max(ax, Math.max(bx, cx));
        var y1:Float = Math.max(ay, Math.max(by, cy));

        var p:Node = c.next;
        while (p != a) {
            if (p.x >= x0 && p.x <= x1 && p.y >= y0 && p.y <= y1 &&
                pointInTriangle(ax, ay, bx, by, cx, cy, p.x, p.y) &&
                area(p.prev, p, p.next) >= 0) return false;
            p = p.next;
        }

        return true;
    }

    static function isEarHashed(ear:Node, minX:Float, minY:Float, invSize:Float):Bool {
        var a:Node = ear.prev;
        var b:Node = ear;
        var c:Node = ear.next;

        if (area(a, b, c) >= 0) return false; // reflex, can't be an ear

        var ax:Float = a.x, bx:Float = b.x, cx:Float = c.x, ay:Float = a.y, by:Float = b.y, cy:Float = c.y;

        // triangle bbox; min & max are calculated like this for speed
        var x0:Float = Math.min(ax, Math.min(bx, cx));
        var y0:Float = Math.min(ay, Math.min(by, cy));
        var x1:Float = Math.max(ax, Math.max(bx, cx));
        var y1:Float = Math.max(ay, Math.max(by, cy));

        // z-order range for the current triangle bbox;
        var minZ:Int = zOrder(x0, y0, minX, minY, invSize);
        var maxZ:Int = zOrder(x1, y1, minX, minY, invSize);

        var p:Node = ear.prevZ;
        var n:Node = ear.nextZ;

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

    static function cureLocalIntersections(start:Node, triangles:Array<Int>, dim:Int):Node {
        var p:Node = start;
        do {
            var a:Node = p.prev;
            var b:Node = p.next.next;

            if (!equals(a, b) && intersects(a, p, p.next, b) && locallyInside(a, b) && locallyInside(b, a)) {
                triangles.push(a.i / dim);
                triangles.push(p.i / dim);
                triangles.push(b.i / dim);

                // remove two nodes involved
                removeNode(p);
                removeNode(p.next);

                p = start = b;
            }

            p = p.next;
        } while (p != start);

        return filterPoints(p);
    }

    static function splitEarcut(start:Node, triangles:Array<Int>, dim:Int, minX:Float, minY:Float, invSize:Float):Void {
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

    static function eliminateHoles(data:Array<Float>, holeIndices:Array<Int>, outerNode:Node, dim:Int):Node {
        var queue:Array<Node> = [];
        var i:Int, len:Int, start:Int, end:Int, list:Node;

        for (i in 0...holeIndices.length) {
            start = holeIndices[i] * dim;
            end = i < holeIndices.length - 1 ? holeIndices[i + 1] * dim : data.length;
            list = linkedList(data, start, end, dim, false);
            if (list == list.next) list.steiner = true;
            queue.push(getLeftmost(list));
        }

        queue.sort((a, b) -> a.x - b.x);

        // process holes from left to right
        for (i in 0...queue.length) eliminateHole(queue[i], outerNode);
        return outerNode;
    }

    static function eliminateHole(hole:Node, outerNode:Node):Void {
        outerNode = findHoleBridge(hole, outerNode);
        if (outerNode != null) {
            var b:Node = splitPolygon(outerNode, hole);
            filterPoints(outerNode, outerNode.next);
            filterPoints(b, b.next);
        }
    }

    static function findHoleBridge(hole:Node, outerNode:Node):Node {
        var p:Node = outerNode;
        var hx:Float = hole.x;
        var hy:Float = hole.y;
        var qx:Float = -Math.POSITIVE_INFINITY;
        var m:Node, stop:Node;

        // find a segment intersected by a ray from the hole's leftmost point to the left;
        // segment's endpoint with lesser x will be potential connection point
        do {
            if (hy <= p.y && hy >= p.next.y && p.next.y != p.y) {
                var x:Float = p.x + (hy - p.y) * (p.next.x - p.x) / (p.next.y - p.y);
                if (x <= hx && x > qx) {
                    qx = x;
                    if (x == hx) {
                        if (hy == p.y) return p;
                        if (hy == p.next.y) return p.next;
                    }
                    m = p.x < p.next.x ? p : p.next;
                }
            }
            p = p.next;
        } while (p != outerNode);

        if (m == null) return null;

        if (hx == qx) return m.prev;

        // look for points inside the triangle of hole point, segment intersection and endpoint;
        // if there are no points found, we have a valid connection;
        // otherwise choose the point of the minimum angle with the ray as connection point

        var stop:Node = m;
        var tanMin:Float = Math.POSITIVE_INFINITY;
        var tan:Float;

        p = m.next;

        while (p != stop) {
            if (hx >= p.x && p.x >= m.x && pointInTriangle(hy < m.y ? hx : qx, hy, m.x, m.y, hy < m.y ? qx : hx, hy, p.x, p.y)) {
                tan = Math.abs(hy - p.y) / (hx - p.x); // tangential

                if (locallyInside(p, hole) && (tan < tanMin || (tan == tanMin && p.x > m.x))) {
                    m = p;
                    tanMin = tan;
                }
            }

            p = p.next;
        }

        return m;
    }

    static function indexCurve(start:Node, minX:Float, minY:Float, invSize:Float):Void {
        var p:Node = start;
        do {
            if (p.z == null) p.z = zOrder(p.x, p.y, minX, minY, invSize);
            p.prevZ = p.prev;
            p.nextZ = p.next;
            p = p.next;
        } while (p != start);

        p.prevZ.nextZ = null;
        p.prevZ = null;

        sortLinked(p);
    }

    static function sortLinked(list:Node):Node {
        var inSize:Int = 1;
        var numMerges:Int;
        var p:Node;
        var q:Node;
        var e:Node;
        var tail:Node;
        var pSize:Int;
        var qSize:Int;
        var i:Int;

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
            inSize *= 2;

        } while (numMerges > 1);

        return list;
    }

    static function zOrder(x:Float, y:Float, minX:Float, minY:Float, invSize:Float):Int {
        x = 32767 * (x - minX) * invSize;
        y = 32767 * (y - minY) * invSize;

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

    static function getLeftmost(start:Node):Node {
        var p:Node = start;
        var