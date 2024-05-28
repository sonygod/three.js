package three.extras;

import haxe.ds.List;

class Earcut {
    public static function triangulate(data:Array<Float>, holeIndices:Array<Int>, dim:Int = 2):Array<Int> {
        var hasHoles:Bool = holeIndices != null && holeIndices.length > 0;
        var outerLen:Int = hasHoles ? holeIndices[0] * dim : data.length;
        var outerNode:Node = linkedList(data, 0, outerLen, dim, true);
        var triangles:Array<Int> = [];

        if (outerNode == null || outerNode.next == outerNode.prev) return triangles;

        var minX:Float, minY:Float, maxX:Float, maxY:Float, x:Float, y:Float, invSize:Float;

        if (hasHoles) outerNode = eliminateHoles(data, holeIndices, outerNode, dim);

        if (data.length > 80 * dim) {
            minX = maxX = data[0];
            minY = maxY = data[1];

            for (i in 0...outerLen) {
                x = data[i];
                y = data[i + 1];
                if (x < minX) minX = x;
                if (y < minY) minY = y;
                if (x > maxX) maxX = x;
                if (y > maxY) maxY = y;
            }

            invSize = Math.max(maxX - minX, maxY - minY);
            invSize = invSize != 0 ? 32767 / invSize : 0;
        }

        earcutLinked(outerNode, triangles, dim, minX, minY, invSize, 0);

        return triangles;
    }

    // create a circular doubly linked list from polygon points in the specified winding order
    static function linkedList(data:Array<Float>, start:Int, end:Int, dim:Int, clockwise:Bool):Node {
        var i:Int, last:Node;

        if (clockwise == (signedArea(data, start, end, dim) > 0)) {
            for (i in start...end) last = insertNode(i, data[i], data[i + 1], last);
        } else {
            for (i in end - dim...start) last = insertNode(i, data[i], data[i + 1], last);
        }

        if (last != null && equals(last, last.next)) {
            removeNode(last);
            last = last.next;
        }

        return last;
    }

    // eliminate colinear or duplicate points
    static function filterPoints(start:Node, end:Node):Node {
        if (start == null) return start;
        if (end == null) end = start;

        var p:Node = start, again:Bool;
        do {
            again = false;

            if (p.steiner == false && (equals(p, p.next) || area(p.prev, p, p.next) == 0)) {
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

        if (pass == 0 && invSize != 0) indexCurve(ear, minX, minY, invSize);

        var stop:Node = ear, prev:Node, next:Node;

        while (ear.prev != ear.next) {
            prev = ear.prev;
            next = ear.next;

            if (invSize != 0 ? isEarHashed(ear, minX, minY, invSize) : isEar(ear)) {
                triangles.push(prev.i / dim | 0);
                triangles.push(ear.i / dim | 0);
                triangles.push(next.i / dim | 0);

                removeNode(ear);

                ear = next.next;
                stop = next.next;
            } else {
                ear = next;
            }
        }
    }

    // check whether a polygon node forms a valid ear with adjacent nodes
    static function isEar(ear:Node):Bool {
        var a:Node = ear.prev, b:Node = ear, c:Node = ear.next;

        if (area(a, b, c) >= 0) return false;

        var ax:Float = a.x, bx:Float = b.x, cx:Float = c.x, ay:Float = a.y, by:Float = b.y, cy:Float = c.y;

        var x0:Float = ax < bx ? (ax < cx ? ax : cx) : (bx < cx ? bx : cx);
        var y0:Float = ay < by ? (ay < cy ? ay : cy) : (by < cy ? by : cy);
        var x1:Float = ax > bx ? (ax > cx ? ax : cx) : (bx > cx ? bx : cx);
        var y1:Float = ay > by ? (ay > cy ? ay : cy) : (by > cy ? by : cy);

        var p:Node = c.next;
        while (p != a) {
            if (p.x >= x0 && p.x <= x1 && p.y >= y0 && p.y <= y1 && p != a && p != c && area(p.prev, p, p.next) >= 0) return false;
            p = p.next;
        }

        return true;
    }

    static function isEarHashed(ear:Node, minX:Float, minY:Float, invSize:Float):Bool {
        var a:Node = ear.prev, b:Node = ear, c:Node = ear.next;

        if (area(a, b, c) >= 0) return false;

        var ax:Float = a.x, bx:Float = b.x, cx:Float = c.x, ay:Float = a.y, by:Float = b.y, cy:Float = c.y;

        var x0:Float = ax < bx ? (ax < cx ? ax : cx) : (bx < cx ? bx : cx);
        var y0:Float = ay < by ? (ay < cy ? ay : cy) : (by < cy ? by : cy);
        var x1:Float = ax > bx ? (ax > cx ? ax : cx) : (bx > cx ? bx : cx);
        var y1:Float = ay > by ? (ay > cy ? ay : cy) : (by > cy ? by : cy);

        var minZ:Float = zOrder(x0, y0, minX, minY, invSize);
        var maxZ:Float = zOrder(x1, y1, minX, minY, invSize);

        var p:Node = ear.prevZ, n:Node = ear.nextZ;

        while (p != null && p.z >= minZ && n != null && n.z <= maxZ) {
            if (p.x >= x0 && p.x <= x1 && p.y >= y0 && p.y <= y1 && p != a && p != c && area(p.prev, p, p.next) >= 0) return false;
            p = p.prevZ;

            if (n.x >= x0 && n.x <= x1 && n.y >= y0 && n.y <= y1 && n != a && n != c && area(n.prev, n, n.next) >= 0) return false;
            n = n.nextZ;
        }

        return true;
    }

    // ...
}

class Node {
    public var i:Int;
    public var x:Float;
    public var y:Float;
    public var prev:Node;
    public var next:Node;
    public var z:Float;
    public var prevZ:Node;
    public var nextZ:Node;
    public var steiner:Bool;

    public function new(i:Int, x:Float, y:Float) {
        this.i = i;
        this.x = x;
        this.y = y;
    }
}