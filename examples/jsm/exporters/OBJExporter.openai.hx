package three.js.examples.jsm.exporters;

import three.Color;
import three.Matrix3;
import three.Vector2;
import three.Vector3;

class OBJExporter {
    public function new() {}

    public function parse(object:Object3D):String {
        var output = '';

        var indexVertex = 0;
        var indexVertexUvs = 0;
        var indexNormals = 0;

        var vertex = new Vector3();
        var color = new Color();
        var normal = new Vector3();
        var uv = new Vector2();

        var face:Array<String> = [];

        function parseMesh(mesh: Mesh) {
            var nbVertex = 0;
            var nbNormals = 0;
            var nbVertexUvs = 0;

            var geometry = mesh.geometry;
            var normalMatrixWorld = new Matrix3();

            var vertices = geometry.getAttribute('position');
            var normals = geometry.getAttribute('normal');
            var uvs = geometry.getAttribute('uv');
            var indices = geometry.getIndex();

            output += 'o ' + mesh.name + '\n';

            if (mesh.material && mesh.material.name) {
                output += 'usemtl ' + mesh.material.name + '\n';
            }

            if (vertices != null) {
                for (i in 0...vertices.count) {
                    vertex.fromBufferAttribute(vertices, i);
                    vertex.applyMatrix4(mesh.matrixWorld);
                    output += 'v ' + vertex.x + ' ' + vertex.y + ' ' + vertex.z + '\n';
                    nbVertex++;
                }
            }

            if (uvs != null) {
                for (i in 0...uvs.count) {
                    uv.fromBufferAttribute(uvs, i);
                    output += 'vt ' + uv.x + ' ' + uv.y + '\n';
                    nbVertexUvs++;
                }
            }

            if (normals != null) {
                normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);
                for (i in 0...normals.count) {
                    normal.fromBufferAttribute(normals, i);
                    normal.applyMatrix3(normalMatrixWorld).normalize();
                    output += 'vn ' + normal.x + ' ' + normal.y + ' ' + normal.z + '\n';
                    nbNormals++;
                }
            }

            if (indices != null) {
                for (i in 0...indices.count step 3) {
                    for (m in 0...3) {
                        var j = indices.getX(i + m) + 1;
                        face[m] = (indexVertex + j) + (normals != null || uvs != null ? '/' + (uvs != null ? (indexVertexUvs + j) : '') + (normals != null ? '/' + (indexNormals + j) : '') : '');
                    }
                    output += 'f ' + face.join(' ') + '\n';
                }
            } else {
                for (i in 0...vertices.count step 3) {
                    for (m in 0...3) {
                        var j = i + m + 1;
                        face[m] = (indexVertex + j) + (normals != null || uvs != null ? '/' + (uvs != null ? (indexVertexUvs + j) : '') + (normals != null ? '/' + (indexNormals + j) : '') : '');
                    }
                    output += 'f ' + face.join(' ') + '\n';
                }
            }

            indexVertex += nbVertex;
            indexVertexUvs += nbVertexUvs;
            indexNormals += nbNormals;
        }

        function parseLine(line:Line) {
            var nbVertex = 0;

            var geometry = line.geometry;
            var type = line.type;

            var vertices = geometry.getAttribute('position');

            output += 'o ' + line.name + '\n';

            if (vertices != null) {
                for (i in 0...vertices.count) {
                    vertex.fromBufferAttribute(vertices, i);
                    vertex.applyMatrix4(line.matrixWorld);
                    output += 'v ' + vertex.x + ' ' + vertex.y + ' ' + vertex.z + '\n';
                    nbVertex++;
                }
            }

            if (type == 'Line') {
                output += 'l ';
                for (j in 1...vertices.count + 1) {
                    output += (indexVertex + j) + ' ';
                }
                output += '\n';
            }

            if (type == 'LineSegments') {
                for (j in 1...vertices.count step 2) {
                    output += 'l ' + (indexVertex + j) + ' ' + (indexVertex + j + 1) + '\n';
                }
            }

            indexVertex += nbVertex;
        }

        function parsePoints(points:Points) {
            var nbVertex = 0;

            var geometry = points.geometry;
            var vertices = geometry.getAttribute('position');
            var colors = geometry.getAttribute('color');

            output += 'o ' + points.name + '\n';

            if (vertices != null) {
                for (i in 0...vertices.count) {
                    vertex.fromBufferAttribute(vertices, i);
                    vertex.applyMatrix4(points.matrixWorld);
                    output += 'v ' + vertex.x + ' ' + vertex.y + ' ' + vertex.z;

                    if (colors != null) {
                        color.fromBufferAttribute(colors, i).convertLinearToSRGB();
                        output += ' ' + color.r + ' ' + color.g + ' ' + color.b;
                    }

                    output += '\n';
                    nbVertex++;
                }

                output += 'p ';

                for (j in 1...vertices.count + 1) {
                    output += (indexVertex + j) + ' ';
                }

                output += '\n';
            }

            indexVertex += nbVertex;
        }

        object.traverse(function(child:Object3D) {
            if (child.isMesh) {
                parseMesh(cast child);
            }

            if (child.isLine) {
                parseLine(cast child);
            }

            if (child.isPoints) {
                parsePoints(cast child);
            }
        });

        return output;
    }
}