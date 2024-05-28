import h3d.Matrix3;
import h3d.Vector2;
import h3d.Vector3;

class OBJExporter {
    public function new() {
        #indexVertex = 0;
        #indexVertexUvs = 0;
        #indexNormals = 0;
        #vertex = new h3d.Vector3();
        #color = new h3d.Color();
        #normal = new h3d.Vector3();
        #uv = new h3d.Vector2();
        #face = [];
    }

    public function parse(object:Dynamic):String {
        var output = "";

        function parseMesh(mesh:Dynamic) {
            var nbVertex = 0;
            var nbNormals = 0;
            var nbVertexUvs = 0;
            var geometry = mesh.geometry;
            var normalMatrixWorld = new h3d.Matrix3();

            var vertices = geometry.getAttribute("position");
            var normals = geometry.getAttribute("normal");
            var uvs = geometry.getAttribute("uv");
            var indices = geometry.getIndex();

            output += "o " + mesh.name + "\n";

            if (mesh.material && mesh.material.name) {
                output += "usemtl " + mesh.material.name + "\n";
            }

            if (vertices != null) {
                for (i in 0...vertices.count) {
                    #vertex.fromBufferAttribute(vertices, i);
                    #vertex.applyMatrix4(mesh.matrixWorld);
                    output += "v " + #vertex.x + " " + #vertex.y + " " + #vertex.z + "\n";
                    nbVertex++;
                }
            }

            if (uvs != null) {
                for (i in 0...uvs.count) {
                    #uv.fromBufferAttribute(uvs, i);
                    output += "vt " + #uv.x + " " + #uv.y + "\n";
                    nbVertexUvs++;
                }
            }

            if (normals != null) {
                normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);

                for (i in 0...normals.count) {
                    #normal.fromBufferAttribute(normals, i);
                    #normal.applyMatrix3(normalMatrixWorld).normalize();
                    output += "vn " + #normal.x + " " + #normal.y + " " + #normal.z + "\n";
                    nbNormals++;
                }
            }

            if (indices != null) {
                for (i in 0...indices.count) {
                    for (m in 0...3) {
                        j = indices.getX(i + m) + 1;
                        #face[m] = (indexVertex + j) + (normals or uvs ? "/" + (uvs ? (indexVertexUvs + j) : "") + (normals ? "/" + (indexNormals + j) : "") : "");
                    }
                    output += "f " + #face.join(" ") + "\n";
                }
            } else {
                for (i in 0...vertices.count) {
                    for (m in 0...3) {
                        j = i + m + 1;
                        #face[m] = (indexVertex + j) + (normals or uvs ? "/" + (uvs ? (indexVertexUvs + j) : "") + (normals ? "/" + (indexNormals + j) : "") : "");
                    }
                    output += "f " + #face.join(" ") + "\n";
                }
            }

            #indexVertex += nbVertex;
            #indexVertexUvs += nbVertexUvs;
            #indexNormals += nbNormals;
        }

        function parseLine(line:Dynamic) {
            var nbVertex = 0;
            var geometry = line.geometry;
            var type = line.type;
            var vertices = geometry.getAttribute("position");

            output += "o " + line.name + "\n";

            if (vertices != null) {
                for (i in 0...vertices.count) {
                    #vertex.fromBufferAttribute(vertices, i);
                    #vertex.applyMatrix4(line.matrixWorld);
                    output += "v " + #vertex.x + " " + #vertex.y + " " + #vertex.z + "\n";
                    nbVertex++;
                }
            }

            if (type == "Line") {
                output += "l ";
                for (j in 1...vertices.count) {
                    output += (indexVertex + j) + " ";
                }
                output += "\n";
            }

            if (type == "LineSegments") {
                for (j in 1...vertices.count) {
                    k = j + 1;
                    output += "l " + (indexVertex + j) + " " + (indexVertex + k) + "\n";
                }
            }

            #indexVertex += nbVertex;
        }

        function parsePoints(points:Dynamic) {
            var nbVertex = 0;
            var geometry = points.geometry;
            var vertices = geometry.getAttribute("position");
            var colors = geometry.getAttribute("color");

            output += "o " + points.name + "\n";

            if (vertices != null) {
                for (i in 0...vertices.count) {
                    #vertex.fromBufferAttribute(vertices, i);
                    #vertex.applyMatrix4(points.matrixWorld);
                    output += "v " + #vertex.x + " " + #vertex.y + " " + #vertex.z;

                    if (colors != null) {
                        #color.fromBufferAttribute(colors, i).convertLinearToSRGB();
                        output += " " + #color.r + " " + #color.g + " " + #color.b;
                    }

                    output += "\n";
                    nbVertex++;
                }

                output += "p ";
                for (j in 1...vertices.count) {
                    output += (indexVertex + j) + " ";
                }
                output += "\n";
            }

            #indexVertex += nbVertex;
        }

        object.traverse(function (child) {
            if (child.isMesh) {
                parseMesh(child);
            }

            if (child.isLine) {
                parseLine(child);
            }

            if (child.isPoints) {
                parsePoints(child);
            }
        });

        return output;
    }

    private var #indexVertex:Int;
    private var #indexVertexUvs:Int;
    private var #indexNormals:Int;
    private var #vertex:h3d.Vector3;
    private var #color:h3d.Color;
    private var #normal:h3d.Vector3;
    private var #uv:h3d.Vector2;
    private var #face:Array<String>;
}