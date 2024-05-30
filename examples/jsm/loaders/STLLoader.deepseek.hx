import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.FileLoader;
import three.Float32BufferAttribute;
import three.Loader;
import three.Vector3;

class STLLoader extends Loader {

    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var scope = this;
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);

        loader.load(url, function(text:Dynamic) {
            try {
                onLoad(scope.parse(text));
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

    public function parse(data:Dynamic):BufferGeometry {
        function isBinary(data:Dynamic):Bool {
            var reader = new DataView(data);
            var face_size = (32 / 8 * 3) + ((32 / 8 * 3) * 3) + (16 / 8);
            var n_faces = reader.getUint32(80, true);
            var expect = 80 + (32 / 8) + (n_faces * face_size);

            if (expect == reader.byteLength) {
                return true;
            }

            var solid = [115, 111, 108, 105, 100];

            for (var off = 0; off < 5; off ++) {
                if (matchDataViewAt(solid, reader, off)) return false;
            }

            return true;
        }

        function matchDataViewAt(query:Array<Int>, reader:DataView, offset:Int):Bool {
            for (var i = 0; i < query.length; i ++) {
                if (query[i] != reader.getUint8(offset + i)) return false;
            }
            return true;
        }

        function parseBinary(data:Dynamic):BufferGeometry {
            var reader = new DataView(data);
            var faces = reader.getUint32(80, true);

            var r:Float, g:Float, b:Float, hasColors = false, colors:Float32Array;
            var defaultR:Float, defaultG:Float, defaultB:Float, alpha:Float;

            for (var index = 0; index < 80 - 10; index ++) {
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

            var dataOffset = 84;
            var faceLength = 12 * 4 + 2;

            var geometry = new BufferGeometry();

            var vertices = new Float32Array(faces * 3 * 3);
            var normals = new Float32Array(faces * 3 * 3);

            var color = new Color();

            for (var face = 0; face < faces; face ++) {
                var start = dataOffset + face * faceLength;
                var normalX = reader.getFloat32(start, true);
                var normalY = reader.getFloat32(start + 4, true);
                var normalZ = reader.getFloat32(start + 8, true);

                if (hasColors) {
                    var packedColor = reader.getUint16(start + 48, true);

                    if ((packedColor & 0x8000) == 0) {
                        r = (packedColor & 0x1F) / 31;
                        g = ((packedColor >> 5) & 0x1F) / 31;
                        b = ((packedColor >> 10) & 0x1F) / 31;
                    } else {
                        r = defaultR;
                        g = defaultG;
                        b = defaultB;
                    }
                }

                for (var i = 1; i <= 3; i ++) {
                    var vertexstart = start + i * 12;
                    var componentIdx = (face * 3 * 3) + ((i - 1) * 3);

                    vertices[componentIdx] = reader.getFloat32(vertexstart, true);
                    vertices[componentIdx + 1] = reader.getFloat32(vertexstart + 4, true);
                    vertices[componentIdx + 2] = reader.getFloat32(vertexstart + 8, true);

                    normals[componentIdx] = normalX;
                    normals[componentIdx + 1] = normalY;
                    normals[componentIdx + 2] = normalZ;

                    if (hasColors) {
                        color.set(r, g, b).convertSRGBToLinear();

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
            var patternSolid = /solid([\s\S]*?)endsolid/g;
            var patternFace = /facet([\s\S]*?)endfacet/g;
            var patternName = /solid\s(.+)/;
            var faceCounter = 0;

            var patternFloat = /[\s]+([+-]?(?:\d*)(?:\.\d*)?(?:[eE][+-]?\d+)?)/.source;
            var patternVertex = new RegExp('vertex' + patternFloat + patternFloat + patternFloat, 'g');
            var patternNormal = new RegExp('normal' + patternFloat + patternFloat + patternFloat, 'g');

            var vertices = [];
            var normals = [];
            var groupNames = [];

            var normal = new Vector3();

            var result:RegExpMatch;

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
                        normal.x = parseFloat(result[1]);
                        normal.y = parseFloat(result[2]);
                        normal.z = parseFloat(result[3]);
                        normalCountPerFace ++;
                    }

                    while ((result = patternVertex.exec(text)) != null) {
                        vertices.push(parseFloat(result[1]), parseFloat(result[2]), parseFloat(result[3]));
                        normals.push(normal.x, normal.y, normal.z);
                        vertexCountPerFace ++;
                        endVertex ++;
                    }

                    if (normalCountPerFace != 1) {
                        trace('THREE.STLLoader: Something isn\'t right with the normal of face number ' + faceCounter);
                    }

                    if (vertexCountPerFace != 3) {
                        trace('THREE.STLLoader: Something isn\'t right with the vertices of face number ' + faceCounter);
                    }

                    faceCounter ++;
                }

                var start = startVertex;
                var count = endVertex - startVertex;

                geometry.userData.groupNames = groupNames;

                geometry.addGroup(start, count, groupCount);
                groupCount ++;
            }

            geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
            geometry.setAttribute('normal', new Float32BufferAttribute(normals, 3));

            return geometry;
        }

        function ensureString(buffer:Dynamic):String {
            if (typeof buffer != 'string') {
                return new TextDecoder().decode(buffer);
            }
            return buffer;
        }

        function ensureBinary(buffer:Dynamic):Dynamic {
            if (typeof buffer == 'string') {
                var array_buffer = new Uint8Array(buffer.length);
                for (var i = 0; i < buffer.length; i ++) {
                    array_buffer[i] = buffer.charCodeAt(i) & 0xff; // implicitly assumes little-endian
                }
                return array_buffer.buffer || array_buffer;
            } else {
                return buffer;
            }
        }

        var binData = ensureBinary(data);

        return isBinary(binData) ? parseBinary(binData) : parseASCII(ensureString(data));
    }
}