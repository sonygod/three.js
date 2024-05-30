import js.Browser.window;
import js.html.CanvasElement;
import js.html.HtmlElement;
import js.html.HtmlImageElement;
import js.html.Image;
import js.html.Document;
import js.html.Location;
import js.html.Anchor;
import js.html.History;
import js.html.Window;
import js.html.Option;
import js.html.Select;
import js.html.TextNode;
import js.html.Node;
import js.html.Element;
import js.html.Event;
import js.html.DataTransfer;
import js.html.DataTransferItem;
import js.html.DataTransferItemList;

import js.sys.Reflect;
import js.sys.Dynamic;
import js.sys.Error;
import js.sys.Function;
import js.sys.ArrayBuffer;
import js.sys.Float32Array;
import js.sys.Float64Array;
import js.sys.Int8Array;
import js.sys.Int16Array;
import js.sys.Int32Array;
import js.sys.Uint8Array;
import js.sys.Uint8ClampedArray;
import js.sys.Uint16Array;
import js.sys.Uint32Array;
import js.sys.Date;
import js.sys.RegExp;
import js.sys.Math;
import js.sys.JSON;
import js.sys.Promise;
import js.sys.Map;
import js.sys.Set;
import js.sys.WeakMap;
import js.sys.WeakSet;
import js.sys.Array;
import js.sys.Reflect;
import js.sys.Proxy;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.crypto.Adler32;
import haxe.crypto.Base64;
import haxe.crypto.Md5;
import haxe.ds.ArraySort;
import haxe.ds.BalancedTree;
import haxe.ds.TreeNode;
import haxe.ds.EnumValueMap;
import haxe.ds.GenericStack;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.Queue;
import haxe.ds.StringMap;
import haxe.ds.Vector;
import haxe.format.JsonParser;
import haxe.format.JsonPrinter;
import haxe.io.Bytes;
import haxe.io.Eof;
import haxe.io.Error;
import haxe.io.FPHelper;
import haxe.io.Input;
import haxe.io.Output;
import haxe.io.Path;
import haxe.io.PathWatcher;
import haxe.io.Strings;
import haxe.Log;
import haxe.Unit;

import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Tools;
import haxe.macro.Type;

import haxe.rtti.Meta;

import haxe.xml.Parser;
import haxe.xml.Printer;

import haxe.zip.Compress;
import haxe.zip.Uncompress;

import js.Browser.console;
import js.Browser.alert;
import js.Browser.confirm;
import js.Browser.prompt;
import js.html.Location;
import js.html.Anchor;
import js.html.History;
import js.html.Window;

import js.node.Buffer;

class Box2Test {
    static function instancing() {
        var a = new Box2();
        assert(a.min.equals(PosInf2.create()), "Passed!");
        assert(a.max.equals(NegInf2.create()), "Passed!");

        a = new Box2(Zero2.clone(), Zero2.clone());
        assert(a.min.equals(Zero2.create()), "Passed!");
        assert(a.max.equals(Zero2.create()), "Passed!");

        a = new Box2(Zero2.clone(), One2.clone());
        assert(a.min.equals(Zero2.create()), "Passed!");
        assert(a.max.equals(One2.create()), "Passed!");
    }

    static function isBox2() {
        var a = new Box2();
        assert(a.isBox2, "Passed!");

        var b = new Object();
        assert(!b.isBox2, "Passed!");
    }

    static function set() {
        var a = new Box2();

        a.set(Zero2.create(), One2.create());
        assert(a.min.equals(Zero2.create()), "Passed!");
        assert(a.max.equals(One2.create()), "Passed!");
    }

    static function setFromPoints() {
        var a = new Box2();

        a.setFromPoints([Zero2.create(), One2.create(), Two2.create()]);
        assert(a.min.equals(Zero2.create()), "Passed!");
        assert(a.max.equals(Two2.create()), "Passed!");

        a.setFromPoints([One2.create()]);
        assert(a.min.equals(One2.create()), "Passed!");
        assert(a.max.equals(One2.create()), "Passed!");

        a.setFromPoints([]);
        assert(a.isEmpty(), "Passed!");
    }

