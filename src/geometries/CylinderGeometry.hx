package three.geometries;

import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
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

        // buffers

        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        // helper variables

        var index:Int = 0;
        var indexArray:Array<Array<Int>> = [];
        var halfHeight:Float = height / 2;
        var groupStart:Int = 0;

        // generate geometry

        generateTorso();

        if (!openEnded) {
            if (radiusTop > 0) generateCap(true);
            if (radiusBottom > 0) generateCap(false);
        }

        // build geometry

        this.setIndex(indices);
        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));

        function generateTorso() {
            var normal:Vector3 = new Vector3();
            var vertex:Vector3 = new Vector3();

            var groupCount:Int = 0;

            // this will be used to calculate the normal
            var slope:Float = (radiusBottom - radiusTop) / height;

            // generate vertices, normals and uvs

            for (y in 0...heightSegments + 1) {
                var indexRow:Array<Int> = [];

                var v:Float = y / heightSegments;

                // calculate the radius of the current row

                var radius:Float = v * (radiusBottom - radiusTop) + radiusTop;

                for (x in 0...radialSegments + 1) {
                    var u:Float = x / radialSegments;

                    var theta:Float = u * thetaLength + thetaStart;

                    var sinTheta:Float = Math.sin(theta);
                    var cosTheta:Float = Math.cos(theta);

                    // vertex

                    vertex.x = radius * sinTheta;
                    vertex.y = -v * height + halfHeight;
                    vertex.z = radius * cosTheta;
                    vertices.push(vertex.x);
                    vertices.push(vertex.y);
                    vertices.push(vertex.z);

                    // normal

                    normal.set(sinTheta, slope, cosTheta).normalize();
                    normals.push(normal.x);
                    normals.push(normal.y);
                    normals.push(normal.z);

                    // uv

                    uvs.push(u);
                    uvs.push(1 - v);

                    // save index of vertex in respective row

                    indexRow.push(index++);
                }

                // now save vertices of the row in our index array

                indexArray.push(indexRow);
            }

            // generate indices

            for (x in 0...radialSegments) {
                for (y in 0...heightSegments) {
                    // we use the index array to access the correct indices

                    var a:Int = indexArray[y][x];
                    var b:Int = indexArray[y + 1][x];
                    var c:Int = indexArray[y + 1][x + 1];
                    var d:Int = indexArray[y][x + 1];

                    // faces

                    indices.push(a);
                    indices.push(b);
                    indices.push(d);
                    indices.push(b);
                    indices.push(c);
                    indices.push(d);

                    // update group counter

                    groupCount += 6;
                }
            }

            // add a group to the geometry. this will ensure multi material support

            scope.addGroup(groupStart, groupCount, 0);

            // calculate new start value for groups

            groupStart += groupCount;
        }

        function generateCap(top:Bool) {
            // save the index of the first center vertex
            var centerIndexStart:Int = index;

            var uv:Vector2 = new Vector2();
            var vertex:Vector3 = new Vector3();

            var groupCount:Int = 0;

            var radius:Float = (top) ? radiusTop : radiusBottom;
            var sign:Float = (top) ? 1 : -1;

            // first we generate the center vertex data of the cap.
            // because the geometry needs one set of uvs per face,
            // we must generate a center vertex per face/segment

            for (x in 1...radialSegments + 1) {
                // vertex

                vertices.push(0);
                vertices.push(halfHeight * sign);
                vertices.push(0);

                // normal

                normals.push(0);
                normals.push(sign);
                normals.push(0);

                // uv

                uvs.push(0.5);
                uvs.push(0.5);

                // increase index

                index++;
            }

            // save the index of the last center vertex
            var centerIndexEnd:Int = index;

            // now we generate the surrounding vertices, normals and uvs

            for (x in 0...radialSegments + 1) {
                var u:Float = x / radialSegments;
                var theta:Float = u * thetaLength + thetaStart;

                var cosTheta:Float = Math.cos(theta);
                var sinTheta:Float = Math.sin(theta);

                // vertex

                vertex.x = radius * sinTheta;
                vertex.y = halfHeight * sign;
                vertex.z = radius * cosTheta;
                vertices.push(vertex.x);
                vertices.push(vertex.y);
                vertices.push(vertex.z);

                // normal

                normals.push(0);
                normals.push(sign);
                normals.push(0);

                // uv

                uv.x = (cosTheta * 0.5) + 0.5;
                uv.y = (sinTheta * 0.5 * sign) + 0.5;
                uvs.push(uv.x);
                uvs.push(uv.y);

                // increase index

                index++;
            }

            // generate indices

            for (x in 0...radialSegments) {
                var c:Int = centerIndexStart + x;
                var i:Int = centerIndexEnd + x;

                if (top) {
                    // face top

                    indices.push(i);
                    indices.push(i + 1);
                    indices.push(c);
                } else {
                    // face bottom

                    indices.push(i + 1);
                    indices.push(i);
                    indices.push(c);
                }

                groupCount += 3;
            }

            // add a group to the geometry. this will ensure multi material support

            scope.addGroup(groupStart, groupCount, top ? 1 : 2);

            // calculate new start value for groups

            groupStart += groupCount;
        }
    }

    public function copy(source:CylinderGeometry):CylinderGeometry {
        super.copy(source);

        this.parameters = Object.assign({}, source.parameters);

        return this;
    }

    public static function fromJSON(data:Dynamic):CylinderGeometry {
        return new CylinderGeometry(data.radiusTop, data.radiusBottom, data.height, data.radialSegments, data.heightSegments, data.openEnded, data.thetaStart, data.thetaLength);
    }
}