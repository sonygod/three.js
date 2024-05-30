import three.Vector3;
import three.Matrix3;
import three.Color;

/**
 * https://github.com/gkjohnson/ply-exporter-js
 *
 * Usage:
 *  const exporter = new PLYExporter();
 *
 *  // second argument is a list of options
 *  exporter.parse(mesh, data -> trace(data), { binary: true, excludeAttributes: ['color'], littleEndian: true });
 *
 * Format Definition:
 * http://paulbourke.net/dataformats/ply/
 */

class PLYExporter {

    public function new() {}

    public function parse(object:Object3D, onDone:Dynamic, options:Dynamic = null):Void {
        options = options != null ? options : {};

        var defaultOptions = {
            binary: false,
            excludeAttributes: [],
            littleEndian: false
        };

        options = Reflect.merge(defaultOptions, options);

        var excludeAttributes = options.excludeAttributes;
        var includeIndices = true;
        var includeNormals = false;
        var includeColors = false;
        var includeUVs = false;

        var vertexCount = 0;
        var faceCount = 0;

        function traverseMeshes(cb:Void->Void):Void {
            object.traverse(function(child:Object3D) {
                if (child.isMesh || child.isPoints) {
                    var mesh:Object3D = child;
                    var geometry:Geometry = mesh.geometry;

                    if (geometry.getAttribute('position') != null) {
                        cb(mesh, geometry);
                    }
                }
            });
        }

        traverseMeshes(function(mesh:Object3D, geometry:Geometry) {
            var vertices = geometry.getAttribute('position');
            var normals = geometry.getAttribute('normal');
            var uvs = geometry.getAttribute('uv');
            var colors = geometry.getAttribute('color');
            var indices = geometry.getIndex();

            if (vertices == null) return;

            vertexCount += vertices.count;
            faceCount += indices != null ? indices.count / 3 : vertices.count / 3;

            if (normals != null) includeNormals = true;
            if (uvs != null) includeUVs = true;
            if (colors != null) includeColors = true;
        });

        var tempColor = new Color();

        includeIndices = includeIndices && excludeAttributes.indexOf('index') == -1;
        includeNormals = includeNormals && excludeAttributes.indexOf('normal') == -1;
        includeColors = includeColors && excludeAttributes.indexOf('color') == -1;
        includeUVs = includeUVs && excludeAttributes.indexOf('uv') == -1;

        if (includeIndices && faceCount != Math.floor(faceCount)) {
            trace('PLYExporter: Failed to generate a valid PLY file with triangle indices because the number of indices is not divisible by 3.');
            return null;
        }

        var indexByteCount = 4;

        var header =
            'ply\n' +
            (options.binary ? (options.littleEndian ? 'binary_little_endian' : 'binary_big_endian') : 'ascii') + ' 1.0\n' +
            'element vertex ' + vertexCount + '\n' +
            'property float x\n' +
            'property float y\n' +
            'property float z\n';

        if (includeNormals) {
            header +=
                'property float nx\n' +
                'property float ny\n' +
                'property float nz\n';
        }

        if (includeUVs) {
            header +=
                'property float s\n' +
                'property float t\n';
        }

        if (includeColors) {
            header +=
                'property uchar red\n' +
                'property uchar green\n' +
                'property uchar blue\n';
        }

        if (includeIndices) {
            header +=
                'element face ' + faceCount + '\n' +
                'property list uchar int vertex_index\n';
        }

        header += 'end_header\n';

        var vertex = new Vector3();
        var normalMatrixWorld = new Matrix3();
        var result:Dynamic = null;

        if (options.binary) {
            var headerBin = haxe.io.Bytes.ofString(header);
            var vertexListLength = vertexCount * (4 * 3 + (includeNormals ? 4 * 3 : 0) + (includeColors ? 3 : 0) + (includeUVs ? 4 * 2 : 0));
            var faceListLength = includeIndices ? faceCount * (indexByteCount * 3 + 1) : 0;
            var output = new haxe.io.BytesBuffer(headerBin.length + vertexListLength + faceListLength);

            new haxe.io.BytesOutput(output).writeBytes(headerBin, 0, headerBin.length);

            var vOffset = headerBin.length;
            var fOffset = headerBin.length + vertexListLength;

            var writtenVertices = 0;

            traverseMeshes(function(mesh:Object3D, geometry:Geometry) {
                var vertices = geometry.getAttribute('position');
                var normals = geometry.getAttribute('normal');
                var uvs = geometry.getAttribute('uv');
                var colors = geometry.getAttribute('color');
                var indices = geometry.getIndex();

                normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);

                for (i in 0...vertices.count) {
                    vertex.fromBufferAttribute(vertices, i);

                    vertex.applyMatrix4(mesh.matrixWorld);

                    // Position information
                    output.setInt32(vOffset, Math.floor(vertex.x));
                    vOffset += 4;

                    output.setInt32(vOffset, Math.floor(vertex.y));
                    vOffset += 4;

                    output.setInt32(vOffset, Math.floor(vertex.z));
                    vOffset += 4;

                    // Normal information
                    if (includeNormals) {
                        if (normals != null) {
                            vertex.fromBufferAttribute(normals, i);

                            vertex.applyMatrix3(normalMatrixWorld).normalize();

                            output.setInt32(vOffset, Math.floor(vertex.x));
                            vOffset += 4;

                            output.setInt32(vOffset, Math.floor(vertex.y));
                            vOffset += 4;

                            output.setInt32(vOffset, Math.floor(vertex.z));
                            vOffset += 4;
                        } else {
                            output.setInt32(vOffset, 0);
                            vOffset += 4;

                            output.setInt32(vOffset, 0);
                            vOffset += 4;

                            output.setInt32(vOffset, 0);
                            vOffset += 4;
                        }
                    }

                    // UV information
                    if (includeUVs) {
                        if (uvs != null) {
                            output.setFloat(vOffset, uvs.getX(i));
                            vOffset += 4;

                            output.setFloat(vOffset, uvs.getY(i));
                            vOffset += 4;
                        } else {
                            output.setFloat(vOffset, 0);
                            vOffset += 4;

                            output.setFloat(vOffset, 0);
                            vOffset += 4;
                        }
                    }

                    // Color information
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
                        for (i in 0...(indices.count / 3)) {
                            output.setUint8(fOffset, 3);
                            fOffset += 1;

                            output.setInt32(fOffset, indices.getX(i * 3) + writtenVertices);
                            fOffset += indexByteCount;

                            output.setInt32(fOffset, indices.getX(i * 3 + 1) + writtenVertices);
                            fOffset += indexByteCount;

                            output.setInt32(fOffset, indices.getX(i * 3 + 2) + writtenVertices);
                            fOffset += indexByteCount;
                        }
                    } else {
                        for (i in 0...(vertices.count / 3)) {
                            output.setUint8(fOffset, 3);
                            fOffset += 1;

                            output.setInt32(fOffset, writtenVertices + i);
                            fOffset += indexByteCount;

                            output.setInt32(fOffset, writtenVertices + i + 1);
                            fOffset += indexByteCount;

                            output.setInt32(fOffset, writtenVertices + i + 2);
                            fOffset += indexByteCount;
                        }
                    }
                }

                writtenVertices += vertices.count;
            });

