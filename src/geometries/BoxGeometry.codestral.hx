import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;

class BoxGeometry extends BufferGeometry {

    public var parameters:Dynamic;

    public function new(width:Float = 1, height:Float = 1, depth:Float = 1, widthSegments:Int = 1, heightSegments:Int = 1, depthSegments:Int = 1) {
        super();

        this.type = 'BoxGeometry';

        this.parameters = {
            width: width,
            height: height,
            depth: depth,
            widthSegments: widthSegments,
            heightSegments: heightSegments,
            depthSegments: depthSegments
        };

        // segments
        widthSegments = Std.int(widthSegments);
        heightSegments = Std.int(heightSegments);
        depthSegments = Std.int(depthSegments);

        // buffers
        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        // helper variables
        var numberOfVertices = 0;
        var groupStart = 0;

        // build each side of the box geometry
        buildPlane('z', 'y', 'x', -1, -1, depth, height, width, depthSegments, heightSegments, 0); // px
        buildPlane('z', 'y', 'x', 1, -1, depth, height, -width, depthSegments, heightSegments, 1); // nx
        buildPlane('x', 'z', 'y', 1, 1, width, depth, height, widthSegments, depthSegments, 2); // py
        buildPlane('x', 'z', 'y', 1, -1, width, depth, -height, widthSegments, depthSegments, 3); // ny
        buildPlane('x', 'y', 'z', 1, -1, width, height, depth, widthSegments, heightSegments, 4); // pz
        buildPlane('x', 'y', 'z', -1, -1, width, height, -depth, widthSegments, heightSegments, 5); // nz

        // build geometry
        this.setIndex(new Int32Array(indices));
        this.setAttribute('position', new BufferAttribute(new Float32Array(vertices), 3));
        this.setAttribute('normal', new BufferAttribute(new Float32Array(normals), 3));
        this.setAttribute('uv', new BufferAttribute(new Float32Array(uvs), 2));
    }

    private function buildPlane(u:String, v:String, w:String, udir:Int, vdir:Int, width:Float, height:Float, depth:Float, gridX:Int, gridY:Int, materialIndex:Int) {
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

        for (var iy = 0; iy < gridY1; iy++) {
            var y = iy * segmentHeight - heightHalf;

            for (var ix = 0; ix < gridX1; ix++) {
                var x = ix * segmentWidth - widthHalf;

                vector[u] = x * udir;
                vector[v] = y * vdir;
                vector[w] = depthHalf;

                vertices.push(vector.x, vector.y, vector.z);

                vector[u] = 0;
                vector[v] = 0;
                vector[w] = depth > 0 ? 1 : -1;

                normals.push(vector.x, vector.y, vector.z);

                uvs.push(ix / gridX);
                uvs.push(1 - (iy / gridY));

                vertexCounter += 1;
            }
        }

        for (var iy = 0; iy < gridY; iy++) {
            for (var ix = 0; ix < gridX; ix++) {
                var a = numberOfVertices + ix + gridX1 * iy;
                var b = numberOfVertices + ix + gridX1 * (iy + 1);
                var c = numberOfVertices + (ix + 1) + gridX1 * (iy + 1);
                var d = numberOfVertices + (ix + 1) + gridX1 * iy;

                indices.push(a, b, d);
                indices.push(b, c, d);

                groupCount += 6;
            }
        }

        this.addGroup(groupStart, groupCount, materialIndex);

        groupStart += groupCount;

        numberOfVertices += vertexCounter;
    }

    public function copy(source:BoxGeometry):BoxGeometry {
        super.copy(source);

        this.parameters = Reflect.copyFields(source.parameters, {});

        return this;
    }

    public static function fromJSON(data:Dynamic):BoxGeometry {
        return new BoxGeometry(data.width, data.height, data.depth, data.widthSegments, data.heightSegments, data.depthSegments);
    }
}