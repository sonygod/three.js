import js.Browser;
import js.html.CanvasElement;
import js.html.Document;
import js.html.Window;

import haxe.Resource;
import haxe.io.Bytes;

import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display.Loader;
import openfl.display.LoaderInfo;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProfile;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.CubeTexture;
import openfl.display3D.textures.RectangleTexture;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.TextureBase;
import openfl.display3D.textures.TextureType;
import openfl.errors.Error;
import openfl.errors.IOError;
import openfl.events.ActivityEvent;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.FocusEvent;
import openfl.events.FullScreenEvent;
import openfl.events.GameInputEvent;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.NetStatusEvent;
import openfl.events.ProgressEvent;
import openfl.events.RenderEvent;
import openfl.events.SecurityErrorEvent;
import openfl.events.TextEvent;
import openfl.events.UncaughtErrorEvent;
import openfl.events.UncaughtErrorEvents;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Matrix3D;
import openfl.geom.Orientation3D;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.media.SoundTransform;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.system.ApplicationDomain;
import openfl.system.LoaderContext;
import openfl.system.Security;
import openfl.text.Font;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.ArrayBufferView;
import openfl.utils.ByteArray;
import openfl.utils.Float32Array;
import openfl.utils.Object;
import openfl.utils.UInt8Array;

class Test {
    public static function main() {
        var canvas = cast CanvasElement (Window.window.document.getElementById("canvas"));
        var stage = Stage.createCanvas(canvas, null, null, 800, 600);
        stage.frameRate = 60;
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        stage.stageWidth = 800;
        stage.stageHeight = 600;
        stage.addEventListener(Event.ENTER_FRAME, stage_enterFrameHandler);

        var ellipseCurve = new openfl.extras.curves.EllipseCurve(0, 0, 10, 10, 0, 6.283185307179586, false, 0);

        function stage_enterFrameHandler(e:Event):Void {
            ellipseCurve.getSpacedPoints();
        }
    }
}

class EllipseCurve extends Curve {
    public function new(ax:Float = 0, ay:Float = 0, xRadius:Float = 0, yRadius:Float = 0, aStartAngle:Float = 0, aEndAngle:Float = 0, aClockwise:Bool = false, aRotation:Float = 0) {
        super();
    }

    public inline function get ax():Float {
        return _ax;
    }

    public inline function set ax(value:Float):Float {
        _ax = value;
    }

    public inline function get ay():Float {
        return _ay;
    }

    public inline function set ay(value:Float):Float {
        _ay = value;
    }

    public inline function get xRadius():Float {
        return _xRadius;
    }

    public inline function set xRadius(value:Float):Float {
        _xRadius = value;
    }

    public inline function get yRadius():Float {
        return _yRadius;
    }

    public inline function set yRadius(value:Float):Float {
        _yRadius = value;
    }

    public inline function get aStartAngle():Float {
        return _aStartAngle;
    }

    public inline function set aStartAngle(value:Float):Float {
        _aStartAngle = value;
    }

    public inline function get aEndAngle():Float {
        return _aEndAngle;
    }

    public inline function set aEndAngle(value:Float):Float {
        _aEndAngle = value;
    }

    public inline function get aClockwise():Bool {
        return _aClockwise;
    }

    public inline function set aClockwise(value:Bool):Bool {
        _aClockwise = value;
    }

    public inline function get aRotation():Float {
        return _aRotation;
    }

    public inline function set aRotation(value:Float):Float {
        _aRotation = value;
    }

    public function getPoint(t:Float, optional target:openfl.geom.Point = null):openfl.geom.Point {
        if (target == null) {
            target = new openfl.geom.Point();
        }

        var x = ax + xRadius * Math.cos(aStartAngle + t * (aEndAngle - aStartAngle));
        var y = ay + yRadius * Math.sin(aStartAngle + t * (aEndAngle - aStartAngle));

        target.x = x;
        target.y = y;

        return target;
    }

