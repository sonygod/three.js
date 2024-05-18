Here is the equivalent Haxe code:
```
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

        for (i in 0...length) {
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

        for (i in 0...length) {
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

    public function fromLine(line:Any):LineGeometry {
        var geometry:Any = line.geometry;
        setPositions(geometry.attributes.position.array); // assumes non-indexed
        // set colors, maybe
        return this;
    }
}

// export the class
extern class LineGeometry {}
```
Note that I've assumed that `Float32Array` is available in the Haxe target platform. If it's not, you may need to use a different type, such as `Array<Float>`.

Also, I've kept the same method and variable names as in the original JavaScript code, but in Haxe, it's conventional to use PascalCase for class names and camelCase for method and variable names.