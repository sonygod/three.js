import h3d.BufferGeometry;
import h3d.Color;
import h3d.FileLoader;
import h3d.Float32BufferAttribute;
import h3d.Group;
import h3d.LineBasicMaterial;
import h3d.Loader;
import h3d.Material;
import h3d.Mesh;
import h3d.MeshPhongMaterial;
import h3d.Points;
import h3d.PointsMaterial;
import h3d.Vector3;

class ParserState {
    var objects:Array<Dynamic>;
    var object:Dynamic;
    var vertices:Array<Float>;
    var normals:Array<Float>;
    var colors:Array<Int>;
    var uvs:Array<Float>;
    var materials:Map<String, Dynamic>;
    var materialLibraries:Array<String>;

    function new() {
        objects = [];
        object = {
            name: "",
            fromDeclaration: false,
            geometry: {
                vertices: [],
                normals: [],
                colors: [],
                uvs: [],
                hasUVIndices: false
            },
            materials: [],
            smooth: true,
            startMaterial: function(name:String, libraries:Array<String>) {
                var previous = _finalize(false);
                if (previous != null && (previous.inherited || previous.groupCount <= 0)) {
                    materials.splice(previous.index, 1);
                }
                var material = {
                    index: materials.length,
                    name: name,
                    mtllib: (libraries != null ? libraries[libraries.length - 1] : ""),
                    smooth: (previous != null ? previous.smooth : smooth),
                    groupStart: (previous != null ? previous.groupEnd : 0),
                    groupEnd: -1,
                    groupCount: -1,
                    inherited: false,
                    clone: function(index:Int) {
                        var cloned = {
                            index: (index != null ? index : index),
                            name: name,
                            mtllib: mtllib,
                            smooth: smooth,
                            groupStart: 0,
                            groupEnd: -1,
                            groupCount: -1,
                            inherited: false
                        };
                        cloned.clone = clone;
                        return cloned;
                    }
                };
                materials.push(material);
                return material;
            },
            currentMaterial: function() {
                if (materials.length > 0) {
                    return materials[materials.length - 1];
                } else {
                    return null;
                }
            },
            _finalize: function(end:Bool) {
                var lastMultiMaterial = currentMaterial();
                if (lastMultiMaterial != null && lastMultiMaterial.groupEnd == -1) {
                    lastMultiMaterial.groupEnd = geometry.vertices.length / 3;
                    lastMultiMaterial.groupCount = lastMultiMaterial.groupEnd - lastMultiMaterial.groupStart;
                    lastMultiMaterial.inherited = false;
                }
                if (end && materials.length > 1) {
                    for (var mi = materials.length - 1; mi >= 0; mi--) {
                        var material = materials[mi];
                        if (material.groupCount <= 0) {
                            materials.splice(mi, 1);
                        }
                    }
                }
                if (end && materials.length == 0) {
                    materials.push({
                        name: "",
                        smooth: smooth
                    });
                }
                return lastMultiMaterial;
            }
        };
        startObject("", false);
    }

