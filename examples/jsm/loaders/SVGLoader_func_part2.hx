package three.js.examples.jsm.loaders;

import Vector2;

class SVGLoader {
    static function createShapes(shapePath:ShapePath):Array<Shape> {
        // ...
    }

    static function getStrokeStyle(width:Float, color:String, lineJoin:String, lineCap:String, miterLimit:Float):StrokeStyle {
        // ...
    }

    static function pointsToStroke(points:Array<Vector2>, style:StrokeStyle, arcDivisions:Int, minDistance:Float):BufferGeometry {
        // ...
    }
}

class Shape {
    public var curves:Array<Curve>;
    public var holes:Array<Path>;

    public function new() {
        curves = new Array<Curve>();
        holes = new Array<Path>();
    }
}

class Path {
    public var curves:Array<Curve>;

    public function new() {
        curves = new Array<Curve>();
    }
}

class Curve {
    // ...
}

class StrokeStyle {
    public var strokeColor:String;
    public var strokeWidth:Float;
    public var strokeLineJoin:String;
    public var strokeLineCap:String;
    public var strokeMiterLimit:Float;

    public function new() {}
}

class BufferGeometry {
    public var vertices:Array<Float>;
    public var normals:Array<Float>;
    public var uvs:Array<Float>;

    public function new() {
        vertices = new Array<Float>();
        normals = new Array<Float>();
        uvs = new Array<Float>();
    }
}

class Vector2 {
    public var x:Float;
    public var y:Float;

    public function new(x:Float, y:Float) {
        this.x = x;
        this.y = y;
    }
}

class Box2 {
    public var min:Vector2;
    public var max:Vector2;

    public function new(min:Vector2, max:Vector2) {
        this.min = min;
        this.max = max;
    }
}

class IntersectionLocationType {
    public static inline var ORIGIN:Int = 0;
    public static inline var DESTINATION:Int = 1;
    public static inline var BETWEEN:Int = 2;
    public static inline var LEFT:Int = 3;
    public static inline var RIGHT:Int = 4;
    public static inline var BEHIND:Int = 5;
    public static inline var BEYOND:Int = 6;
}

// ...