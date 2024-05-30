import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector3;

class BoxGeometry extends BufferGeometry {
    public var parameters:Dynamic;

    public function new(width:Float = 1, height:Float = 1, depth:Float = 1, widthSegments:Int = 1, heightSegments:Int = 1, depthSegments:Int = 1) {
        super();

        this.type = "BoxGeometry";

        this.parameters = {
            width: width,
            height: height,
            depth: depth,
            widthSegments: widthSegments,
            heightSegments: heightSegments,
            depthSegments: depthSegments
        };

        var scope = this;

        // segments
        widthSegments = Math.floor(widthSegments);
        heightSegments = Math.floor(heightSegments);
        depthSegments = Math.floor(depthSegments);

        // buffers
        var indices = [];
        var vertices = [];
        var normals = [];
        var uvs = [];

        // helper variables
        var numberOfVertices = 0;
        var groupStart = 0;

        // build each side of the box geometry
        buildPlane("z", "y", "x", -1, -1, depth, height, width, depthSegments, heightSegments, 0); // px
        buildPlane("z", "y", "x", 1, -1, depth, height, -width, depthSegments, heightSegments, 1); // nx
        buildPlane("x", "z", "y", 1, 1, width, depth, height, widthSegments, depthSegments, 2); // py
        buildPlane("x", "z", "y", 1, -1, width, depth, -height, widthSegments, depthSegments, 3); // ny
        buildPlane("x", "y", "z", 1, -1, width, height, depth, widthSegments, heightSegments, 4); // pz
        buildPlane("x", "y", "z", -1, -1, width, height, -depth, widthSegments, heightSegments, 5); // nz

        // build geometry
        this.setIndex(indices);
        this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
        this.setAttribute("normal", new Float32BufferAttribute(normals, 3));
        this.setAttribute("uv", new Float32BufferAttribute(uvs, 2));

        function buildPlane(u:String, v:String, w:String, udir:Int, vdir:Int, width:Float, height:Float, depth:Float, gridX:Int, gridY:Int, materialIndex:Int) {
            var segmentWidth = width / gridX;
            var segmentHeight = height / gridY;

            var widthHalf = width / 2;
            var heightHalf = height / 2;
            var depthHalf = depth / 2;

            var gridX1 = gridX + 1;
            var gridY1 = gridY + 1;

            var vertexCounter = 0;
            var groupCount = 0;

            var vector = new Vector3();

            // generate vertices, normals and uvs
            for (iy in 0...gridY1) {
                var y = iy * segmentHeight - heightHalf;

                for (ix in 0...gridX1) {
                    var x = ix * segmentWidth - widthHalf;

                    // set values to correct vector component
                    vector[u] = x * udir;
                    vector[v] = y * vdir;
                    vector[w] = depthHalf;

                    // now apply vector to vertex buffer
                    vertices.push(vector.x, vector.y, vector.z);

                    // set values to correct vector component
                    vector[u] = 0;
                    vector[v] = 0;
                    vector[w] = depth > 0 ? 1 : -1;

                    // now apply vector to normal buffer
                    normals.push(vector.x, vector.y, vector.z);

                    // uvs
                    uvs.push(ix / gridX);
                    uvs.push(1 - (iy / gridY));

                    // counters
                    vertexCounter += 1;
                }
            }

            // indices
            // 1. you need three indices to draw a single face
            // 2. a single segment consists of two faces
            // 3. so we need to generate six (2*3) indices per segment
            for (iy in 0...gridY) {
                for (ix in 0...gridX) {
                    var a = numberOfVertices + ix + gridX1 * iy;
                    var b = numberOfVertices + ix + gridX1 * (iy + 1);
                    var c = numberOfVertices + (ix + 1) + gridX1 * (iy + 1);
                    var d = numberOfVertices + (ix + 1) + gridX1 * iy;

                    // faces
                    indices.push(a, b, d);
                    indices.push(b, c, d);

                    // increase counter
                    groupCount += 6;
                }
            }

            // add a group to the geometry. this will ensure multi material support
            scope.addGroup(groupStart, groupCount, materialIndex);

            // calculate new start value for groups
            groupStart += groupCount;

            // update total number of vertices
            numberOfVertices += vertexCounter;
        }
    }

    public function copy(source:BoxGeometry):BoxGeometry {
        super.copy(source);

        this.parameters = {
            width: source.parameters.width,
            height: source.parameters.height,
            depth: source.parameters.depth,
            widthSegments: source.parameters.widthSegments,
            heightSegments: source.parameters.heightSegments,
            depthSegments: source.parameters.depthSegments
        };

        return this;
    }

    public static function fromJSON(data:Dynamic):BoxGeometry {
        return new BoxGeometry(data.width, data.height, data.depth, data.widthSegments, data.heightSegments, data.depthSegments);
    }
}