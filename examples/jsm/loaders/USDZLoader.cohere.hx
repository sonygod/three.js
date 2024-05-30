import haxe.zip.Reader;
import js.html.DataView;
import js.html.Blob;
import js.html.URL;
import js.html.Uint8Array;
import js.html.ArrayBuffer;

class USDAParser {
    public function parse(text:String):Dynamic {
        var data:Dynamic = {};
        var lines = text.split('\n');
        var string:String = null;
        var target = data;
        var stack:Array<Dynamic> = [data];

        for (line in lines) {
            if (line.indexOf('=') != -1) {
                var assignment = line.split('=');
                var lhs = assignment[0].trim();
                var rhs = assignment[1].trim();

                if (rhs.endsWith('{')) {
                    var group = {};
                    stack.push(group);
                    target[lhs] = group;
                    target = group;
                } else {
                    target[lhs] = rhs;
                }
            } else if (line.endsWith('{')) {
                var group = target[string] || {};
                stack.push(group);
                target[string] = group;
                target = group;
            } else if (line.endsWith('}')) {
                stack.pop();
                if (stack.length == 0) continue;
                target = stack[stack.length - 1];
            } else if (line.endsWith('(')) {
                var meta = {};
                stack.push(meta);
                string = line.split('(')[0].trim() || string;
                target[string] = meta;
                target = meta;
            } else if (line.endsWith(')')) {
                stack.pop();
                target = stack[stack.length - 1];
            } else {
                string = line.trim();
            }
        }

        return data;
    }
}

