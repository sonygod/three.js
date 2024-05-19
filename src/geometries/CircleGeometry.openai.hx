import three.BufferGeometry;
import three.Float32BufferAttribute;
import three.Vector3;
import three.Vector2;

class CircleGeometry extends BufferGeometry {

    public var radius:Float;
    public var segments:Int;
    public var thetaStart:Float;
    public var thetaLength:Float;

    public function new(radius:Float = 1, segments:Int = 32, thetaStart:Float = 0, thetaLength:Float = Math.PI * 2) {
        super();

        this.radius = radius;
        this.segments = Math.max(3, segments);
        this.thetaStart = thetaStart;
        this.thetaLength = thetaLength;

        this.indices = [];
        this.vertices = [];
        this.normals = [];
        this.uvs = [];

        var vertex = new Vector3();
        var uv = new Vector2();

        this.vertices.push(0, 0, 0);
        this.normals.push(0, 0, 1);
        this.uvs.push(0.5, 0.5);
        
        var i = 3;
        for (s in 0...segments+1) {
            var segment = thetaStart + s / segments * thetaLength;

            vertex.x = radius * Math.cos(segment);
            vertex.y = radius * Math.sin(segment);

            this.vertices.push(vertex.x, vertex.y, vertex.z);
            this.normals.push(0, 0, 1);

            uv.x = (this.vertices[i] / radius + 1) / 2;
            uv.y = (this.vertices[i + 1] / radius + 1) / 2;

            this.uvs.push(uv.x, uv.y);
            
            i += 3;
        }

        for (i in 1...segments+1) {
            this.indices.push(i, i + 1, 0);
        }

        this.setIndex(this.indices);
        this.setAttribute("position", new Float32BufferAttribute(this.vertices, 3));
        this.setAttribute("normal", new Float32BufferAttribute(this.normals, 3));
        this.setAttribute("uv", new Float32BufferAttribute(this.uvs, 2));
    }

    public function copy(source:CircleGeometry):CircleGeometry {
        super.copy(source);
        this.parameters = {radius: source.parameters.radius, segments: source.parameters.segments, thetaStart: source.parameters.thetaStart, thetaLength: source.parameters.thetaLength};
        return this;
    }

    public static function fromJSON(data):CircleGeometry {
        return new CircleGeometry(data.radius, data.segments, data.thetaStart, data.thetaLength);
    }

}
```