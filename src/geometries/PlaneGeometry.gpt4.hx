import three.core.BufferGeometry;
import three.core.BufferAttribute.Float32BufferAttribute;

class PlaneGeometry extends BufferGeometry {
    
    public var parameters:Dynamic;

    public function new(width:Float = 1, height:Float = 1, widthSegments:Int = 1, heightSegments:Int = 1) {
        super();

        this.type = 'PlaneGeometry';

        this.parameters = {
            width: width,
            height: height,
            widthSegments: widthSegments,
            heightSegments: heightSegments
        };

        var width_half:Float = width / 2;
        var height_half:Float = height / 2;

        var gridX:Int = Math.floor(widthSegments);
        var gridY:Int = Math.floor(heightSegments);

        var gridX1:Int = gridX + 1;
        var gridY1:Int = gridY + 1;

        var segment_width:Float = width / gridX;
        var segment_height:Float = height / gridY;

        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        for (iy in 0...gridY1) {
            var y:Float = iy * segment_height - height_half;
            for (ix in 0...gridX1) {
                var x:Float = ix * segment_width - width_half;

                vertices.push(x, -y, 0);

                normals.push(0, 0, 1);

                uvs.push(ix / gridX);
                uvs.push(1 - (iy / gridY));
            }
        }

        for (iy in 0...gridY) {
            for (ix in 0...gridX) {
                var a:Int = ix + gridX1 * iy;
                var b:Int = ix + gridX1 * (iy + 1);
                var c:Int = (ix + 1) + gridX1 * (iy + 1);
                var d:Int = (ix + 1) + gridX1 * iy;

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

        this.parameters = {
            width: source.parameters.width,
            height: source.parameters.height,
            widthSegments: source.parameters.widthSegments,
            heightSegments: source.parameters.heightSegments
        };

        return this;
    }

    public static function fromJSON(data:Dynamic):PlaneGeometry {
        return new PlaneGeometry(data.width, data.height, data.widthSegments, data.heightSegments);
    }

}