class USDZLoader {
    public function new(manager:Dynamic) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic -> Void, onProgress:Dynamic -> Void, onError:Dynamic -> Void):Void {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.path = scope.path;
        loader.responseType = 'arraybuffer';
        loader.requestHeader = scope.requestHeader;
        loader.withCredentials = scope.withCredentials;
        loader.load(url, function(text) {
            try {
                onLoad(scope.parse(text));
            } catch (e) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace.error(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(buffer:ArrayBuffer):Dynamic {
        var parser = new USDAParser();
        function parseAssets(zip:Dynamic):Dynamic {
            var data:Dynamic = {};
            var loader = new FileLoader();
            loader.responseType = 'arraybuffer';

            for (filename in zip) {
                if (filename.endsWith('png')) {
                    var blob = new Blob([zip[filename]], {type: {type: 'image/png'}});
                    data[filename] = URL.createObjectURL(blob);
                }

                if (filename.endsWith('usd') || filename.endsWith('usda')) {
                    if (isCrateFile(zip[filename])) {
                        trace.warn('THREE.USDZLoader: Crate files (.usdc or binary .usd) are not supported.');
                        continue;
                    }

                    var text = fflate.strFromU8(zip[filename]);
                    data[filename] = parser.parse(text);
                }
            }

            return data;
        }

        function isCrateFile(buffer:ArrayBuffer):Bool {
            var fileHeader = new DataView(buffer, 0, 7);
            var crateHeader = new Uint8Array([0x50, 0x58, 0x52, 0x2D, 0x55, 0x53, 0x44, 0x43]);

            for (i in 0...7) {
                if (fileHeader.getUint8(i) != crateHeader[i]) {
                    return false;
                }
            }

            return true;
        }

        function findUSD(zip:Dynamic):Dynamic {
            if (zip.length < 1) return null;

            var firstFileName = Object.keys(zip)[0];
            var isCrate = false;

            if (firstFileName.endsWith('usda')) {
                return zip[firstFileName];
            }

            if (firstFileName.endsWith('usdc')) {
                isCrate = true;
            } else if (firstFileName.endsWith('usd')) {
                if (!isCrateFile(zip[firstFileName])) {
                    return zip[firstFileName];
                } else {
                    isCrate = true;
                }
            }

            if (isCrate) {
                trace.warn('THREE.USDZLoader: Crate files (.usdc or binary .usd) are not supported.');
            }

            return null;
        }

        var zip = fflate.unzipSync(new Uint8Array(buffer));
        var assets = parseAssets(zip);
        var file = findUSD(zip);

        if (file == null) {
            trace.warn('THREE.USDZLoader: No usda file found.');
            return new Group();
        }

        function findMeshGeometry(data:Dynamic):Dynamic {
            if (data == null) return null;

            if ('prepend references' in data) {
                var reference = data['prepend references'];
                var parts = reference.split('@');
                var path = parts[1].replace(/^.\//, '');
                var id = parts[2].replace(/^<\//, '').replace(/>$/, '');

                return findGeometry(assets[path], id);
            }

            return findGeometry(data);
        }

        function findGeometry(data:Dynamic, id:String = null):Dynamic {
            if (data == null) return null;

            if (id != null) {
                var def = 'def Mesh "' + id + '"';

                if (def in data) {
                    return data[def];
                }
            }

            for (name in data) {
                var object = data[name];

                if (name.startsWith('def Mesh')) {
                    if ('point3f[] points' in data) {
                        object['point3f[] points'] = data['point3f[] points'];
                    }

                    if ('texCoord2f[] primvars:st' in data) {
                        object['texCoord2f[] primvars:st'] = data['texCoord2f[] primvars:st'];
                    }

                    if ('int[] primvars:st:indices' in data) {
                        object['int[] primvars:st:indices'] = data['int[] primvars:st:indices'];
                    }

                    return object;
                }

                if (Std.is(object, Dynamic)) {
                    var geometry = findGeometry(object);

                    if (geometry != null) return geometry;
                }
            }

            return null;
        }

        function buildGeometry(data:Dynamic):BufferGeometry {
            if (data == null) return null;

            var geometry = new BufferGeometry();

            if ('int[] faceVertexIndices' in data) {
                var indices = JSON.parse(data['int[] faceVertexIndices']);
                geometry.setIndex(indices);
            }

            if ('point3f[] points' in data) {
                var positions = JSON.parse(data['point3f[] points'].replace(/[()]*/g, ''));
                var attribute = new BufferAttribute(new Float32Array(positions), 3);
                geometry.setAttribute('position', attribute);
            }

            if ('normal3f[] normals' in data) {
                var normals = JSON.parse(data['normal3f[] normals'].replace(/[()]*/g, ''));
                var attribute = new BufferAttribute(new Float32Array(normals), 3);
                geometry.setAttribute('normal', attribute);
            } else {
                geometry.computeVertexNormals();
            }

            if ('float2[] primvars:st' in data) {
                data['texCoord2f[] primvars:st'] = data['float2[] primvars:st'];
            }

            if ('texCoord2f[] primvars:st' in data) {
                var uvs = JSON.parse(data['texCoord2f[] primvars:st'].replace(/[()]*/g, ''));
                var attribute = new BufferAttribute(new Float32Array(uvs), 2);

                if ('int[] primvars:st:indices' in data) {
                    geometry = geometry.toNonIndexed();
                    var indices = JSON.parse(data['int[] primvars:st:indices']);
                    geometry.setAttribute('uv', toFlatBufferAttribute(attribute, indices));
                } else {
                    geometry.setAttribute('uv', attribute);
                }
            }

            return geometry;
        }

        function toFlatBufferAttribute(attribute:BufferAttribute, indices:Array<Int>):BufferAttribute {
            var array = attribute.array;
            var itemSize = attribute.itemSize;
            var array2 = new Array<Float>(indices.length * itemSize);

            var index = 0;
            var index2 = 0;

            for (i in 0...indices.length) {
                index = indices[i] * itemSize;

                for (j in 0...itemSize) {
                    array2[index2++] = array[index++];
                }
            }

            return new BufferAttribute(array2, itemSize);
        }

        function findMeshMaterial(data:Dynamic):Dynamic {
            if (data == null) return null;

            if ('rel material:binding' in data) {
                var reference = data['rel material:binding'];
                var id = reference.replace(/^<\//, '').replace(/>$/, '');
                var parts = id.split('/');

                return findMaterial(root, ' "' + parts[1] + '"');
            }

            return findMaterial(data);
        }

        function findMaterial(data:Dynamic, id:String = ''):Dynamic {
            for (name in data) {
                var object = data[name];

                if (name.startsWith('def Material' + id)) {
                    return object;
                }

                if (Std.is(object, Dynamic)) {
                    var material = findMaterial(object, id);

                    if (material != null) return material;
                }
            }

            return null;
        }

        function setTextureParams(map:Texture, data_value:Dynamic):Void {
            if ('float inputs:rotation' in data_value) {
                map.rotation = Std.parseFloat(data_value['float inputs:rotation']);
            }

            if ('float2 inputs:scale' in data_value) {
                map.repeat = new Vector2().fromArray(JSON.parse('[' + data_value['float2 inputs:scale'].replace(/[()]*/g, '') + ']'));
            }

            if ('float2 inputs:translation' in data_value) {
                map.offset = new Vector2().fromArray(JSON.parse('[' + data_value['float2 inputs:translation'].replace(/[()]*/g, '') + ']'));
            }
        }

        function buildMaterial(data:Dynamic):MeshPhysicalMaterial {
            var material = new MeshPhysicalMaterial();

            if (data != null) {
                if ('def Shader "PreviewSurface"' in data) {
                    var surface = data['def Shader "PreviewSurface"'];

                    if ('color3f inputs:diffuseColor.connect' in surface) {
                        var path = surface['color3f inputs:diffuseColor.connect'];
                        var sampler = findTexture(root, /(\w+)\.output/.exec(path)[1]);

                        material.map = buildTexture(sampler);
                        material.map.colorSpace = SRGBColorSpace;

                        if ('def Shader "Transform2d_diffuse"' in data) {
                            setTextureParams(material.map, data['def Shader "Transform2d_diffuse"']);
                        }
                    } else if ('color3f inputs:diffuseColor' in surface) {
                        var color = surface['color3f inputs:diffuseColor'].replace(/[()]*/g, '');
                        material.color.fromArray(JSON.parse('[' + color + ']'));
                    }

                    if ('color3f inputs:emissiveColor.connect' in surface) {
                        var path = surface['color3f inputs:emissiveColor.connect'];
                        var sampler = findTexture(root, /(\w+)\.output/.exec(path)[1]);

                        material.emissiveMap = buildTexture(sampler);
                        material.emissiveMap.colorSpace = SRGBColorSpace;
                        material.emissive.set(0xffffff);

                        if ('def Shader "Transform2d_emissive"' in data) {
                            setTextureParams(material.emissiveMap, data['def Shader "Transform2d_emissive"']);
                        }
                    } else if ('color3f inputs:emissiveColor' in surface) {
                        var color = surface['color3f inputs:emissiveColor'].replace(/[()]*/g, '');
                        material.emissive.fromArray(JSON.parse('[' + color + ']'));
                    }

                    if ('normal3f inputs:normal.connect' in surface) {
                        var path = surface['normal3f inputs:normal.connect'];
                        var sampler = findTexture(root, /(\w+)\.output/.exec(path)[1]);

                        material.normalMap = buildTexture(sampler);
                        material.normalMap.colorSpace = NoColorSpace;

                        if ('def Shader "Transform2d_normal"' in data) {
                            setTextureParams(material.normalMap, data['def Shader "Transform2d_normal"']);
                        }
                    }

                    if ('float inputs:roughness.connect' in surface) {
                        var path = surface['float inputs:roughness.connect'];
                        var sampler = findTexture(root, /(\w+)\.output/.exec(path)[1]);

                        material.roughness = 1.0;
                        material.roughnessMap = buildTexture(sampler);
                        material.roughnessMap.colorSpace = NoColorSpace;

                        if ('def Shader "Transform2d_roughness"' in data) {
                            setTextureParams(material.roughnessMap, data['def Shader "Transform2d_roughness"']);
                        }
                    } else if ('float inputs:roughness' in surface) {
                        material.roughness = Std.parseFloat(surface['float inputs:roughness']);
                    }

                    if ('float inputs:metallic.connect' in surface) {
                        var path = surface['float inputs:metallic.connect'];
                        var sampler = findTexture(root, /(\w+)\.output/.exec(path)[1]);

                        material.metalness = 1.0;
                        material.metalnessMap = buildTexture(sampler);
                        material.metalnessMap.colorSpace = NoColorSpace;

                        if ('def Shader "Transform2d_metallic"' in data) {
                            setTextureParams(material.metalnessMap, data['def Shader "Transform2d_metallic"']);
                        }
                    } else if ('float inputs:metallic' in surface) {
                        material.metalness = Std.parseFloat(surface['float inputs:metallic']);
                    }

                    if ('float inputs:clearcoat.connect' in surface) {
                        var path = surface['float inputs:clearcoat.connect'];
                        var sampler = findTexture(root, /(\w+)\.output/.exec(path)[1]);

                        material.clearcoat = 1.0;
                        material.clearcoatMap = buildTexture(sampler);
                        material.clearcoatMap.colorSpace = NoColorSpace;

                        if ('def Shader "Transform2d_clearcoat"' in data) {
                            setTextureParams(material.clearcoatMap, data['def Shader "Transform2d_clearcoat"']);
                        }
                    } else if ('float inputs:clearcoat' in surface) {
                        material.clearcoat = Std.parseFloat(surface['float inputs:clearcoat']);
                    }

                    if ('float inputs:clearcoatRoughness.connect' in surface) {
                        var path = surface['float inputs:clearcoatRoughness.connect'];
                        var sampler = findTexture(root, /(\w+)\.output/.exec(path)[1]);

                        material.clearcoatRoughness = 1.0;
                        material.clearcoatRoughnessMap = buildTexture(sampler);
                        material.clearcoatRoughnessMap.colorSpace = NoColorSpace;

                        if ('def Shader "Transform2d_clearcoatRoughness"' in data) {
                            setTextureParams(material.clearcoatRoughnessMap, data['def Shader "Transform2d_clearcoatRoughness"']);
                        }
                    } else if ('float inputs:clearcoatRoughness' in surface) {
                        material.clearcoatRoughness = Std.parseFloat(surface['float inputs:clearcoatRoughness']);
                    }

                    if ('float inputs:ior' in surface) {
                        material.ior = Std.parseFloat(surface['float inputs:ior']);
                    }

                    if ('float inputs:occlusion.connect' in surface) {
                        var path = surface['float inputs:occlusion.connect'];
                        var sampler = findTexture(root, /(\w+)\.output/.exec(path)[1]);

                        material.aoMap = buildTexture(sampler);
                        material.aoMap.colorSpace = NoColorSpace;

                        if ('def Shader "Transform2d_occlusion"' in data) {
                            setTextureParams(material.aoMap, data['def Shader "Transform2d_occlusion"']);
                        }
                    }
                }

                if ('def Shader "diffuseColor_texture"' in data) {
                    var sampler = data['def Shader "diffuseColor_texture"'];

                    material.map = buildTexture(sampler);
                    material.map.colorSpace = SRGBColorSpace;
                }

                if ('def Shader "normal_texture"' in data) {
                    var sampler = data['def Shader "normal_texture"'];

                    material.normalMap = buildTexture(sampler);
                    material.normalMap.colorSpace = NoColorSpace;
                }
                }
            }

            return material;
        }

        function findTexture(data:Dynamic, id:String):Dynamic {
            for (name in data) {
                var object = data[name];

                if (name.startsWith('def Shader "' + id + '"')) {
                    return object;
                }

                if (Std.is(object, Dynamic)) {
                    var texture = findTexture(object, id);

                    if (texture != null) return texture;
                }
            }

            return null;
        }

        function buildTexture(data:Dynamic):Texture {
            if ('asset inputs:file' in data) {
                var path = data['asset inputs:file'].replace(/@*/, '');

                var loader = new TextureLoader();
                var texture = loader.load(assets[path]);

                var map = {
                    '"clamp"': ClampToEdgeWrapping,
                    '"mirror"': MirroredRepeatWrapping,
                    '"repeat"': RepeatWrapping
                };

                if ('token inputs:wrapS' in data) {
                    texture.wrapS = map[data['token inputs:wrapS']];
                }

                if ('token inputs:wrapT' in data) {
                    texture.wrapT = map[data['token inputs:wrapT']];
                }

                return texture;
            }

            return null;
        }

        function buildObject(data:Dynamic):Object3D {
            var geometry = buildGeometry(findMeshGeometry(data));
            var material = buildMaterial(findMeshMaterial(data));

            var mesh = geometry != null ? new Mesh(geometry, material) : new Object3D();

            if ('matrix4d xformOp:transform' in data) {
                var array = JSON.parse('[' + data['matrix4d xformOp:transform'].replace(/[()]*/g, '') + ']');

                mesh.matrix.fromArray(array);
                mesh.matrix.decompose(mesh.position, mesh.quaternion, mesh.scale);
            }

            return mesh;
        }

        function buildHierarchy(data:Dynamic, group:Group):Void {
            for (name in data) {
                if (name.startsWith('def Scope')) {
                    buildHierarchy(data[name], group);
                } else if (name.startsWith('def Xform')) {
                    var mesh = buildObject(data[name]);

                    if (/def Xform "(\w+)/.match(name) != null) {
                        mesh.name = /def Xform "(\w+)/.match(name)[1];
                    }

                    group.add(mesh);

                    buildHierarchy(data[name], mesh);
                }
            }
        }

        var root = parser.parse(text);
        var group = new Group();

        buildHierarchy(root, group);

        return group;
    }
}

class Group {
    public var name:String;
    public function new() { }
    public function add(mesh:Object3D):Void { }
}

class Mesh {
    public function new(geometry:BufferGeometry, material:MeshPhysicalMaterial) { }
}

class BufferGeometry {
    public function setIndex(indices:Array<Int>):Void { }
    public function setAttribute(name:String, attribute:BufferAttribute):Void { }
    public function toNonIndexed():BufferGeometry { }
    public function computeVertexNormals():Void { }
}

class BufferAttribute {
    public var array:Array<Float>;
    public var itemSize:Int;
    public function new(array:Array<Float>, itemSize:Int) { }
}

class Vector2 {
    public function fromArray(array:Array<Float>):Void { }
}

class MeshPhysicalMaterial {
    public var map:Texture;
    public var color:Array<Float>;
    public var emissive:Array<Float>;
    public var normalMap:Texture;
    public var roughness:Float;
    public var roughnessMap:Texture;
    public var metalness:Float;
    public var metalnessMap:Texture;
    public var clearcoat:Float;
    public var clearcoatMap:Texture;
    public var clearcoatRoughness:Float;
    public var clearcoatRoughnessMap:Texture;
    public var ior:Float;
    public var aoMap:Texture;
    public function new() { }
}

class Texture {
    public var wrapS:Int;
    public var wrapT:Int;
    public function load(url:String):Void { }
}

class TextureLoader { }

class FileLoader {
    public var path:String;
    public var responseType:String;
    public var requestHeader:Dynamic;
    public var withCredentials:Bool;
    public function load(url:String, onLoad:Dynamic -> Void, onProgress:Dynamic -> Void, onError:Dynamic -> Void):Void { }
}

class Loader {
    public var manager:Dynamic;
    public var path:String;
    public var requestHeader:Dynamic;
    public var withCredentials:Bool;
    public function new(manager:Dynamic) { }
}

class NoColorSpace { }

class SRGBColorSpace { }

class ClampToEdgeWrapping { }

class MirroredRepeatWrapping { }

class RepeatWrapping { }

class Object3D {
    public var position:Dynamic;
    public var quaternion:Dynamic;
    public var scale:Dynamic;
    public var matrix:Dynamic;
    public function new() { }
}

class Uint8Array { }

class URL { }

class Blob { }

class DataView { }

class Reader { }

class fflate {
    public static function unzipSync(data:Uint8Array):Dynamic { }
    public static function strFromU8(data:Dynamic):String { }
}