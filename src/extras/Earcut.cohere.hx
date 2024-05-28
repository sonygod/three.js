package earcut;

class Earcut {
    public static function triangulate(data:Array<Float>, holeIndices:Array<Int>, dim:Int=2):Array<Int> {
        var hasHoles = holeIndices != null && holeIndices.length > 0;
        var outerLen = hasHoles ? holeIndices[0] * dim : data.length;
        var outerNode = linkedList(data, 0, outerLen, dim, true);
        var triangles = [];

        if (outerNode == null || outerNode.next == outerNode.prev) {
            return triangles;
        }

        var minX = 0.0, minY = 0.0, maxX = 0.0, maxY = 0.0, x = 0.0, y = 0.0, invSize = 0.0;

        if (hasHoles) {
            outerNode = eliminateHoles(data, holeIndices, outerNode, dim);
        }

        // if the shape is not too simple, we'll use z-order curve hash later; calculate polygon bbox
        if (data.length > 80 * dim) {
            minX = maxX = data[0];
            minY = maxY = data[1];

            var i = dim;
            while (i < outerLen) {
                x = data[i];
                y = data[i+1];
                if (x < minX) {
                    minX = x;
                }
                if (y < minY) {
                    minY = y;
                }
                if (x > maxX) {
                    maxX = x;
                }
                if (y > maxY) {
                    maxY = y;
                }
                i += dim;
            }

            // minX, minY and invSize are later used to transform coords into integers for z-order calculation
            invSize = (maxX - minX) !== 0 ? 32767 / (maxX - minX) : 0;
            invSize = (maxY - minY) !== 0 ? 32767 / (maxY - minY) : 0;
        }

        earcutLinked(outerNode, triangles, dim, minX, minY, invSize, 0);

        return triangles;
    }

    function linkedList(data:Array<Float>, start:Int, end:Int, dim:Int, clockwise:Bool):Node {
        var i:Int, last:Node;

        if (clockwise == (signedArea(data, start, end, dim) > 0)) {
            for (i = start; i < end; i += dim) {
                last = insertNode(i, data[i], data[i+1], last);
            }
        } else {
            for (i = end - dim; i >= start; i -= dim) {
                last = insertNode(i, data[i], data[i+1], last);
            }
        }

        if (last != null && equals(last, last.next)) {
            removeNode(last);
            last = last.next;
        }

        return last;
    }

    function filterPoints(start:Node, end:Node):Node {
        if (start == null) {
            return start;
        }
        if (end == null) {
            end = start;
        }

        var p = start,
            again = true;
        while (again || p != end) {
            again = false;

            if (p.steiner || (equals(p, p.next) && area(p.prev, p, p.next) === 0)) {
                removeNode(p);
                p = end = p.prev;
                if (p == p.next) {
                    break;
                }
                again = true;

            } else {
                p = p.next;
            }
        }

        return end;
    }