            result = output.getBytes();

        } else {
            // Ascii File Generation
            var vertexList = '';
            var faceList = '';

            traverseMeshes(function(mesh:Object3D, geometry:Geometry) {
                var vertices = geometry.getAttribute('position');
                var normals = geometry.getAttribute('normal');
                var uvs = geometry.getAttribute('uv');
                var colors = geometry.getAttribute('color');
                var indices = geometry.getIndex();

                normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);

                for (i in 0...vertices.count) {
                    vertex.fromBufferAttribute(vertices, i);

                    vertex.applyMatrix4(mesh.matrixWorld);

                    // Position information
                    line = vertex.x + ' ' + vertex.y + ' ' + vertex.z;

                    // Normal information
                    if (includeNormals) {
                        if (normals != null) {
                            vertex.fromBufferAttribute(normals, i);

                            vertex.applyMatrix3(normalMatrixWorld).normalize();

                            line += ' ' + vertex.x + ' ' + vertex.y + ' ' + vertex.z;
                        } else {
                            line += ' 0 0 0';
                        }
                    }

                    // UV information
                    if (includeUVs) {
                        if (uvs != null) {
                            line += ' ' + uvs.getX(i) + ' ' + uvs.getY(i);
                        } else {
                            line += ' 0 0';
                        }
                    }

                    // Color information
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
                        for (i in 0...(indices.count / 3)) {
                            faceList += '3 ' + indices.getX(i * 3) + ' ' + indices.getX(i * 3 + 1) + ' ' + indices.getX(i * 3 + 2) + '\n';
                        }
                    } else {
                        for (i in 0...(vertices.count / 3)) {
                            faceList += '3 ' + (writtenVertices + i) + ' ' + (writtenVertices + i + 1) + ' ' + (writtenVertices + i + 2) + '\n';
                        }
                    }
                }

                writtenVertices += vertices.count;
            });

            result = header + vertexList + (includeIndices ? faceList : '');
        }

        if (onDone != null) {
            onDone(result);
        }
    }
}