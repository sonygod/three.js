import haxe.io.Bytes;
import js.html.DataView;
import js.html.Float32Array;
import js.html.Int16Array;
import js.html.Int32Array;
import js.html.Int8Array;
import js.html.Uint16Array;
import js.html.Uint8Array;

class MD2Loader {
    public function new(manager:Dynamic) {
        // ...
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.path = scope.path;
        loader.responseType = 'arraybuffer';
        loader.setRequestHeader(scope.requestHeader);
        loader.withCredentials = scope.withCredentials;
        loader.load(url, function(buffer:Bytes) {
            try {
                onLoad(scope.parse(buffer));
            } catch (e) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(buffer:Bytes):BufferGeometry {
        var data = new DataView(buffer);

        // http://tfc.duke.free.fr/coding/md2-specs-en.html

        var header = new Hash<Int>();
        var headerNames = [
            'ident', 'version',
            'skinwidth', 'skinheight',
            'framesize',
            'num_skins', 'num_vertices', 'num_st', 'num_tris', 'num_glcmds', 'num_frames',
            'offset_skins', 'offset_st', 'offset_tris', 'offset_frames', 'offset_glcmds', 'offset_end'
        ];

        for (i in 0...headerNames.length) {
            header[headerNames[i]] = data.getInt32(i * 4, true);
        }

        if (header.ident != 844121161 || header.version != 8) {
            throw 'Not a valid MD2 file';
        }

        if (header.offset_end != buffer.length) {
            throw 'Corrupted MD2 file';
        }

        //

        var geometry = new BufferGeometry();

        // uvs

        var uvsTemp = [];
        var offset = header.offset_st;

        for (i in 0...header.num_st) {
            var u = data.getInt16(offset + 0, true);
            var v = data.getInt16(offset + 2, true);
            uvsTemp.push([u / header.skinwidth, 1 - (v / header.skinheight)]);
            offset += 4;
        }

        // triangles

        offset = header.offset_tris;

        var vertexIndices = [];
        var uvIndices = [];

        for (i in 0...header.num_tris) {
            vertexIndices.push([
                data.getUint16(offset + 0, true),
                data.getUint16(offset + 2, true),
                data.getUint16(offset + 4, true)
            ]);
            uvIndices.push([
                data.getUint16(offset + 6, true),
                data.getUint16(offset + 8, true),
                data.getUint16(offset + 10, true)
            ]);
            offset += 12;
        }

        // frames

        var translation = new Vector3();
        var scale = new Vector3();

        var frames = [];

        offset = header.offset_frames;

        for (i in 0...header.num_frames) {
            scale.set(
                data.getFloat32(offset + 0, true),
                data.getFloat32(offset + 4, true),
                data.getFloat32(offset + 8, true)
            );
            translation.set(
                data.getFloat32(offset + 12, true),
                data.getFloat32(offset + 16, true),
                data.getFloat32(offset + 20, true)
            );
            offset += 24;
            var string = [];
            for (j in 0...16) {
                var character = data.getUint8(offset + j);
                if (character == 0) {
                    break;
                }
                string.push(character);
            }
            var frame = {
                name: String.fromCharCodeArray(string),
                vertices: [],
                normals: []
            };
            offset += 16;
            for (j in 0...header.num_vertices) {
                var x = data.getUint8(offset++);
                var y = data.getUint8(offset++);
                var z = data.getUint8(offset++);
                var n = _normalData[data.getUint8(offset++)];
                x = x * scale.x + translation.x;
                y = y * scale.y + translation.y;
                z = z * scale.z + translation.z;
                frame.vertices.push([x, z, y]); // convert to Y-up
                frame.normals.push([n[0], n[2], n[1]]); // convert to Y-up
            }
            frames.push(frame);
        }

        // static

        var positions = [];
        var normals = [];
        var uvs = [];

        var verticesTemp = frames[0].vertices;
        var normalsTemp = frames[0].normals;

        for (i in 0...vertexIndices.length) {
            var vertexIndex = vertexIndices[i];
            var stride = vertexIndex * 3;
            var x = verticesTemp[stride];
            var y = verticesTemp[stride + 1];
            var z = verticesTemp[stride + 2];
            positions.push([x, y, z]);
            var nx = normalsTemp[stride];
            var ny = normalsTemp[stride + 1];
            var nz = normalsTemp[stride + 2];
            normals.push([nx, ny, nz]);
            var uvIndex = uvIndices[i];
            stride = uvIndex * 2;
            var u = uvsTemp[stride];
            var v = uvsTemp[stride + 1];
            uvs.push([u, v]);
        }

        geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
        geometry.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        geometry.setAttribute('uv', new Float32BufferAttribute(uvs, 2));

        // animation

        var morphPositions = [];
        var morphNormals = [];

        for (i in 0...frames.length) {
            var frame = frames[i];
            var attributeName = frame.name;
            if (frame.vertices.length > 0) {
                var positions = [];
                for (j in 0...vertexIndices.length) {
                    var vertexIndex = vertexIndices[j];
                    var stride = vertexIndex * 3;
                    var x = frame.vertices[stride];
                    var y = frame.vertices[stride + 1];
                    var z = frame.vertices[stride + 2];
                    positions.push([x, y, z]);
                }
                var positionAttribute = new Float32BufferAttribute(positions, 3);
                positionAttribute.name = attributeName;
                morphPositions.push(positionAttribute);
            }
            if (frame.normals.length > 0) {
                var normals = [];
                for (j in 0...vertexIndices.length) {
                    var vertexIndex = vertexIndices[j];
                    var stride = vertexIndex * 3;
                    var nx = frame.normals[stride];
                    var ny = frame.normals[stride + 1];
                    var nz = frame.normals[stride + 2];
                    normals.push([nx, ny, nz]);
                }
                var normalAttribute = new Float32BufferAttribute(normals, 3);
                normalAttribute.name = attributeName;
                morphNormals.push(normalAttribute);
            }
        }

        geometry.morphAttributes.position = morphPositions;
        geometry.morphAttributes.normal = morphNormals;
        geometry.morphTargetsRelative = false;
        geometry.animations = AnimationClip.CreateClipsFromMorphTargetSequences(frames, 10);
        return geometry;
    }
}

class _Main {
    static function main() {
        var _normalData = [
            [-0.525731, 0.0, 0.850651], [-0.442863, 0.238856, 0.864188],
            [-0.295242, 0.0, 0.955423], [-0.309017, 0.5, 0.809017],
            [-0.16246, 0.262866, 0.951056], [0.0, 0.0, 1.0],
            [0.0, 0.850651, 0.525731], [-0.147621, 0.716567, 0.681718],
            [0.147621, 0.716567, 0.681718], [0.0, 0.525731, 0.850651],
            [0.309017, 0.5, 0.809017], [0.525731, 0.0, 0.850651],
            [0.295242, 0.0, 0.955423], [0.442863, 0.238856, 0.864188],
            [0.16246, 0.262866, 0.951056], [-0.681718, 0.147621, 0.716567],
            [-0.809017, 0.309017, 0.5], [-0.587785, 0.425325, 0.688191],
            [-0.850651, 0.525731, 0.0], [-0.864188, 0.442863, 0.238856],
            [-0.716567, 0.681718, 0.147621], [-0.688191, 0.587785, 0.425325],
            [-0.5, 0.809017, 0.309017], [-0.238856, 0.864188, 0.442863],
            [-0.425325, 0.688191, 0.587785], [-0.716567, 0.681718, -0.147621],
            [-0.5, 0.809017, -0.309017], [-0.525731, 0.850651, 0.0],
            [0.0, 0.850651, -0.525731], [-0.238856, 0.864188, -0.442863],
            [0.0, 0.955423, -0.295242], [-0.262866, 0.951056, -0.16246],
            [0.0, 1.0, 0.0], [0.0, 0.955423, 0.295242],
            [-0.262866, 0.951056, 0.16246], [0.238856, 0.864188, 0.442863],
            [0.262866, 0.951056, 0.16246], [0.5, 0.809017, 0.309017],
            [0.238856, 0.864188, -0.442863], [0.262866, 0.951056, -0.16246],
            [0.5, 0.809017, -0.309017], [0.850651, 0.525731, 0.0],
            [0.716567, 0.681718, 0.147621], [0.716567, 0.681718, -0.147621],
            [0.525731, 0.850651, 0.0], [0.425325, 0.688191, 0.587785],
            [0.864188, 0.442863, 0.238856], [0.688191, 0.587785, 0.425325],
            [0.809017, 0.309017, 0.5], [0.681718, 0.147621, 0.716567],
            [0.587785, 0.425325, 0.688191], [0.955423, 0.295242, 0.0],
            [1.0, 0.0, 0.0], [0.951056, 0.16246, 0.262866],
            [0.850651, -0.525731, 0.0], [0.955423, -0.295242, 0.0],
            [0.864188, -0.442863, 0.238856], [0.951056, -0.16246, 0.262866],
            [0.809017, -0.309017, 0.5], [0.681718, -0.147621, 0.716567],
            [0.850651, 0.0, 0.525731], [0.864188, 0.442863, -0.238856],
            [0.809017, 0.309017, -0.5], [0.951056, 0.16246, -0.262866],
            [0.525731, 0.0, -0.850651], [0.681718, 0.147621, -0.716567],
            [0.681718, -0.147621, -0.716567], [0.850651, 0.0, -0.525731],
            [0.809017, -0.309017, -0.5], [0.864188, -0.442863, -0.238856],
            [0.951056, -0.16246, -0.262866], [0.147621, 0.716567, -0.681718],
            [0.309017, 0.5, -0.809017], [0.425325, 0.688191, -0.587785],
            [0.442863, 0.238856, -0.864188], [0.587785, 0.425325, -0.6881965],
            [0.688191, -0.587785, -0.425325],
            [-0.147621, 0.716567, -0.681718],
            [-0.309017, 0.5, -0.809017],
            [0.0, 0.525731, -0.850651],
            [-0.525731, 0.0, -0.850651],
            [-0.442863, 0.238856, -0.864188],
            [-0.295242, 0.0, -0.955423],
            [-0.16246, 0.262866, -0.951056],
            [0.0, 0.0, -1.0],
            [0.295242, 0.0, -0.955423],
            [0.16246, 0.262866, -0.951056],
            [-0.442863, -0.238856, -0.864188],
            [-0.309017, -0.5, -0.809017],
            [-0.16246, -0.262866, -0.951056],
            [0.0, -0.850651, -0.525731],
            [-0.147621, -0.716567, -0.681718],
            [0.147621, -0.716567, -0.681718],
            [0.0, -0.525731, -0.850651],
            [0.309017, -0.5, -0.809017],
            [0.442863, -0.238856, -0.864188],
            [0.16246, -0.262866, -0.951056],
            [0.5, -0.809017, -0.309017],
            [0.425325, -0.688191, -0.587785],
            [0.716567, -0.681718, -0.147621],
            [0.688191, -0.587785, -0.425325],
            [0.587785, -0.425325, -0.688191],
            [0.0, -0.955423, -0.295242],
            [0.0, -1.0, 0.0],
            [0.262866, -0.951056, -0.16246],
            [0.0, -0.850651, 0.525731],
            [0.0, -0.955423, 0.295242],
            [0.238856, -0.864188, 0.442863],
            [0.262866, -0.951056, 0.16246],
            [0.5, -0.809017, 0.309017],
            [0.716567, -0.681718, 0.147621],
            [0.525731, -0.850651, 0.0],
            [-0.238856, -0.864188, -0.442863],
            [-0.5, -0.809017, -0.309017],
            [-0.262866, -0.951056, -0.16246],
            [-0.850651, -0.525731, 0.0],
            [-0.716567, -0.681718, -0.147621],
            [-0.716567, -0.681718, 0.147621],
            [-0.525731, -0.850651, 0.0],
            [-0.688191, -0.587785, 0.425325],
            [-0.864188, -0.442863, 0.238856],
            [-0.688191, -0.587785, -0.425325],
            [-0.809017, -0.309017, 0.5],
            [-0.681718, -0.147621, 0.716567],
            [-0.587785, -0.425325, 0.688191],
            [-0.955423, 0.295242, 0.0],
            [-0.951056, 0.16246, 0.262866],
            [-1.0, 0.0, 0.0],
            [-0.850651, 0.0, 0.525731],
            [-0.955423, -0.295242, 0.0],
            [-0.951056, -0.16246, 0.262866],
            [-0.864188, 0.442863, -0.238856],
            [-0.951056, 0.16246, -0.262866],
            [-0.809017, 0.309017, -0.5],
            [-0.864188, -0.442863, -0.238856],
            [-0.951056, -0.16246, -0.262866],
            [-0.809017, -0.309017, -0.5],
            [-0.681718, 0.147621, -0.716567],
            [-0.681718, -0.147621, -0.716567],
            [-0.850651, 0.0, -0.525731],
            [-0.688191, 0.587785, -0.425325],
            [-0.587785, 0.425325, -0.688191],
            [-0.425325, 0.688191, -0.587785],
            [-0.425325, -688191, -0.587785],
            [-0.587785, -0.425325, -0.688191],
            [-0.688191, -0.587785, -0.425325]
        ];
    }
}