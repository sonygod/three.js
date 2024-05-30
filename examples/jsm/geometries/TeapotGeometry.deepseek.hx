import three.BufferAttribute;
import three.BufferGeometry;
import three.Matrix4;
import three.Vector3;
import three.Vector4;

class TeapotGeometry extends BufferGeometry {

    public function new(size:Float = 50, segments:Int = 10, bottom:Bool = true, lid:Bool = true, body:Bool = true, fitLid:Bool = true, blinn:Bool = true) {

        var teapotPatches = [
            // ...
        ];

        var teapotVertices = [
            // ...
        ];

        super();

        // ...

        var indices = new Uint32Array(numTriangles * 3);

        var numVertices = bottom ? 4 : 0;
        numVertices += lid ? 8 : 0;
        numVertices += body ? 20 : 0;
        numVertices *= (segments + 1) * (segments + 1);

        var vertices = new Float32Array(numVertices * 3);
        var normals = new Float32Array(numVertices * 3);
        var uvs = new Float32Array(numVertices * 2);

        // ...

        this.setIndex(new BufferAttribute(indices, 1));
        this.setAttribute('position', new BufferAttribute(vertices, 3));
        this.setAttribute('normal', new BufferAttribute(normals, 3));
        this.setAttribute('uv', new BufferAttribute(uvs, 2));

        this.computeBoundingSphere();

    }

}