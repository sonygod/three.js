import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector3;

class SphereGeometry extends BufferGeometry {
    public var parameters:Dynamic;

    public function new(radius:Float = 1, widthSegments:Int = 32, heightSegments:Int = 16, phiStart:Float = 0, phiLength:Float = Math.PI * 2, thetaStart:Float = 0, thetaLength:Float = Math.PI) {
        super();

        this.type = "SphereGeometry";

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
        var grid:Array<Array<Int>> = [];

        var vertex = new Vector3();
        var normal = new Vector3();

        // buffers

        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        // generate vertices, normals and uvs

        for (iy in 0...heightSegments + 1) {
            var verticesRow:Array<Int> = [];
            var v = iy / heightSegments;

            // special case for the poles

            var uOffset = 0;

            if (iy == 0 && thetaStart == 0) {
                uOffset = 0.5 / widthSegments;
            } else if (iy == heightSegments && thetaEnd == Math.PI) {
                uOffset = -0.5 / widthSegments;
            }

            for (ix in 0...widthSegments + 1) {
                var u = ix / widthSegments;

                // vertex

                vertex.x = -radius * Math.cos(phiStart + u * phiLength) * Math.sin(thetaStart + v * thetaLength);
                vertex.y = radius * Math.cos(thetaStart + v * thetaLength);
                vertex.z = radius * Math.sin(phiStart + u * phiLength) * Math.sin(thetaStart + v * thetaLength);

                vertices.push(vertex.x, vertex.y, vertex.z);

                // normal

                normal.copy(vertex).normalize();
                normals.push(normal.x, normal.y, normal.z);

                // uv

                uvs.push(u + uOffset, 1 - v);

                verticesRow.push(index++);
            }

            grid.push(verticesRow);
        }

        // indices

        for (iy in 0...heightSegments) {
            for (ix in 0...widthSegments) {
                var a = grid[iy][ix + 1];
                var b = grid[iy][ix];
                var c = grid[iy + 1][ix];
                var d = grid[iy + 1][ix + 1];

                if (iy != 0 || thetaStart > 0) indices.push(a, b, d);
                if (iy != heightSegments - 1 || thetaEnd < Math.PI) indices.push(b, c, d);
            }
        }

        // build geometry

        this.setIndex(indices);
        this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
        this.setAttribute("normal", new Float32BufferAttribute(normals, 3));
        this.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
    }

    public override function copy(source:BufferGeometry):BufferGeometry {
        super.copy(source);
        this.parameters = haxe.Json.parse(haxe.Json.stringify(source.parameters));
        return this;
    }

    public static function fromJSON(data:Dynamic):SphereGeometry {
        return new SphereGeometry(data.radius, data.widthSegments, data.heightSegments, data.phiStart, data.phiLength, data.thetaStart, data.thetaLength);
    }
}