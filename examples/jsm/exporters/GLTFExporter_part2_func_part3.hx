package three.js.examples.jsm.exporters;

import haxe.Json;
import three/jsm/exporters/GLTFExporter;

class GLTFExporter_part2_func_part3 {
  public function processMaterial(material:Dynamic):Void {
    var cache:Dynamic = this.cache;
    var json:Dynamic = this.json;

    if (cache.materials.exists(material)) return cache.materials.get(material);

    if (material.isShaderMaterial) {
      console.warn('GLTFExporter: THREE.ShaderMaterial not supported.');
      return null;
    }

    if (json.materials == null) json.materials = [];

    var materialDef:Dynamic = { pbrMetallicRoughness: {} };

    if (!(material.isMeshStandardMaterial || material.isMeshBasicMaterial)) {
      console.warn('GLTFExporter: Use MeshStandardMaterial or MeshBasicMaterial for best results.');
    }

    // pbrMetallicRoughness.baseColorFactor
    var color:Array<Float> = material.color.toArray().concat([material.opacity]);

    if (!equalArray(color, [1, 1, 1, 1])) {
      materialDef.pbrMetallicRoughness.baseColorFactor = color;
    }

    if (material.isMeshStandardMaterial) {
      materialDef.pbrMetallicRoughness.metallicFactor = material.metalness;
      materialDef.pbrMetallicRoughness.roughnessFactor = material.roughness;
    } else {
      materialDef.pbrMetallicRoughness.metallicFactor = 0.5;
      materialDef.pbrMetallicRoughness.roughnessFactor = 0.5;
    }

    // pbrMetallicRoughness.metallicRoughnessTexture
    if (material.metalnessMap || material.roughnessMap) {
      var metalRoughTexture:Dynamic = this.buildMetalRoughTexture(material.metalnessMap, material.roughnessMap);

      var metalRoughMapDef:Dynamic = {
        index: this.processTexture(metalRoughTexture),
        channel: metalRoughTexture.channel
      };
      this.applyTextureTransform(metalRoughMapDef, metalRoughTexture);
      materialDef.pbrMetallicRoughness.metallicRoughnessTexture = metalRoughMapDef;
    }

    // pbrMetallicRoughness.baseColorTexture
    if (material.map) {
      var baseColorMapDef:Dynamic = {
        index: this.processTexture(material.map),
        texCoord: material.map.channel
      };
      this.applyTextureTransform(baseColorMapDef, material.map);
      materialDef.pbrMetallicRoughness.baseColorTexture = baseColorMapDef;
    }

    if (material.emissive) {
      var emissive:Dynamic = material.emissive;
      var maxEmissiveComponent:Float = Math.max(emissive.r, emissive.g, emissive.b);

      if (maxEmissiveComponent > 0) {
        materialDef.emissiveFactor = material.emissive.toArray();
      }

      // emissiveTexture
      if (material.emissiveMap) {
        var emissiveMapDef:Dynamic = {
          index: this.processTexture(material.emissiveMap),
          texCoord: material.emissiveMap.channel
        };
        this.applyTextureTransform(emissiveMapDef, material.emissiveMap);
        materialDef.emissiveTexture = emissiveMapDef;
      }
    }

    // normalTexture
    if (material.normalMap) {
      var normalMapDef:Dynamic = {
        index: this.processTexture(material.normalMap),
        texCoord: material.normalMap.channel
      };

      if (material.normalScale && material.normalScale.x != 1) {
        normalMapDef.scale = material.normalScale.x;
      }

      this.applyTextureTransform(normalMapDef, material.normalMap);
      materialDef.normalTexture = normalMapDef;
    }

    // occlusionTexture
    if (material.aoMap) {
      var occlusionMapDef:Dynamic = {
        index: this.processTexture(material.aoMap),
        texCoord: material.aoMap.channel
      };

      if (material.aoMapIntensity != 1.0) {
        occlusionMapDef.strength = material.aoMapIntensity;
      }

      this.applyTextureTransform(occlusionMapDef, material.aoMap);
      materialDef.occlusionTexture = occlusionMapDef;
    }

    // alphaMode
    if (material.transparent) {
      materialDef.alphaMode = 'BLEND';
    } else {
      if (material.alphaTest > 0.0) {
        materialDef.alphaMode = 'MASK';
        materialDef.alphaCutoff = material.alphaTest;
      }
    }

    // doubleSided
    if (material.side == DoubleSide) materialDef.doubleSided = true;
    if (material.name != '') materialDef.name = material.name;

    this.serializeUserData(material, materialDef);

    this._invokeAll(function(ext:Dynamic) {
      ext.writeMaterial && ext.writeMaterial(material, materialDef);
    });

    var index:Int = json.materials.push(materialDef) - 1;
    cache.materials.set(material, index);
    return index;
  }

