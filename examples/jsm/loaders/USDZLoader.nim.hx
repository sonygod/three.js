import three.js.examples.jsm.loaders.USDZLoader;
import three.js.examples.jsm.loaders.USDAParser;
import three.js.examples.jsm.loaders.FileLoader;
import three.js.examples.jsm.loaders.TextureLoader;
import three.js.examples.jsm.loaders.Loader;
import three.js.examples.jsm.loaders.BufferGeometry;
import three.js.examples.jsm.loaders.BufferAttribute;
import three.js.examples.jsm.loaders.ClampToEdgeWrapping;
import three.js.examples.jsm.loaders.NoColorSpace;
import three.js.examples.jsm.loaders.SRGBColorSpace;
import three.js.examples.jsm.loaders.MirroredRepeatWrapping;
import three.js.examples.jsm.loaders.RepeatWrapping;
import three.js.examples.jsm.loaders.Mesh;
import three.js.examples.jsm.loaders.MeshPhysicalMaterial;
import three.js.examples.jsm.loaders.Object3D;
import three.js.examples.jsm.loaders.Vector2;

class Main {
    static function main() {
        var loader = new USDZLoader();
        loader.load("path/to/file.usdz", function(object) {
            // Do something with the loaded object
        });
    }
}

class USDZLoader extends Loader {
    public function new(manager) {
        super(manager);
    }

