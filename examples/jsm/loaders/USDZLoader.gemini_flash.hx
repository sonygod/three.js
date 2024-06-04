import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.core.ClampToEdgeWrapping;
import three.loaders.FileLoader;
import three.core.Group;
import three.core.NoColorSpace;
import three.loaders.Loader;
import three.objects.Mesh;
import three.materials.MeshPhysicalMaterial;
import three.core.MirroredRepeatWrapping;
import three.core.RepeatWrapping;
import three.core.SRGBColorSpace;
import three.loaders.TextureLoader;
import three.core.Object3D;
import three.math.Vector2;
import fflate.FFlate;

class USDAParser {
  public function parse(text:String):Dynamic {
    var data = {};
    var lines = text.split("\n");
    var string:String = null;
    var target = data;
    var stack = [data];

    for (line in lines) {
      if (line.indexOf("=") != -1) {
        var assignment = line.split("=");
        var lhs = assignment[0].trim();
        var rhs = assignment[1].trim();

        if (rhs.endsWith("{")) {
          var group = {};
          stack.push(group);

          target[lhs] = group;
          target = group;
        } else {
          target[lhs] = rhs;
        }
      } else if (line.endsWith("{")) {
        var group = target[string] || {};
        stack.push(group);

        target[string] = group;
        target = group;
      } else if (line.endsWith("}")) {
        stack.pop();

        if (stack.length == 0) continue;
        target = stack[stack.length - 1];
      } else if (line.endsWith("(")) {
        var meta = {};
        stack.push(meta);

        string = line.split("(")[0].trim() || string;
        target[string] = meta;
        target = meta;
      } else if (line.endsWith(")")) {
        stack.pop();
        target = stack[stack.length - 1];
      } else {
        string = line.trim();
      }
    }

    return data;
  }
}

class USDZLoader extends Loader {
  public function new(manager:Loader) {
    super(manager);
  }

