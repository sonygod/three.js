import js.three.BufferAttribute;
import js.three.BufferGeometry;
import js.math.Vector2;
import js.math.Vector3;

class CylinderGeometry extends BufferGeometry {

    public var radiusTop: Float;
    public var radiusBottom: Float;
    public var height: Float;
    public var radialSegments: Int;
    public var heightSegments: Int;
    public var openEnded: Bool;
    public var thetaStart: Float;
    public var thetaLength: Float;

    public function new(radiusTop: Float = 1, radiusBottom: Float = 1, height: Float = 1, radialSegments: Int = 32, heightSegments: Int = 1, openEnded: Bool = false, thetaStart: Float = 0, thetaLength: Float = Math.PI * 2): Void {
        super();

        this.radiusTop = radiusTop;
        this.radiusBottom = radiusBottom;
        this.height = height;
        this.radialSegments = radialSegments;
        this.heightSegments = heightSegments;
        this.openEnded = openEnded;
        this.thetaStart = thetaStart;
        this.thetaLength = thetaLength;

        var scope = this;

        radialSegments = Math.floor(radialSegments);
        heightSegments = Math.floor(heightSegments);

        // buffers

        var indices: Array<Int> = [];
        var vertices: Array<Float> = [];
        var normals: Array<Float> = [];
        var uvs: Array<Float> = [];

        // helper variables

        var index: Int = 0;
        var indexArray: Array<Array<Int>> = [];
        var halfHeight: Float = height / 2;
        var groupStart: Int = 0;

        // generate geometry

        generateTorso();

        if (!openEnded) {
            if (radiusTop > 0) generateCap(true);
            if (radiusBottom > 0) generateCap(false);
        }

        // build geometry

        setIndex(indices);
        setAttribute("position", new BufferAttribute(vertices, 3));
        setAttribute("normal", new BufferAttribute(normals, 3));
        setAttribute("uv", new BufferAttribute(uvs, 2));

        function generateTorso(): Void {

            var normal = new Vector3();
            var vertex = new Vector3();
            var groupCount: Int = 0;

            // this will be used to calculate the normal
            var slope: Float = (radiusBottom - radiusTop) / height;

            // generate vertices, normals and uvs

            for (var y: Int = 0; y <= heightSegments; y++) {

                var indexRow: Array<Int> = [];

                var v: Float = y / heightSegments;

                // calculate the radius of the current row

                var radius: Float = v * (radiusBottom - radiusTop) + radiusTop;

                for (var x: Int = 0; x <= radialSegments; x++) {

                    var u: Float = x / radialSegments;

                    var theta: Float = u * thetaLength + thetaStart;

                    var sinTheta: Float = Math.sin(theta);
                    var cosTheta: Float = Math.cos(theta);

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

            for (var x: Int = 0; x < radialSegments; x++) {
                for (var y: Int = 0; y < heightSegments; y++) {

                    // we use the index array to access the correct indices

                    var a: Int = indexArray[y][x];
                    var b: Int = indexArray[y + 1][x];
                    var c: Int = indexArray[y + 1][x + 1];
                    var d: Int = indexArray[y][x + 1];

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

            addGroup(groupStart, groupCount, 0);

            // calculate new start value for groups

            groupStart += groupCount;

        }

        function generateCap(top: Bool): Void {

            // save the index of the first center vertex
            var centerIndexStart: Int = index;

            var uv = new Vector2();
            var vertex = new Vector3();
            var groupCount: Int = 0;

            var r: Float = top === true ? radiusTop : radiusBottom;
            var sign: Int = top === true ? 1 : -1;

            // first we generate the center vertex data of the cap.
            // because the geometry needs one set of uvs per face,
            // we must generate a center vertex per face/segment

            for (var x: Int = 1; x <= radialSegments; x++) {

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
            var centerIndexEnd: Int = index;

            // now we generate the surrounding vertices, normals and uvs

            for (var x: Int = 0; x <= radialSegments; x++) {

                var u: Float = x / radialSegments;
                var theta: Float = u * thetaLength + thetaStart;

                var cosTheta: Float = Math.cos(theta);
                var sinTheta: Float = Math.sin(theta);

                // vertex

                vertex.x = r * sinTheta;
                vertex.y = halfHeight * sign;
                vertex.z = r * cosTheta;
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

            for (var x: Int = 0; x < radialSegments; x++) {

                var c: Int = centerIndexStart + x;
                var i: Int = centerIndexEnd + x;

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

            addGroup(groupStart, groupCount, top === true ? 1 : 2);

            // calculate new start value for groups

            groupStart += groupCount;

        }

    }
    
    public function copy(source: CylinderGeometry): CylinderGeometry {
        super.copy(source);

        this.radiusTop = source.radiusTop;
        this.radiusBottom = source.radiusBottom;
        this.height = source.height;
        this.radialSegments = source.radialSegments;
        this.heightSegments = source.heightSegments;
        this.openEnded = source.openEnded;
        this.thetaStart = source.thetaStart;
        this.thetaLength = source.thetaLength;

        return this;
    }

    public static function fromJSON(data: Dynamic): CylinderGeometry {
        return new CylinderGeometry(data.radiusTop, data.radiusBottom, data.height, data.radialSegments, data.heightSegments, data.openEnded, data.thetaStart, data.thetaLength);
    }

}
```