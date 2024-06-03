import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;

class SphereGeometry extends BufferGeometry {
    public var parameters:Dynamic;

    public function new(radius:Float = 1, widthSegments:Int = 32, heightSegments:Int = 16, phiStart:Float = 0, phiLength:Float = Math.PI * 2, thetaStart:Float = 0, thetaLength:Float = Math.PI) {
        super();

        this.type = 'SphereGeometry';

        this.parameters = {
            radius: radius,
            widthSegments: widthSegments,
            heightSegments: heightSegments,
            phiStart: phiStart,
            phiLength: phiLength,
            thetaStart: thetaStart,
            thetaLength: thetaLength
        };

        widthSegments = Math.max(3, Math.floor(widthSegments));
        heightSegments = Math.max(2, Math.floor(heightSegments));

        var thetaEnd = Math.min(thetaStart + thetaLength, Math.PI);

        var index = 0;
        var grid = new Array<Array<Int>>();

        var vertex = new Vector3();
        var normal = new Vector3();

        var indices = new Array<Int>();
        var vertices = new Array<Float>();
        var normals = new Array<Float>();
        var uvs = new Array<Float>();

        for (var iy = 0; iy <= heightSegments; iy++) {
            var verticesRow = new Array<Int>();

            var v = iy / heightSegments;

            var uOffset = 0;

            if (iy == 0 && thetaStart == 0) {
                uOffset = 0.5 / widthSegments;
            } else if (iy == heightSegments && thetaEnd == Math.PI) {
                uOffset = -0.5 / widthSegments;
            }

            for (var ix = 0; ix <= widthSegments; ix++) {
                var u = ix / widthSegments;

                vertex.x = -radius * Math.cos(phiStart + u * phiLength) * Math.sin(thetaStart + v * thetaLength);
                vertex.y = radius * Math.cos(thetaStart + v * thetaLength);
                vertex.z = radius * Math.sin(phiStart + u * phiLength) * Math.sin(thetaStart + v * thetaLength);

                vertices.push(vertex.x, vertex.y, vertex.z);

                normal.copy(vertex).normalize();
                normals.push(normal.x, normal.y, normal.z);

                uvs.push(u + uOffset, 1 - v);

                verticesRow.push(index++);
            }

            grid.push(verticesRow);
        }

        for (var iy = 0; iy < heightSegments; iy++) {
            for (var ix = 0; ix < widthSegments; ix++) {
                var a = grid[iy][ix + 1];
                var b = grid[iy][ix];
                var c = grid[iy + 1][ix];
                var d = grid[iy + 1][ix + 1];

                if (iy != 0 || thetaStart > 0) indices.push(a, b, d);
                if (iy != heightSegments - 1 || thetaEnd < Math.PI) indices.push(b, c, d);
            }
        }

        this.setIndex(indices);
        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
    }

    public function copy(source:SphereGeometry):SphereGeometry {
        super.copy(source);

        this.parameters = Reflect.copyFields(source.parameters, {});

        return this;
    }

    public static function fromJSON(data:Dynamic):SphereGeometry {
        return new SphereGeometry(data.radius, data.widthSegments, data.heightSegments, data.phiStart, data.phiLength, data.thetaStart, data.thetaLength);
    }
}

export SphereGeometry;