  public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
    var scope = this;
    var loader = new FileLoader(scope.manager);
    loader.setPath(scope.path);
    loader.setResponseType("arraybuffer");
    loader.setRequestHeader(scope.requestHeader);
    loader.setWithCredentials(scope.withCredentials);
    loader.load(url, function(text:haxe.io.Bytes) {
      try {
        onLoad(scope.parse(text));
      } catch(e:Dynamic) {
        if (onError != null) {
          onError(e);
        } else {
          console.error(e);
        }

        scope.manager.itemError(url);
      }
    }, onProgress, onError);
  }

  public function parse(buffer:haxe.io.Bytes):Object3D {
    var parser = new USDAParser();

    function parseAssets(zip:Dynamic):Dynamic {
      var data = {};
      var loader = new FileLoader();
      loader.setResponseType("arraybuffer");

      for (filename in zip) {
        if (filename.endsWith("png")) {
          var blob = new haxe.io.Bytes(zip[filename]);
          data[filename] = URL.createObjectURL(blob);
        }

        if (filename.endsWith("usd") || filename.endsWith("usda")) {
          if (isCrateFile(zip[filename])) {
            console.warn("THREE.USDZLoader: Crate files (.usdc or binary .usd) are not supported.");
            continue;
          }

          var text = FFlate.strFromU8(zip[filename]);
          data[filename] = parser.parse(text);
        }
      }

      return data;
    }

    function isCrateFile(buffer:haxe.io.Bytes):Bool {
      // Check if this a crate file. First 7 bytes of a crate file are "PXR-USDC".
      var fileHeader = buffer.sub(0, 7);
      var crateHeader = new haxe.io.Bytes([0x50, 0x58, 0x52, 0x2D, 0x55, 0x53, 0x44, 0x43]);

      // If this is not a crate file, we assume it is a plain USDA file.
      return fileHeader.every(function(value, index) {
        return value == crateHeader.get(index);
      });
    }

    function findUSD(zip:Dynamic):haxe.io.Bytes {
      if (zip.length < 1) return null;

      var firstFileName = Reflect.field(zip, 0);
      var isCrate = false;

      // As per the USD specification, the first entry in the zip archive is used as the main file ("UsdStage").
      // ASCII files can end in either .usda or .usd.
      // See https://openusd.org/release/spec_usdz.html#layout
      if (firstFileName.endsWith("usda")) return zip[firstFileName];

      if (firstFileName.endsWith("usdc")) {
        isCrate = true;
      } else if (firstFileName.endsWith("usd")) {
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

      return null;
    }

    var zip = FFlate.unzipSync(new haxe.io.Bytes(buffer));
    var assets = parseAssets(zip);
    var file = findUSD(zip);

    if (file == null) {
      console.warn("THREE.USDZLoader: No usda file found.");
      return new Group();
    }

    // Parse file
    var text = FFlate.strFromU8(file);
    var root = parser.parse(text);

    // Build scene
    function findMeshGeometry(data:Dynamic):Dynamic {
      if (data == null) return null;

      if ("prepend references" in data) {
        var reference = data["prepend references"];
        var parts = reference.split("@");
        var path = parts[1].replace(/^.\//, "");
        var id = parts[2].replace(/^<\//, "").replace(/>$/, "");

        return findGeometry(assets[path], id);
      }

      return findGeometry(data);
    }

    function findGeometry(data:Dynamic, id:String):Dynamic {
      if (data == null) return null;

      if (id != null) {
        var def = "def Mesh \"" + id + "\"";

        if (def in data) {
          return data[def];
        }
      }

      for (name in data) {
        var object = data[name];

        if (name.startsWith("def Mesh")) {
          // Move points to Mesh

          if ("point3f[] points" in data) {
            object["point3f[] points"] = data["point3f[] points"];
          }

          // Move st to Mesh

          if ("texCoord2f[] primvars:st" in data) {
            object["texCoord2f[] primvars:st"] = data["texCoord2f[] primvars:st"];
          }

          // Move st indices to Mesh

          if ("int[] primvars:st:indices" in data) {
            object["int[] primvars:st:indices"] = data["int[] primvars:st:indices"];
          }

          return object;
        }

        if (Reflect.isObject(object)) {
          var geometry = findGeometry(object);

          if (geometry != null) return geometry;
        }
      }
    }

    function buildGeometry(data:Dynamic):BufferGeometry {
      if (data == null) return null;

      var geometry = new BufferGeometry();

      if ("int[] faceVertexIndices" in data) {
        var indices = Std.parseInt(data["int[] faceVertexIndices"]);
        geometry.setIndex(indices);
      }

      if ("point3f[] points" in data) {
        var positions = Std.parseInt(data["point3f[] points"].replace(/[()]*/g, ""));
        var attribute = new BufferAttribute(new Float32Array(positions), 3);
        geometry.setAttribute("position", attribute);
      }

      if ("normal3f[] normals" in data) {
        var normals = Std.parseInt(data["normal3f[] normals"].replace(/[()]*/g, ""));
        var attribute = new BufferAttribute(new Float32Array(normals), 3);
        geometry.setAttribute("normal", attribute);
      } else {
        geometry.computeVertexNormals();
      }

      if ("float2[] primvars:st" in data) {
        data["texCoord2f[] primvars:st"] = data["float2[] primvars:st"];
      }

      if ("texCoord2f[] primvars:st" in data) {
        var uvs = Std.parseInt(data["texCoord2f[] primvars:st"].replace(/[()]*/g, ""));
        var attribute = new BufferAttribute(new Float32Array(uvs), 2);

        if ("int[] primvars:st:indices" in data) {
          geometry = geometry.toNonIndexed();
          var indices = Std.parseInt(data["int[] primvars:st:indices"]);
          geometry.setAttribute("uv", toFlatBufferAttribute(attribute, indices));
        } else {
          geometry.setAttribute("uv", attribute);
        }
      }

      return geometry;
    }

    function toFlatBufferAttribute(attribute:BufferAttribute, indices:Array<Int>):BufferAttribute {
      var array = attribute.array;
      var itemSize = attribute.itemSize;

      var array2 = new array.constructor(indices.length * itemSize);
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

      if ("rel material:binding" in data) {
        var reference = data["rel material:binding"];
        var id = reference.replace(/^<\//, "").replace(/>$/, "");
        var parts = id.split("/");

        return findMaterial(root, " \"" + parts[1] + "\"");
      }

      return findMaterial(data);
    }

    function findMaterial(data:Dynamic, id:String = ""):Dynamic {
      for (name in data) {
        var object = data[name];

        if (name.startsWith("def Material" + id)) {
          return object;
        }

        if (Reflect.isObject(object)) {
          var material = findMaterial(object, id);

          if (material != null) return material;
        }
      }
    }

    function setTextureParams(map:Dynamic, data_value:Dynamic):Void {
      // rotation, scale and translation

      if ("float inputs:rotation" in data_value) {
        map.rotation = Std.parseFloat(data_value["float inputs:rotation"]);
      }

      if ("float2 inputs:scale" in data_value) {
        map.repeat = new Vector2().fromArray(Std.parseInt("[${data_value["float2 inputs:scale"].replace(/[()]*/g, "")}]"));
      }

      if ("float2 inputs:translation" in data_value) {
        map.offset = new Vector2().fromArray(Std.parseInt("[${data_value["float2 inputs:translation"].replace(/[()]*/g, "")}]"));
      }
    }

    function buildMaterial(data:Dynamic):MeshPhysicalMaterial {
      var material = new MeshPhysicalMaterial();

      if (data != null) {
        if ("def Shader \"PreviewSurface\"" in data) {
          var surface = data["def Shader \"PreviewSurface\""];

          if ("color3f inputs:diffuseColor.connect" in surface) {
            var path = surface["color3f inputs:diffuseColor.connect"];
            var sampler = findTexture(root, RegExp.exec(path, /(\w+).output/).get(1));

            material.map = buildTexture(sampler);
            material.map.colorSpace = SRGBColorSpace;

            if ("def Shader \"Transform2d_diffuse\"" in data) {
              setTextureParams(material.map, data["def Shader \"Transform2d_diffuse\""]);
            }
          } else if ("color3f inputs:diffuseColor" in surface) {
            var color = surface["color3f inputs:diffuseColor"].replace(/[()]*/g, "");
            material.color.fromArray(Std.parseInt("[${color}]"));
          }

          if ("color3f inputs:emissiveColor.connect" in surface) {
            var path = surface["color3f inputs:emissiveColor.connect"];
            var sampler = findTexture(root, RegExp.exec(path, /(\w+).output/).get(1));

            material.emissiveMap = buildTexture(sampler);
            material.emissiveMap.colorSpace = SRGBColorSpace;
            material.emissive.set(0xffffff);

            if ("def Shader \"Transform2d_emissive\"" in data) {
              setTextureParams(material.emissiveMap, data["def Shader \"Transform2d_emissive\""]);
            }
          } else if ("color3f inputs:emissiveColor" in surface) {
            var color = surface["color3f inputs:emissiveColor"].replace(/[()]*/g, "");
            material.emissive.fromArray(Std.parseInt("[${color}]"));
          }

          if ("normal3f inputs:normal.connect" in surface) {
            var path = surface["normal3f inputs:normal.connect"];
            var sampler = findTexture(root, RegExp.exec(path, /(\w+).output/).get(1));

            material.normalMap = buildTexture(sampler);
            material.normalMap.colorSpace = NoColorSpace;

            if ("def Shader \"Transform2d_normal\"" in data) {
              setTextureParams(material.normalMap, data["def Shader \"Transform2d_normal\""]);
            }
          }

          if ("float inputs:roughness.connect" in surface) {
            var path = surface["float inputs:roughness.connect"];
            var sampler = findTexture(root, RegExp.exec(path, /(\w+).output/).get(1));

            material.roughness = 1.0;
            material.roughnessMap = buildTexture(sampler);
            material.roughnessMap.colorSpace = NoColorSpace;

            if ("def Shader \"Transform2d_roughness\"" in data) {
              setTextureParams(material.roughnessMap, data["def Shader \"Transform2d_roughness\""]);
            }
          } else if ("float inputs:roughness" in surface) {
            material.roughness = Std.parseFloat(surface["float inputs:roughness"]);
          }

          if ("float inputs:metallic.connect" in surface) {
            var path = surface["float inputs:metallic.connect"];
            var sampler = findTexture(root, RegExp.exec(path, /(\w+).output/).get(1));

            material.metalness = 1.0;
            material.metalnessMap = buildTexture(sampler);
            material.metalnessMap.colorSpace = NoColorSpace;

            if ("def Shader \"Transform2d_metallic\"" in data) {
              setTextureParams(material.metalnessMap, data["def Shader \"Transform2d_metallic\""]);
            }
          } else if ("float inputs:metallic" in surface) {
            material.metalness = Std.parseFloat(surface["float inputs:metallic"]);
          }

          if ("float inputs:clearcoat.connect" in surface) {
            var path = surface["float inputs:clearcoat.connect"];
            var sampler = findTexture(root, RegExp.exec(path, /(\w+).output/).get(1));

            material.clearcoat = 1.0;
            material.clearcoatMap = buildTexture(sampler);
            material.clearcoatMap.colorSpace = NoColorSpace;

            if ("def Shader \"Transform2d_clearcoat\"" in data) {
              setTextureParams(material.clearcoatMap, data["def Shader \"Transform2d_clearcoat\""]);
            }
          } else if ("float inputs:clearcoat" in surface) {
            material.clearcoat = Std.parseFloat(surface["float inputs:clearcoat"]);
          }

          if ("float inputs:clearcoatRoughness.connect" in surface) {
            var path = surface["float inputs:clearcoatRoughness.connect"];
            var sampler = findTexture(root, RegExp.exec(path, /(\w+).output/).get(1));

            material.clearcoatRoughness = 1.0;
            material.clearcoatRoughnessMap = buildTexture(sampler);
            material.clearcoatRoughnessMap.colorSpace = NoColorSpace;

            if ("def Shader \"Transform2d_clearcoatRoughness\"" in data) {
              setTextureParams(material.clearcoatRoughnessMap, data["def Shader \"Transform2d_clearcoatRoughness\""]);
            }
          } else if ("float inputs:clearcoatRoughness" in surface) {
            material.clearcoatRoughness = Std.parseFloat(surface["float inputs:clearcoatRoughness"]);
          }

          if ("float inputs:ior" in surface) {
            material.ior = Std.parseFloat(surface["float inputs:ior"]);
          }

          if ("float inputs:occlusion.connect" in surface) {
            var path = surface["float inputs:occlusion.connect"];
            var sampler = findTexture(root, RegExp.exec(path, /(\w+).output/).get(1));

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

    function findTexture(data:Dynamic, id:String):Dynamic {
      for (name in data) {
        var object = data[name];

        if (name.startsWith("def Shader \"" + id + "\"")) {
          return object;
        }

        if (Reflect.isObject(object)) {
          var texture = findTexture(object, id);

          if (texture != null) return texture;
        }
      }
    }

    function buildTexture(data:Dynamic):Dynamic {
      if ("asset inputs:file" in data) {
        var path = data["asset inputs:file"].replace(/@*/g, "");

        var loader = new TextureLoader();

        var texture = loader.load(assets[path]);

        var map = {
          "\"clamp\"": ClampToEdgeWrapping,
          "\"mirror\"": MirroredRepeatWrapping,
          "\"repeat\"": RepeatWrapping
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

    function buildObject(data:Dynamic):Object3D {
      var geometry = buildGeometry(findMeshGeometry(data));
      var material = buildMaterial(findMeshMaterial(data));

      var mesh = geometry != null ? new Mesh(geometry, material) : new Object3D();

      if ("matrix4d xformOp:transform" in data) {
        var array = Std.parseInt("[${data["matrix4d xformOp:transform"].replace(/[()]*/g, "")}]");
        mesh.matrix.fromArray(array);
        mesh.matrix.decompose(mesh.position, mesh.quaternion, mesh.scale);
      }

      return mesh;
    }

    function buildHierarchy(data:Dynamic, group:Group):Void {
      for (name in data) {
        if (name.startsWith("def Scope")) {
          buildHierarchy(data[name], group);
        } else if (name.startsWith("def Xform")) {
          var mesh = buildObject(data[name]);

          if (RegExp.match(name, /def Xform "(\w+)"/).get(1) != null) {
            mesh.name = RegExp.exec(name, /def Xform "(\w+)"/).get(1);
          }

          group.add(mesh);
          buildHierarchy(data[name], mesh);
        }
      }
    }

    var group = new Group();
    buildHierarchy(root, group);
    return group;
  }
}

class USDZLoader {
  public static function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
    new USDZLoader().load(url, onLoad, onProgress, onError);
  }
}