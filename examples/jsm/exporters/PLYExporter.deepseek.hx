import three.Matrix3;
import three.Vector3;
import three.Color;

class PLYExporter {

    public function new() {}

    public function parse(object:Dynamic, onDone:Dynamic, options:Dynamic = null):Dynamic {

        function traverseMeshes(cb:Dynamic) {

            object.traverse(function (child:Dynamic) {

                if (child.isMesh === true || child.isPoints) {

                    var mesh = child;
                    var geometry = mesh.geometry;

                    if (geometry.hasAttribute('position') === true) {

                        cb(mesh, geometry);

                    }

                }

            });

        }

        var defaultOptions = {
            binary: false,
            excludeAttributes: [], // normal, uv, color, index
            littleEndian: false
        };

        options = (options == null) ? defaultOptions : options;

        var excludeAttributes = options.excludeAttributes;
        var includeIndices = true;
        var includeNormals = false;
        var includeColors = false;
        var includeUVs = false;

        var vertexCount = 0;
        var faceCount = 0;

        object.traverse(function (child:Dynamic) {

            if (child.isMesh === true) {

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
                faceCount += (indices != null) ? indices.count / 3 : vertices.count / 3;

                if (normals != null) includeNormals = true;

                if (uvs != null) includeUVs = true;

                if (colors != null) includeColors = true;

            } else if (child.isPoints) {

                var mesh = child;
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
        includeIndices = includeIndices && excludeAttributes.indexOf('index') === - 1;
        includeNormals = includeNormals && excludeAttributes.indexOf('normal') === - 1;
        includeColors = includeColors && excludeAttributes.indexOf('color') === - 1;
        includeUVs = includeUVs && excludeAttributes.indexOf('uv') === - 1;

        if (includeIndices && faceCount !== Math.floor(faceCount)) {

            trace(

                'PLYExporter: Failed to generate a valid PLY file with triangle indices because the ' +
                'number of indices is not divisible by 3.'

            );

            return null;

        }

        var indexByteCount = 4;

        var header =
            'ply\n' +
            `format ${options.binary ? (options.littleEndian ? 'binary_little_endian' : 'binary_big_endian') : 'ascii'} 1.0\n` +
            `element vertex ${vertexCount}\n` +

            'property float x\n' +
            'property float y\n' +
            'property float z\n';

        if (includeNormals === true) {

            header +=
                'property float nx\n' +
                'property float ny\n' +
                'property float nz\n';

        }

        if (includeUVs === true) {

            header +=
                'property float s\n' +
                'property float t\n';

        }

        if (includeColors === true) {

            header +=
                'property uchar red\n' +
                'property uchar green\n' +
                'property uchar blue\n';

        }

        if (includeIndices === true) {

            header +=
                `element face ${faceCount}\n` +
                'property list uchar int vertex_index\n';

        }

        header += 'end_header\n';

        var vertex = new Vector3();
        var normalMatrixWorld = new Matrix3();
        var result:Dynamic = null;

        if (options.binary === true) {

            var headerBin = haxe.io.Bytes.ofString(header);

            var vertexListLength = vertexCount * (4 * 3 + (includeNormals ? 4 * 3 : 0) + (includeColors ? 3 : 0) + (includeUVs ? 4 * 2 : 0));

            var faceListLength = includeIndices ? faceCount * (indexByteCount * 3 + 1) : 0;
            var output = new haxe.io.BytesOutput();
            output.writeBytes(headerBin, 0, headerBin.length);

            var vOffset = headerBin.length;
            var fOffset = headerBin.length + vertexListLength;
            var writtenVertices = 0;
            traverseMeshes(function (mesh:Dynamic, geometry:Dynamic) {

                var vertices = geometry.getAttribute('position');
                var normals = geometry.getAttribute('normal');
                var uvs = geometry.getAttribute('uv');
                var colors = geometry.getAttribute('color');
                var indices = geometry.getIndex();

                normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);

                for (i in 0...vertices.count) {

                    vertex.fromBufferAttribute(vertices, i);

                    vertex.applyMatrix4(mesh.matrixWorld);

                    output.writeFloat(vertex.x);
                    output.writeFloat(vertex.y);
                    output.writeFloat(vertex.z);

                    if (includeNormals === true) {

                        if (normals != null) {

                            vertex.fromBufferAttribute(normals, i);

                            vertex.applyMatrix3(normalMatrixWorld).normalize();

                            output.writeFloat(vertex.x);
                            output.writeFloat(vertex.y);
                            output.writeFloat(vertex.z);

                        } else {

                            output.writeFloat(0);
                            output.writeFloat(0);
                            output.writeFloat(0);

                        }

                    }

                    if (includeUVs === true) {

                        if (uvs != null) {

                            output.writeFloat(uvs.getX(i));
                            output.writeFloat(uvs.getY(i));

                        } else {

                            output.writeFloat(0);
                            output.writeFloat(0);

                        }

                    }

                    if (includeColors === true) {

                        if (colors != null) {

                            tempColor
                                .fromBufferAttribute(colors, i)
                                .convertLinearToSRGB();

                            output.writeUnsignedByte(Math.floor(tempColor.r * 255));
                            output.writeUnsignedByte(Math.floor(tempColor.g * 255));
                            output.writeUnsignedByte(Math.floor(tempColor.b * 255));

                        } else {

                            output.writeUnsignedByte(255);
                            output.writeUnsignedByte(255);
                            output.writeUnsignedByte(255);

                        }

                    }

                }

                if (includeIndices === true) {

                    if (indices != null) {

                        for (i in 0...indices.count) {

                            output.writeUnsignedByte(3);
                            output.writeUnsignedInt(indices.getX(i) + writtenVertices);
                            output.writeUnsignedInt(indices.getX(i + 1) + writtenVertices);
                            output.writeUnsignedInt(indices.getX(i + 2) + writtenVertices);

                        }

                    } else {

                        for (i in 0...vertices.count) {

                            output.writeUnsignedByte(3);
                            output.writeUnsignedInt(writtenVertices + i);
                            output.writeUnsignedInt(writtenVertices + i + 1);
                            output.writeUnsignedInt(writtenVertices + i + 2);

                        }

                    }

                }

                writtenVertices += vertices.count;

            });

            result = output.getBytes();

        } else {

            var vertexList = '';
            var faceList = '';

            traverseMeshes(function (mesh:Dynamic, geometry:Dynamic) {

                var vertices = geometry.getAttribute('position');
                var normals = geometry.getAttribute('normal');
                var uvs = geometry.getAttribute('uv');
                var colors = geometry.getAttribute('color');
                var indices = geometry.getIndex();

                normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);

                for (i in 0...vertices.count) {

                    vertex.fromBufferAttribute(vertices, i);

                    vertex.applyMatrix4(mesh.matrixWorld);

                    var line =
                        vertex.x + ' ' +
                        vertex.y + ' ' +
                        vertex.z;

                    if (includeNormals === true) {

                        if (normals != null) {

                            vertex.fromBufferAttribute(normals, i);

                            vertex.applyMatrix3(normalMatrixWorld).normalize();

                            line += ' ' +
                                vertex.x + ' ' +
                                vertex.y + ' ' +
                                vertex.z;

                        } else {

                            line += ' 0 0 0';

                        }

                    }

                    if (includeUVs === true) {

                        if (uvs != null) {

                            line += ' ' +
                                uvs.getX(i) + ' ' +
                                uvs.getY(i);

                        } else {

                            line += ' 0 0';

                        }

                    }

                    if (includeColors === true) {

                        if (colors != null) {

                            tempColor
                                .fromBufferAttribute(colors, i)
                                .convertLinearToSRGB();

                            line += ' ' +
                                Math.floor(tempColor.r * 255) + ' ' +
                                Math.floor(tempColor.g * 255) + ' ' +
                                Math.floor(tempColor.b * 255);

                        } else {

                            line += ' 255 255 255';

                        }

                    }

                    vertexList += line + '\n';

                }

                if (includeIndices === true) {

                    if (indices != null) {

                        for (i in 0...indices.count) {

                            faceList += `3 ${indices.getX(i + 0) + writtenVertices}`;
                            faceList += ` ${indices.getX(i + 1) + writtenVertices}`;
                            faceList += ` ${indices.getX(i + 2) + writtenVertices}\n`;

                        }

                    } else {

                        for (i in 0...vertices.count) {

                            faceList += `3 ${writtenVertices + i} ${writtenVertices + i + 1} ${writtenVertices + i + 2}\n`;

                        }

                    }

                }

                writtenVertices += vertices.count;

            });

            result = `${header}${vertexList}${includeIndices ? `${faceList}\n` : '\n'}`;

        }

        if (typeof onDone === 'function') haxe.Timer.delay(function () { onDone(result); }, 0);

        return result;

    }

}