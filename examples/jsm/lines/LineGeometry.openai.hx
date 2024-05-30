package three.js.examples.jsm.lines;

import three.js.examples.jsm.lines.LineSegmentsGeometry;

class LineGeometry extends LineSegmentsGeometry {
    public var isLineGeometry:Bool = true;
    public var type:String = 'LineGeometry';

    public function new() {
        super();
    }

    public function setPositions(array:Array<Float>):LineGeometry {
        var length:Int = array.length - 3;
        var points:Float32Array = new Float32Array(2 * length);

        for (i in 0...length step 3) {
            points[2 * i] = array[i];
            points[2 * i + 1] = array[i + 1];
            points[2 * i + 2] = array[i + 2];
            points[2 * i + 3] = array[i + 3];
            points[2 * i + 4] = array[i + 4];
            points[2 * i + 5] = array[i + 5];
        }

        super.setPositions(points);
        return this;
    }

    public function setColors(array:Array<Float>):LineGeometry {
        var length:Int = array.length - 3;
        var colors:Float32Array = new Float32Array(2 * length);

        for (i in 0...length step 3) {
            colors[2 * i] = array[i];
            colors[2 * i + 1] = array[i + 1];
            colors[2 * i + 2] = array[i + 2];
            colors[2 * i + 3] = array[i + 3];
            colors[2 * i + 4] = array[i + 4];
            colors[2 * i + 5] = array[i + 5];
        }

        super.setColors(colors);
        return this;
    }

    public function fromLine(line:Dynamic):LineGeometry {
        var geometry:Dynamic = line.geometry;
        this.setPositions(geometry.attributes.position.array); // assumes non-indexed
        // set colors, maybe
        return this;
    }
}

// export (not necessary in Haxe, but can be useful for compatibility)
// @:expose
// export var LineGeometry:Class<LineGeometry> = LineGeometry;