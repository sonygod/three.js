import js.html.File;
import js.html.FileReader;
import js.html.Blob;
import js.html.ProgressEvent;
import js.html.XMLHttpRequest;
import js.html.ArrayBuffer;
import js.html.DataView;

import three.AnimationClip;
import three.BufferGeometry;
import three.Loader;
import three.LoaderManager;
import three.FileLoader;
import three.Float32BufferAttribute;
import three.Vector3;

class MD2Loader extends Loader {

    private var _normalData:Array<Array<Float>> = [
        [-0.525731, 0.000000, 0.850651], [-0.442863, 0.238856, 0.864188],
        // ... rest of the data
    ];

    public function new(manager:LoaderManager = null) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null) {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setResponseType("arraybuffer");
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(buffer:ArrayBuffer) {
            try {
                onLoad(scope.parse(buffer));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(buffer:ArrayBuffer):three.BufferGeometry {
        var data = new DataView(buffer);

        var header:Dynamic = {};
        var headerNames:Array<String> = [
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
            trace("Not a valid MD2 file");
            return null;
        }

        if (header.offset_end != data.byteLength) {
            trace("Corrupted MD2 file");
            return null;
        }

        var geometry = new BufferGeometry();

        // uvs

        var uvsTemp = [];
        var offset = header.offset_st;

        for (i in 0...header.num_st) {
            var u = data.getInt16(offset + 0, true);
            var v = data.getInt16(offset + 2, true);

            uvsTemp.push(u / header.skinwidth, 1 - (v / header.skinheight));

            offset += 4;
        }

        // triangles

        offset = header.offset_tris;

        var vertexIndices = [];
        var uvIndices = [];

        for (i in 0...header.num_tris) {
            vertexIndices.push(
                data.getUint16(offset + 0, true),
                data.getUint16(offset + 2, true),
                data.getUint16(offset + 4, true)
            );

            uvIndices.push(
                data.getUint16(offset + 6, true),
                data.getUint16(offset + 8, true),
                data.getUint16(offset + 10, true)
            );

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
                if (character == 0) break;

                string[j] = character;
            }

            var frame = {
                name: String.fromCharCode.apply(null, string),
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

                frame.vertices.push(x, z, y); // convert to Y-up
                frame.normals.push(n[0], n[2], n[1]); // convert to Y-up
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

            positions.push(x, y, z);

            var nx = normalsTemp[stride];
            var ny = normalsTemp[stride + 1];
            var nz = normalsTemp[stride + 2];

            normals.push(nx, ny, nz);

            var uvIndex = uvIndices[i];
            stride = uvIndex * 2;

            var u = uvsTemp[stride];
            var v = uvsTemp[stride + 1];

            uvs.push(u, v);
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

                    positions.push(x, y, z);
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

                    normals.push(nx, ny, nz);
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