import haxe.io.Bytes;
import haxe.io.BytesInput;
import js.html.DataView;
import js.html.TextEncoder;

class PLYExporter {
    public function new() {

    }

    public function parse(object:Dynamic, ?onDone:Dynamic, ?options:Dynamic):Void {
        var defaultOptions:Dynamic = {
            binary: false,
            excludeAttributes: [], // normal, uv, color, index
            littleEndian: false
        };
        options = options != null ? Object.assign(defaultOptions, options) : defaultOptions;

        var excludeAttributes = options.excludeAttributes;
        var includeIndices = true;
        var includeNormals = false;
        var includeColors = false;
        var includeUVs = false;

        var vertexCount = 0;
        var faceCount = 0;

        var tempColor = new js.html.CanvasRenderingContext2D();

        includeIndices = includeIndices && excludeAttributes.indexOf('index') == -1;
        includeNormals = includeNormals && excludeAttributes.indexOf('normal') == -1;
        includeColors = includeColors && excludeAttributes.indexOf('color') == -1;
        includeUVs = includeUVs && excludeAttributes.indexOf('uv') == -1;

        if (includeIndices && faceCount != Std.int(faceCount)) {
            throw "PLYExporter: Failed to generate a valid PLY file with triangle indices because the number of indices is not divisible by 3.";
        }

        var indexByteCount = 4;

        var header = "ply\nformat " + (options.binary ? (options.littleEndian ? "binary_little_endian" : "binary_big_endian") : "ascii") + " 1.0\nelement vertex " + vertexCount + "\nproperty float x\nproperty float y\nproperty float z\n";

        if (includeNormals) {
            header += "property float nx\nproperty float ny\nproperty float nz\n";
        }

        if (includeUVs) {
            header += "property float s\nproperty float t\n";
        }

        if (includeColors) {
            header += "property uchar red\nproperty uchar green\nproperty uchar blue\n";
        }

        if (includeIndices) {
            header += "element face " + faceCount + "\nproperty list uchar int vertex_index\n";
        }

        header += "end_header\n";

        var vertex = new js.html.CanvasRenderingContext2D();
        var normalMatrixWorld = new js.html.CanvasRenderingContext2D();
        var result = null;

        if (options.binary) {
            // Binary File Generation
            var headerBin = new TextEncoder().encode(header);

            var vertexListLength = vertexCount * (4 * 3 + (includeNormals ? 4 * 3 : 0) + (includeColors ? 3 : 0) + (includeUVs ? 4 * 2 : 0));
            var faceListLength = includeIndices ? faceCount * (indexByteCount * 3 + 1) : 0;
            var output = new DataView(new Bytes(headerBin.length + vertexListLength + faceListLength));
            var outputBytes = output.getBytes();
            var outputBytesInput = new BytesInput(outputBytes);
            outputBytesInput.setPosition(headerBin.length);

            var vOffset = headerBin.length;
            var fOffset = headerBin.length + vertexListLength;
            var writtenVertices = 0;

            var traverseMeshes = function(cb:Dynamic):Void {
                object.traverse(function(child:Dynamic):Void {
                    if (child.isMesh || child.isPoints) {
                        var mesh = child;
                        var geometry = mesh.geometry;

                        var vertices = geometry.getAttribute('position');
                        var normals = geometry.getAttribute('normal');
                        var uvs = geometry.getAttribute('uv');
                        var colors = geometry.getAttribute('color');
                        var indices = geometry.getIndex();

                        if (vertices == null) {
                            return;
                        }

                        vertexCount += vertices.count;
                        faceCount += indices != null ? indices.count / 3 : vertices.count / 3;

                        if (normals != null) includeNormals = true;

                        if (uvs != null) includeUVs = true;

                        if (colors != null) includeColors = true;

                        cb(mesh, geometry);
                    });
                });
            };

            traverseMeshes(function(mesh:Dynamic, geometry:Dynamic):Void {
                var vertices = geometry.getAttribute('position');
                var normals = geometry.getAttribute('normal');
                var uvs = geometry.getAttribute('uv');
                var colors = geometry.getAttribute('color');
                var indices = geometry.getIndex();

                normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);

                var i = 0;
                var l = vertices.count;

                while (i < l) {
                    vertex.fromBufferAttribute(vertices, i);
                    vertex.applyMatrix4(mesh.matrixWorld);

                    // Position information
                    output.setFloat32(vOffset, vertex.x, options.littleEndian);
                    vOffset += 4;

                    output.setFloat32(vOffset, vertex.y, options.littleEndian);
                    vOffset += 4;

                    output.setFloat32(vOffset, vertex.z, options.littleEndian);
                    vOffset += 4;

                    // Normal information
                    if (includeNormals) {
                        if (normals != null) {
                            vertex.fromBufferAttribute(normals, i);
                            vertex.applyMatrix3(normalMatrixWorld).normalize();

                            output.setFloat32(vOffset, vertex.x, options.littleEndian);
                            vOffset += 4;

                            output.setFloat32(vOffset, vertex.y, options.littleEndian);
                            vOffset += 4;

                            output.setFloat32(vOffset, vertex.z, options.littleEndian);
                            vOffset += 4;
                        } else {
                            output.setFloat32(vOffset, 0, options.littleEndian);
                            vOffset += 4;

                            output.setFloat32(vOffset, 0, options.littleEndian);
                            vOffset += 4;

                            output.setFloat32(vOffset, 0, options.littleEndian);
                            vOffset += 4;
                        }
                    }

                    // UV information
                    if (includeUVs) {
                        if (uvs != null) {
                            output.setFloat32(vOffset, uvs.getX(i), options.littleEndian);
                            vOffset += 4;

                            output.setFloat32(vOffset, uvs.getY(i), options.littleEndian);
                            vOffset += 4;
                        } else {
                            output.setFloat32(vOffset, 0, options.littleEndian);
                            vOffset += 4;

                            output.setFloat32(vOffset, 0, options.littleEndian);
                            vOffset += 4;
                        }
                    }

                    // Color information
                    if (includeColors) {
                        if (colors != null) {
                            tempColor.fromBufferAttribute(colors, i).convertLinearToSRGB();

                            output.setUint8(vOffset, Std.int(tempColor.r * 255));
                            vOffset += 1;

                            output.setUint8(vOffset, Std.int(tempColor.g * 255));
                            vOffset += 1;

                            output.setUint8(vOffset, Std.int(tempColor.b * 255));
                            vOffset += 1;
                        } else {
                            output.setUint8(vOffset, 255);
                            vOffset += 1;

                            output.setUint8(vOffset, 255);
                            vOffset += 1;

                            output.setUint8(vOffset, 255);
                            vOffset += 1;
                        }
                    }

                    i++;
                }

                if (includeIndices) {
                    // Create the face list
                    if (indices != null) {
                        var i = 0;
                        var l = indices.count;

                        while (i < l) {
                            output.setUint8(fOffset, 3);
                            fOffset += 1;

                            output.setUint32(fOffset, indices.getX(i) + writtenVertices, options.littleEndian);
                            fOffset += indexByteCount;

                            output.setUint32(fOffset, indices.getX(i + 1) + writtenVertices, options.littleEndian);
                            fOffset += indexByteCount;

                            output.setUint32(fOffset, indices.getX(i + 2) + writtenVertices, options.littleEndian);
                            fOffset += indexByteCount;

                            i += 3;
                        }
                    } else {
                        var i = 0;
                        var l = vertices.count;

                        while (i < l) {
                            output.setUint8(fOffset, 3);
                            fOffset += 1;

                            output.setUint32(fOffset, writtenVertices + i, options.littleEndian);
                            fOffset += indexByteCount;

                            output.setUint32(fOffset, writtenVertices + i + 1, options.littleEndian);
                            fOffset += indexByteCount;

                            output.setUint32(fOffset, writtenVertices + i + 2, options.littleEndian);
                            fOffset += indexByteCount;

                            i += 3;
                        }
                    }
                }

                // Save the amount of verts we've already written so we can offset
                // the face index on the next mesh
                writtenVertices += vertices.count;
            });

