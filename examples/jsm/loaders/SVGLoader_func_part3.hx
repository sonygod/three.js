package three.js.examples.jsm.loaders;

import Math;

class SVGLoader {
    static function pointsToStrokeWithBuffers(points:Array<Vector2>, style:Dynamic, arcDivisions:Int, minDistance:Float, vertices:Array<Float>, normals:Array<Float>, uvs:Array<Float>, vertexOffset:Int):Int {
        // ...
    }
}

class Vector2 {
    public var x:Float;
    public var y:Float;

    public function new(x:Float = 0, y:Float = 0) {
        this.x = x;
        this.y = y;
    }

    public function subVectors(v:Vector2):Vector2 {
        return new Vector2(x - v.x, y - v.y);
    }

    public function addVectors(v:Vector2):Vector2 {
        return new Vector2(x + v.x, y + v.y);
    }

    public function multiplyScalar(s:Float):Vector2 {
        return new Vector2(x * s, y * s);
    }

    public function normalize():Vector2 {
        var length = Math.sqrt(x * x + y * y);
        return new Vector2(x / length, y / length);
    }

    public function dot(v:Vector2):Float {
        return x * v.x + y * v.y;
    }

    public function distanceTo(v:Vector2):Float {
        return Math.sqrt(Math.pow(v.x - x, 2) + Math.pow(v.y - y, 2));
    }

    public function set(x:Float, y:Float):Vector2 {
        this.x = x;
        this.y = y;
        return this;
    }

    public function copy(v:Vector2):Vector2 {
        x = v.x;
        y = v.y;
        return this;
    }

    public function toArray(arr:Array<Float>, offset:Int):Void {
        arr[offset] = x;
        arr[offset + 1] = y;
    }
}

// ... other functions ...