    static function setFromCenterAndSize() {
        var a = new Box2();

        a.setFromCenterAndSize(Zero2.create(), Two2.create());
        assert(a.min.equals(NegOne2.create()), "Passed!");
        assert(a.max.equals(One2.create()), "Passed!");

        a.setFromCenterAndSize(One2.create(), Two2.create());
        assert(a.min.equals(Zero2.create()), "Passed!");
        assert(a.max.equals(Two2.create()), "Passed!");

        a.setFromCenterAndSize(Zero2.create(), Zero2.create());
        assert(a.min.equals(Zero2.create()), "Passed!");
        assert(a.max.equals(Zero2.create()), "Passed!");
    }

    static function clone() {
        var a = new Box2(Zero2.create(), Zero2.create());

        var b = a.clone();
        assert(b.min.equals(Zero2.create()), "Passed!");
        assert(b.max.equals(Zero2.create()), "Passed!");

        a = new Box2();
        b = a.clone();
        assert(b.min.equals(PosInf2.create()), "Passed!");
        assert(b.max.equals(NegInf2.create()), "Passed!");
    }

    static function copy() {
        var a = new Box2(Zero2.create(), One2.create());
        var b = new Box2().copy(a);
        assert(b.min.equals(Zero2.create()), "Passed!");
        assert(b.max.equals(One2.create()), "Passed!");

        // ensure that it is a true copy
        a.min = Zero2.create();
        a.max = One2.create();
        assert(b.min.equals(Zero2.create()), "Passed!");
        assert(b.max.equals(One2.create()), "Passed!");
    }

    static function emptyMakeEmpty() {
        var a = new Box2();

        assert(a.isEmpty(), "Passed!");

        a = new Box2(Zero2.create(), One2.create());
        assert(!a.isEmpty(), "Passed!");

        a.makeEmpty();
        assert(a.isEmpty(), "Passed!");
    }

    static function isEmpty() {
        var a = new Box2(Zero2.create(), Zero2.create());
        assert(!a.isEmpty(), "Passed!");

        a = new Box2(Zero2.create(), One2.create());
        assert(!a.isEmpty(), "Passed!");

        a = new Box2(Two2.create(), One2.create());
        assert(a.isEmpty(), "Passed!");

        a = new Box2(PosInf2.create(), NegInf2.create());
        assert(a.isEmpty(), "Passed!");
    }

    static function getCenter() {
        var a = new Box2(Zero2.create(), Zero2.create());
        var center = new Vector2();
        assert(a.getCenter(center).equals(Zero2.create()), "Passed!");

        a = new Box2(Zero2.create(), One2.create());
        var midpoint = One2.create().multiplyScalar(0.5);
        assert(a.getCenter(center).equals(midpoint), "Passed!");
    }

    static function getSize() {
        var a = new Box2(Zero2.create(), Zero2.create());
        var size = new Vector2();

        assert(a.getSize(size).equals(Zero2.create()), "Passed!");

        a = new Box2(Zero2.create(), One2.create());
        assert(a.getSize(size).equals(One2.create()), "Passed!");
    }

    static function expandByPoint() {
        var a = new Box2(Zero2.create(), Zero2.create());
        var size = new Vector2();
        var center = new Vector2();

        a.expandByPoint(Zero2.create());
        assert(a.getSize(size).equals(Zero2.create()), "Passed!");

        a.expandByPoint(One2.create());
        assert(a.getSize(size).equals(One2.create()), "Passed!");

        a.expandByPoint(One2.create().negate());
        assert(a.getSize(size).equals(One2.create().multiplyScalar(2)), "Passed!");
        assert(a.getCenter(center).equals(Zero2.create()), "Passed!");
    }

    static function expandByVector() {
        var a = new Box2(Zero2.create(), Zero2.create());
        var size = new Vector2();
        var center = new Vector2();

        a.expandByVector(Zero2.create());
        assert(a.getSize(size).equals(Zero2.create()), "Passed!");

        a.expandByVector(One2.create());
        assert(a.getSize(size).equals(One2.create().multiplyScalar(2)), "Passed!");
        assert(a.getCenter(center).equals(Zero2.create()), "Passed!");
    }

    static function expandByScalar() {
        var a = new Box2(Zero2.create(), Zero2.create());
        var size = new Vector2();
        var center = new VectorFreq();

        a.expandByScalar(0);
        assert(a.getSize(size).equals(Zero2.create()), "Passed!");

        a.expandByScalar(1);
        assert(a.getSize(size).equals(One2.create().multiplyScalar(2)), "Passed!");
        assert(a.getCenter(center).equals(Zero2.create()), "Passed!");
    }

