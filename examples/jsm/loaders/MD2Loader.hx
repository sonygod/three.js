package three.js.loaders;

import haxe.io.Bytes;
import three.js.loaders.Loader;
import three.js.loaders.FileLoader;
import three.js.core.BufferGeometry;
import three.js.core.Float32BufferAttribute;
import three.js.animation.AnimationClip;

class MD2Loader extends Loader {
    private var _normalData:Array<Array<Float>> = [
        [-0.525731, 0.000000, 0.850651], [-0.442863, 0.238856, 0.864188], [-0.295242, 0.000000, 0.955423], 
        // ... (rest of the normal data array)
    ];

    public function new(manager:Loader) {
        super(manager);
    }

    public function load(url:String, onLoad:(geometry:BufferGeometry)->Void, onProgress:(bytesLoaded:Int, bytesTotal:Int)->Void, onError:(error:Dynamic)->Void) {
        var loader:FileLoader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(buffer:haxe.io.Bytes) {
            try {
                onLoad(parse(buffer));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    Console.error(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    private function parse(buffer:haxe.io.Bytes):BufferGeometry {
        var data:DataView = new DataView(buffer);
        var header:Dynamic = {};
        var headerNames:Array<String> = [
            'ident', 'version',
            'skinwidth', 'skinheight',
            'framesize',
            'num_skins', 'num_vertices', 'num_st', 'num_tris', 'num_glcmds', 'num_frames',
            'offset_skins', 'offset_st', 'offset_tris', 'offset_frames', 'offset_glcmds', 'offset_end'
        ];

        for (i in 0...headerNames.length) {
            Reflect.setField(header, headerNames[i], data.getInt32(i * 4, true));
        }

        if (header.ident != 844121161 || header.version != 8) {
            Console.error('Not a valid MD2 file');
            return null;
        }

        if (header.offset_end != data.byteLength) {
            Console.error('Corrupted MD2 file');
            return null;
        }

        var geometry:BufferGeometry = new BufferGeometry();

        // uvs
        var uvsTemp:Array<Float> = [];
        var offset:Int = header.offset_st;
        for (i in 0...header.num_st) {
            var u:Int = data.getInt16(offset, true);
            var v:Int = data.getInt16(offset + 2, true);
            uvsTemp.push(u / header.skinwidth, 1 - (v / header.skinheight));
            offset += 4;
        }

        // triangles
        offset = header.offset_tris;
        var vertexIndices:Array<Int> = [];
        var uvIndices:Array<Int> = [];

        for (i in 0...header.num_tris) {
            vertexIndices.push(data.getUint16(offset, true));
            vertexIndices.push(data.getUint16(offset + 2, true));
            vertexIndices.push(data.getUint16(offset + 4, true));
            uvIndices.push(data.getUint16(offset + 6, true));
            uvIndices.push(data.getUint16(offset + 8, true));
            uvIndices.push(data.getUint16(offset + 10, true));
            offset += 12;
        }

        // frames
        var translation:Vector3 = new Vector3();
        var scale:Vector3 = new Vector3();

        var frames:Array<Dynamic> = [];

        offset = header.offset_frames;

        for (i in 0...header.num_frames) {
            scale.x = data.getFloat32(offset, true);
            scale.y = data.getFloat32(offset + 4, true);
            scale.z = data.getFloat32(offset + 8, true);

            translation.x = data.getFloat32(offset + 12, true);
            translation.y = data.getFloat32(offset + 16, true);
            translation.z = data.getFloat32(offset + 20, true);

            offset += 24;

            var string:Array<Int> = [];

            for (j in 0...16) {
                var character:Int = data.getUint8(offset + j);
                if (character == 0) break;
                string.push(character);
            }

            var frame:Dynamic = {
                name: String.fromCharCode.apply(null, string),
                vertices: [],
                normals: []
            };

            offset += 16;

            for (j in 0...header.num_vertices) {
                var x:Int = data.getUint8(offset++);
                var y:Int = data.getUint8(offset++);
                var z:Int = data.getUint8(offset++);
                var n:Array<Float> = _normalData[data.getUint8(offset++)];

                x = x * scale.x + translation.x;
                y = y * scale.y + translation.y;
                z = z * scale.z + translation.z;

                frame.vertices.push(x, z, y); // convert to Y-up
                frame.normals.push(n[0], n[2], n[1]); // convert to Y-up
            }

            frames.push(frame);
        }

        // static

        var positions:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        var verticesTemp:Array<Float> = frames[0].vertices;
        var normalsTemp:Array<Float> = frames[0].normals;

        for (i in 0...vertexIndices.length) {
            var vertexIndex:Int = vertexIndices[i];
            var stride:Int = vertexIndex * 3;

            // position
            var x:Float = verticesTemp[stride];
            var y:Float = verticesTemp[stride + 1];
            var z:Float = verticesTemp[stride + 2];
            positions.push(x, y, z);

            // normal
            var nx:Float = normalsTemp[stride];
            var ny:Float = normalsTemp[stride + 1];
            var nz:Float = normalsTemp[stride + 2];
            normals.push(nx, ny, nz);

            // uv
            var uvIndex:Int = uvIndices[i];
            stride = uvIndex * 2;
            var u:Float = uvsTemp[stride];
            var v:Float = uvsTemp[stride + 1];
            uvs.push(u, v);
        }

        geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
        geometry.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        geometry.setAttribute('uv', new Float32BufferAttribute(uvs, 2));

        // animation

        var morphPositions:Array<Float32BufferAttribute> = [];
        var morphNormals:Array<Float32BufferAttribute> = [];

        for (i in 0...frames.length) {
            var frame:Dynamic = frames[i];
            var attributeName:String = frame.name;

            if (frame.vertices.length > 0) {
                var positions:Array<Float> = [];

                for (j in 0...vertexIndices.length) {
                    var vertexIndex:Int = vertexIndices[j];
                    var stride:Int = vertexIndex * 3;

                    var x:Float = frame.vertices[stride];
                    var y:Float = frame.vertices[stride + 1];
                    var z:Float = frame.vertices[stride + 2];
                    positions.push(x, y, z);
                }

                var positionAttribute:Float32BufferAttribute = new Float32BufferAttribute(positions, 3);
                positionAttribute.name = attributeName;
                morphPositions.push(positionAttribute);
            }

            if (frame.normals.length > 0) {
                var normals:Array<Float> = [];

                for (j in 0...vertexIndices.length) {
                    var vertexIndex:Int = vertexIndices[j];
                    var stride:Int = vertexIndex * 3;

                    var nx:Float = frame.normals[stride];
                    var ny:Float = frame.normals[stride + 1];
                    var nz:Float = frame.normals[stride + 2];
                    normals.push(nx, ny, nz);
                }

                var normalAttribute:Float32BufferAttribute = new Float32BufferAttribute(normals, 3);
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