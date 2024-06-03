import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.FileLoader;
import three.Float32BufferAttribute;
import three.Loader;
import three.Vector3;

/**
 * Description: A THREE loader for STL ASCII files, as created by Solidworks and other CAD programs.
 *
 * Supports both binary and ASCII encoded files, with automatic detection of type.
 *
 * The loader returns a non-indexed buffer geometry.
 *
 * Limitations:
 *  Binary decoding supports "Magics" color format (http://en.wikipedia.org/wiki/STL_(file_format)#Color_in_binary_STL).
 *  There is perhaps some question as to how valid it is to always assume little-endian-ness.
 *  ASCII decoding assumes file is UTF-8.
 *
 * Usage:
 *  const loader = new STLLoader();
 *  loader.load( './models/stl/slotted_disk.stl', function ( geometry ) {
 *    scene.add( new THREE.Mesh( geometry ) );
 *  });
 *
 * For binary STLs geometry might contain colors for vertices. To use it:
 *  // use the same code to load STL as above
 *  if (geometry.hasColors) {
 *    material = new THREE.MeshPhongMaterial({ opacity: geometry.alpha, vertexColors: true });
 *  } else { .... }
 *  const mesh = new THREE.Mesh( geometry, material );
 *
 * For ASCII STLs containing multiple solids, each solid is assigned to a different group.
 * Groups can be used to assign a different color by defining an array of materials with the same length of
 * geometry.groups and passing it to the Mesh constructor:
 *
 * const mesh = new THREE.Mesh( geometry, material );
 *
 * For example:
 *
 *  const materials = [];
 *  const nGeometryGroups = geometry.groups.length;
 *
 *  const colorMap = ...; // Some logic to index colors.
 *
 *  for (let i = 0; i < nGeometryGroups; i++) {
 *
 *		const material = new THREE.MeshPhongMaterial({
 *			color: colorMap[i],
 *			wireframe: false
 *		});
 *
 *  }
 *
 *  materials.push(material);
 *  const mesh = new THREE.Mesh(geometry, materials);
 */

class STLLoader extends Loader {

    public function new(manager:Loader.LoaderManager = null) {
        super(manager);
    }

    public function load(url:String, onLoad:(geometry:BufferGeometry) -> Void, onProgress:(event:ProgressEvent) -> Void = null, onError:(event:Error) -> Void = null):Void {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);

        loader.load(url, function(text:ArrayBuffer) {
            try {
                onLoad(this.parse(text));
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

    public function parse(data:ArrayBuffer):BufferGeometry {
        function isBinary(data:ArrayBuffer):Bool {
            var reader = new DataView(data);
            var face_size = (32 / 8 * 3) + ((32 / 8 * 3) * 3) + (16 / 8);
            var n_faces = reader.getUint32(80, true);
            var expect = 80 + (32 / 8) + (n_faces * face_size);

            if (expect == reader.byteLength) {
                return true;
            }

            var solid = [115, 111, 108, 105, 100];

            for (var off in 0...5) {
                if (matchDataViewAt(solid, reader, off)) return false;
            }

            return true;
        }

        function matchDataViewAt(query:Array<Int>, reader:DataView, offset:Int):Bool {
            for (var i in 0...query.length) {
                if (query[i] != reader.getUint8(offset + i)) return false;
            }

            return true;
        }

        function parseBinary(data:ArrayBuffer):BufferGeometry {
            var reader = new DataView(data);
            var faces = reader.getUint32(80, true);

            var r:Float, g:Float, b:Float, hasColors = false, colors:Float32Array;
            var defaultR:Float, defaultG:Float, defaultB:Float, alpha:Float;

            for (var index in 0...80 - 10) {
                if ((reader.getUint32(index, false) == 0x434F4C4F) &&
                    (reader.getUint8(index + 4) == 0x52) &&
                    (reader.getUint8(index + 5) == 0x3D)) {

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

            for (var face in 0...faces) {
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

                for (var i in 1...4) {
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
            var patternSolid = new EReg("solid([\\s\\S]*?)endsolid", "g");
            var patternFace = new EReg("facet([\\s\\S]*?)endfacet", "g");
            var patternName = new EReg("solid\\s(.+)");
            var faceCounter = 0;

            var patternFloat = "[\s]+([+-]?(?:\\d*)(?:\\.\\d*)?(?:[eE][+-]?\\d+)?)".toEReg();
            var patternVertex = new EReg("vertex" + patternFloat + patternFloat + patternFloat, "g");
            var patternNormal = new EReg("normal" + patternFloat + patternFloat + patternFloat, "g");

            var vertices:Array<Float> = [];
            var normals:Array<Float> = [];
            var groupNames:Array<String> = [];

            var normal = new Vector3();

            var result:ERegMatch;

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

                    if (normalCountPerFace != 1) {
                        trace("THREE.STLLoader: Something isn't right with the normal of face number " + faceCounter);
                    }

                    if (vertexCountPerFace != 3) {
                        trace("THREE.STLLoader: Something isn't right with the vertices of face number " + faceCounter);
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

        function ensureString(buffer:ArrayBuffer):String {
            if (Type.getClass(buffer) != String) {
                var bytes = new Uint8Array(buffer);
                return String.fromCharCode.apply(null, bytes);
            }

            return buffer;
        }

        function ensureBinary(buffer:String):ArrayBuffer {
            if (Type.getClass(buffer) == String) {
                var array_buffer = new Uint8Array(buffer.length);
                for (var i in 0...buffer.length) {
                    array_buffer[i] = buffer.charCodeAt(i) & 0xff;
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

export STLLoader;