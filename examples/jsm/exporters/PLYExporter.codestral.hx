import three.Matrix3;
import three.Vector3;
import three.Color;

class PLYExporter {

    public function parse(object:Object3D, onDone:Void -> Void, options:Dynamic = null) {

        // Default options
        var defaultOptions = {
            binary: false,
            excludeAttributes: [], // normal, uv, color, index
            littleEndian: false
        };

        if (options == null) {
            options = defaultOptions;
        } else {
            for (key in defaultOptions.keys()) {
                if (!options.exists(key)) {
                    options[key] = defaultOptions[key];
                }
            }
        }

        var excludeAttributes = options.excludeAttributes;
        var includeIndices = true;
        var includeNormals = false;
        var includeColors = false;
        var includeUVs = false;

        // count the vertices, check which properties are used,
        // and cache the BufferGeometry
        var vertexCount = 0;
        var faceCount = 0;

        object.traverse(function (child) {

            if (child is Mesh) {

                var mesh = child as Mesh;
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

            } else if (child is Points) {

                var mesh = child as Points;
                var geometry = mesh.geometry;

                var vertices = geometry.getAttribute('position');
                var normals = geometry.getAttribute('normal');
                var colors = geometry.getAttribute('color');

                vertexCount += vertices.count;

                if (normals != null) includeNormals = true;
                if (colors != null) includeColors = true;

                includeIndices = false;

            }

        });

        var tempColor = new Color();
        includeIndices = includeIndices && excludeAttributes.indexOf('index') == -1;
        includeNormals = includeNormals && excludeAttributes.indexOf('normal') == -1;
        includeColors = includeColors && excludeAttributes.indexOf('color') == -1;
        includeUVs = includeUVs && excludeAttributes.indexOf('uv') == -1;

        if (includeIndices && faceCount != Std.int(faceCount)) {
            trace('PLYExporter: Failed to generate a valid PLY file with triangle indices because the number of indices is not divisible by 3.');
            return null;
        }

        var indexByteCount = 4;

        var header = 'ply\n' +
            `format ${options.binary ? (options.littleEndian ? 'binary_little_endian' : 'binary_big_endian') : 'ascii'} 1.0\n` +
            `element vertex ${vertexCount}\n` +
            'property float x\n' +
            'property float y\n' +
            'property float z\n';

        if (includeNormals) {
            header += 'property float nx\n' +
            'property float ny\n' +
            'property float nz\n';
        }

        if (includeUVs) {
            header += 'property float s\n' +
            'property float t\n';
        }

        if (includeColors) {
            header += 'property uchar red\n' +
            'property uchar green\n' +
            'property uchar blue\n';
        }

        if (includeIndices) {
            header += `element face ${faceCount}\n` +
            'property list uchar int vertex_index\n';
        }

        header += 'end_header\n';

        // Generate attribute data
        var vertex = new Vector3();
        var normalMatrixWorld = new Matrix3();
        var result = null;

        if (options.binary) {
            // Binary File Generation
            var headerBin = new TextEncoder().encode(header);
            var vertexListLength = vertexCount * (4 * 3 + (includeNormals ? 4 * 3 : 0) + (includeColors ? 3 : 0) + (includeUVs ? 4 * 2 : 0));
            var faceListLength = includeIndices ? faceCount * (indexByteCount * 3 + 1) : 0;
            var output = new DataView(new Uint8Array(headerBin.length + vertexListLength + faceListLength).buffer);
            new Uint8Array(output.buffer).set(headerBin, 0);

            var vOffset = headerBin.length;
            var fOffset = headerBin.length + vertexListLength;
            var writtenVertices = 0;

            object.traverse(function (child) {
                if (child is Mesh || child is Points) {
                    var mesh = child;
                    var geometry = mesh.geometry;
                    var vertices = geometry.getAttribute('position');
                    var normals = geometry.getAttribute('normal');
                    var uvs = geometry.getAttribute('uv');
                    var colors = geometry.getAttribute('color');
                    var indices = geometry.getIndex();

                    normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);

                    for (var i = 0; i < vertices.count; i++) {
                        vertex.fromBufferAttribute(vertices, i);
                        vertex.applyMatrix4(mesh.matrixWorld);

                        output.setFloat32(vOffset, vertex.x, options.littleEndian);
                        vOffset += 4;
                        output.setFloat32(vOffset, vertex.y, options.littleEndian);
                        vOffset += 4;
                        output.setFloat32(vOffset, vertex.z, options.littleEndian);
                        vOffset += 4;

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

                        if (includeColors) {
                            if (colors != null) {
                                tempColor.fromBufferAttribute(colors, i).convertLinearToSRGB();
                                output.setUint8(vOffset, Math.floor(tempColor.r * 255));
                                vOffset += 1;
                                output.setUint8(vOffset, Math.floor(tempColor.g * 255));
                                vOffset += 1;
                                output.setUint8(vOffset, Math.floor(tempColor.b * 255));
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
                    }

                    if (includeIndices) {
                        if (indices != null) {
                            for (var i = 0; i < indices.count; i += 3) {
                                output.setUint8(fOffset, 3);
                                fOffset += 1;
                                output.setUint32(fOffset, indices.getX(i + 0) + writtenVertices, options.littleEndian);
                                fOffset += indexByteCount;
                                output.setUint32(fOffset, indices.getX(i + 1) + writtenVertices, options.littleEndian);
                                fOffset += indexByteCount;
                                output.setUint32(fOffset, indices.getX(i + 2) + writtenVertices, options.littleEndian);
                                fOffset += indexByteCount;
                            }
                        } else {
                            for (var i = 0; i < vertices.count; i += 3) {
                                output.setUint8(fOffset, 3);
                                fOffset += 1;
                                output.setUint32(fOffset, writtenVertices + i, options.littleEndian);
                                fOffset += indexByteCount;
                                output.setUint32(fOffset, writtenVertices + i + 1, options.littleEndian);
                                fOffset += indexByteCount;
                                output.setUint32(fOffset, writtenVertices + i + 2, options.littleEndian);
                                fOffset += indexByteCount;
                            }
                        }
                    }

                    writtenVertices += vertices.count;
                }
            });

            result = output.buffer;

        } else {
            // ASCII File Generation
            var writtenVertices = 0;
            var vertexList = '';
            var faceList = '';

            object.traverse(function (child) {
                if (child is Mesh || child is Points) {
                    var mesh = child;
                    var geometry = mesh.geometry;
                    var vertices = geometry.getAttribute('position');
                    var normals = geometry.getAttribute('normal');
                    var uvs = geometry.getAttribute('uv');
                    var colors = geometry.getAttribute('color');
                    var indices = geometry.getIndex();

                    normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);

                    for (var i = 0; i < vertices.count; i++) {
                        vertex.fromBufferAttribute(vertices, i);
                        vertex.applyMatrix4(mesh.matrixWorld);

                        var line = vertex.x + ' ' + vertex.y + ' ' + vertex.z;

                        if (includeNormals) {
                            if (normals != null) {
                                vertex.fromBufferAttribute(normals, i);
                                vertex.applyMatrix3(normalMatrixWorld).normalize();
                                line += ' ' + vertex.x + ' ' + vertex.y + ' ' + vertex.z;
                            } else {
                                line += ' 0 0 0';
                            }
                        }

                        if (includeUVs) {
                            if (uvs != null) {
                                line += ' ' + uvs.getX(i) + ' ' + uvs.getY(i);
                            } else {
                                line += ' 0 0';
                            }
                        }

                        if (includeColors) {
                            if (colors != null) {
                                tempColor.fromBufferAttribute(colors, i).convertLinearToSRGB();
                                line += ' ' + Math.floor(tempColor.r * 255) + ' ' + Math.floor(tempColor.g * 255) + ' ' + Math.floor(tempColor.b * 255);
                            } else {
                                line += ' 255 255 255';
                            }
                        }

                        vertexList += line + '\n';
                    }

                    if (includeIndices) {
                        if (indices != null) {
                            for (var i = 0; i < indices.count; i += 3) {
                                faceList += `3 ${indices.getX(i + 0) + writtenVertices} ${indices.getX(i + 1) + writtenVertices} ${indices.getX(i + 2) + writtenVertices}\n`;
                            }
                        } else {
                            for (var i = 0; i < vertices.count; i += 3) {
                                faceList += `3 ${writtenVertices + i} ${writtenVertices + i + 1} ${writtenVertices + i + 2}\n`;
                            }
                        }
                    }

                    writtenVertices += vertices.count;
                }
            });

            result = header + vertexList + (includeIndices ? faceList + '\n' : '\n');
        }

        if (onDone != null) {
            js.Browser.window.requestAnimationFrame(() -> onDone(result));
        }

        return result;
    }
}