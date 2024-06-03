import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector3;

class TorusGeometry extends BufferGeometry {

  public var radius:Float;
  public var tube:Float;
  public var radialSegments:Int;
  public var tubularSegments:Int;
  public var arc:Float;

  public function new(radius = 1, tube = 0.4, radialSegments = 12, tubularSegments = 48, arc = Math.PI * 2) {
    super();

    this.type = "TorusGeometry";

    this.radius = radius;
    this.tube = tube;
    this.radialSegments = Math.floor(radialSegments);
    this.tubularSegments = Math.floor(tubularSegments);
    this.arc = arc;

    // buffers
    var indices:Array<Int> = [];
    var vertices:Array<Float> = [];
    var normals:Array<Float> = [];
    var uvs:Array<Float> = [];

    // helper variables
    var center = new Vector3();
    var vertex = new Vector3();
    var normal = new Vector3();

    // generate vertices, normals and uvs
    for (j in 0...radialSegments + 1) {
      for (i in 0...tubularSegments + 1) {
        var u = i / tubularSegments * arc;
        var v = j / radialSegments * Math.PI * 2;

        // vertex
        vertex.x = (radius + tube * Math.cos(v)) * Math.cos(u);
        vertex.y = (radius + tube * Math.cos(v)) * Math.sin(u);
        vertex.z = tube * Math.sin(v);

        vertices.push(vertex.x, vertex.y, vertex.z);

        // normal
        center.x = radius * Math.cos(u);
        center.y = radius * Math.sin(u);
        normal.subVectors(vertex, center).normalize();

        normals.push(normal.x, normal.y, normal.z);

        // uv
        uvs.push(i / tubularSegments);
        uvs.push(j / radialSegments);
      }
    }

    // generate indices
    for (j in 1...radialSegments + 1) {
      for (i in 1...tubularSegments + 1) {
        // indices
        var a = (tubularSegments + 1) * j + i - 1;
        var b = (tubularSegments + 1) * (j - 1) + i - 1;
        var c = (tubularSegments + 1) * (j - 1) + i;
        var d = (tubularSegments + 1) * j + i;

        // faces
        indices.push(a, b, d);
        indices.push(b, c, d);
      }
    }

    // build geometry
    this.setIndex(indices);
    this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
    this.setAttribute("normal", new Float32BufferAttribute(normals, 3));
    this.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
  }

  public function copy(source:TorusGeometry):TorusGeometry {
    super.copy(source);

    this.radius = source.radius;
    this.tube = source.tube;
    this.radialSegments = source.radialSegments;
    this.tubularSegments = source.tubularSegments;
    this.arc = source.arc;

    return this;
  }

  public static function fromJSON(data:Dynamic):TorusGeometry {
    return new TorusGeometry(data.radius, data.tube, data.radialSegments, data.tubularSegments, data.arc);
  }

}