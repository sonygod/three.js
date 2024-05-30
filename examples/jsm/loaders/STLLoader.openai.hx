package three.js.loaders;

import haxe.io.Bytes;
import three.js.BufferAttribute;
import three.js.BufferGeometry;
import three.js.Color;
import three.js.FileLoader;
import three.js.Float32BufferAttribute;
import three.js.Loader;
import three.js.Vector3;

/**
 * ...
 */

class STLLoader extends Loader {
    public function new(manager:Loader) {
        super(manager);
    }

    public function load(url:String, onLoad:Event->Void, onProgress:Event->Void, onError:Event->Void) {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);

        loader.load(url, function(text:Event) {
            try {
                onLoad(parse(text));
            } catch (e:Any) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    function parse(data:Any) {
        function isBinary(data:Bytes):Bool {
            var reader = new DataView(data);
            var faceSize = (32 / 8 * 3) + (32 / 8 * 3 * 3) + (16 / 8);
            var nFaces = reader.getUint32(80, true);
            var expect = 80 + (32 / 8) + (nFaces * faceSize);

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
            var solid = [115, 111, 108, 105, 100];

            for (i in 0...5) {
                // If "solid" text is matched to the current offset, declare it to be an ASCII STL.
                if (matchDataViewAt(solid, reader, i)) return false;
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

        function parseBinary(data:Bytes):BufferGeometry {
            var reader = new DataView(data);
            var faces = reader.getUint32(80, true);

            var r, g, b, hasColors = false, colors;
            var defaultR, defaultG, defaultB, alpha;

            // process STL header
            // check for default color in header ("COLOR=rgba" sequence).
            for (i in 0...(80 - 10)) {
                if ((reader.getUint32(i, false) == 0x434F4C4F /*COLO*/) &&
                    (reader.getUint8(i + 4) == 0x52 /*'R'*/) &&
                    (reader.getUint8(i + 5) == 0x3D /*'='*/)) {
                    hasColors = true;
                    colors = new Float32Array(faces * 3 * 3);

                    defaultR = reader.getUint8(i + 6) / 255;
                    defaultG = reader.getUint8(i + 7) / 255;
                    defaultB = reader.getUint8(i + 8) / 255;
                    alpha = reader.getUint8(i + 9) / 255;
                }
            }

            var dataOffset = 84;
            var faceLength = 12 * 4 + 2;

            var geometry = new BufferGeometry();

            var vertices = new Float32Array(faces * 3 * 3);
            var normals = new Float32Array(faces * 3 * 3);

            var color = new Color();

            for (face in 0...faces) {
                var start = dataOffset + face * faceLength;
                var normalX = reader.getFloat32(start, true);
                var normalY = reader.getFloat32(start + 4, true);
                var normalZ = reader.getFloat32(start + 8, true);

                if (hasColors) {
                    var packedColor = reader.getUint16(start + 48, true);

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
                    var vertexStart = start + i * 12;
                    var componentIdx = (face * 3 * 3) + ((i - 1) * 3);

                    vertices[componentIdx] = reader.getFloat32(vertexStart, true);
                    vertices[componentIdx + 1] = reader.getFloat32(vertexStart + 4, true);
                    vertices[componentIdx + 2] = reader.getFloat32(vertexStart + 8, true);

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
            var geometry = new BufferGeometry();
            var patternSolid = ~/solid([\s\S]*?)endsolid/g;
            var patternFace = ~/facet([\s\S]*?)endfacet/g;
            var patternName = ~/solid\s(.+)/;
            var faceCounter = 0;

            var patternFloat = ~/[\s]+([+-]?(\d*)(\.\d*)?([eE][+-]?\d+)?)?/;
            var patternVertex = new EReg('vertex' + patternFloat.source + patternFloat.source + patternFloat.source, 'g');
            var patternNormal = new EReg('normal' + patternFloat.source + patternFloat.source + patternFloat.source, 'g');

            var vertices = [];
            var normals = [];
            var groupNames = [];

            var normal = new Vector3();

            var groupCount = 0;
            var startVertex = 0;
            var endVertex = 0;

            while ((result = patternSolid.exec(data)) != null) {
                startVertex = endVertex;

                var solid = result[0];

                var name = (result = patternName.exec(solid)) != null ? result[1] : '';
                groupNames.push(name);

                while ((result = patternFace.exec(solid)) != null) {
                    var vertexCountPerFace = 0;
                    var normalCountPerFace = 0;

                    var text = result[0];

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

                var start = startVertex;
                var count = endVertex - startVertex;

                geometry.userData.groupNames = groupNames;

                geometry.addGroup(start, count, groupCount);
                groupCount++;
            }

            geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
            geometry.setAttribute('normal', new Float32BufferAttribute(normals, 3));

            return geometry;
        }

        function ensureString(buffer:Any):String {
            if (Std.is(buffer, String)) {
                return buffer;
            }

            return new String(buffer);
        }

        function ensureBinary(buffer:Any):Bytes {
            if (Std.is(buffer, Bytes)) {
                return buffer;
            }

            var arrayBuffer = new UInt8Array(buffer.length);
            for (i in 0...buffer.length) {
                arrayBuffer[i] = buffer.charCodeAt(i) & 0xff; // implicitly assumes little-endian
            }

            return arrayBuffer;
        }

        var data = ensureBinary(data);
        return isBinary(data) ? parseBinary(data) : parseASCII(ensureString(data));
    }
}