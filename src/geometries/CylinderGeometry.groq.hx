package three.geom;

import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;
import three.math.Vector2;

class CylinderGeometry extends BufferGeometry {

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

        var scope = this;

        radialSegments = Math.floor(radialSegments);
        heightSegments = Math.floor(heightSegments);

        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        var index:Int = 0;
        var indexArray:Array<Array<Int>> = [];
        var halfHeight:Float = height / 2;
        var groupStart:Int = 0;

        generateTorso();

        if (!openEnded) {
            if (radiusTop > 0) generateCap(true);
            if (radiusBottom > 0) generateCap(false);
        }

        this.setIndex(indices);
        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));

        function generateTorso() {
            var normal:Vector3 = new Vector3();
            var vertex:Vector3 = new Vector3();

            var groupCount:Int = 0;

            var slope:Float = (radiusBottom - radiusTop) / height;

            for (y in 0...heightSegments + 1) {
                var indexRow:Array<Int> = [];

                var v:Float = y / heightSegments;

                var radius:Float = v * (radiusBottom - radiusTop) + radiusTop;

                for (x in 0...radialSegments + 1) {
                    var u:Float = x / radialSegments;

                    var theta:Float = u * thetaLength + thetaStart;

                    var sinTheta:Float = Math.sin(theta);
                    var cosTheta:Float = Math.cos(theta);

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

            for (x in 0...radialSegments) {
                for (y in 0...heightSegments) {
                    var a:Int = indexArray[y][x];
                    var b:Int = indexArray[y + 1][x];
                    var c:Int = indexArray[y + 1][x + 1];
                    var d:Int = indexArray[y][x + 1];

                    indices.push(a, b, d);
                    indices.push(b, c, d);

                    groupCount += 6;
                }
            }

            scope.addGroup(groupStart, groupCount, 0);

            groupStart += groupCount;
        }

        function generateCap(top:Bool) {
            var centerIndexStart:Int = index;

            var uv:Vector2 = new Vector2();
            var vertex:Vector3 = new Vector3();

            var groupCount:Int = 0;

            var radius:Float = (top) ? radiusTop : radiusBottom;
            var sign:Int = (top) ? 1 : -1;

            for (x in 1...radialSegments + 1) {
                vertices.push(0, halfHeight * sign, 0);
                normals.push(0, sign, 0);
                uvs.push(0.5, 0.5);
                index++;
            }

            var centerIndexEnd:Int = index;

            for (x in 0...radialSegments + 1) {
                var u:Float = x / radialSegments;
                var theta:Float = u * thetaLength + thetaStart;

                var cosTheta:Float = Math.cos(theta);
                var sinTheta:Float = Math.sin(theta);

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

            for (x in 0...radialSegments) {
                var c:Int = centerIndexStart + x;
                var i:Int = centerIndexEnd + x;

                if (top) {
                    indices.push(i, i + 1, c);
                } else {
                    indices.push(i + 1, i, c);
                }

                groupCount += 3;
            }

            scope.addGroup(groupStart, groupCount, top ? 1 : 2);

            groupStart += groupCount;
        }
    }

    override public function copy(source:BufferGeometry) {
        super.copy(source);

        this.parameters = Object.assign({}, source.parameters);

        return this;
    }

    static public function fromJSON(data:Dynamic) {
        return new CylinderGeometry(data.radiusTop, data.radiusBottom, data.height, data.radialSegments, data.heightSegments, data.openEnded, data.thetaStart, data.thetaLength);
    }
}