    static function containsPoint() {
        var a = new Box2(Zero2.create(), Zero2.create());

        assert(a.containsPoint(Zero2.create()), "Passed!");
        assert(!a.containsPoint(One2.create()), "Passed!");

        a.expandByScalar(1);
        assert(a.containsPoint(Zero2.create()), "Passed!");
        assert(a.containsPoint(One2.create()), "Passed!");
        assert(a.containsPoint(One2.create().negate()), "Passed!");
    }

    static function containsBox() {
        var a = new Box2(Zero2.create(), Zero2.create());
        var b = new Box2(Zero2.create(), One2.create());
        var c = new Box2(One2.create().negate(), One2.create());

        assert(a.containsBox(a), "Passed!");
        assert(!a.containsBox(b), "Passed!");
        assert(!a.containsBox(c), "Passed!");

        assert(b.containsBox(a), "Passed!");
        assert(c.containsBox(a), "Passed!");
        assert(!b.containsBox(c), "Passed!");
    }

    static function getParameter() {
        var a = new Box2(Zero2.create(), One2.create());
        var b = new Box2(One2.create().negate(), One2.create());

        var parameter = new Vector2();

        a.getParameter(Zero2.create(), parameter);
        assert(parameter.equals(Zero2.create()), "Passed!");
        a.getParameter(One2.create(), parameter);
        assert(parameter.equals(One2.create()), "Passed!");

        b.getParameter(One2.create().negate(), parameter);
        assert(parameter.equals(Zero2.create()), "Passed!");
        b.getParameter(Zero2.create(), parameter);
        assert(parameter.equals(new Vector2(0.5, 0.5)), "Passed!");
        b.getParameter(One2.create(), parameter);
        assert(parameter.equals(One2.create()), "Passed!");
    }

    static function intersectsBox() {
        var a = new Box2(Zero2.create(), Zero2.create());
        var b = new Box2(Zero2.create(), One2.create());
        var c = new Box2(One2.create().negate(), One2.create());

        assert(a.intersectsBox(a), "Passed!");
        assert(a.intersectsBox(b), "Passed!");
        assert(a.intersectsBox(c), "Passed!");

        assert(b.intersectsBox(a), "Passed!");
        assert(c.intersectsBox(a), "Passed!");
        assert(b.intersectsBox(c), "Passed!");

        b.translate(Two2.create());
        assert(!a.intersectsBox(b), "Passed!");
        assert(!b.intersectsBox(a), "Passed!");
        assert(!b.intersectsBox(c), "Passed!");
    }

    static function clampPoint() {
        var a = new Box2(Zero2.create(), Zero2.create());
        var b = new Box2(One2.create().negate(), One2.create());

        var point = new Vector2();

        a.clampPoint(Zero2.create(), point);
        assert(point.equals(new Vector2(0, 0)), "Passed!");
        a.clampPoint(One2.create(), point);
        assert(point.equals(new Vector2(0, 0)), "Passed!");
        a.clampPoint(One2.create().negate(), point);
        assert(point.equals(new Vector2(0, 0)), "Passed!");

        b.clampPoint(Two2.create(), point);
        assert(point.equals(new Vector2(1, 1)), "Passed!");
        b.clampPoint(One2.create(), point);
        assert(point.equals(new Vector2(1, 1)), "Passed!");
        b.clampPoint(Zero2.create(), point);
        assert(point.equals(new Vector2(0, 0)), "Passed!");
        b.clampPoint(One2.create().negate(), point);
        assert(point.equals(new Vector2(-1, -1)), "Passed!");
        b.clampPoint(Two2.create().negate(), point);
        assert(point.equals(new Vector2(-1, -1)), "Passed!");
    }

