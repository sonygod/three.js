Here is the converted Haxe code:
```
package three.js.examples.jsm.loaders;

import three.js.BufferAttribute;
import three.js.BufferGeometry;
import three.js.Color;
import three.js.FileLoader;
import three.js.Float32BufferAttribute;
import three.js.Loader;
import three.js.Vector3;

class STLLoader extends Loader {
    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:(geometry:BufferGeometry) -> Void, onProgress:(progress:Float) -> Void, onError:(error:String) -> Void):Void {
        var loader:FileLoader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);

        loader.load(url, function(data:ArrayBuffer) {
            try {
                onLoad(parse(data));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    private function parse(data:ArrayBuffer):BufferGeometry {
        function isBinary(data:ArrayBuffer):Bool {
            var reader:DataView = new DataView(data);
            var face_size:Int = (32 / 8 * 3) + (32 / 8 * 3 * 3) + (16 / 8);
            var n_faces:Int = reader.getUint32(80, true);
            var expect:Int = 80 + (32 / 8) + (n_faces * face_size);

            if (expect == reader.byteLength) {
                return true;
            }

            // An ASCII STL data must begin with 'solid ' as the first six bytes.
            // However, ASCII STLs lacking the SPACE after the 'd' are known to be
            // plentiful.  So, check the first 5 bytes for 'solid'.

            // Several encodings, such as UTF-8, precede the text with up to 5 bytes:
            // https://en.wikipedia.org/wiki/Byte_order_mark#Byte_order_marks_by_encoding
            // Search for "solid" to start anywhere after those prefixes.

            // US-ASCII ordinal values for 's', 'o', 'l', 'i', 'd'

            var solid:Array<Int> = [115, 111, 108, 105, 100];

            for (off in 0...5) {
                // If "solid" text is matched to the current offset, declare it to be an ASCII STL.

                if (matchDataViewAt(solid, reader, off)) return false;
            }

            // Couldn't find "solid" text at the beginning; it is binary STL.

            return true;
        }

        function matchDataViewAt(query:Array<Int>, reader:DataView, offset:Int):Bool {
            // Check if each byte in query matches the corresponding byte from the current offset

            for (i in 0...query.length) {
                if (query[i] != reader.getUint8(offset + i)) return false;
            }

            return true;
        }

        function parseBinary(data:ArrayBuffer):BufferGeometry {
            var reader:DataView = new DataView(data);
            var faces:Int = reader.getUint32(80, true);

            var r:Float, g:Float, b:Float, hasColors:Bool = false, colors:Float32Array;
            var defaultR:Float, defaultG:Float, defaultB:Float, alpha:Float;

            // process STL header
            // check for default color in header ("COLOR=rgba" sequence).

            for (index in 0...80 - 10) {
                if ((reader.getUint32(index, false) == 0x434F4C4F /*COLO*/) &&
                    (reader.getUint8(index + 4) == 0x52 /*'R'*/) &&
                    (reader.getUint8(index + 5) == 0x3D /*'='*/)) {

                    hasColors = true;
                    colors = new Float32Array(faces * 3 * 3);

                    defaultR = reader.getUint8(index + 6) / 255;
                    defaultG = reader.getUint8(index + 7) / 255;
                    defaultB = reader.getUint8(index + 8) / 255;
                    alpha = reader.getUint8(index + 9) / 255;

                }
            }

            var dataOffset:Int = 84;
            var faceLength:Int = 12 * 4 + 2;

            var geometry:BufferGeometry = new BufferGeometry();

            var vertices:Float32Array = new Float32Array(faces * 3 * 3);
            var normals:Float32Array = new Float32Array(faces * 3 * 3);

            var color:Color = new Color();

            for (face in 0...faces) {
                var start:Int = dataOffset + face * faceLength;
                var normalX:Float = reader.getFloat32(start, true);
                var normalY:Float = reader.getFloat32(start + 4, true);
                var normalZ:Float = reader.getFloat32(start + 8, true);

                if (hasColors) {
                    var packedColor:Int = reader.getUint16(start + 48, true);

                    if ((packedColor & 0x8000) == 0) {
                        // facet has its own unique color

                        r = (packedColor & 0x1F) / 31;
                        g = ((packedColor >> 5) & 0x1F) / 31;
                        b = ((packedColor >> 10) & 0x1F) / 31;

                    } else {
                        r = defaultR;
                        g = defaultG;
                        b = defaultB;

                    }
                }

                for (i in 1...4) {
                    var vertexstart:Int = start + i * 12;
                    var componentIdx:Int = face * 3 * 3 + (i - 1) * 3;

                    vertices[componentIdx] = reader.getFloat32(vertexstart, true);
                    vertices[componentIdx + 1] = reader.getFloat32(vertexstart + 4, true);
                    vertices[componentIdx + 2] = reader.getFloat32(vertexstart + 8, true);

                    normals[componentIdx] = normalX;
                    normals[componentIdx + 1] = normalY;
                    normals[componentIdx + 2] = normalZ;

                    if (hasColors) {
                        color.setRGB(r, g, b).convertSRGBToLinear();

                        colors[componentIdx] = color.r;
                        colors[componentIdx + 1] = color.g;
                        colors[componentIdx + 2] = color.b;
                    }
                }
            }

            geometry.setAttribute('position', new BufferAttribute(vertices, 3));
            geometry.setAttribute('normal', new BufferAttribute(normals, 3));

            if (hasColors) {
                geometry.setAttribute('color', new BufferAttribute(colors, 3));
                geometry.hasColors = true;
                geometry.alpha = alpha;
            }

            return geometry;
        }

        function parseASCII(data:String):BufferGeometry {
            var geometry:BufferGeometry = new BufferGeometry();
            var patternSolid:EReg = ~/solid([\s\S]*?)endsolid/g;
            var patternFace:EReg = ~/facet([\s\S]*?)endfacet/g;
            var patternName:EReg = ~/solid\s(.+)/;
            var faceCounter:Int = 0;

            var patternFloat:String = ~/[\s]+([+-]?((?:\d*)(?:\.\d*)?(?:[eE][+-]?\d+)?)/.source;
            var patternVertex:EReg = new EReg('vertex' + patternFloat + patternFloat + patternFloat, 'g');
            var patternNormal:EReg = new EReg('normal' + patternFloat + patternFloat + patternFloat, 'g');

            var vertices:Array<Float> = [];
            var normals:Array<Float> = [];
            var groupNames:Array<String> = [];

            var normal:Vector3 = new Vector3();

            var result:ERegMatch;
            var groupCount:Int = 0;
            var startVertex:Int = 0;
            var endVertex:Int = 0;

            while ((result = patternSolid.exec(data)) != null) {
                startVertex = endVertex;

                var solid:String = result[0];

                var name:String = (result = patternName.exec(solid)) != null ? result[1] : '';
                groupNames.push(name);

                while ((result = patternFace.exec(solid)) != null) {
                    var vertexCountPerFace:Int = 0;
                    var normalCountPerFace:Int = 0;

                    var text:String = result[0];

                    while ((result = patternNormal.exec(text)) != null) {
                        normal.x = Std.parseFloat(result[1]);
                        normal.y = Std.parseFloat(result[2]);
                        normal.z = Std.parseFloat(result[3]);
                        normalCountPerFace++;
                    }

                    while ((result = patternVertex.exec(text)) != null) {
                        vertices.push(Std.parseFloat(result[1]), Std.parseFloat(result[2]), Std.parseFloat(result[3]));
                        normals.push(normal.x, normal.y, normal.z);
                        vertexCountPerFace++;
                        endVertex++;
                    }

                    // every face have to own ONE valid normal

                    if (normalCountPerFace != 1) {
                        trace('THREE.STLLoader: Something isn\'t right with the normal of face number ' + faceCounter);
                    }

                    // each face have to own THREE valid vertices

                    if (vertexCountPerFace != 3) {
                        trace('THREE.STLLoader: Something isn\'t right with the vertices of face number ' + faceCounter);
                    }

                    faceCounter++;
                }

                var start:Int = startVertex;
                var count:Int = endVertex - startVertex;

                geometry.userData.groupNames = groupNames;

                geometry.addGroup(start, count, groupCount);
                groupCount++;
            }

            geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
            geometry.setAttribute('normal', new Float32BufferAttribute(normals, 3));

            return geometry;
        }

        function ensureString(buffer:Dynamic):String {
            if (Std.is(buffer, String)) {
                return buffer;
            }

            return new String(buffer);
        }

        function ensureBinary(buffer:Dynamic):ArrayBuffer {
            if (Std.is(buffer, String)) {
                var array_buffer:ArrayBuffer = new Uint8Array(buffer.length);
                for (i in 0...buffer.length) {
                    array_buffer[i] = buffer.charCodeAt(i) & 0xff; // implicitly assumes little-endian
                }

                return array_buffer.buffer || array_buffer;
            } else {
                return buffer;
            }
        }

        // start

        var binData:ArrayBuffer = ensureBinary(data);

        return isBinary(binData) ? parseBinary(binData) : parseASCII(ensureString(data));
    }
}
```
Note that I had to make some assumptions about the Haxe target and libraries used. Please adjust the code accordingly based on your specific needs.