    function startObject(name:String, fromDeclaration:Bool) {
        var previousMaterial = (object != null ? object.currentMaterial() : null);
        if (object != null && Reflect.hasField(object, "_finalize")) {
            object._finalize(true);
        }
        object = {
            name: name,
            fromDeclaration: fromDeclaration,
            geometry: {
                vertices: [],
                normals: [],
                colors: [],
                uvs: [],
                hasUVIndices: false
            },
            materials: [],
            smooth: true,
            startMaterial: function(name:String, libraries:Array<String>) {
                var previous = _finalize(false);
                if (previous != null && (previous.inherited || previous.groupCount <= 0)) {
                    materials.splice(previous.index, 1);
                }
                var material = {
                    index: materials.length,
                    name: name,
                    mtllib: (libraries != null ? libraries[libraries.length - 1] : ""),
                    smooth: (previous != null ? previous.smooth : smooth),
                    groupStart: (previous != null ? previous.groupEnd : 0),
                    groupEnd: -1,
                    groupCount: -1,
                    inherited: false,
                    clone: function(index:Int) {
                        var cloned = {
                            index: (index != null ? index : index),
                            name: name,
                            mtllib: mtllib,
                            smooth: smooth,
                            groupStart: 0,
                            groupEnd: -1,
                            groupCount: -1,
                            inherited: false
                        };
                        cloned.clone = clone;
                        return cloned;
                    }
                };
                materials.push(material);
                return material;
            },
            currentMaterial: function() {
                if (materials.length > 0) {
                    return materials[materials.length - 1];
                } else {
                    return null;
                }
            },
            _finalize: function(end:Bool) {
                var lastMultiMaterial = currentMaterial();
                if (lastMultiMaterial != null && lastMultiMaterial.groupEnd == -1) {
                    lastMultiMaterial.groupEnd = geometry.vertices.length / 3;
                    lastMultiMaterial.groupCount = lastMultiMaterial.groupEnd - lastMultiMaterial.groupStart;
                    lastMultiMaterial.inherited = false;
                }
                if (end && materials.length > 1) {
                    for (var mi = materials.length - 1; mi >= 0; mi--) {
                        var material = materials[mi];
                        if (material.groupCount <= 0) {
                            materials.splice(mi, 1);
                        }
                    }
                }
                if (end && materials.length == 0) {
                    materials.push({
                        name: "",
                        smooth: smooth
                    });
                }
                return lastMultiMaterial;
            }
        };
        objects.push(object);
        if (previousMaterial != null && Reflect.hasField(previousMaterial, "clone")) {
            var declared = previousMaterial.clone(0);
            declared.inherited = true;
            object.materials.push(declared);
        }
    }

    function finalize() {
        if (object != null && Reflect.hasField(object, "_finalize")) {
            object._finalize(true);
        }
    }

    function parseVertexIndex(value:Int, len:Int) {
        var index = Std.parseInt(value);
        return (index >= 0 ? index - 1 : index + len / 3) * 3;
    }

    function parseNormalIndex(value:Int, len:Int) {
        var index = Std.parseInt(value);
        return (index >= 0 ? index - 1 : index + len / 3) * 3;
    }

    function parseUVIndex(value:Int, len:Int) {
        var index = Std.parseInt(value);
        return (index >= 0 ? index - 1 : index + len / 2) * 2;
    }

    function addVertex(a:Int, b:Int, c:Int) {
        var src = vertices;
        var dst = object.geometry.vertices;
        dst.push(src[a]);
        dst.push(src[a + 1]);
        dst.push(src[a + 2]);
        dst.push(src[b]);
        dst.push(src[b + 1]);
        dst.push(src[b + 2]);
        dst.push(src[c]);
        dst.push(src[c + 1]);
        dst.push(src[c + 2]);
    }

    function addVertexPoint(a:Int) {
        var src = vertices;
        var dst = object.geometry.vertices;
        dst.push(src[a]);
        dst.push(src[a + 1]);
        dst.push(src[a + 2]);
    }

    function addVertexLine(a:Int) {
        var src = vertices;
        var dst = object.geometry.vertices;
        dst.push(src[a]);
        dst.push(src[a + 1]);
        dst.push(src[a + 2]);
    }

    function addNormal(a:Int, b:Int, c:Int) {
        var src = normals;
        var dst = object.geometry.normals;
        dst.push(src[a]);
        dst.push(src[a + 1]);
        dst.push(src[a + 2]);
        dst.push(src[b]);
        dst.push(src[b + 1]);
        dst.push(src[b + 2]);
        dst.push(src[c]);
        dst.push(src[c + 1]);
        dst.push(src[c + 2]);
    }

    function addFaceNormal(a:Int, b:Int, c:Int) {
        var src = vertices;
        var dst = object.geometry.normals;
        var _vA = new Vector3();
        var _vB = new Vector3();
        var _vC = new Vector3();
        var _ab = new Vector3();
        var _cb = new Vector3();
        _vA.fromArray(src, a);
        _vB.fromArray(src, b);
        _vC.fromArray(src, c);
        _cb.subVectors(_vC, _vB);
        _ab.subVectors(_vA, _vB);
        _cb.cross(_ab);
        _cb.normalize();
        dst.push(_cb.x);
        dst.push(_cb.y);
        dst.push(_cb.z);
        dst.push(_cb.x);
        dst.push(_cb.y);
        dst.push(_cb.z);
    }

