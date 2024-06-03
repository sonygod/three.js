import js.Browser.document;
import js.html.Float32Array;
import js.html.ArrayBuffer;
import js.html.DataView;

class PlaneGeometry extends BufferGeometry {
    public var width:Float;
    public var height:Float;
    public var widthSegments:Int;
    public var heightSegments:Int;
    public var parameters:Dynamic;

    public function new(width:Float = 1, height:Float = 1, widthSegments:Int = 1, heightSegments:Int = 1) {
        super();
        this.type = 'PlaneGeometry';
        this.width = width;
        this.height = height;
        this.widthSegments = widthSegments;
        this.heightSegments = heightSegments;
        this.parameters = {
            width: width,
            height: height,
            widthSegments: widthSegments,
            heightSegments: heightSegments
        };

        var width_half = width / 2;
        var height_half = height / 2;
        var gridX = Math.floor(widthSegments);
        var gridY = Math.floor(heightSegments);
        var gridX1 = gridX + 1;
        var gridY1 = gridY + 1;
        var segment_width = width / gridX;
        var segment_height = height / gridY;
        var indices = [];
        var vertices = [];
        var normals = [];
        var uvs = [];

        for (var iy = 0; iy < gridY1; iy++) {
            var y = iy * segment_height - height_half;
            for (var ix = 0; ix < gridX1; ix++) {
                var x = ix * segment_width - width_half;
                vertices.push(x, -y, 0);
                normals.push(0, 0, 1);
                uvs.push(ix / gridX);
                uvs.push(1 - (iy / gridY));
            }
        }

        for (var iy = 0; iy < gridY; iy++) {
            for (var ix = 0; ix < gridX; ix++) {
                var a = ix + gridX1 * iy;
                var b = ix + gridX1 * (iy + 1);
                var c = (ix + 1) + gridX1 * (iy + 1);
                var d = (ix + 1) + gridX1 * iy;
                indices.push(a, b, d);
                indices.push(b, c, d);
            }
        }

        this.setIndex(indices);
        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
    }

    public function copy(source:PlaneGeometry):PlaneGeometry {
        super.copy(source);
        this.parameters = js.Boot.clone(source.parameters);
        return this;
    }

    public static function fromJSON(data:Dynamic):PlaneGeometry {
        return new PlaneGeometry(data.width, data.height, data.widthSegments, data.heightSegments);
    }
}