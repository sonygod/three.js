import js.html.ArrayBufferView;
import three.js.lines.LineSegmentsGeometry;

class LineGeometry extends LineSegmentsGeometry {

    public function new() {
        super();

        this.isLineGeometry = true;
        this.type = 'LineGeometry';
    }

    public function setPositions(array:Array<Float>):LineGeometry {
        var length = array.length - 3;
        var points = new Float32Array(2 * length);

        for (var i = 0; i < length; i += 3) {
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
        var length = array.length - 3;
        var colors = new Float32Array(2 * length);

        for (var i = 0; i < length; i += 3) {
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
        var geometry = line.geometry;
        this.setPositions(ArrayBufferView.wrap(geometry.attributes.position.array).getFloat32Data());
        return this;
    }
}