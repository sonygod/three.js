import three.Color;
import three.Matrix3;
import three.Vector2;
import three.Vector3;
import three.core.Object3D;
import three.geometries.Geometry;
import three.materials.Material;
import three.objects.Line;
import three.objects.Mesh;
import three.objects.Points;

class OBJExporter {

  public function new() {}

  public function parse(object:Object3D):String {
    var output = "";

    var indexVertex = 0;
    var indexVertexUvs = 0;
    var indexNormals = 0;

    var vertex = new Vector3();
    var color = new Color();
    var normal = new Vector3();
    var uv = new Vector2();

    var face = [];

    function parseMesh(mesh:Mesh) {
      var nbVertex = 0;
      var nbNormals = 0;
      var nbVertexUvs = 0;

      var geometry = mesh.geometry;

      var normalMatrixWorld = new Matrix3();

      // shortcuts
      var vertices = geometry.getAttribute("position");
      var normals = geometry.getAttribute("normal");
      var uvs = geometry.getAttribute("uv");
      var indices = geometry.getIndex();

      // name of the mesh object
      output += "o " + mesh.name + "\n";

      // name of the mesh material
      if (mesh.material != null && mesh.material.name != null) {
        output += "usemtl " + mesh.material.name + "\n";
      }

      // vertices

      if (vertices != null) {
        for (i in 0...vertices.count) {
          vertex.fromBufferAttribute(vertices, i);

          // transform the vertex to world space
          vertex.applyMatrix4(mesh.matrixWorld);

          // transform the vertex to export format
          output += "v " + vertex.x + " " + vertex.y + " " + vertex.z + "\n";

          nbVertex++;
        }
      }

      // uvs

      if (uvs != null) {
        for (i in 0...uvs.count) {
          uv.fromBufferAttribute(uvs, i);

          // transform the uv to export format
          output += "vt " + uv.x + " " + uv.y + "\n";

          nbVertexUvs++;
        }
      }

      // normals

      if (normals != null) {
        normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);

        for (i in 0...normals.count) {
          normal.fromBufferAttribute(normals, i);

          // transform the normal to world space
          normal.applyMatrix3(normalMatrixWorld).normalize();

          // transform the normal to export format
          output += "vn " + normal.x + " " + normal.y + " " + normal.z + "\n";

          nbNormals++;
        }
      }

      // faces

      if (indices != null) {
        for (i in 0...indices.count) {
          if (i % 3 == 0) {
            for (m in 0...3) {
              var j = indices.getX(i + m) + 1;

              face[m] = (indexVertex + j) + (normals != null || uvs != null ? "/" + (uvs != null ? (indexVertexUvs + j) : "") + (normals != null ? "/" + (indexNormals + j) : "") : "");
            }

            // transform the face to export format
            output += "f " + face.join(" ") + "\n";
          }
        }
      } else {
        for (i in 0...vertices.count) {
          if (i % 3 == 0) {
            for (m in 0...3) {
              var j = i + m + 1;

              face[m] = (indexVertex + j) + (normals != null || uvs != null ? "/" + (uvs != null ? (indexVertexUvs + j) : "") + (normals != null ? "/" + (indexNormals + j) : "") : "");
            }

            // transform the face to export format
            output += "f " + face.join(" ") + "\n";
          }
        }
      }

      // update index
      indexVertex += nbVertex;
      indexVertexUvs += nbVertexUvs;
      indexNormals += nbNormals;
    }

    function parseLine(line:Line) {
      var nbVertex = 0;

      var geometry = line.geometry;
      var type = line.type;

      // shortcuts
      var vertices = geometry.getAttribute("position");

      // name of the line object
      output += "o " + line.name + "\n";

      if (vertices != null) {
        for (i in 0...vertices.count) {
          vertex.fromBufferAttribute(vertices, i);

          // transform the vertex to world space
          vertex.applyMatrix4(line.matrixWorld);

          // transform the vertex to export format
          output += "v " + vertex.x + " " + vertex.y + " " + vertex.z + "\n";

          nbVertex++;
        }
      }

      if (type == "Line") {
        output += "l ";

        for (j in 1...(vertices.count + 1)) {
          output += (indexVertex + j) + " ";
        }

        output += "\n";
      }

      if (type == "LineSegments") {
        for (j in 1...(vertices.count + 1)) {
          if (j % 2 == 1) {
            output += "l " + (indexVertex + j) + " " + (indexVertex + j + 1) + "\n";
          }
        }
      }

      // update index
      indexVertex += nbVertex;
    }

    function parsePoints(points:Points) {
      var nbVertex = 0;

      var geometry = points.geometry;

      var vertices = geometry.getAttribute("position");
      var colors = geometry.getAttribute("color");

      output += "o " + points.name + "\n";

      if (vertices != null) {
        for (i in 0...vertices.count) {
          vertex.fromBufferAttribute(vertices, i);
          vertex.applyMatrix4(points.matrixWorld);

          output += "v " + vertex.x + " " + vertex.y + " " + vertex.z;

          if (colors != null) {
            color.fromBufferAttribute(colors, i).convertLinearToSRGB();

            output += " " + color.r + " " + color.g + " " + color.b;
          }

          output += "\n";

          nbVertex++;
        }

        output += "p ";

        for (j in 1...(vertices.count + 1)) {
          output += (indexVertex + j) + " ";
        }

        output += "\n";
      }

      // update index
      indexVertex += nbVertex;
    }

    object.traverse(function(child:Object3D) {
      if (cast child : Mesh) {
        parseMesh(child);
      }

      if (cast child : Line) {
        parseLine(child);
      }

      if (cast child : Points) {
        parsePoints(child);
      }
    });

    return output;
  }
}