    public function load(url, onLoad, onProgress, onError) {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setResponseType("arraybuffer");
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(text) {
            try {
                onLoad(scope.parse(text));
            } catch (e) {
                if (onError) {
                    onError(e);
                } else {
                    console.error(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(buffer) {
        var parser = new USDAParser();
        var zip = fflate.unzipSync(new Uint8Array(buffer));
        var assets = parseAssets(zip);
        var file = findUSD(zip);
        if (file === undefined) {
            console.warn("THREE.USDZLoader: No usda file found.");
            return new Group();
        }
        var text = fflate.strFromU8(file);
        var root = parser.parse(text);
        var group = new Group();
        buildHierarchy(root, group);
        return group;
    }

    private function parseAssets(zip) {
        var data = {};
        var loader = new FileLoader();
        loader.setResponseType("arraybuffer");
        for (filename in zip) {
            if (filename.endsWith(".png")) {
                var blob = new Blob([zip[filename]], {type: {type: "image/png"}});
                data[filename] = URL.createObjectURL(blob);
            }
            if (filename.endsWith(".usd") || filename.endsWith(".usda")) {
                if (isCrateFile(zip[filename])) {
                    console.warn("THREE.USDZLoader: Crate files (.usdc or binary .usd) are not supported.");
                    continue;
                }
                var text = fflate.strFromU8(zip[filename]);
                data[filename] = parser.parse(text);
            }
        }
        return data;
    }

    private function isCrateFile(buffer) {
        // Check if this a crate file. First 7 bytes of a crate file are "PXR-USDC".
        var fileHeader = buffer.slice(0, 7);
        var crateHeader = new Uint8Array([0x50, 0x58, 0x52, 0x2D, 0x55, 0x53, 0x44, 0x43]);
        // If this is not a crate file, we assume it is a plain USDA file.
        return fileHeader.every(function(value, index) return value === crateHeader[index]);
    }

    private function findUSD(zip) {
        if (zip.length < 1) return undefined;
        var firstFileName = Object.keys(zip)[0];
        var isCrate = false;
        // As per the USD specification, the first entry in the zip archive is used as the main file ("UsdStage").
        // ASCII files can end in either .usda or .usd.
        // See https://openusd.org/release/spec_usdz.html#layout
        if (firstFileName.endsWith(".usda")) return zip[firstFileName];
        if (firstFileName.endsWith(".usdc")) {
            isCrate = true;
        } else if (firstFileName.endsWith(".usd")) {
            // If this is not a crate file, we assume it is a plain USDA file.
            if (!isCrateFile(zip[firstFileName])) {
                return zip[firstFileName];
            } else {
                isCrate = true;
            }
        }
        if (isCrate) {
            console.warn("THREE.USDZLoader: Crate files (.usdc or binary .usd) are not supported.");
        }
        return undefined;
    }

    private function buildHierarchy(data, group) {
        for (name in data) {
            if (name.startsWith("def Scope")) {
                buildHierarchy(data[name], group);
            } else if (name.startsWith("def Xform")) {
                var mesh = buildObject(data[name]);
                if (/def Xform "(\w+)"/.test(name)) {
                    mesh.name = /def Xform "(\w+)"/.exec(name)[1];
                }
                group.add(mesh);
                buildHierarchy(data[name], mesh);
            }
        }
    }

    private function buildObject(data) {
        var geometry = buildGeometry(findMeshGeometry(data));
        var material = buildMaterial(findMeshMaterial(data));
        var mesh = geometry ? new Mesh(geometry, material) : new Object3D();
        if ("matrix4d xformOp:transform" in data) {
            var array = JSON.parse("[" + data["matrix4d xformOp:transform"].replace(/[()]*/g, "") + "]");
            mesh.matrix.fromArray(array);
            mesh.matrix.decompose(mesh.position, mesh.quaternion, mesh.scale);
        }
        return mesh;
    }

    private function buildMaterial(data) {
        var material = new MeshPhysicalMaterial();
        if (data !== undefined) {
            if ("def Shader \"PreviewSurface\"" in data) {
                var surface = data["def Shader \"PreviewSurface\""];
                if ("color3f inputs:diffuseColor.connect" in surface) {
                    var path = surface["color3f inputs:diffuseColor.connect"];
                    var sampler = findTexture(root, /(\w+).output/.exec(path)[1]);
                    material.map = buildTexture(sampler);
                    material.map.colorSpace = SRGBColorSpace;
                    if ("def Shader \"Transform2d_diffuse\"" in data) {
                        setTextureParams(material.map, data["def Shader \"Transform2d_diffuse\""]);
                    }
                } else if ("color3f inputs:diffuseColor" in surface) {
                    var color = surface["color3f inputs:diffuseColor"].replace(/[()]*/g, "");
                    material.color.fromArray(JSON.parse("[" + color + "]"));
                }
                if ("color3f inputs:emissiveColor.connect" in surface) {
                    var path = surface["color3f inputs:emissiveColor.connect"];
                    var sampler = findTexture(root, /(\w+).output/.exec(path)[1]);
                    material.emissiveMap = buildTexture(sampler);
                    material.emissiveMap.colorSpace = SRGBColorSpace;
                    material.emissive.set(0xffffff);
                    if ("def Shader \"Transform2d_emissive\"" in data) {
                        setTextureParams(material.emissiveMap, data["def Shader \"Transform2d_emissive\""]);
                    }
                } else if ("color3f inputs:emissiveColor" in surface) {
                    var color = surface["color3f inputs:emissiveColor"].replace(/[()]*/g, "");
                    material.emissive.fromArray(JSON.parse("[" + color + "]"));
                }
                if ("normal3f inputs:normal.connect" in surface) {
                    var path = surface["normal3f inputs:normal.connect"];
                    var sampler = findTexture(root, /(\w+).output/.exec(path)[1]);
                    material.normalMap = buildTexture(sampler);
                    material.normalMap.colorSpace = NoColorSpace;
                    if ("def Shader \"Transform2d_normal\"" in data) {
                        setTextureParams(material.normalMap, data["def Shader \"Transform2d_normal\""]);
                    }
                }
                if ("float inputs:roughness.connect" in surface) {
                    var path = surface["float inputs:roughness.connect"];
                    var sampler = findTexture(root, /(\w+).output/.exec(path)[1]);
                    material.roughness = 1.0;
                    material.roughnessMap = buildTexture(sampler);
                    material.roughnessMap.colorSpace = NoColorSpace;
                    if ("def Shader \"Transform2d_roughness\"" in data) {
                        setTextureParams(material.roughnessMap, data["def Shader \"Transform2d_roughness\""]);
                    }
                } else if ("float inputs:roughness" in surface) {
                    material.roughness = parseFloat(surface["float inputs:roughness"]);
                }
                if ("float inputs:metallic.connect" in surface) {
                    var path = surface["float inputs:metallic.connect"];
                    var sampler = findTexture(root, /(\w+).output/.exec(path)[1]);
                    material.metalness = 1.0;
                    material.metalnessMap = buildTexture(sampler);
                    material.metalnessMap.colorSpace = NoColorSpace;
                    if ("def Shader \"Transform2d_metallic\"" in data) {
                        setTextureParams(material.metalnessMap, data["def Shader \"Transform2d_metallic\""]);
                    }
                } else if ("float inputs:metallic" in surface) {
                    material.metalness = parseFloat(surface["float inputs:metallic"]);
                }
                if ("float inputs:clearcoat.connect" in surface) {
                    var path = surface["float inputs:clearcoat.connect"];
                    var sampler = findTexture(root, /(\w+).output/.exec(path)[1]);
                    material.clearcoat = 1.0;
                    material.clearcoatMap = buildTexture(sampler);
                    material.clearcoatMap.colorSpace = NoColorSpace;
                    if ("def Shader \"Transform2d_clearcoat\"" in data) {
                        setTextureParams(material.clearcoatMap, data["def Shader \"Transform2d_clearcoat\""]);
                    }
                } else if ("float inputs:clearcoat" in surface) {
                    material.clearcoat = parseFloat(surface["float inputs:clearcoat"]);
                }
                if ("float inputs:clearcoatRoughness.connect" in surface) {
                    var path = surface["float inputs:clearcoatRoughness.connect"];
                    var sampler = findTexture(root, /(\w+).output/.exec(path)[1]);
                    material.clearcoatRoughness = 1.0;
                    material.clearcoatRoughnessMap = buildTexture(sampler);
                    material.clearcoatRoughnessMap.colorSpace = NoColorSpace;
                    if ("def Shader \"Transform2d_clearcoatRoughness\"" in data) {
                        setTextureParams(material.clearcoatRoughnessMap, data["def Shader \"Transform2d_clearcoatRoughness\""]);
                    }
                } else if ("float inputs:clearcoatRoughness" in surface) {
                    material.clearcoatRoughness = parseFloat(surface["float inputs:clearcoatRoughness"]);
                }
                if ("float inputs:ior" in surface) {
                    material.ior = parseFloat(surface["float inputs:ior"]);
                }
                if ("float inputs:occlusion.connect" in surface) {
                    var path = surface["float inputs:occlusion.connect"];
                    var sampler = findTexture(root, /(\w+).output/.exec(path)[1]);
                    material.aoMap = buildTexture(sampler);
                    material.aoMap.colorSpace = NoColorSpace;
                    if ("def Shader \"Transform2d_occlusion\"" in data) {
                        setTextureParams(material.aoMap, data["def Shader \"Transform2d_occlusion\""]);
                    }
                }
            }
            if ("def Shader \"diffuseColor_texture\"" in data) {
                var sampler = data["def Shader \"diffuseColor_texture\""];
                material.map = buildTexture(sampler);
                material.map.colorSpace = SRGBColorSpace;
            }
            if ("def Shader \"normal_texture\"" in data) {
                var sampler = data["def Shader \"normal_texture\""];
                material.normalMap = buildTexture(sampler);
                material.normalMap.colorSpace = NoColorSpace;
            }
        }
        return material;
    }

    private function findTexture(data, id) {
        for (name in data) {
            if (name.startsWith(`def Shader "${id}"`)) {
                return data[name];
            }
            if (typeof data[name] === "object") {
                var texture = findTexture(data[name], id);
                if (texture) return texture;
            }
        }
    }

    private function buildTexture(data) {
        if ("asset inputs:file" in data) {
            var path = data["asset inputs:file"].replace(/@*/g, "");
            var loader = new TextureLoader();
            var texture = loader.load(assets[path]);
            var map = {
                "\"clamp\"" : ClampToEdgeWrapping,
                "\"mirror\"" : MirroredRepeatWrapping,
                "\"repeat\"" : RepeatWrapping
            };
            if ("token inputs:wrapS" in data) {
                texture.wrapS = map[data["token inputs:wrapS"]];
            }
            if ("token inputs:wrapT" in data) {
                texture.wrapT = map[data["token inputs:wrapT"]];
            }
            return texture;
        }
        return null;
    }

    private function setTextureParams(map, data_value) {
        // rotation, scale and translation
        if ("float inputs:rotation" in data_value) {
            map.rotation = parseFloat(data_value["float inputs:rotation"]);
        }
        if ("float2 inputs:scale" in data_value) {
            map.repeat = new Vector2().fromArray(JSON.parse("[" + data_value["float2 inputs:scale"].replace(/[()]*/g, "") + "]"));
        }
        if ("float2 inputs:translation" in data_value) {
            map.offset = new Vector2().fromArray(JSON.parse("[" + data_value["float2 inputs:translation"].replace(/[()]*/g, "") + "]"));
        }
    }

    private function findMeshMaterial(data) {
        if (!data) return undefined;
        if ("rel material:binding" in data) {
            var reference = data["rel material:binding"];
            var id = reference.replace(/^<\//, "").replace(/>$/, "");
            var parts = id.split("/");
            return findMaterial(root, ` "${parts[1]}"`);
        }
        return findMaterial(data);
    }

    private function findMaterial(data, id = "") {
        for (name in data) {
            if (name.startsWith(`def Material${id}`)) {
                return data[name];
            }
            if (typeof data[name] === "object") {
                var material = findMaterial(data[name], id);
                if (material) return material;
            }
        }
    }

    private function findMeshGeometry(data) {
        if (!data) return undefined;
        if ("prepend references" in data) {
            var reference = data["prepend references"];
            var parts = reference.split("@");
            var path = parts[1].replace(/^.\//, "");
            var id = parts[2].replace(/^<\//, "").replace(/>$/, "");
            return findGeometry(assets[path], id);
        }
        return findGeometry(data);
    }

    private function findGeometry(data, id) {
        if (!data) return undefined;
        if (id !== undefined) {
            var def = `def Mesh "${id}"`;
            if (def in data) {
                return data[def];
            }
        }
        for (name in data) {
            if (name.startsWith("def Mesh")) {
                // Move points to Mesh
                if ("point3f[] points" in data) {
                    data[name]["point3f[] points"] = data["point3f[] points"];
                }
                // Move st to Mesh
                if ("texCoord2f[] primvars:st" in data) {
                    data[name]["texCoord2f[] primvars:st"] = data["texCoord2f[] primvars:st"];
                }
                // Move st indices to Mesh
                if ("int[] primvars:st:indices" in data) {
                    data[name]["int[] primvars:st:indices"] = data["int[] primvars:st:indices"];
                }
                return data[name];
            }
            if (typeof data[name] === "object") {
                var geometry = findGeometry(data[name]);
                if (geometry) return geometry;
            }
        }
    }

    private function buildGeometry(data) {
        if (!data) return undefined;
        var geometry = new BufferGeometry();
        if ("int[] faceVertexIndices" in data) {
            var indices = JSON.parse(data["int[] faceVertexIndices"]);
            geometry.setIndex(indices);
        }
        if ("point3f[] points" in data) {
            var positions = JSON.parse(data["point3f[] points"].replace(/[()]*/g, ""));
            var attribute = new BufferAttribute(new Float32Array(positions), 3);
            geometry.setAttribute("position", attribute);
        }
        if ("normal3f[] normals" in data) {
            var normals = JSON.parse(data["normal3f[] normals"].replace(/[()]*/g, ""));
            var attribute = new BufferAttribute(new Float32Array(normals), 3);
            geometry.setAttribute("normal", attribute);
        } else {
            geometry.computeVertexNormals();
        }
        if ("float2[] primvars:st" in data) {
            data["texCoord2f[] primvars:st"] = data["float2[] primvars:st"];
        }
        if ("texCoord2f[] primvars:st" in data) {
            var uvs = JSON.parse(data["texCoord2f[] primvars:st"].replace(/[()]*/g, ""));
            var attribute = new BufferAttribute(new Float32Array(uvs), 2);
            if ("int[] primvars:st:indices" in data) {
                geometry = geometry.toNonIndexed();
                var indices = JSON.parse(data["int[] primvars:st:indices"]);
                geometry.setAttribute("uv", toFlatBufferAttribute(attribute, indices));
            } else {
                geometry.setAttribute("uv", attribute);
            }
        }
        return geometry;
    }

    private function toFlatBufferAttribute(attribute, indices) {
        var array = attribute.array;
        var itemSize = attribute.itemSize;
        var array2 = new array.constructor(indices.length * itemSize);
        var index = 0, index2 = 0;
        for (var i = 0, l = indices.length; i < l; i++) {
            index = indices[i] * itemSize;
            for (var j = 0; j < itemSize; j++) {
                array2[index2++] = array[index++];
            }
        }
        return new BufferAttribute(array2, itemSize);
    }
}