    function addColor(a:Int, b:Int, c:Int) {
        var src = colors;
        var dst = object.geometry.colors;
        if (src[a] != null) {
            dst.push(src[a]);
            dst.push(src[a + 1]);
            dst.push(src[a + 2]);
        }
        if (src[b] != null) {
            dst.push(src[b]);
            dst.push(src[b + 1]);
            dst.push(src[b + 2]);
        }
        if (src[c] != null) {
            dst.push(src[c]);
            dst.push(src[c + 1]);
            dst.push(src[c + 2]);
        }
    }

    function addUV(a:Int, b:Int, c:Int) {
        var src = uvs;
        var dst = object.geometry.uvs;
        dst.push(src[a]);
        dst.push(src[a + 1]);
        dst.push(src[b]);
        dst.push(src[b + 1]);
        dst.push(src[c]);
        dst.push(src[c + 1]);
    }

    function addDefaultUV() {
        var dst = object.geometry.uvs;
        dst.push(0);
        dst.push(0);
        dst.push(0);
        dst.push(0);
        dst.push(0);
        dst.push(0);
    }

    function addUVLine(a:Int) {
        var src = uvs;
        var dst = object.geometry.uvs;
        dst.push(src[a]);
        dst.push(src[a + 1]);
    }

    function addFace(a:Int, b:Int, c:Int, ua:Int, ub:Int, uc:Int, na:Int, nb:Int, nc:Int) {
        var vLen = vertices.length;
        var ia = parseVertexIndex(a, vLen);
        var ib = parseVertexIndex(b, vLen);
        var ic = parseVertexIndex(c, vLen);
        addVertex(ia, ib, ic);
        addColor(ia, ib, ic);
        var nLen = normals.length;
        if (na != null && na != "") {
            ia = parseNormalIndex(na, nLen);
            ib = parseNormalIndex(nb, nLen);
            ic = parseNormalIndex(nc, nLen);
            addNormal(ia, ib, ic);
        } else {
            addFaceNormal(ia, ib, ic);
        }
        var uvLen = uvs.length;
        if (ua != null && ua != "") {
            ia = parseUVIndex(ua, uvLen);
            ib = parseUVIndex(ub, uvLen);
            ic = parseUVIndex(uc, uvLen);
            addUV(ia, ib, ic);
            object.geometry.hasUVIndices = true;
        } else {
            addDefaultUV();
        }
    }

    function addPointGeometry(vertices:Array<Int>) {
        object.geometry.type = "Points";
        var vLen = vertices.length;
        for (var vi = 0; vi < vLen; vi++) {
            var index = parseVertexIndex(vertices[vi], vLen);
            addVertexPoint(index);
            addColor(index);
        }
    }

    function addLineGeometry(vertices:Array<Int>, uvs:Array<Int>) {
        object.geometry.type = "Line";
        var vLen = vertices.length;
        var uvLen = uvs.length;
        for (var vi = 0; vi < vLen; vi++) {
            addVertexLine(parseVertexIndex(vertices[vi], vLen));
        }
        for (var uvi = 0; uvi < uvLen; uvi++) {
            addUVLine(parseUVIndex(uvs[uvi], uvLen));
        }
    }
}

class OBJLoader extends Loader {
    var materials:Dynamic;

    function new(manager:Dynamic) {
        super(manager);
        materials = null;
    }