            result = output.getBytes();
        } else {
            // Ascii File Generation
            var writtenVertices = 0;
            var vertexList = "";
            var faceList = "";

            traverseMeshes(function(mesh:Dynamic, geometry:Dynamic):Void {
                var vertices = geometry.getAttribute('position');
                var normals = geometry.getAttribute('normal');
                var uvs = geometry.getAttribute('uv');
                var colors = geometry.getAttribute('color');
                var indices = geometry.getIndex();

                normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);

                var i = 0;
                var l = vertices.count;

                while (i < l) {
                    vertex.fromBufferAttribute(vertices, i);
                    vertex.applyMatrix4(mesh.matrixWorld);

                    // Position information
                    var line = vertex.x + " " + vertex.y + " " + vertex.z;

                    // Normal information
                    if (includeNormals) {
                        if (normals != null) {
                            vertex.fromBufferAttribute(normals, i);
                            vertex.applyMatrix3(normalMatrixWorld).normalize();

                            line += " " + vertex.x + " " + vertex.y + " " + vertex.z;
                        } else {
                            line += " 0 0 0";
                        }
                    }

                    // UV information
                    if (includeUVs) {
                        if (uvs != null) {
                            line += " " + uvs.getX(i) + " " + uvs.getY(i);
                        } else {
                            line += " 0 0";
                        }
                    }

                    // Color information
                    if (includeColors) {
                        if (colors != null) {
                            tempColor.fromBufferAttribute(colors, i).convertLinearToSRGB();

                            line += " " + Std.int(tempColor.r * 255) + " " + Std.int(tempColor.g * 255) + " " + Std.int(tempColor.b * 255);
                        } else {
                            line += " 255 255 255";
                        }
                    }

                    vertexList += line + "\n";

                    i++;
                }

                // Create the face list
                if (includeIndices) {
                    if (indices != null) {
                        var i = 0;
                        var l = indices.count;

                        while (i < l) {
                            faceList += "3 " + indices.getX(i) + " " + indices.getX(i + 1) + " " + indices.getX(i + 2) + "\n";

                            i += 3;
                        }
                    } else {
                        var i = 0;
                        var l = vertices.count;

                        while (i < l) {
                            faceList += "3 " + writtenVertices + " " + writtenVertices + 1 + " " + writtenVertices + 2 + "\n";

                            i += 3;
                        }
                    }

                    faceCount += indices != null ? indices.count / 3 : vertices.count / 3;
                }

                writtenVertices += vertices.count;
            });

            result = header + vertexList + (includeIndices ? faceList + "\n" : "\n");
        }

        if (onDone != null) {
            onDone(result);
        }
    }
}