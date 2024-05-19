Here is the Haxe code equivalent to the provided JavaScript code:
```
package three.js.examples.jsm.loaders;

import js.Promise;
import js.html.ArrayBuffer;
import js.html.ImageBitmap;
import js.html.Texture;
import js.html.Material;
import js.html.Mesh;
import js.html.Geometry;
import js.html.BufferAttribute;
import js.html.InterleavedBuffer;
import js.html.InterleavedBufferAttribute;
import three.js.loaders.GLTFLoader;

class GLTFLoader {
  public function loadAccessor(accessorIndex: Int): Promise<BufferAttribute> {
    var parser: GLTFLoader = this;
    var json: Dynamic = this.json;
    var accessorDef: Dynamic = json.accessors[accessorIndex];

    if (accessorDef.bufferView == null && accessorDef.sparse == null) {
      var itemSize: Int = WEBGL_TYPE_SIZES[accessorDef.type];
      var TypedArray: Dynamic = WEBGL_COMPONENT_TYPES[accessorDef.componentType];
      var normalized: Bool = accessorDef.normalized == true;

      var array: Array<Float> = new TypedArray(accessorDef.count * itemSize);
      return Promise.resolve(new BufferAttribute(array, itemSize, normalized));
    }

    var pendingBufferViews: Array<Promise<Dynamic>> = [];

    if (accessorDef.bufferView != null) {
      pendingBufferViews.push(this.getDependency('bufferView', accessorDef.bufferView));
    } else {
      pendingBufferViews.push(Promise.resolve(null));
    }

    if (accessorDef.sparse != null) {
      pendingBufferViews.push(this.getDependency('bufferView', accessorDef.sparse.indices.bufferView));
      pendingBufferViews.push(this.getDependency('bufferView', accessorDef.sparse.values.bufferView));
    }

    return Promise.all(pendingBufferViews).then(function(bufferViews: Array<Dynamic>) {
      var bufferView: Dynamic = bufferViews[0];

      var itemSize: Int = WEBGL_TYPE_SIZES[accessorDef.type];
      var TypedArray: Dynamic = WEBGL_COMPONENT_TYPES[accessorDef.componentType];

      var elementBytes: Int = TypedArray.BYTES_PER_ELEMENT;
      var itemBytes: Int = elementBytes * itemSize;
      var byteOffset: Int = accessorDef.byteOffset || 0;
      var byteStride: Int = accessorDef.bufferView != null ? json.bufferViews[accessorDef.bufferView].byteStride : undefined;
      var normalized: Bool = accessorDef.normalized == true;
      var array: Array<Float>;
      var bufferAttribute: BufferAttribute;

      if (byteStride != null && byteStride != itemBytes) {
        var ibSlice: Int = Math.floor(byteOffset / byteStride);
        var ibCacheKey: String = 'InterleavedBuffer:' + accessorDef.bufferView + ':' + accessorDef.componentType + ':' + ibSlice + ':' + accessorDef.count;
        var ib: InterleavedBuffer = parser.cache.get(ibCacheKey);

        if (ib == null) {
          array = new TypedArray(bufferView, ibSlice * byteStride, accessorDef.count * byteStride / elementBytes);

          ib = new InterleavedBuffer(array, byteStride / elementBytes);

          parser.cache.add(ibCacheKey, ib);
        }

        bufferAttribute = new InterleavedBufferAttribute(ib, itemSize, (byteOffset % byteStride) / elementBytes, normalized);
      } else {
        if (bufferView == null) {
          array = new TypedArray(accessorDef.count * itemSize);
        } else {
          array = new TypedArray(bufferView, byteOffset, accessorDef.count * itemSize);
        }

        bufferAttribute = new BufferAttribute(array, itemSize, normalized);
      }

      if (accessorDef.sparse != null) {
        var itemSizeIndices: Int = WEBGL_TYPE_SIZES.SCALAR;
        var TypedArrayIndices: Dynamic = WEBGL_COMPONENT_TYPES[accessorDef.sparse.indices.componentType];

        var byteOffsetIndices: Int = accessorDef.sparse.indices.byteOffset || 0;
        var byteOffsetValues: Int = accessorDef.sparse.values.byteOffset || 0;

        var sparseIndices: Array<Float> = new TypedArrayIndices(bufferViews[1], byteOffsetIndices, accessorDef.sparse.count * itemSizeIndices);
        var sparseValues: Array<Float> = new TypedArray(bufferViews[2], byteOffsetValues, accessorDef.sparse.count * itemSize);

        if (bufferView != null) {
          bufferAttribute = new BufferAttribute(bufferAttribute.array.slice(), bufferAttribute.itemSize, bufferAttribute.normalized);
        }

        for (i in 0...sparseIndices.length) {
          var index: Int = sparseIndices[i];

          bufferAttribute.setX(index, sparseValues[i * itemSize]);
          if (itemSize >= 2) bufferAttribute.setY(index, sparseValues[i * itemSize + 1]);
          if (itemSize >= 3) bufferAttribute.setZ(index, sparseValues[i * itemSize + 2]);
          if (itemSize >= 4) bufferAttribute.setW(index, sparseValues[i * itemSize + 3]);
          if (itemSize >= 5) throw new Error('THREE.GLTFLoader: Unsupported itemSize in sparse BufferAttribute.');
        }
      }

      return bufferAttribute;
    });
  }

  public function loadTexture(textureIndex: Int): Promise<Texture> {
    var json: Dynamic = this.json;
    var options: Dynamic = this.options;
    var textureDef: Dynamic = json.textures[textureIndex];
    var sourceIndex: Int = textureDef.source;
    var sourceDef: Dynamic = json.images[sourceIndex];

    var loader: Dynamic = this.textureLoader;

    if (sourceDef.uri != null) {
      var handler: Dynamic = options.manager.getHandler(sourceDef.uri);
      if (handler != null) loader = handler;
    }

    return this.loadTextureImage(textureIndex, sourceIndex, loader);
  }

  public function loadTextureImage(textureIndex: Int, sourceIndex: Int, loader: Dynamic): Promise<Texture> {
    var parser: GLTFLoader = this;
    var json: Dynamic = this.json;

    var textureDef: Dynamic = json.textures[textureIndex];
    var sourceDef: Dynamic = json.images[sourceIndex];

    var cacheKey: String = (sourceDef.uri || sourceDef.bufferView) + ':' + textureDef.sampler;

    if (this.textureCache[cacheKey] != null) {
      return this.textureCache[cacheKey];
    }

    var promise: Promise<Texture> = this.loadImageSource(sourceIndex, loader).then(function(texture: Texture) {
      texture.flipY = false;

      texture.name = textureDef.name || sourceDef.name || '';

      if (texture.name == '' && typeof sourceDef.uri == 'string' && sourceDef.uri.indexOf('data:image/') == -1) {
        texture.name = sourceDef.uri;
      }

      var samplers: Dynamic = json.samplers || {};
      var sampler: Dynamic = samplers[textureDef.sampler] || {};

      texture.magFilter = WEBGL_FILTERS[sampler.magFilter] || LinearFilter;
      texture.minFilter = WEBGL_FILTERS[sampler.minFilter] || LinearMipmapLinearFilter;
      texture.wrapS = WEBGL_WRAPPINGS[sampler.wrapS] || RepeatWrapping;
      texture.wrapT = WEBGL_WRAPPINGS[sampler.wrapT] || RepeatWrapping;

      parser.associations.set(texture, { textures: textureIndex });

      return texture;
    }).catch(function() {
      return null;
    });

    this.textureCache[cacheKey] = promise;

    return promise;
  }

  public function loadImageSource(sourceIndex: Int, loader: Dynamic): Promise<Texture> {
    var parser: GLTFLoader = this;
    var json: Dynamic = this.json;
    var options: Dynamic = this.options;

    if (this.sourceCache[sourceIndex] != null) {
      return this.sourceCache[sourceIndex].then(function(texture: Texture) {
        return texture.clone();
      });
    }

    var sourceDef: Dynamic = json.images[sourceIndex];

    var sourceURI: String = sourceDef.uri || '';
    var isObjectURL: Bool = false;

    if (sourceDef.bufferView != null) {
      sourceURI = this.getDependency('bufferView', sourceDef.bufferView).then(function(bufferView: ArrayBuffer) {
        isObjectURL = true;
        var blob: Blob = new Blob([bufferView], { type: sourceDef.mimeType });
        sourceURI = URL.createObjectURL(blob);
        return sourceURI;
      });
    } else if (sourceDef.uri == null) {
      throw new Error('THREE.GLTFLoader: Image ' + sourceIndex + ' is missing URI and bufferView');
    }

    var promise: Promise<Texture> = Promise.resolve(sourceURI).then(function(sourceURI: String) {
      return new Promise(function(resolve: Texture->Void, reject: Dynamic->Void) {
        loader.load(LoaderUtils.resolveURL(sourceURI, options.path), function(imageBitmap: ImageBitmap) {
          var texture: Texture = new Texture(imageBitmap);
          texture.needsUpdate = true;

          resolve(texture);
        }, undefined, reject);
      });
    }).then(function(texture: Texture) {
      if (isObjectURL) URL.revokeObjectURL(sourceURI);

      assignExtrasToUserData(texture, sourceDef);

      texture.userData.mimeType = sourceDef.mimeType || getImageURIMimeType(sourceDef.uri);

      return texture;
    }).catch(function(error: Dynamic) {
      console.error('THREE.GLTFLoader: Couldn\'t load texture', sourceURI);
      throw error;
    });

    this.sourceCache[sourceIndex] = promise;

    return promise;
  }

  public function assignTexture(materialParams: Dynamic, mapName: String, mapDef: Dynamic, colorSpace: Dynamic): Promise<Texture> {
    var parser: GLTFLoader = this;

    return this.getDependency('texture', mapDef.index).then(function(texture: Texture) {
      if (texture == null) return null;

      if (mapDef.texCoord != null && mapDef.texCoord > 0) {
        texture = texture.clone();
        texture.channel = mapDef.texCoord;
      }

      if (parser.extensions[EXTENSIONS.KHR_TEXTURE_TRANSFORM] != null) {
        var transform: Dynamic = mapDef.extensions != null ? mapDef.extensions[EXTENSIONS.KHR_TEXTURE_TRANSFORM] : null;

        if (transform != null) {
          var gltfReference: Dynamic = parser.associations.get(texture);
          texture = parser.extensions[EXTENSIONS.KHR_TEXTURE_TRANSFORM].extendTexture(texture, transform);
          parser.associations.set(texture, gltfReference);
        }
      }

      if (colorSpace != null) {
        texture.colorSpace = colorSpace;
      }

      materialParams[mapName] = texture;

      return texture;
    });
  }

  public function assignFinalMaterial(mesh: Mesh): Void {
    var geometry: Geometry = mesh.geometry;
    var material: Material = mesh.material;

    var useDerivativeTangents: Bool = geometry.attributes.tangent == null;
    var useVertexColors: Bool = geometry.attributes.color != null;
    var useFlatShading: Bool = geometry.attributes.normal == null;

    if (mesh.isPoints) {
      var cacheKey: String = 'PointsMaterial:' + material.uuid;

      var pointsMaterial: Material = this.cache.get(cacheKey);

      if (pointsMaterial == null) {
        pointsMaterial = new PointsMaterial();
        Material.prototype.copy.call(pointsMaterial, material);
        pointsMaterial.color.copy(material.color);
        pointsMaterial.map = material.map;
        pointsMaterial.sizeAttenuation = false; // glTF spec says points should be 1px

        this.cache.add(cacheKey, pointsMaterial);
      }

      material = pointsMaterial;
    } else if (mesh.isLine) {
      var cacheKey: String = 'LineBasicMaterial:' + material.uuid;

      var lineMaterial: Material = this.cache.get(cacheKey);

      if (lineMaterial == null) {
        lineMaterial = new LineBasicMaterial();
        Material.prototype.copy.call(lineMaterial, material);
        lineMaterial.color.copy(material.color);
        lineMaterial.map = material.map;

        this.cache.add(cacheKey, lineMaterial);
      }

      material = lineMaterial;
    }

    if (useDerivativeTangents || useVertexColors || useFlatShading) {
      var cacheKey: String = 'ClonedMaterial:' + material.uuid + ':';

      if (useDerivativeTangents) cacheKey += 'derivative-tangents:';
      if (useVertexColors) cacheKey += 'vertex-colors:';
      if (useFlatShading) cacheKey += 'flat-shading:';

      var cachedMaterial: Material = this.cache.get(cacheKey);

      if (cachedMaterial == null) {
        cachedMaterial = material.clone();

        if (useVertexColors) cachedMaterial.vertexColors = true;
        if (useFlatShading) cachedMaterial.flatShading = true;

        if (useDerivativeTangents) {
          if (cachedMaterial.normalScale != null) cachedMaterial.normalScale.y *= -1;
          if (cachedMaterial.clearcoatNormalScale != null) cachedMaterial.clearcoatNormalScale.y *= -1;
        }

        this.cache.add(cacheKey, cachedMaterial);

        this.associations.set(cachedMaterial, this.associations.get(material));
      }

      material = cachedMaterial;
    }

    mesh.material = material;
  }

  public function getMaterialType(): Class<Material> {
    return MeshStandardMaterial;
  }
}
```
Note that I've assumed that the `WEBGL_TYPE_SIZES`, `WEBGL_COMPONENT_TYPES`, `WEBGL_FILTERS`, and `WEBGL_WRAPPINGS` constants are already defined elsewhere in the code. Also, I've used the Haxe `Dynamic` type to represent JSON objects, which may need to be adjusted depending on the specific requirements of your project.