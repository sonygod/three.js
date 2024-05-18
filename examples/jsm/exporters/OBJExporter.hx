package three.js.examples.jsm.exporters;

import three.Color;
import three.Matrix3;
import three.Vector2;
import three.Vector3;

class OBJExporter {
    public function new() {}

    public function parse(object:Object3D):String {
        var output:String = '';

        var indexVertex:Int = 0;
        var indexVertexUvs:Int = 0;
        var indexNormals:Int = 0;

        var vertex:Vector3 = new Vector3();
        var color:Color = new Color();
        var normal:Vector3 = new Vector3();
        var uv:Vector2 = new Vector2();

        var face:Array<String> = [];

        function parseMesh(mesh:Mesh) {
            var nbVertex:Int = 0;
            var nbNormals:Int = 0;
            var nbVertexUvs:Int = 0;

            var geometry:Geometry = mesh.geometry;

            var normalMatrixWorld:Matrix3 = new Matrix3();

            // shortcuts
            var vertices:BufferAttribute = geometry.getAttribute('position');
            var normals:BufferAttribute = geometry.getAttribute('normal');
            var uvs:BufferAttribute = geometry.getAttribute('uv');
            var indices:Array<Int> = geometry.getIndex();

            // name of the mesh object
            output += 'o ' + mesh.name + '\n';

            // name of the mesh material
            if (mesh.material != null && mesh.material.name != null) {
                output += 'usemtl ' + mesh.material.name + '\n';
            }

            // vertices
            if (vertices != null) {
                for (i in 0...vertices.count) {
                    vertex.fromBufferAttribute(vertices, i);
                    vertex.applyMatrix4(mesh.matrixWorld);
                    output += 'v ' + vertex.x + ' ' + vertex.y + ' ' + vertex.z + '\n';
                    nbVertex++;
                }
            }

            // uvs
            if (uvs != null) {
                for (i in 0...uvs.count) {
                    uv.fromBufferAttribute(uvs, i);
                    output += 'vt ' + uv.x + ' ' + uv.y + '\n';
                    nbVertexUvs++;
                }
            }

            // normals
            if (normals != null) {
                normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);
                for (i in 0...normals.count) {
                    normal.fromBufferAttribute(normals, i);
                    normal.applyMatrix3(normalMatrixWorld).normalize();
                    output += 'vn ' + normal.x + ' ' + normal.y + ' ' + normal.z + '\n';
                    nbNormals++;
                }
            }

            // faces
            if (indices != null) {
                for (i in 0...indices.length) {
                    for (m in 0...3) {
                        var j:Int = indices[i + m] + 1;
                        face[m] = (indexVertex + j) + (normals != null || uvs != null ? '/' + (uvs != null ? (indexVertexUvs + j) : '') + (normals != null ? '/' + (indexNormals + j) : '') : '');
                    }
                    output += 'f ' + face.join(' ') + '\n';
                }
            } else {
                for (i in 0...(vertices.count - 2)) {
                    for (m in 0...3) {
                        var j:Int = i + m + 1;
                        face[m] = (indexVertex + j) + (normals != null || uvs != null ? '/' + (uvs != null ? (indexVertexUvs + j) : '') + (normals != null ? '/' + (indexNormals + j) : '') : '');
                    }
                    output += 'f ' + face.join(' ') + '\n';
                }
            }

            // update index
            indexVertex += nbVertex;
            indexVertexUvs += nbVertexUvs;
            indexNormals += nbNormals;
        }

        function parseLine(line:Line) {
            var nbVertex:Int = 0;

            var geometry:Geometry = line.geometry;
            var type:String = line.type;

            // shortcuts
            var vertices:BufferAttribute = geometry.getAttribute('position');

            // name of the line object
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
                for (j in 1...vertices.count) {
                    output += (indexVertex + j) + ' ';
                }
                output += '\n';
            }

            if (type == 'LineSegments') {
                for (j in 1...vertices.count - 1) {
                    output += 'l ' + (indexVertex + j) + ' ' + (indexVertex + j + 1) + '\n';
                }
            }

            // update index
            indexVertex += nbVertex;
        }

        function parsePoints(points:Points) {
            var nbVertex:Int = 0;

            var geometry:Geometry = points.geometry;

            var vertices:BufferAttribute = geometry.getAttribute('position');
            var colors:BufferAttribute = geometry.getAttribute('color');

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

                for (j in 1...vertices.count) {
                    output += (indexVertex + j) + ' ';
                }

                output += '\n';
            }

            // update index
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