  public function processMesh(mesh:Dynamic):Void {
    var cache:Dynamic = this.cache;
    var json:Dynamic = this.json;

    var meshCacheKeyParts:Array<String> = [mesh.geometry.uuid];

    if (Std.isOfType(mesh.material, Array)) {
      for (i in 0...mesh.material.length) {
        meshCacheKeyParts.push(mesh.material[i].uuid);
      }
    } else {
      meshCacheKeyParts.push(mesh.material.uuid);
    }

    var meshCacheKey:String = meshCacheKeyParts.join(':');

    if (cache.meshes.exists(meshCacheKey)) return cache.meshes.get(meshCacheKey);

    var geometry:Dynamic = mesh.geometry;

    var mode:Int;

    if (mesh.isLineSegments) {
      mode = WEBGL_CONSTANTS.LINES;
    } else if (mesh.isLineLoop) {
      mode = WEBGL_CONSTANTS.LINE_LOOP;
    } else if (mesh.isLine) {
      mode = WEBGL_CONSTANTS.LINE_STRIP;
    } else if (mesh.isPoints) {
      mode = WEBGL_CONSTANTS.POINTS;
    } else {
      mode = mesh.material.wireframe ? WEBGL_CONSTANTS.LINES : WEBGL_CONSTANTS.TRIANGLES;
    }

    var meshDef:Dynamic = {};
    var attributes:Dynamic = {};
    var primitives:Array<Dynamic> = [];
    var targets:Array<Dynamic> = [];

    var nameConversion:Dynamic = {
      uv: 'TEXCOORD_0',
      uv1: 'TEXCOORD_1',
      uv2: 'TEXCOORD_2',
      uv3: 'TEXCOORD_3',
      color: 'COLOR_0',
      skinWeight: 'WEIGHTS_0',
      skinIndex: 'JOINTS_0'
    };

    var originalNormal:Dynamic = geometry.getAttribute('normal');

    if (originalNormal != null && !isNormalizedNormalAttribute(originalNormal)) {
      console.warn('THREE.GLTFExporter: Creating normalized normal attribute from the non-normalized one.');
      geometry.setAttribute('normal', createNormalizedNormalAttribute(originalNormal));
    }

    // @QUESTION Detect if .vertexColors = true?
    // For every attribute create an accessor
    var modifiedAttribute:Dynamic = null;

    for (attributeName in geometry.attributes) {
      // Ignore morph target attributes, which are exported later.
      if (attributeName.slice(0, 5) == 'morph') continue;

      var attribute:Dynamic = geometry.attributes[attributeName];
      attributeName = nameConversion[attributeName] || attributeName.toUpperCase();

      // Prefix all geometry attributes except the ones specifically
      // listed in the spec; non-spec attributes are considered custom.
      var validVertexAttributes:EReg = ~/^(POSITION|NORMAL|TANGENT|TEXCOORD_\d+|COLOR_\d+|JOINTS_\d+|WEIGHTS_\d+)$/;
      if (!validVertexAttributes.match(attributeName)) attributeName = '_' + attributeName;

      if (cache.attributes.exists(getUID(attribute))) {
        attributes[attributeName] = cache.attributes.get(getUID(attribute));
        continue;
      }

      modifiedAttribute = null;
      var array:Array<Dynamic> = attribute.array;

      if (attributeName == 'JOINTS_0' && !(array instanceof Uint16Array) && !(array instanceof Uint8Array)) {
        console.warn('GLTFExporter: Attribute "skinIndex" converted to type UNSIGNED_SHORT.');
        modifiedAttribute = new BufferAttribute(new Uint16Array(array), attribute.itemSize, attribute.normalized);
      }

      var accessor:Dynamic = processAccessor(modifiedAttribute || attribute, geometry);

      if (accessor != null) {
        if (!attributeName.startsWith('_')) {
          detectMeshQuantization(attributeName, attribute);
        }

        attributes[attributeName] = accessor;
        cache.attributes.set(getUID(attribute), accessor);
      }
    }

    if (originalNormal != null) geometry.setAttribute('normal', originalNormal);

    // Skip if no exportable attributes found
    if (Lambda.count(attributes) == 0) return null;

    // Morph targets
    if (mesh.morphTargetInfluences != null && mesh.morphTargetInfluences.length > 0) {
      var weights:Array<Float> = [];
      var targetNames:Array<String> = [];
      var reverseDictionary:Dynamic = {};

      if (mesh.morphTargetDictionary != null) {
        for (key in mesh.morphTargetDictionary) {
          reverseDictionary[mesh.morphTargetDictionary[key]] = key;
        }
      }

      for (i in 0...mesh.morphTargetInfluences.length) {
        var target:Dynamic = {};
        var warned:Bool = false;

        for (attributeName in geometry.morphAttributes) {
          // glTF 2.0 morph supports only POSITION/NORMAL/TANGENT.
          // Three.js doesn't support TANGENT yet.

          if (attributeName != 'position' && attributeName != 'normal') {
            if (!warned) {
              console.warn('GLTFExporter: Only POSITION and NORMAL morph are supported.');
              warned = true;
            }

            continue;
          }

          var attribute:Dynamic = geometry.morphAttributes[attributeName][i];
          var gltfAttributeName:String = attributeName.toUpperCase();

          // Three.js morph attribute has absolute values while the one of glTF has relative values.
          // glTF 2.0 Specification:
          // https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#morph-targets

          var baseAttribute:Dynamic = geometry.attributes[attributeName];

          if (cache.attributes.exists(getUID(attribute, true))) {
            target[gltfAttributeName] = cache.attributes.get(getUID(attribute, true));
            continue;
          }

          // Clones attribute not to override
          var relativeAttribute:Dynamic = attribute.clone();

          if (!geometry.morphTargetsRelative) {
            for (j in 0...attribute.count) {
              for (a in 0...attribute.itemSize) {
                if (a == 0) relativeAttribute.setX(j, attribute.getX(j) - baseAttribute.getX(j));
                if (a == 1) relativeAttribute.setY(j, attribute.getY(j) - baseAttribute.getY(j));
                if (a == 2) relativeAttribute.setZ(j, attribute.getZ(j) - baseAttribute.getZ(j));
                if (a == 3) relativeAttribute.setW(j, attribute.getW(j) - baseAttribute.getW(j));
              }
            }
          }

          target[gltfAttributeName] = processAccessor(relativeAttribute, geometry);
          cache.attributes.set(getUID(baseAttribute, true), target[gltfAttributeName]);
        }

        targets.push(target);

        weights.push(mesh.morphTargetInfluences[i]);

        if (mesh.morphTargetDictionary != null) targetNames.push(reverseDictionary[i]);
      }

      meshDef.weights = weights;

      if (targetNames.length > 0) {
        meshDef.extras = {};
        meshDef.extras.targetNames = targetNames;
      }
    }

    const isMultiMaterial:Bool = Std.isOfType(mesh.material, Array);

    if (isMultiMaterial && geometry.groups.length == 0) return null;

    var didForceIndices:Bool = false;

    if (isMultiMaterial && geometry.index == null) {
      var indices:Array<Int> = [];

      for (i in 0...geometry.attributes.position.count) {
        indices[i] = i;
      }

      geometry.setIndex(indices);

      didForceIndices = true;
    }

    var materials:Array<Dynamic> = isMultiMaterial ? mesh.material : [mesh.material];
    var groups:Array<Dynamic> = isMultiMaterial ? geometry.groups : [{ materialIndex: 0, start: undefined, count: undefined }];

    for (i in 0...groups.length) {
      var primitive:Dynamic = {
        mode: mode,
        attributes: attributes
      };

      serializeUserData(geometry, primitive);

      if (targets.length > 0) primitive.targets = targets;

      if (geometry.index != null) {
        var cacheKey:String = getUID(geometry.index);

        if (groups[i].start != undefined || groups[i].count != undefined) {
          cacheKey += ':' + groups[i].start + ':' + groups[i].count;
        }

        if (cache.attributes.exists(cacheKey)) {
          primitive.indices = cache.attributes.get(cacheKey);
        } else {
          primitive.indices = processAccessor(geometry.index, geometry, groups[i].start, groups[i].count);
          cache.attributes.set(cacheKey, primitive.indices);
        }

        if (primitive.indices == null) delete primitive.indices;
      }

      var material:Dynamic = processMaterial(materials[groups[i].materialIndex]);

      if (material != null) primitive.material = material;

      primitives.push(primitive);
    }

    if (didForceIndices) {
      geometry.setIndex(null);
    }

    meshDef.primitives = primitives;

    if (!json.meshes) json.meshes = [];

    this._invokeAll(function(ext:Dynamic) {
      ext.writeMesh && ext.writeMesh(mesh, meshDef);
    });

    var index:Int = json.meshes.push(meshDef) - 1;
    cache.meshes.set(meshCacheKey, index);
    return index;
  }
}