    function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        var scope = this;
        var loader = new FileLoader(manager);
        loader.path = path;
        loader.setRequestHeader(requestHeader);
        loader.setWithCredentials(withCredentials);
        loader.load(url, function(text:String) {
            try {
                onLoad(scope.parse(text));
            } catch (_g) {
                var e = haxe_Exception.caught(_g).unwrap();
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                manager.itemError(url);
            }
        }, onProgress, onError);
    }

    function setMaterials(materials:Dynamic) {
        this.materials = materials;
        return this;
    }

    function parse(text:String) {
        var state = new ParserState();
        if (text.indexOf("\r\n") != -1) {
            text = text.split("\r\n").join("\n");
        }
        if (text.indexOf("\\\n") != -1) {
            text = text.split("\\\n").join("");
        }
        var lines = text.split("\n");
        var result = [];
        var _g = 0;
        while (_g < lines.length) {
            var line = lines[_g];
            ++_g;
            if (line.length == 0) {
                continue;
            }
            var lineFirstChar = line.charAt(0);
            if (lineFirstChar == "#") {
                continue;
            }
            if (lineFirstChar == "v") {
                var data = line.split(_face_vertex_data_separator_pattern);
                switch (data[0]) {
                    case "v":
                        var v = Std.parseFloat(data[1]);
                        var v1 = Std.parseFloat(data[2]);
                        var v2 = Std.parseFloat(data[3]);
                        state.vertices.push(v);
                        state.vertices.push(v1);
                        state.vertices.push(v2);
                        if (data.length >= 7) {
                            var _color = new Color();
                            _color.setRGB(Std.parseFloat(data[4]), Std.parseFloat(data[5]), Std.parseFloat(data[6]));
                            _color.convertSRGBToLinear();
                            state.colors.push(_color.r);
                            state.colors.push(_color.g);
                            state.colors.push(_color.b);
                        } else {
                            state.colors.push(null);
                            state.colors.push(null);
                            state.colors.push(null);
                        }
                        break;
                    case "vn":
                        var vn = Std.parseFloat(data[1]);
                        var vn1 = Std.parseFloat(data[2]);
                        var vn2 = Std.parseFloat(data[3]);
                        state.normals.push(vn);
                        state.normals.push(vn1);
                        state.normals.push(vn2);
                        break;
                    case "vt":
                        var vt = Std.parseFloat(data[1]);
                        var vt1 = Std.parseFloat(data[2]);
                        state.uvs.push(vt);
                        state.uvs.push(vt1);
                        break;
                }
            } else if (lineFirstChar == "f") {
                var lineData = line.slice(1).trim();
                var vertexData = lineData.split(_face_vertex_data_separator_pattern);
                var faceVertices = [];
                var _g1 = 0;
                while (_g1 < vertexData.length) {
                    var vertex = vertexData[_g1];
                    ++_g1;
                    if (vertex.length > 0) {
                        var vertexParts = vertex.split("/");
                        faceVertices.push(vertexParts);
                    }
                }
                var v1 = faceVertices[0];
                var _g2 = 1;
                while (_
                var v2 = faceVertices[_g2];
                var v3 = faceVertices[_g2 + 1];
                ++_g2;
                state.addFace(v1[0], v2[0], v3[0], v1[1], v2[1], v3[1], v1[2], v2[2], v3[2]);
            } else if (lineFirstChar == "l") {
                var lineParts = line.substring(1).trim().split(" ");
                var lineVertices = [];
                var lineUVs = [];
                if (line.indexOf("/") == -1) {
                    lineVertices = lineParts;
                } else {
                    var _g3 = 0;
                    while (_g3 < lineParts.length) {
                        var parts = lineParts[_g3];
                        ++_g3;
                        if (parts.charAt(0) != "") {
                            lineVertices.push(parts.charAt(0));
                        }
                        if (parts.indexOf("/") != -1) {
                            lineUVs.push(parts.split("/")[1]);
                        }
                    }
                }
                state.addLineGeometry(lineVertices, lineUVs);
            } else if (lineFirstChar == "p") {
                var lineData = line.slice(1).trim();
                var pointData = lineData.split(" ");
                state.addPointGeometry(pointData);
            } else if (_object_pattern.match(line) != null) {
                var name = _object_pattern.matched(1).slice(1).trim();
                state.startObject(name);
            } else if (_material_use_pattern.match(line) != null) {
                state.object.startMaterial(line.substring(7).trim(), state.materialLibraries);
            } else if (_material_library_pattern.match(line) != null) {
                state.materialLibraries.push(line.substring(7).trim());
            } else if (_map_use_pattern.match(line) != null) {
                console.log("THREE.OBJLoader: Rendering identifier \"usemap\" not supported. Textures must be defined in MTL files.");
            } else if (lineFirstChar == "s") {
                var result1 = line.split(" ");
                if (result1.length > 1) {
                    var value = result1[1].trim().toLowerCase();
                    state.object.smooth = (value != "0" && value != "off");
                } else {
                    state.object.smooth = true;
                }
                var material = state.object.currentMaterial();
                if (material != null) {
                    material.smooth = state.object.smooth;
                }
            } else {
                if (line == "\0") {
                    continue;
                }
                console.log("THREE.OBJLoader: Unexpected line: " + line);
            }
        }
        state.finalize();
        var container = new Group();
        container.materialLibraries = state.materialLibraries.slice();
        var hasPrimitives = !((state.objects.length == 1 && state.objects[0].geometry.vertices.length == 0));
        if (hasPrimitives) {
            var _g4 = 0;
            while (_g4 < state.objects.length) {
                var object1 = state.objects[_g4];
                ++_g4;
                var geometry = object1.geometry;
                var materials1 = object1.materials;
                var isLine = (geometry.type == "Line");
                var isPoints = (geometry.type == "Points");
                var hasVertexColors = false;
                if (geometry.vertices.length == 0) {
                    continue;
                }
                var buffergeometry = new BufferGeometry();
                buffergeometry.setAttribute("position", new Float32BufferAttribute(geometry.vertices, 3));
                if (geometry.normals.length > 0) {
                    buffergeometry.setAttribute("normal", new Float32BufferAttribute(geometry.normals, 3));
                }
                if (geometry.colors.length > 0) {
                    hasVertexColors = true;
                    buffergeometry.setAttribute("color", new Float32BufferAttribute(geometry.colors, 3));
                }
                if (geometry.hasUVIndices) {
                    buffergeometry.setAttribute("uv", new Float32BufferAttribute(geometry.uvs, 2));
                }
                var createdMaterials = [];
                var _g5 = 0;
                while (_g5 < materials1.length) {
                    var sourceMaterial = materials1[_g5];
                    ++_g5;
                    var materialHash = sourceMaterial.name + "_" + sourceMaterial.smooth + "_" + hasVertexColors;
                    var material1 = state.materials.get(materialHash);
                    if (materials != null) {
                        material1 = materials.create(sourceMaterial.name);
                        if (isLine && (material1 == null || !Type.enumEq(Type.getClass(material1), LineBasicMaterial))) {
                            var materialLine = new LineBasicMaterial();
                            Material.copy(materialLine, material1);
                            materialLine.color.copy(material1.color);
                            material1 = materialLine;
                        } else if (isPoints && (material1 == null || !Type.enumEq(Type.getClass(material1), PointsMaterial))) {
                            var materialPoints = new PointsMaterial({ size : 10, sizeAttenuation : false });
                            Material.copy(materialPoints, material1);
                            materialPoints.color.copy(material1.color);
                            materialPoints.map = material1.map;
                            material1 = materialPoints;
                        }
                    }
                    if (material1 == null) {
                        if (isLine) {
                            material1 = new LineBasicMaterial();
                        } else if (isPoints) {
                            material1 = new PointsMaterial({ size : 1, sizeAttenuation : false });
                        } else {
                            material1 = new MeshPhongMaterial();
                        }
                        material1.name = sourceMaterial.name;
                        material1.flatShading = sourceMaterial.smooth ? false : true;
                        material1.vertexColors = hasVertexColors;
                        state.materials.set(materialHash, material1);
                    }
                    createdMaterials.push(material1);
                }
                if (createdMaterials.length > 1) {
                    var _g6 = 0;
                    while (_g6 < materials1.length) {
                        var sourceMaterial1 = materials1[_g6];
                        ++_g6;
                        buffergeometry.addGroup(sourceMaterial1.groupStart, sourceMaterial1.groupCount, _g6);
                    }
                    if (isLine) {
                        var mesh = new LineSegments(buffergeometry, createdMaterials);
                    } else if (isPoints) {
                        var mesh = new Points(buffergeometry, createdMaterials);
                    } else {
                        var mesh = new Mesh(buffergeometry, createdMaterials);
                    }
                } else {
                    if (isLine) {
                        var mesh = new LineSegments(buffergeometry, createdMaterials[0]);
                    } else if (isPoints) {
                        var mesh = new Points(buffergeometry, createdMaterials[0]);
                    } else {
                        var mesh = new Mesh(buffergeometry, createdMaterials[0]);
                    }
                }
                mesh.name = object1.name;
                container.add(mesh);
            }
        } else {
            if (state.vertices.length > 0) {
                var material = new PointsMaterial({ size : 1, sizeAttenuation : false });
                var buffergeometry = new BufferGeometry();
                buffergeometry.setAttribute("position", new Float32BufferAttribute(state.vertices, 3));
                if (state.colors.length > 0 && state.colors[0] != null) {
                    buffergeometry.setAttribute("color", new Float32BufferAttribute(state.colors, 3));
                    material.vertexColors = true;
                }
                var points = new Points(buffergeometry, material);
                container.add(points);
            }
        }
        return container;
    }
}