    static function distanceToPoint() {
        var a = new Box2(Zero2.create(), Zero2.create());
        var b = new Box2(One2.create().negate(), One2.create());

        assert(a.distanceToPoint(new Vector2(0, 0)) == 0, "Passed!");
        assert(a.distanceToPoint(new Vector2(1, 1)) == Math.sqrt(2), "Passed!");
        assert(a.distanceToPoint(new Vector2(-1, -1)) == Math.sqrt(2), "Passed!");

        assert(b.distanceToPoint(new Vector2(2, 2)) == Math.sqrt(2), "Passed!");
        assert(b.distanceToPoint(new Vector2(1, 1)) == 0, "Passed!");
        assert(b.distancePoint(new Vector2(0, 0)) == 0, "Passed!");
        assert(b.distanceToPoint(new Vector2(-1, -1)) == 0, "Passed!");
        assert(b.distanceToPoint(new Vector2(-2, -2)) == Math.sqrt(2), "Passed!");
    }

    static function intersect() {
        var a = new Box2(Zero2.create(), Zero2.create());
        var b = new Box2(Zero2.create(), One2.create());
        var c = new Box2(One2.create().negate(), One2.create());

        assert(a.clone().intersect(a).equals(a), "Passed!");
        assert(a.clone().intersect(b).equals(a), "Passed!");
        assert(b.clone().intersect(b).equals(b), "Passed!");
        assert(a.clone().intersect(c).equals(a), "Passed!");
        assert(b.clone().intersect(c).equals(b), "Passed!");
        assert(c.clone().intersect(c).equals(c), "Passed!");

        var d = new Box2(One2.create().negate(), Zero2.create());
        var e = new Box2(One2.create(), Two2.create()).intersect(d);

        assert(e.min.equals(PosInf2.create()) && e.max.equals(NegInf2.create()), "Infinite empty");
    }

    static function union() {
        var a = new Box2(Zero2.create(), Zero2.create());
        var b = new Box2(Zero2.create(), One2.create());
        var c = new Box2(One2.create().negate(), One2.create());

        assert(a.clone().union(a).equals(a), "Passed!");
        assert(a.clone().union(b).equals(b), "Passed!");
        assert(a.clone().union(c).equals(c), "Passed!");
        assert(b.clone().union(c).equals(c), "Passed!");
    }

    static function translate() {
        var a = new Box2(Zero2.create(), Zero2.create());
        var b = new Box2(Zero2.create(), One2.create());
        var c = new Box2(One2.create().negate(), Zero2.create());

        assert(a.clone().translate(One2.create()).equals(new Box2(One2.create(), One2.create())), "Passed!");
        assert(a.clone().translate(One2.create()).translate(One2.create().negate()).equals(a), "Passed!");
        assert(c.clone().translate(One2.create()).equals(b), "Passed!");
        assert(b.clone().translate(One2.create().negate()).equals(c), "Passed!");
    }

    static function equals() {
        var a = new Box2();
        var b = new Box2();
        assert(b.equals(a), "Passed!");
        assert(a.equals(b), "Passed!");

        a = new Box2(One2.create(), Two2.create());
        b = new Box2(One2.create(), Two2.create());
        assert(b.equals(a), "Passed!");
        assert(a.equals(b), "Passed!");

        a = new Box2(One2.create(), Two2.create());
        b = a.clone();
        assert(b.equals(a), "Passed!");
        assert(a.equals(b), "Passed!");

        a = new Box2(One2.create(), Two2.create());
        b = new Box2(One2.create(), One2.create());
        assert(!b.equals(a), "Passed!");
        assert(!a.equals(b), "Passed!");

        a = new Box2();
        b = new Box2(One2.create(), One2.create());
        assert(!b.equals(a), "Passed!");
        assert(!a.equals(b), "Passed!");

        a = new Box2(One2.create(), Two2.create());
        b = new Box2(One2.create(), One2.create());
        assert(!b.equals(a), "Passed!");
        assert(!a.equals(b), "Passed!");
    }
}

class QUnit {
    static function module(name:String, callback:Void->Void) {
        callback();
    }
}

class Vector2 {
    var x:Float;
    var y:Float;

    function new(x:Float, y:Float) {
        this.x = x;
        this.y = y;
    }

    function clone() {
        return new Vector2(this.x, this.y);
    }

    function equals(v:Vector2) {
        return this.x == v.x && this.y == v.y;
    }

    function multiplyScalar(s:Float) {
        return new Vector2(this.x * s, this.y * s);
    }
}

class Box2 {
    var min:Vector2;
    var max:Vector2;

