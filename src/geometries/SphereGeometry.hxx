package three.js.src.geometries;

import three.js.src.core.BufferGeometry;
import three.js.src.core.BufferAttribute;
import three.js.src.math.Vector3;

class SphereGeometry extends BufferGeometry {

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

        widthSegments = Math.max(3, Std.int(widthSegments));
        heightSegments = Math.max(2, Std.int(heightSegments));

        var thetaEnd = Math.min(thetaStart + thetaLength, Math.PI);

        var index = 0;
        var grid = [];

        var vertex = new Vector3();
        var normal = new Vector3();

        var indices = [];
        var vertices = [];
        var normals = [];
        var uvs = [];

        for (iy in 0...heightSegments+1) {
            var verticesRow = [];

            var v = iy / heightSegments;

            var uOffset = 0;

            if (iy == 0 && thetaStart == 0) {
                uOffset = 0.5 / widthSegments;
            } else if (iy == heightSegments && thetaEnd == Math.PI) {
                uOffset = - 0.5 / widthSegments;
            }

            for (ix in 0...widthSegments+1) {
                var u = ix / widthSegments;

                vertex.x = - radius * Math.cos(phiStart + u * phiLength) * Math.sin(thetaStart + v * thetaLength);
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

        this.setIndex(indices);
        this.setAttribute('position', new BufferAttribute(vertices, 3));
        this.setAttribute('normal', new BufferAttribute(normals, 3));
        this.setAttribute('uv', new BufferAttribute(uvs, 2));
    }

    public function copy(source:SphereGeometry):SphereGeometry {
        super.copy(source);

        this.parameters = Std.clone(source.parameters);

        return this;
    }

    public static function fromJSON(data:Dynamic):SphereGeometry {
        return new SphereGeometry(data.radius, data.widthSegments, data.heightSegments, data.phiStart, data.phiLength, data.thetaStart, data.thetaLength);
    }
}