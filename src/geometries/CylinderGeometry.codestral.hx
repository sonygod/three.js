import three.js.core.BufferGeometry;
import three.js.core.BufferAttribute;
import three.js.math.Vector3;
import three.js.math.Vector2;

class CylinderGeometry extends BufferGeometry {
    public var parameters:Dynamic;

    public function new(radiusTop:Float = 1, radiusBottom:Float = 1, height:Float = 1, radialSegments:Int = 32, heightSegments:Int = 1, openEnded:Bool = false, thetaStart:Float = 0, thetaLength:Float = Math.PI * 2) {
        super();

        this.type = 'CylinderGeometry';

        this.parameters = {
            radiusTop: radiusTop,
            radiusBottom: radiusBottom,
            height: height,
            radialSegments: radialSegments,
            heightSegments: heightSegments,
            openEnded: openEnded,
            thetaStart: thetaStart,
            thetaLength: thetaLength
        };

        radialSegments = Math.floor(radialSegments);
        heightSegments = Math.floor(heightSegments);

        var indices = new Array<Int>();
        var vertices = new Array<Float>();
        var normals = new Array<Float>();
        var uvs = new Array<Float>();

        var index = 0;
        var indexArray = new Array<Array<Int>>();
        var halfHeight = height / 2;
        var groupStart = 0;

        generateTorso();

        if (openEnded == false) {
            if (radiusTop > 0) generateCap(true);
            if (radiusBottom > 0) generateCap(false);
        }

        this.setIndex(indices);
        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));

        function generateTorso() {
            var normal = new Vector3();
            var vertex = new Vector3();

            var groupCount = 0;
            var slope = (radiusBottom - radiusTop) / height;

            for (var y = 0; y <= heightSegments; y++) {
                var indexRow = new Array<Int>();

                var v = y / heightSegments;
                var radius = v * (radiusBottom - radiusTop) + radiusTop;

                for (var x = 0; x <= radialSegments; x++) {
                    var u = x / radialSegments;
                    var theta = u * thetaLength + thetaStart;

                    var sinTheta = Math.sin(theta);
                    var cosTheta = Math.cos(theta);

                    vertex.x = radius * sinTheta;
                    vertex.y = -v * height + halfHeight;
                    vertex.z = radius * cosTheta;
                    vertices.push(vertex.x, vertex.y, vertex.z);

                    normal.set(sinTheta, slope, cosTheta).normalize();
                    normals.push(normal.x, normal.y, normal.z);

                    uvs.push(u, 1 - v);
                    indexRow.push(index++);
                }

                indexArray.push(indexRow);
            }

            for (var x = 0; x < radialSegments; x++) {
                for (var y = 0; y < heightSegments; y++) {
                    var a = indexArray[y][x];
                    var b = indexArray[y + 1][x];
                    var c = indexArray[y + 1][x + 1];
                    var d = indexArray[y][x + 1];

                    indices.push(a, b, d);
                    indices.push(b, c, d);

                    groupCount += 6;
                }
            }

            this.addGroup(groupStart, groupCount, 0);
            groupStart += groupCount;
        }

        function generateCap(top:Bool) {
            var centerIndexStart = index;

            var uv = new Vector2();
            var vertex = new Vector3();

            var groupCount = 0;
            var radius = top == true ? radiusTop : radiusBottom;
            var sign = top == true ? 1 : -1;

            for (var x = 1; x <= radialSegments; x++) {
                vertices.push(0, halfHeight * sign, 0);
                normals.push(0, sign, 0);
                uvs.push(0.5, 0.5);

                index++;
            }

            var centerIndexEnd = index;

            for (var x = 0; x <= radialSegments; x++) {
                var u = x / radialSegments;
                var theta = u * thetaLength + thetaStart;

                var cosTheta = Math.cos(theta);
                var sinTheta = Math.sin(theta);

                vertex.x = radius * sinTheta;
                vertex.y = halfHeight * sign;
                vertex.z = radius * cosTheta;
                vertices.push(vertex.x, vertex.y, vertex.z);

                normals.push(0, sign, 0);

                uv.x = (cosTheta * 0.5) + 0.5;
                uv.y = (sinTheta * 0.5 * sign) + 0.5;
                uvs.push(uv.x, uv.y);

                index++;
            }

            for (var x = 0; x < radialSegments; x++) {
                var c = centerIndexStart + x;
                var i = centerIndexEnd + x;

                if (top == true) {
                    indices.push(i, i + 1, c);
                } else {
                    indices.push(i + 1, i, c);
                }

                groupCount += 3;
            }

            this.addGroup(groupStart, groupCount, top == true ? 1 : 2);
            groupStart += groupCount;
        }
    }

    public function copy(source:CylinderGeometry):CylinderGeometry {
        super.copy(source);
        this.parameters = haxe.ds.StringMap.copy(source.parameters);
        return this;
    }
}