    public function getTangent(t:Float, optional target:openfl.geom.Point = null):openfl.geom.Point {
        if (target == null) {
            target = new openfl.geom.Point();
        }

        var delta = 0.001;
        var t1 = t - delta;
        var t2 = t + delta;

        if (t1 < 0) {
            t1 = 0;
        }

        if (t2 > 1) {
            t2 = 1;
        }

        var pt1 = getPoint(t1);
        var pt2 = getPoint(t2);

        target.x = (pt2.x - pt1.x) / (t2 - t1);
        target.y = (pt2.y - pt1.y) / (t2 - t1);

        return target;
    }

    public function getPoints(divisions:Int, optional target:Array<openfl.geom.Point> = null):Array<openfl.geom.Point> {
        if (target == null) {
            target = new Array<openfl.geom.Point>();
        }

        var pt:openfl.geom.Point;
        var i:Int;

        for (i = 0; i < divisions + 1; i++) {
            pt = getPoint(i / divisions);
            target.push(pt);
        }

        return target;
    }

    public function getSpacedPoints(optional divisions:Int = 0):Array<openfl.geom.Point> {
        if (divisions == 0) {
            divisions = Math.ceil(getLength() / 20);
        }

        var pts:Array<openfl.geom.Point> = getPoints(divisions);
        var distances:Array<Float> = getLengths(divisions);
        var i:Int;
        var p:openfl.geom.Point;
        var d:Float;
        var total:Float = 0;
        var positions:Array<Float> = [];

        for (i = 0; i < divisions; i++) {
            d = distances[i];
            total += d;
            positions.push(total);
        }

        var results:Array<openfl.geom.Point> = [];
        var px:Float;
        var py:Float;

        for (i = 0; i < divisions; i++) {
            px = 0;
            py = 0;

            for (var j:Int = 0; j < divisions; j++) {
                p = pts[j];
                px += p.x * ((positions[i] - total) / distances[j]);
                py += p.y * ((positions[i] - total) / distances[j]);
            }

            results.push(new openfl.geom.Point(px, py));
        }

        return results;
    }

    public function getLength(resolution:Int = 12):Float {
        return getLengths(resolution)[resolution];
    }

    public function getLengths(divisions:Int, optional calcTangents:Bool = false):Array<Float> {
        var cache:Bool = _cacheLengths;
        _cacheLengths = true;

        if (!_lengths) {
            _lengths = [];
        }

        if (cache && _lengths.length > 0) {
            return _lengths;
        }

        var pts:Array<openfl.geom.Point> = getPoints(divisions);
        var distances:Array<Float> = [];
        var i:Int;
        var pt:openfl.geom.Point;
        var d:Float;
        var total:Float = 0;

        for (i = 0; i < divisions; i++) {
            pt = pts[i];
            d = (i > 0) ? pt.distanceTo(pts[i - 1]) : 0;
            distances.push(d);
            total += d;
        }

        _lengths = distances;

        return _lengths;
    }

    public function getUtoTmapping(u:Float, length:Float):Float {
        var t:Float = 0;
        var ut:Float = u * getLength();
        var i:Int;
        var l:Float;
        var segmentLength:Float;

        for (i = 0; i < _lengths.length; i++) {
            l = _lengths[i];
            segmentLength = l / length;

            if (ut < segmentLength) {
                t = i / divisions;
                break;
            }

            ut -= segmentLength;
        }

        return t;
    }

    public function getEnvelope(divisions:Int):Array<openfl.geom.Point> {
        return getPoints(divisions);
    }

    public function getResolution(resolution:Int = 12):Int {
        return resolution;
    }

    public function clone():openfl.extras.curves.EllipseCurve {
        return new openfl.extras.curves.EllipseCurve(ax, ay, xRadius, yRadius, aStartAngle, aEndAngle, aClockwise, aRotation);
    }

    public function toJSON():Dynamic {
        return {
            ax: ax,
            ay: ay,
            xRadius: xRadius,
            yRadius: yRadius,
            aStartAngle: aStartAngle,
            aEndAngle: aEndAngle,
            aClockwise: aClockwise,
            aRotation: aRotation
        };
    }

    public static function fromJSON(data:Dynamic):openfl.extras.curves.EllipseCurve {
        return new openfl.extras.curves.EllipseCurve(data.ax, data.ay, data.xRadius, data.yRadius, data.aStartAngle, data.aEndAngle, data.aClockwise, data.aRotation);
    }

