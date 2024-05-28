package three.geom;

import three.buffer.BufferAttribute;
import three.buffer.BufferGeometry;
import three.math.Vector2;
import three.math.Vector3;
import three.math.MathUtils;

class LatheGeometry extends BufferGeometry {
    public function new(points:Array<Vector2> = [new Vector2(0, -0.5), new Vector2(0.5, 0), new Vector2(0, 0.5)],
                         segments:Int = 12, phiStart:Float = 0, phiLength:Float = Math.PI * 2) {
        super();
        this.type = 'LatheGeometry';

        this.parameters = {
            points: points,
            segments: segments,
            phiStart: phiStart,
            phiLength: phiLength
        };

        segments = Math.floor(segments);
        phiLength = MathUtils.clamp(phiLength, 0, Math.PI * 2);

        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var uvs:Array<Float> = [];
        var initNormals:Array<Float> = [];
        var normals:Array<Float> = [];

        var inverseSegments:Float = 1.0 / segments;
        var vertex:Vector3 = new Vector3();
        var uv:Vector2 = new Vector2();
        var normal:Vector3 = new Vector3();
        var curNormal:Vector3 = new Vector3();
        var prevNormal:Vector3 = new Vector3();
        var dx:Float = 0;
        var dy:Float = 0;

        for (j in 0...points.length) {
            switch (j) {
                case 0: // special handling for 1st vertex on path
                    dx = points[j + 1].x - points[j].x;
                    dy = points[j + 1].y - points[j].y;

                    normal.x = dy * 1.0;
                    normal.y = -dx;
                    normal.z = dy * 0.0;

                    prevNormal.copy(normal);

                    normal.normalize();

                    initNormals.push(normal.x, normal.y, normal.z);

                    break;

                case (points.length - 1): // special handling for last Vertex on path
                    initNormals.push(prevNormal.x, prevNormal.y, prevNormal.z);

                    break;

                default: // default handling for all vertices in between
                    dx = points[j + 1].x - points[j].x;
                    dy = points[j + 1].y - points[j].y;

                    normal.x = dy * 1.0;
                    normal.y = -dx;
                    normal.z = dy * 0.0;

                    curNormal.copy(normal);

                    normal.x += prevNormal.x;
                    normal.y += prevNormal.y;
                    normal.z += prevNormal.z;

                    normal.normalize();

                    initNormals.push(normal.x, normal.y, normal.z);

                    prevNormal.copy(curNormal);
            }
        }

        for (i in 0...segments + 1) {
            var phi:Float = phiStart + i * inverseSegments * phiLength;
            var sin:Float = Math.sin(phi);
            var cos:Float = Math.cos(phi);

            for (j in 0...points.length) {
                // vertex
                vertex.x = points[j].x * sin;
                vertex.y = points[j].y;
                vertex.z = points[j].x * cos;

                vertices.push(vertex.x, vertex.y, vertex.z);

                // uv
                uv.x = i / segments;
                uv.y = j / (points.length - 1);

                uvs.push(uv.x, uv.y);

                // normal
                var x:Float = initNormals[3 * j + 0] * sin;
                var y:Float = initNormals[3 * j + 1];
                var z:Float = initNormals[3 * j + 0] * cos;

                normals.push(x, y, z);
            }
        }

        for (i in 0...segments) {
            for (j in 0...(points.length - 1)) {
                var base:Int = j + i * points.length;

                var a:Int = base;
                var b:Int = base + points.length;
                var c:Int = base + points.length + 1;
                var d:Int = base + 1;

                indices.push(a, b, d);
                indices.push(c, d, b);
            }
        }

        this.setIndex(indices);
        this.setAttribute('position', new BufferAttribute(vertices, 3));
        this.setAttribute('uv', new BufferAttribute(uvs, 2));
        this.setAttribute('normal', new BufferAttribute(normals, 3));
    }

    public function copy(source:LatheGeometry):LatheGeometry {
        super.copy(source);

        this.parameters = Object.assign({}, source.parameters);

        return this;
    }

    static public function fromJSON(data:Dynamic):LatheGeometry {
        return new LatheGeometry(data.points, data.segments, data.phiStart, data.phiLength);
    }
}