    function earcutLinked(ear:Node, triangles:Array<Int>, dim:Int, minX:Float, minY:Float, invSize:Float, pass:Int):Void {
        if (ear == null) {
            return;
        }

        // interlink polygon nodes in z-order
        if (pass == 0 && invSize) {
            indexCurve(ear, minX, minY, invSize);
        }

        var stop = ear,
            prev:Node,
            next:Node;

        // iterate through ears, slicing them one by one
        while (ear.prev != ear.next) {
            prev = ear.prev;
            next = ear.next;

            if (invSize ? isEarHashed(ear, minX, minY, invSize) : isEar(ear)) {
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

    function isEar(ear:Node):Bool {
        var a = ear.prev,
            b = ear,
            c = ear.next;

        if (area(a, b, c) >= 0) {
            return false; // reflex, can't be an ear
        }

        // now make sure we don't have other points inside the potential ear
        var ax = a.x, bx = b.x, cx = c.x, ay = a.y, by = b.y, cy = c.y;

        // triangle bbox; min & max are calculated like this for speed
        var x0 = ax < bx ? (ax < cx ? ax : cx) : (bx < cx ? bx : cx),
            y0 = ay < by ? (ay < cy ? ay : cy) : (by < cy ? by : cy),
            x1 = ax > bx ? (ax > cx ? ax : cx) : (bx > cx ? bx : cx),
            y1 = ay > by ? (ay > cy ? ay : cy) : (by > cy ? by : cy);

        var p = c.next;
        while (p != a) {
            if (p.x < x1 && p.x > x0 && p.y < y1 && p.y > y0 &&
                pointInTriangle(ax, ay, bx, by, cx, cy, p.x, p.y) &&
                area(p.prev, p, p.next) >= 0) {
                return false;
            }
            p = p.next;
        }

        return true;
    }

    function isEarHashed(ear:Node, minX:Float, minY:Float, invSize:Float):Bool {
        var a = ear.prev,
            b = ear,
            c = ear.next;

        if (area(a, b, c) >= 0) {
            return false; // reflex, can't be an ear
        }

        var ax = a.x, bx = b.x, cx = c.x, ay = a.y, by = b.y, cy = c.y;

        // triangle bbox; min & max are calculated like this for speed
        var x0 = ax < bx ? (ax < cx ? ax : cx) : (bx < cx ? bx : cx),
            y0 = ay < by ? (ay < cy ? ay : cy) : (by < cy ? by : cy),
            x1 = ax > bx ? (ax > cx ? ax : cx) : (bx > cx ? bx : cx),
            y1 = ay > by ? (ay > cy ? ay : cy) : (by > cy ? by : cy);

        // z-order range for the current triangle bbox;
        var minZ = zOrder(x0, y0, minX, minY, invSize),
            maxZ = zOrder(x1, y1, minX, minY, invSize);

        var p = ear.prevZ,
            n = ear.nextZ;

        // look for points inside the triangle in both directions
        while (p && p.z >= minZ && n && n.z <= maxZ) {
            if (p.z != n.z && p.x >= x0 && p.x <= x1 && p.y >= y0 && p.y <= y1 && p != a && p != c &&
                pointInTriangle(ax, ay, bx, by, cx, cy, p.x, p.y) && area(p.prev, p, p.next) >= 0) {
                return false;
            }
            p = p.prevZ;

            if (n.z != p.z && n.x >= x0 && n.x <= x1 && n.y >= y0 && n.y <= y1 && n != a && n != c &&
                pointInTriangle(ax, ay, bx, by, cx, cy, n.x, n.y) && area(n.prev, n, n.next) >= 0) {
                return false;
            }
            n = n.nextZ;
        }

        // look for remaining points in decreasing z-order
        while (p && p.z >= minZ) {
            if (p.x >= x0 && p.x <= x1 && p.y >= y0 && p.y <= y1 && p != a && p != c &&
                pointInTriangle(ax, ay, bx, by, cx, cy, p.x, p.y) && area(p.prev, p, p.next) >= 0) {
                return false;
            }
            p = p.prevZ;
        }

        // look for remaining points in increasing z-order
        while (n && n.z <= maxZ) {
            if (n.x >= x0 && n.x <= x1 && n.y >= y0 && n.y <= y1 && n != a && n != c &&
                pointInTriangle(ax, ay, bx, by, cx, cy, n.x, n.y) && area(n.prev, n, n.next) >= 0) {
                return false;
            }
            n = n.nextZ;
        }

        return true;
    }

    function cureLocalIntersections(start:Node, triangles:Array<Int>, dim:Int):Node {
        var p = start;
        do {
            var a = p.prev,
                b = p.next.next;

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

    function splitEarcut(start:Node, triangles:Array<Int>, dim:Int, minX:Float, minY:Float, invSize:Float):Void {
        // look for a valid diagonal that divides the polygon into two
        var a = start;
        do {
            var b = a.next.next;
            while (b != a.prev) {
                if (a.i != b.i && isValidDiagonal(a, b)) {
                    // split the polygon in two by the diagonal
                    var c = splitPolygon(a, b);

                    // filter collinear points around the cuts
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

    function eliminateHoles(data:Array<Float>, holeIndices:Array<Int>, outerNode:Node, dim:Int):Node {
        var queue = [];
        var i = 0,
            len = holeIndices.length,
            start = 0,
            end = 0,
            list = null;

        for (i = 0; i < len; i++) {
            start = holeIndices[i] * dim;
            end = i < len - 1 ? holeIndices[i+1] * dim : data.length;
            list = linkedList(data, start, end, dim, false);
            if (list == list.next) {
                list.steiner = true;
            }
            queue.push(getLeftmost(list));
        }

        queue.sort(compareX);

        // process holes from left to right
        for (i = 0; i < queue.length; i++) {
            outerNode = eliminateHole(queue[i], outerNode);
        }

        return outerNode;
    }

    function compareX(a:Node, b:Node):Int {
        return a.x - b.x;
    }

    function eliminateHole(hole:Node, outerNode:Node):Node {
        var bridge = findHoleBridge(hole, outerNode);
        if (bridge == null) {
            return outerNode;
        }

        var bridgeReverse = splitPolygon(bridge, hole);

        // filter collinear points around the cuts
        filterPoints(bridgeReverse, bridgeReverse.next);
        filterPoints(bridge, bridge.next);

        return filterPoints(outerNode, outerNode.next);
    }

    function findHoleBridge(hole:Node, outerNode:Node):Node {
        var p = outerNode,
            hx = hole.x,
            hy = hole.y,
            qx = -Infinity,
            m = null;

        // find a segment intersected by a ray from the hole's leftmost point to the left;
        // segment's endpoint with lesser x will be potential connection point
        do {
            if (hy <= p.y && hy >= p.next.y && p.next.y != p.y) {
                var x = p.x + (hy - p.y) * (p.next.x - p.x) / (p.next.y - p.y);
                if (x <= hx && x > qx) {
                    qx = x;
                    m = p.x < p.next.x ? p : p.next;
                }
            }
            p = p.next;
        } while (p != outerNode);

        if (m == null) {
            return null;
        }

        // look for points inside the triangle of hole point, segment intersection and endpoint;
        // if there are no points found, we have a valid connection;
        // otherwise choose the point of the minimum angle with the ray as connection point

        var stop = m,
            mx = m.x,
            my = m.y,
            tanMin = Infinity,
            tan;

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

    function sectorContainsSector(m:Node, p:Node):Bool {
        return area(m.prev, m, p.prev) < 0 && area(p.next, m, m.next) < 0;
    }

    function indexCurve(start:Node, minX:Float, minY:Float, invSize:Float):Void {
        var p = start;
        do {
            if (p.z == 0) {
                p.z = zOrder(p.x, p.y, minX, minY, invSize);
            }
            p.prevZ = p.prev;
            p.nextZ = p.next;
            p = p.next;
        } while (p != start);

        p.prevZ.nextZ = null;
        p.prevZ = null;

        sortLinked(p);
    }

    function sortLinked(list:Node):Void {
        var i = 0,
            p = list,
            q = null,
            e = null,
            tail = null,
            numMerges = 0,
            pSize = 0,
            qSize = 0,
            inSize = 1;

        do {
            p = list;
            list = null;
            tail = null;
            numMerges = 0;

            while (
            pSize != 0 || (qSize != 0 && q)
            ) {
                if (pSize != 0 && (qSize == 0 || !q || p.z <= q.z)) {
                    e = p;
                    p = p.nextZ;
                    pSize--;
                } else {
                    e = q;
                    q = q.nextZ;
                    qSize--;
                }

                if (tail) {
                    tail.nextZ = e;
                } else {
                    list = e;
                }

                e.prevZ = tail;
                tail = e;
            }

            p = q;
        } while (p != null);

        tail.nextZ = null;

        inSize *= 2;
    } while (numMerges > 1);

    return list;
}

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

function getLeftmost(start:Node):Node {
    var p = start,
        leftmost = start;
    do {
        if (p.x < leftmost.x || (p.x == leftmost.x && p.y < leftmost.y)) {
            leftmost = p;
        }
        p = p.next;
    } while (p != start);

    return leftmost;
}

function pointInTriangle(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float, px:Float, py:Float):Bool {
    return (cx - px) * (ay - py) >= (ax - px) * (cy - py) &&
           (ax - px) * (by - py) >= (bx - px) * (ay - py) &&
           (bx - px) * (cy - py) >= (cx - px) * (by - py);
}

function isValidDiagonal(a:Node, b:Node):Bool {
    return a.next.i != b.i && a.prev.i != b.i && !intersectsPolygon(a, b) && // dones't intersect other edges
           (locallyInside(a, b) && locallyInside(b, a) && middleInside(a, b) && // locally visible
            (area(a.prev, a, b.prev) || area(a, b.prev, b)) || // does not create opposite-facing sectors
            equals(a, b) && area(a.prev, a, a.next) > 0 && area(b.prev, b, b.next) > 0); // special zero-length case
}

function intersects(p1:Node, q1:Node, p2:Node, q2:Node):Bool {
    var o1 = sign(area(p1, q1, p2));
    var o2 = sign(area(p1, q1, q2));
    var o3 = sign(area(p2, q2, p1));
    var o4 = sign(area(p2, q2, q1));

    if (o1 != o2 && o3 != o4) {
        return true; // general case
    }

    // handle collinear cases
    if (o1 == 0 && onSegment(p1, p2, q1)) {
        return true; // p1, q1 and p2 are collinear and p2 lies on p1q1
    }
    if (o2 == 0 && onSegment(p1, q2, q1)) {
        return true; // p1, q1 and q2 are collinear and q2 lies on p1q1
    }
    if (o3 == 0 && onSegment(p2, p1, q2)) {
        return true; // p2, q2 and p1 are collinear and p1 lies on p2q2
    }
    if (o4 == 0 && onSegment(p2, q1, q2)) {
        return true; // p2, q2 and q1 are collinear and q1 lies on p2q2
    }

    return false;
}

function sign(num:Float):Int {
    return num > 0 ? 1 : num < 0 ? -1 : 0;
}

function onSegment(p:Node, q:Node, r:Node):Bool {
    return q.x <= Math.max(p.x, r.x) && q.x >= Math.min(p.x, r.x) && q.y <= Math.max(p.y, r.y) && q.y >= Math.min(p.y, r.y);
}

function intersectsPolygon(a:Node, b:Node):Bool {
    var p = a;
    do {
        if (p.i != a.i && p.next.i != a.i && p.i != b.i && p.next.i != b.i &&
            intersects(p, p.next, a, b)) {
            return true;
        }
        p = p.next;
    } while (p != a);

    return false;
}

function locallyInside(a:Node, b:Node):Bool {
    return area(a.prev, a, a.next) < 0 ?
        area(a, b, a.next) >= 0 && area(a, a.prev, b) >= 0 :
        area(a, b, a.prev) < 0 || area(a, a.next, b) < 0;
}

function middleInside(a:Node, b:Node):Bool {
    var p = a,
        inside = false,
        px = (a.x + b.x) / 2,
        py = (a.y + b.y) / 2;
    do {
        if ((p.y > py) != (p.next.y > py) && p.next.y != p.y &&
            (px < (p.next.x - p.x) * (py - p.y) / (p.next.y - p.y) + p.x)) {
            inside = !inside;
        }
        p = p.next;
    } while (p != a);

    return inside;
}

function splitPolygon(a:Node, b:Node):Node {
    var a2 = new Node(a.i, a.x, a.y),
        b2 = new Node(b.i, b.x, b.y),
        an = a.next,
        bp = b.prev;

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

function insertNode(i:Int, x:Float, y:Float, last:Node):Node {
    var p = new Node(i, x, y);

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

function removeNode(p:Node):Void {
    p.next.prev = p.prev;
    p.prev.next = p.next;

    if (p.prevZ) {
        p.prevZ.nextZ = p.nextZ;
    }
    if (p.nextZ) {
        p.nextZ.prevZ = p.prevZ;
    }
}

class Node {
    public i:Int;
    public x:Float;
    public y:Float;
    public prev:Node;
    public next:Node;
    public z:Int;
    public prevZ:Node;
    public nextZ:Node;
    public steiner:Bool;

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
    var sum = 0;
    var j = end - dim;
    for (var i = start; i < end; i += dim) {
        sum += (data[j] - data[i]) * (data[i+1] + data[j+1]);
        j = i;
    }

    return sum;
}