    function new(?min:Vector2, ?max:Vector2) {
        if (min == null) {
            min = PosInf2.create();
        }
        if (max == null) {
            max = NegInf2.create();
        }
        this.min = min;
        this.max = max;
    }

    function clone() {
        return new Box2(this.min.clone(), this.max.clone());
    }

    function copy(source:Box2) {
        this.min = source.min.clone();
        this.max = source.max.clone();
    }

    function isEmpty() {
        return this.min.x > this.max.x;
    }

    function makeEmpty() {
        this.min = PosInf2.create();
        this.max = NegInf2.create();
    }

    function getCenter(target:Vector2) {
        return target.addVectors(this.min, this.max).multiplyScalar(0.5);
    }

    function getSize(target:Vector2) {
        return target.subVectors(this.max, this.min);
    }

    function expandByPoint(point:Vector2) {
        this.min.min(point);
        this.max.max(point);
    }

    function expandByVector(vector:Vector2) {
        this.min.sub(vector);
        this.max.add(vector);
    }

    function expandByScalar(scalar:Float) {
        this.expandByVector(new Vector2(scalar, scalar));
    }

    function containsPoint(point:Vector2) {
        return (point.x < this.min.x || point.x > this.max.x) ||
               (point.y < this.min.y || point.y > this.max.y);
    }

    function containsBox(box:Box2) {
        return this.min.x <= box.min.x && box.max.x <= this.max.x &&
               this.min.y <= box.min.y && box.max.y <= this.max.y;
    }

    function getParameter(point:Vector2, target:Vector2) {
        // This function assumes that point is on a line segment from min to max
        var division = new Vector2(this.max.x - this.min.x, this.max.y - this.min.y);
        return target.set(
            (point.x - this.min.x) / division.x,
            (point.y - this.min.y) / division.y
        );
    }

    function intersectsBox(box:Box2) {
        return this.max.x >= box.min.x && box.max.x >= this.min.x &&
               this.max.y >= box.min.y && box.max.y >= this.min.y;
    }

    function clampPoint(point:Vector2, target:Vector2) {
        return target.copy(this.min).max(this.max).clamp(point);
    }

    function distanceToPoint(point:Vector2) {
        var clampedPoint = new Vector2();
        this.clampPoint(point, clampedPoint);
        return clampedPoint.sub(point).length();
    }

    function intersect(box:Box2) {
        this.min.max(box.min);
        this.max.min(box.max);
    }

    function union(box:Box2) {
        this.min.min(box.min);
        this.max.max(box.max);
    }

    function translate(offset:Vector2) {
        this.min.add(offset);
        this.max.add(offset);
    }

    function equals(box:Box2) {
        return this.min.equals(box.min) && this.max.equals(box.max);
    }
}

class PosInf2 {
    static function create() {
        return new Vector2(Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY);
    }
}

class NegInf2 {
    static function create() {
        return new Vector2(Float.NEGATIVE_INFINITY, Float.NEGATIVE_INFINITY);
    }
}

class Zero2 {
    static function create() {
        return new Vector2(0, 0);
    }

    static function clone() {
        return new Vector2(0, 0);
    }
}

class One2 {
    static function create() {
        return new Vector2(1, 1);
    }

    static function clone() {
        return new Vector2(1, 1);
    }
}

class Two2 {
    static function create() {
        return new Vector2(2, 2);
    }

    static function clone() {
        return new Vector2(2, 2);
    }
}

class NegOne2 {
    static function create() {
        return new Vector2(-1, -1);
    }
}

class Main {
    static function main() {
        Box2Test.instancing();
        Box2Test.isBox2();
        Box2Test.set();
        Box2Test.setFromPoints();
        Box2Test.setFromCenterAndSize();
        Box2Test.clone();
        Box2Test.copy();
        Box2Test.emptyMakeEmpty();
        Box2Test.isEmpty();
        Box2Test.getCenter();
        Box2Test.getSize();
        Box2Test.expandByPoint();
        Box2Test.expandByVector();
        Box2Test.expandByScalar();
        Box2Test.containsPoint();
        Box2Test.containsBox();
        Box2Test.getParameter();
        Box2Test.intersectsBox();
        Box2Test.clampPoint();
        Box2Test.distanceToPoint();
        Box2Test.intersect();
        Box2Test.union();
        Box2Test.translate();
        Box2Test.equals();
    }
}