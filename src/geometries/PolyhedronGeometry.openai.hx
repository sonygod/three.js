import three.BufferGeometry;
import three.Float32BufferAttribute;
import three.Vector3;
import three.Vector2;

class PolyhedronGeometry extends BufferGeometry {
  var vertices:Array<Float>;
  var indices:Array<Int>;
  var radius:Float;
  var detail:Int;

  public function new(vertices:Array<Float>, indices:Array<Int>, radius:Float = 1, detail:Int = 0):Void {
    super();

    this.type = "PolyhedronGeometry";

    this.vertices = vertices;
    this.indices = indices;
    this.radius = radius;
    this.detail = detail;

    // default buffer data
    var vertexBuffer:Array<Float> = [];
    var uvBuffer:Array<Float> = [];

    // the subdivision creates the vertex buffer data
    subdivide(detail);

    // all vertices should lie on a conceptual sphere with a given radius
    applyRadius(radius);

    // finally, create the uv data
    generateUVs();

    // build non-indexed geometry
    this.setAttribute("position", new Float32BufferAttribute(vertexBuffer, 3));
    this.setAttribute("normal", new Float32BufferAttribute(vertexBuffer.slice(), 3));
    this.setAttribute("uv", new Float32BufferAttribute(uvBuffer, 2));

    if (detail == 0) {
      this.computeVertexNormals(); // flat normals
    } else {
      this.normalizeNormals(); // smooth normals
    }

    function subdivide(detail:Int):Void {
      var a:Vector3 = new Vector3();
      var b:Vector3 = new Vector3();
      var c:Vector3 = new Vector3();

      // iterate over all faces and apply a subdivision with the given detail value
      for (i in 0...indices.length / 3) {
        // get the vertices of the face
        getVertexByIndex(indices[i * 3], a);
        getVertexByIndex(indices[i * 3 + 1], b);
        getVertexByIndex(indices[i * 3 + 2], c);

        // perform subdivision
        subdivideFace(a, b, c, detail);
      }
    }

    function subdivideFace(a:Vector3, b:Vector3, c:Vector3, detail:Int):Void {
      var cols:Int = detail + 1;

      // we use this multidimensional array as a data structure for creating the subdivision
      var v:Array<Vector3> = [];

      // construct all of the vertices for this subdivision
      for (i in 0...cols + 1) {
        v[i] = [];
        var aj:Vector3 = a.clone().lerp(c, i / cols);
        var bj:Vector3 = b.clone().lerp(c, i / cols);
        var rows:Int = cols - i;

        for (j in 0...rows + 1) {
          if (j == 0 && i == cols) {
            v[i][j] = aj;
          } else {
            v[i][j] = aj.clone().lerp(bj, j / rows);
          }
        }
      }

      // construct all of the faces
      for (i in 0...cols) {
        for (j in 0...2 * (cols - i) - 1) {
          var k:Int = Math.floor(j / 2);

          if (j % 2 == 0) {
            pushVertex(v[i][k + 1]);
            pushVertex(v[i + 1][k]);
            pushVertex(v[i][k]);
          } else {
            pushVertex(v[i][k + 1]);
            pushVertex(v[i + 1][k + 1]);
            pushVertex(v[i + 1][k]);
          }
        }
      }
    }

    function applyRadius(radius:Float):Void {
      var vertex:Vector3 = new Vector3();

      // iterate over the entire buffer and apply the radius to each vertex
      for (i in 0...vertexBuffer.length / 3) {
        vertex.x = vertexBuffer[i * 3 + 0];
        vertex.y = vertexBuffer[i * 3 + 1];
        vertex.z = vertexBuffer[i * 3 + 2];

        vertex.normalize().multiplyScalar(radius);

        vertexBuffer[i * 3 + 0] = vertex.x;
        vertexBuffer[i * 3 + 1] = vertex.y;
        vertexBuffer[i * 3 + 2] = vertex.z;
      }
    }

    function generateUVs():Void {
      var vertex:Vector3 = new Vector3();

      for (i in 0...vertexBuffer.length / 3) {
        vertex.x = vertexBuffer[i * 3 + 0];
        vertex.y = vertexBuffer[i * 3 + 1];
        vertex.z = vertexBuffer[i * 3 + 2];

        var u:Float = azimuth(vertex) / 2 / Math.PI + 0.5;
        var v:Float = inclination(vertex) / Math.PI + 0.5;
        uvBuffer.push(u, 1 - v);
      }

      correctUVs();

      correctSeam();
    }

    function correctSeam():Void {
      // handle case when face straddles the seam, see #3269
      for (i in 0...uvBuffer.length / 6) {
        // uv data of a single face
        var x0:Float = uvBuffer[i * 6 + 0];
        var x1:Float = uvBuffer[i * 6 + 2];
        var x2:Float = uvBuffer[i * 6 + 4];

        var max:Float = Math.max(x0, x1, x2);
        var min:Float = Math.min(x0, x1, x2);

        // 0.9 is somewhat arbitrary
        if (max > 0.9 && min < 0.1) {
          if (x0 < 0.2)
            uvBuffer[i * 6 + 0] += 1;
          if (x1 < 0.2)
            uvBuffer[i * 6 + 2] += 1;
          if (x2 < 0.2)
            uvBuffer[i * 6 + 4] += 1;
        }
      }
    }

    function pushVertex(vertex:Vector3):Void {
      vertexBuffer.push(vertex.x, vertex.y, vertex.z);
    }

    function getVertexByIndex(index:Int, vertex:Vector3):Void {
      var stride:Int = index * 3;

      vertex.x = vertices[stride + 0];
      vertex.y = vertices[stride + 1];
      vertex.z = vertices[stride + 2];
    }

    function correctUVs():Void {
      var a:Vector3 = new Vector3();
      var b:Vector3 = new Vector3();
      var c:Vector3 = new Vector3();

      var centroid:Vector3 = new Vector3();

      var uvA:Vector2 = new Vector2();
      var uvB:Vector2 = new Vector2();
      var uvC:Vector2 = new Vector2();

      for (i in 0...(vertexBuffer.length / 9)) {
        a.set(vertexBuffer[i * 9 + 0], vertexBuffer[i * 9 + 1], vertexBuffer[i * 9 + 2]);
        b.set(vertexBuffer[i * 9 + 3], vertexBuffer[i * 9 + 4], vertexBuffer[i * 9 + 5]);
        c.set(vertexBuffer[i * 9 + 6], vertexBuffer[i * 9 + 7], vertexBuffer[i * 9 + 8]);

        uvA.set(uvBuffer[i * 6 + 0], uvBuffer[i * 6 + 1]);
        uvB.set(uvBuffer[i * 6 + 2], uvBuffer[i * 6 + 3]);
        uvC.set(uvBuffer[i * 6 + 4], uvBuffer[i * 6 + 5]);

        centroid.copy(a).add(b).add(c).divideScalar(3);

        var azi:Float = azimuth(centroid);

        correctUV(uvA, i * 6 + 0, a, azi);
        correctUV(uvB, i * 6 + 2, b, azi);
        correctUV(uvC, i * 6 + 4, c, azi);
      }
    }

    function correctUV(uv:Vector2, stride:Int, vector:Vector3, azimuth:Float):Void {
      if ((azimuth < 0) && (uv.x == 1)) {
        uvBuffer[stride] = uv.x - 1;
      }

      if ((vector.x == 0) && (vector.z == 0)) {
        uvBuffer[stride] = azimuth / 2 / Math.PI + 0.5;
      }
    }

    // Angle around the Y axis, counter-clockwise when looking from above.
    function azimuth(vector:Vector3):Float {
      return Math.atan2(vector.z, -vector.x);
    }

    // Angle above the XZ plane.
    function inclination(vector:Vector3):Float {
      return Math.atan2(-vector.y, Math.sqrt((vector.x * vector.x) + (vector.z * vector.z)));
    }
  }
  
  public function copy(source:PolyhedronGeometry):PolyhedronGeometry {
    super.copy(source);

    this.vertices = source.vertices.slice();
    this.indices = source.indices.slice();
    this.radius = source.radius;
    this.detail = source.detail;

    return this;
  }

  public static function fromJSON(data:Dynamic):PolyhedronGeometry {
    return new PolyhedronGeometry(data.vertices, data.indices, data.radius, data.detail);
  }
}