    private var _ax:Float;
    private var _ay:Float;
    private var _xRadius:Float;
    private var _yRadius:Float;
    private var _aStartAngle:Float;
    private var _aEndAngle:Float;
    private var _aClockwise:Bool;
    private var _aRotation:Float;
    private var _lengths:Array<Float>;
    private var _cacheLengths:Bool = false;
}

class Curve extends openfl.events.EventDispatcher {
    public function new() {
        super();
    }

    public function getPoint(t:Float, optional target:openfl.geom.Point = null):openfl.geom.Point {
        return target;
    }

    public function getTangent(t:Float, optional target:openfl.geom.Point = null):openfl.geom.Point {
        return target;
    }

    public function getPoints(divisions:Int, optional target:Array<openfl.geom.Point> = null):Array<openfl.geom.Point> {
        return target;
    }

    public function getSpacedPoints(optional divisions:Int = 0):Array<openfl.geom.Point> {
        return new Array<openfl.geom.Point>();
    }

    public function getLength(resolution:Int = 12):Float {
        return 0;
    }

    public function getLengths(divisions:Int, optional calcTangents:Bool = false):Array<Float> {
        return new Array<Float>();
    }

    public function getUtoTmapping(u:Float, length:Float):Float {
        return 0;
    }

    public function getEnvelope(divisions:Int):Array<openfl.geom.Point> {
        return new Array<openfl.geom.Point>();
    }

    public function getResolution(resolution:Int = 12):Int {
        return 0;
    }

    public function clone():Curve {
        return new Curve();
    }

    public function toJSON():Dynamic {
        return {};
    }

    public static function fromJSON(data:Dynamic):Curve {
        return new Curve();
    }
}

class Vector2 {
    public function new(x:Float = 0, y:Float = 0) {
        this.x = x;
        this.y = y;
    }

    public function set(x:Float, y:Float):Void {
        this.x = x;
        this.y = y;
    }

    public function copy(source:Vector2):Void {
        this.x = source.x;
        this.y = source.y;
    }

    public function add(a:Vector2, b:Vector2):Void {
        this.x = a.x + b.x;
        this.y = a.y + b.y;
    }

    public function subtract(a:Vector2, b:Vector2):Void {
        this.x = a.x - b.x;
        this.y = a.y - b.y;
    }

    public function negate(a:Vector2):Void {
        this.x = -a.x;
        this.y = -a.y;
    }

    public function scale(a:Vector2, s:Float):Void {
        this.x = a.x * s;
        this.y = a.y * s;
    }

    public function normalize(optional length:Float = 1):Float {
        var l:Float = length / this.length;
        this.x *= l;
        this.y *= l;

        return this.length;
    }

    public function dot(a:Vector2, b:Vector2):Float {
        return a.x * b.x + a.y * b.y;
    }

    public function cross(a:Vector2, b:Vector2):Float {
        return a.x * b.y - a.y * b.x;
    }

    public function reflect(a:Vector2, normal:Vector2):Void {
        var dot:Float = a.x * normal.x + a.y * normal.y;
        this.x = a.x - (normal.x * 2 * dot);
        this.y = a.y - (normal.y * 2 * dot);
    }

    public function distanceTo(a:Vector2, b:Vector2):Float {
        var dx:Float = b.x - a.x;
        var dy:Float = b.y - a.y;

        return Math.sqrt(dx * dx + dy * dy);
    }

    public function distanceSquared(a:Vector2, b:Vector2):Float {
        var dx:Float = b.x - a.x;
        var dy:Float = b.y - a.y;

        return (dx * dx + dy * dy);
    }

    public function lerp(a:Vector2, b:Vector2, t:Float):Void {
        this.x = a.x + (b.x - a.x) * t;
        this.y = a.y + (b.y - a.y) * t;
    }

    public function clone():Vector2 {
        return new Vector2(this.x, this.y);
    }

    public function equals(a:Vector2, b:Vector2):Bool {
        return (a.x == b.x && a.y == b.y);
    }

    public function toString():String {
        return "Vector2(" + this.x + ", " + this.y + ")";
    }

    public var x:Float;
    public var y:Float;
}