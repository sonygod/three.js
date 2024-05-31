import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector3;

class TorusKnotGeometry extends BufferGeometry {

  public var radius:Float;
  public var tube:Float;
  public var tubularSegments:Int;
  public var radialSegments:Int;
  public var p:Int;
  public var q:Int;

  public function new(radius:Float = 1, tube:Float = 0.4, tubularSegments:Int = 64, radialSegments:Int = 8, p:Int = 2, q:Int = 3) {
    super();
    this.type = "TorusKnotGeometry";
    this.parameters = {
      "radius": radius,
      "tube": tube,
      "tubularSegments": tubularSegments,
      "radialSegments": radialSegments,
      "p": p,
      "q": q
    };
    this.radius = radius;
    this.tube = tube;
    this.tubularSegments = tubularSegments;
    this.radialSegments = radialSegments;
    this.p = p;
    this.q = q;
    this.generateGeometry();
  }

  private function generateGeometry() {
    var indices = new Array<Int>();
    var vertices = new Array<Float>();
    var normals = new Array<Float>();
    var uvs = new Array<Float>();

    var vertex = new Vector3();
    var normal = new Vector3();

    var P1 = new Vector3();
    var P2 = new Vector3();

    var B = new Vector3();
    var T = new Vector3();
    var N = new Vector3();

    for (i in 0...this.tubularSegments + 1) {
      var u = i / this.tubularSegments * this.p * Math.PI * 2;
      calculatePositionOnCurve(u, this.p, this.q, this.radius, P1);
      calculatePositionOnCurve(u + 0.01, this.p, this.q, this.radius, P2);

      T.subVectors(P2, P1);
      N.addVectors(P2, P1);
      B.crossVectors(T, N);
      N.crossVectors(B, T);

      B.normalize();
      N.normalize();

      for (j in 0...this.radialSegments + 1) {
        var v = j / this.radialSegments * Math.PI * 2;
        var cx = -this.tube * Math.cos(v);
        var cy = this.tube * Math.sin(v);

        vertex.x = P1.x + (cx * N.x + cy * B.x);
        vertex.y = P1.y + (cx * N.y + cy * B.y);
        vertex.z = P1.z + (cx * N.z + cy * B.z);

        vertices.push(vertex.x);
        vertices.push(vertex.y);
        vertices.push(vertex.z);

        normal.subVectors(vertex, P1).normalize();

        normals.push(normal.x);
        normals.push(normal.y);
        normals.push(normal.z);

        uvs.push(i / this.tubularSegments);
        uvs.push(j / this.radialSegments);
      }
    }

    for (j in 1...this.tubularSegments + 1) {
      for (i in 1...this.radialSegments + 1) {
        var a = (this.radialSegments + 1) * (j - 1) + (i - 1);
        var b = (this.radialSegments + 1) * j + (i - 1);
        var c = (this.radialSegments + 1) * j + i;
        var d = (this.radialSegments + 1) * (j - 1) + i;

        indices.push(a);
        indices.push(b);
        indices.push(d);
        indices.push(b);
        indices.push(c);
        indices.push(d);
      }
    }

    this.setIndex(new IntBufferAttribute(indices, 1));
    this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
    this.setAttribute("normal", new Float32BufferAttribute(normals, 3));
    this.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
  }

  private function calculatePositionOnCurve(u:Float, p:Int, q:Int, radius:Float, position:Vector3) {
    var cu = Math.cos(u);
    var su = Math.sin(u);
    var quOverP = q / p * u;
    var cs = Math.cos(quOverP);

    position.x = radius * (2 + cs) * 0.5 * cu;
    position.y = radius * (2 + cs) * su * 0.5;
    position.z = radius * Math.sin(quOverP) * 0.5;
  }

  public function copy(source:TorusKnotGeometry):TorusKnotGeometry {
    super.copy(source);
    this.radius = source.radius;
    this.tube = source.tube;
    this.tubularSegments = source.tubularSegments;
    this.radialSegments = source.radialSegments;
    this.p = source.p;
    this.q = source.q;
    return this;
  }

  public static function fromJSON(data:Dynamic):TorusKnotGeometry {
    return new TorusKnotGeometry(data.radius, data.tube, data.tubularSegments, data.radialSegments, data.p, data.q);
  }

}