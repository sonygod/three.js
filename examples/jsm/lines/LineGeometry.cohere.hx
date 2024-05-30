import js.Browser.window;
import js.html.Float32Array;

class LineGeometry {
    public var isLineGeometry: Bool = true;
    public var type: String = 'LineGeometry';

    public function new() {
        // ...
    }

    public function setPositions(array: Array<Float>) -> Void {
        var length = array.length - 3;
        var points = new Float32Array(2 * length);

        for (i in 0...length) {
            var j = i * 2;
            var k = i * 3;
            points[j] = array[k];
            points[j + 1] = array[k + 1];
            points[j + 2] = array[k + 2];

            j += 3;
            k += 3;
            points[j] = array[k];
            points[j + 1] = array[k + 1];
            points[j + 2] = array[k + 2];
        }

        // ...
    }

    public function setColors(array: Array<Float>) -> Void {
        var length = array.length - 3;
        var colors = new Float32Array(2 * length);

        for (i in 0...length) {
            var j = i * 2;
            var k = i * 3;
            colors[j] = array[k];
            colors[j + 1] = array[k + 1];
            colors[j + 2] = array[k + 2];

            j += 3;
            k += 3;
            colors[j] = array[k];
            colors[j + 1] = array[k + 1];
            colors[j + 2] = array[k + 2];
        }

        // ...
    }

    public function fromLine(line: Line) -> Void {
        var geometry = line.geometry;

        this.setPositions(geometry.attributes.position.array);

        // ...
    }
}

class LineSegmentsGeometry {
    // ...
}

class Line {
    public var geometry: LineGeometry;
    // ...
}