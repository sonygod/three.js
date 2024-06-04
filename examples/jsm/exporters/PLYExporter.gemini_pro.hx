import three.math.Matrix3;
import three.math.Vector3;
import three.core.Object3D;
import three.core.Mesh;
import three.core.Points;
import three.core.Geometry;
import three.core.BufferGeometry;
import three.core.Color;
import three.geometries.BufferAttribute;
import haxe.io.Bytes;
import haxe.io.Output;

/**
 * https://github.com/gkjohnson/ply-exporter-js
 *
 * Usage:
 *  const exporter = new PLYExporter();
 *
 *  // second argument is a list of options
 *  exporter.parse(mesh, data => console.log(data), { binary: true, excludeAttributes: [ 'color' ], littleEndian: true });
 *
 * Format Definition:
 * http://paulbourke.net/dataformats/ply/
 */
class PLYExporter {

  public function new() {}

  /**
   * Parses a Three.js Object3D and returns a PLY string.
   *
   * @param {Object3D} object The Object3D to parse.
   * @param {Function} onDone A callback function that is called when the parsing is complete.
   * @param {Object} options An object that contains options for the exporter.
   * @return {String|ArrayBuffer} The PLY string or ArrayBuffer.
   */
  public function parse(object:Object3D, onDone:Dynamic->Void, options:Dynamic = {}):Dynamic {
    // Iterate over the valid meshes in the object
    function traverseMeshes(cb:Mesh->Void):Void {
      object.traverse(function(child:Object3D) {
        if (child.isMesh == true || child.isPoints) {
          var mesh:Mesh = cast child;
          var geometry:Geometry = mesh.geometry;
          if (geometry.hasAttribute('position') == true) {
            cb(mesh);
          }
        }
      });
    }

    // Default options
    var defaultOptions = {
      binary: false,
      excludeAttributes: [], // normal, uv, color, index
      littleEndian: false
    };

    options = js.Boot.objectAssign(defaultOptions, options);

    var excludeAttributes = options.excludeAttributes;
    var includeIndices = true;
    var includeNormals = false;
    var includeColors = false;
    var includeUVs = false;

    // count the vertices, check which properties are used,
    // and cache the BufferGeometry
    var vertexCount = 0;
    var faceCount = 0;

    object.traverse(function(child:Object3D) {
      if (child.isMesh == true) {
        var mesh:Mesh = cast child;
        var geometry:Geometry = mesh.geometry;

        var vertices:BufferAttribute = geometry.getAttribute('position');
        var normals:BufferAttribute = geometry.getAttribute('normal');
        var uvs:BufferAttribute = geometry.getAttribute('uv');
        var colors:BufferAttribute = geometry.getAttribute('color');
        var indices:BufferAttribute = geometry.getIndex();

        if (vertices == null) {
          return;
        }

        vertexCount += vertices.count;
        faceCount += (indices != null ? indices.count / 3 : vertices.count / 3);

        if (normals != null) includeNormals = true;

        if (uvs != null) includeUVs = true;

        if (colors != null) includeColors = true;

      } else if (child.isPoints) {
        var mesh:Points = cast child;
        var geometry:Geometry = mesh.geometry;

        var vertices:BufferAttribute = geometry.getAttribute('position');
        var normals:BufferAttribute = geometry.getAttribute('normal');
        var colors:BufferAttribute = geometry.getAttribute('color');

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

    if (includeIndices && faceCount != Std.parseInt(faceCount)) {
      // point cloud meshes will not have an index array and may not have a
      // number of vertices that is divisble by 3 (and therefore representable
      // as triangles)
      js.Lib.console.error('PLYExporter: Failed to generate a valid PLY file with triangle indices because the ' +
        'number of indices is not divisible by 3.');
      return null;
    }

    var indexByteCount = 4;
    var header =
      'ply\n' +
      `format ${options.binary ? (options.littleEndian ? 'binary_little_endian' : 'binary_big_endian') : 'ascii'} 1.0\n` +
      `element vertex ${vertexCount}\n` +

      // position
      'property float x\n' +
      'property float y\n' +
      'property float z\n';

    if (includeNormals == true) {
      // normal
      header +=
        'property float nx\n' +
        'property float ny\n' +
        'property float nz\n';
    }

    if (includeUVs == true) {
      // uvs
      header +=
        'property float s\n' +
        'property float t\n';
    }

    if (includeColors == true) {
      // colors
      header +=
        'property uchar red\n' +
        'property uchar green\n' +
        'property uchar blue\n';
    }

    if (includeIndices == true) {
      // faces
      header +=
        `element face ${faceCount}\n` +
        'property list uchar int vertex_index\n';
    }

    header += 'end_header\n';

    // Generate attribute data
    var vertex = new Vector3();
    var normalMatrixWorld = new Matrix3();
    var result:Dynamic = null;

    if (options.binary == true) {
      // Binary File Generation
      var headerBin = new haxe.io.Bytes(haxe.io.Bytes.ofString(header)).toArray();

      // 3 position values at 4 bytes
      // 3 normal values at 4 bytes
      // 3 color channels with 1 byte
      // 2 uv values at 4 bytes
      var vertexListLength = vertexCount * (4 * 3 + (includeNormals ? 4 * 3 : 0) + (includeColors ? 3 : 0) + (includeUVs ? 4 * 2 : 0));

      // 1 byte shape desciptor
      // 3 vertex indices at ${indexByteCount} bytes
      var faceListLength = includeIndices ? faceCount * (indexByteCount * 3 + 1) : 0;
      var output = new Bytes(headerBin.length + vertexListLength + faceListLength);
      var outputArray = output.toArray();
      outputArray.blit(0, headerBin, 0, headerBin.length);

      var vOffset = headerBin.length;
      var fOffset = headerBin.length + vertexListLength;
      var writtenVertices = 0;
      traverseMeshes(function(mesh:Mesh) {
        var geometry:Geometry = mesh.geometry;

        var vertices:BufferAttribute = geometry.getAttribute('position');
        var normals:BufferAttribute = geometry.getAttribute('normal');
        var uvs:BufferAttribute = geometry.getAttribute('uv');
        var colors:BufferAttribute = geometry.getAttribute('color');
        var indices:BufferAttribute = geometry.getIndex();

        normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);

        for (var i = 0; i < vertices.count; i++) {
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
          if (includeNormals == true) {
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
          if (includeUVs == true) {
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
          if (includeColors == true) {
            if (colors != null) {
              tempColor.fromBufferAttribute(colors, i).convertLinearToSRGB();
              output.setUint8(vOffset, Std.parseInt(tempColor.r * 255));
              vOffset += 1;
              output.setUint8(vOffset, Std.parseInt(tempColor.g * 255));
              vOffset += 1;
              output.setUint8(vOffset, Std.parseInt(tempColor.b * 255));
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

        if (includeIndices == true) {
          // Create the face list
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

        // Save the amount of verts we've already written so we can offset
        // the face index on the next mesh
        writtenVertices += vertices.count;
      });

      result = output.buffer;

    } else {
      // Ascii File Generation
      // count the number of vertices
      var writtenVertices = 0;
      var vertexList = '';
      var faceList = '';

      traverseMeshes(function(mesh:Mesh) {
        var geometry:Geometry = mesh.geometry;

        var vertices:BufferAttribute = geometry.getAttribute('position');
        var normals:BufferAttribute = geometry.getAttribute('normal');
        var uvs:BufferAttribute = geometry.getAttribute('uv');
        var colors:BufferAttribute = geometry.getAttribute('color');
        var indices:BufferAttribute = geometry.getIndex();

        normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);

        // form each line
        for (var i = 0; i < vertices.count; i++) {
          vertex.fromBufferAttribute(vertices, i);

          vertex.applyMatrix4(mesh.matrixWorld);

          // Position information
          var line =
            vertex.x + ' ' +
            vertex.y + ' ' +
            vertex.z;

          // Normal information
          if (includeNormals == true) {
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

          // UV information
          if (includeUVs == true) {
            if (uvs != null) {
              line += ' ' +
                uvs.getX(i) + ' ' +
                uvs.getY(i);
            } else {
              line += ' 0 0';
            }
          }

          // Color information
          if (includeColors == true) {
            if (colors != null) {
              tempColor.fromBufferAttribute(colors, i).convertLinearToSRGB();
              line += ' ' +
                Std.parseInt(tempColor.r * 255) + ' ' +
                Std.parseInt(tempColor.g * 255) + ' ' +
                Std.parseInt(tempColor.b * 255);
            } else {
              line += ' 255 255 255';
            }
          }

          vertexList += line + '\n';
        }

        // Create the face list
        if (includeIndices == true) {
          if (indices != null) {
            for (var i = 0; i < indices.count; i += 3) {
              faceList += `3 ${indices.getX(i + 0) + writtenVertices}`;
              faceList += ` ${indices.getX(i + 1) + writtenVertices}`;
              faceList += ` ${indices.getX(i + 2) + writtenVertices}\n`;
            }
          } else {
            for (var i = 0; i < vertices.count; i += 3) {
              faceList += `3 ${writtenVertices + i} ${writtenVertices + i + 1} ${writtenVertices + i + 2}\n`;
            }
          }
          faceCount += (indices != null ? indices.count / 3 : vertices.count / 3);
        }

        writtenVertices += vertices.count;
      });

      result = `${header}${vertexList}${includeIndices ? `${faceList}\n` : '\n'}`;
    }

    if (js.Boot.isFunction(onDone)) {
      window.requestAnimationFrame(function() {
        onDone(result);
      });
    }

    return result;
  }

}