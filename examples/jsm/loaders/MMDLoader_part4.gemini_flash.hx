import three.core.BufferGeometry;
import three.materials.MMDToonMaterial;
import three.loaders.TextureLoader;
import three.math.Color;
import three.constants.Blending;
import three.constants.BlendingEquation;
import three.constants.Side;
import three.constants.Wrapping;
import three.constants.TextureFilter;
import three.constants.ColorSpace;
import three.constants.Combine;
import three.loaders.TGALoader;
import three.core.Object3D;
import three.constants.TextureFormat;

class MaterialBuilder {

  public var manager:Object3D;
  public var textureLoader:TextureLoader;
  public var tgaLoader:TGALoader = null;
  public var crossOrigin:String = "anonymous";
  public var resourcePath:String = null;

  public function new(manager:Object3D) {
    this.manager = manager;
    this.textureLoader = new TextureLoader(this.manager);
  }

  public function setCrossOrigin(crossOrigin:String):MaterialBuilder {
    this.crossOrigin = crossOrigin;
    return this;
  }

  public function setResourcePath(resourcePath:String):MaterialBuilder {
    this.resourcePath = resourcePath;
    return this;
  }

  public function build(data:Dynamic, geometry:BufferGeometry, ?onProgress:Dynamic, ?onError:Dynamic):Array<MMDToonMaterial> {
    var materials:Array<MMDToonMaterial> = [];
    var textures:Map<String, Dynamic> = new Map();

    this.textureLoader.setCrossOrigin(this.crossOrigin);

    for (i in 0...data.metadata.materialCount) {
      var material:Dynamic = data.materials[i];
      var params:Dynamic = { userData: { MMD: {} } };
      if (material.name != null) params.name = material.name;

      params.diffuse = new Color().setRGB(material.diffuse[0], material.diffuse[1], material.diffuse[2], ColorSpace.SRGB);
      params.opacity = material.diffuse[3];
      params.specular = new Color().setRGB(material.specular[0], material.specular[1], material.specular[2], ColorSpace.SRGB);
      params.shininess = material.shininess;
      params.emissive = new Color().setRGB(material.ambient[0], material.ambient[1], material.ambient[2], ColorSpace.SRGB);
      params.transparent = params.opacity != 1.0;

      params.fog = true;
      params.blending = Blending.CustomBlending;
      params.blendSrc = BlendingEquation.SrcAlphaFactor;
      params.blendDst = BlendingEquation.OneMinusSrcAlphaFactor;
      params.blendSrcAlpha = BlendingEquation.SrcAlphaFactor;
      params.blendDstAlpha = BlendingEquation.DstAlphaFactor;

      if (data.metadata.format == "pmx" && (material.flag & 0x1) == 1) {
        params.side = Side.DoubleSide;
      } else {
        params.side = params.opacity == 1.0 ? Side.FrontSide : Side.DoubleSide;
      }

      if (data.metadata.format == "pmd") {
        if (material.fileName != null) {
          var fileName:Array<String> = material.fileName.split("*");

          params.map = this._loadTexture(fileName[0], textures);

          if (fileName.length > 1) {
            var extension:String = fileName[1].slice(-4).toLowerCase();
            params.matcap = this._loadTexture(fileName[1], textures);
            params.matcapCombine = extension == ".sph" ? Combine.MultiplyOperation : Combine.AddOperation;
          }
        }

        var toonFileName:String = material.toonIndex == -1 ? "toon00.bmp" : data.toonTextures[material.toonIndex].fileName;
        params.gradientMap = this._loadTexture(toonFileName, textures, { isToonTexture: true, isDefaultToonTexture: this._isDefaultToonTexture(toonFileName) });

        params.userData.outlineParameters = {
          thickness: material.edgeFlag == 1 ? 0.003 : 0.0,
          color: [0, 0, 0],
          alpha: 1.0,
          visible: material.edgeFlag == 1
        };
      } else {
        if (material.textureIndex != -1) {
          params.map = this._loadTexture(data.textures[material.textureIndex], textures);
          params.userData.MMD.mapFileName = data.textures[material.textureIndex];
        }

        if (material.envTextureIndex != -1 && (material.envFlag == 1 || material.envFlag == 2)) {
          params.matcap = this._loadTexture(data.textures[material.envTextureIndex], textures);
          params.userData.MMD.matcapFileName = data.textures[material.envTextureIndex];
          params.matcapCombine = material.envFlag == 1 ? Combine.MultiplyOperation : Combine.AddOperation;
        }

        var toonFileName:String, isDefaultToon:Bool;
        if (material.toonIndex == -1 || material.toonFlag != 0) {
          toonFileName = "toon" + ("0" + (material.toonIndex + 1)).slice(-2) + ".bmp";
          isDefaultToon = true;
        } else {
          toonFileName = data.textures[material.toonIndex];
          isDefaultToon = false;
        }

        params.gradientMap = this._loadTexture(toonFileName, textures, { isToonTexture: true, isDefaultToonTexture: isDefaultToon });

        params.userData.outlineParameters = {
          thickness: material.edgeSize / 300,
          color: material.edgeColor.slice(0, 3),
          alpha: material.edgeColor[3],
          visible: (material.flag & 0x10) != 0 && material.edgeSize > 0.0
        };
      }

      if (params.map != null) {
        if (!params.transparent) {
          this._checkImageTransparency(params.map, geometry, i);
        }

        params.emissive.multiplyScalar(0.2);
      }

      materials.push(new MMDToonMaterial(params));
    }

    if (data.metadata.format == "pmx") {
      function checkAlphaMorph(elements:Array<Dynamic>, materials:Array<MMDToonMaterial>):Void {
        for (i in 0...elements.length) {
          var element:Dynamic = elements[i];
          if (element.index == -1) continue;
          var material:MMDToonMaterial = materials[element.index];
          if (material.opacity != element.diffuse[3]) {
            material.transparent = true;
          }
        }
      }

      for (i in 0...data.morphs.length) {
        var morph:Dynamic = data.morphs[i];
        var elements:Array<Dynamic> = morph.elements;
        if (morph.type == 0) {
          for (j in 0...elements.length) {
            var morph2:Dynamic = data.morphs[elements[j].index];
            if (morph2.type != 8) continue;
            checkAlphaMorph(morph2.elements, materials);
          }
        } else if (morph.type == 8) {
          checkAlphaMorph(elements, materials);
        }
      }
    }

    return materials;
  }

  private function _getTGALoader():TGALoader {
    if (this.tgaLoader == null) {
      this.tgaLoader = new TGALoader(this.manager);
    }
    return this.tgaLoader;
  }

  private function _isDefaultToonTexture(name:String):Bool {
    if (name.length != 10) return false;
    return name.match(/toon(10|0[0-9])\.bmp/) != null;
  }

  private function _loadTexture(filePath:String, textures:Map<String, Dynamic>, ?params:Dynamic, ?onProgress:Dynamic, ?onError:Dynamic):Dynamic {
    params = params != null ? params : {};
    var scope:MaterialBuilder = this;

    var fullPath:String;
    if (params.isDefaultToonTexture == true) {
      var index:Int;
      try {
        index = Std.parseInt(filePath.match(/toon([0-9]{2})\.bmp$/)[1]);
      } catch (e:Dynamic) {
        Sys.println("THREE.MMDLoader: " + filePath + " seems like a not right default texture path. Using toon00.bmp instead.");
        index = 0;
      }

      fullPath = DEFAULT_TOON_TEXTURES[index];
    } else {
      fullPath = this.resourcePath + filePath;
    }

    if (textures.exists(fullPath)) return textures.get(fullPath);

    var loader:Dynamic = this.manager.getHandler(fullPath);
    if (loader == null) {
      loader = filePath.slice(-4).toLowerCase() == ".tga" ? this._getTGALoader() : this.textureLoader;
    }

    var texture:Dynamic = loader.load(fullPath, function(t:Dynamic) {
      if (params.isToonTexture == true) {
        t.image = scope._getRotatedImage(t.image);
        t.magFilter = TextureFilter.NearestFilter;
        t.minFilter = TextureFilter.NearestFilter;
      }
      t.flipY = false;
      t.wrapS = Wrapping.RepeatWrapping;
      t.wrapT = Wrapping.RepeatWrapping;
      t.colorSpace = ColorSpace.SRGBColorSpace;

      for (i in 0...texture.readyCallbacks.length) {
        texture.readyCallbacks[i](texture);
      }

      texture.readyCallbacks = [];
    }, onProgress, onError);

    texture.readyCallbacks = [];
    textures.set(fullPath, texture);
    return texture;
  }

  private function _getRotatedImage(image:Dynamic):Dynamic {
    var canvas:Dynamic = document.createElement("canvas");
    var context:Dynamic = canvas.getContext("2d");
    var width:Int = image.width;
    var height:Int = image.height;

    canvas.width = width;
    canvas.height = height;

    context.clearRect(0, 0, width, height);
    context.translate(width / 2.0, height / 2.0);
    context.rotate(0.5 * Math.PI);
    context.translate(-width / 2.0, -height / 2.0);
    context.drawImage(image, 0, 0);

    return context.getImageData(0, 0, width, height);
  }

  private function _checkImageTransparency(map:Dynamic, geometry:BufferGeometry, groupIndex:Int):Void {
    map.readyCallbacks.push(function(texture:Dynamic) {
      function createImageData(image:Dynamic):Dynamic {
        var canvas:Dynamic = document.createElement("canvas");
        canvas.width = image.width;
        canvas.height = image.height;
        var context:Dynamic = canvas.getContext("2d");
        context.drawImage(image, 0, 0);
        return context.getImageData(0, 0, canvas.width, canvas.height);
      }

      function detectImageTransparency(image:Dynamic, uvs:Array<Float>, indices:Array<Int>):Bool {
        var width:Int = image.width;
        var height:Int = image.height;
        var data:Array<Int> = image.data;
        var threshold:Int = 253;

        if (data.length / (width * height) != 4) return false;

        for (i in 0...indices.length) {
          if (i % 3 != 0) continue;
          var centerUV:Dynamic = { x: 0.0, y: 0.0 };
          for (j in 0...3) {
            var index:Int = indices[i * 3 + j];
            var uv:Dynamic = { x: uvs[index * 2 + 0], y: uvs[index * 2 + 1] };
            if (getAlphaByUv(image, uv) < threshold) return true;
            centerUV.x += uv.x;
            centerUV.y += uv.y;
          }
          centerUV.x /= 3;
          centerUV.y /= 3;
          if (getAlphaByUv(image, centerUV) < threshold) return true;
        }

        return false;
      }

      function getAlphaByUv(image:Dynamic, uv:Dynamic):Int {
        var width:Int = image.width;
        var height:Int = image.height;
        var x:Int = Math.round(uv.x * width) % width;
        var y:Int = Math.round(uv.y * height) % height;
        if (x < 0) x += width;
        if (y < 0) y += height;
        var index:Int = y * width + x;
        return image.data[index * 4 + 3];
      }

      if (texture.isCompressedTexture == true) {
        if (NON_ALPHA_CHANNEL_FORMATS.includes(texture.format)) {
          map.transparent = false;
        } else {
          map.transparent = true;
        }
        return;
      }

      var imageData:Dynamic = texture.image.data != null ? texture.image : createImageData(texture.image);
      var group:Dynamic = geometry.groups[groupIndex];

      if (detectImageTransparency(imageData, geometry.attributes.uv.array, geometry.index.array.slice(group.start, group.start + group.count))) {
        map.transparent = true;
      }
    });
  }

}

private var DEFAULT_TOON_TEXTURES:Array<String> = [
  "assets/mmd/toon/toon00.bmp",
  "assets/mmd/toon/toon01.bmp",
  "assets/mmd/toon/toon02.bmp",
  "assets/mmd/toon/toon03.bmp",
  "assets/mmd/toon/toon04.bmp",
  "assets/mmd/toon/toon05.bmp",
  "assets/mmd/toon/toon06.bmp",
  "assets/mmd/toon/toon07.bmp",
  "assets/mmd/toon/toon08.bmp",
  "assets/mmd/toon/toon09.bmp",
  "assets/mmd/toon/toon10.bmp"
];

private var NON_ALPHA_CHANNEL_FORMATS:Array<TextureFormat> = [
  TextureFormat.RGBAFormat,
  TextureFormat.RGBFormat,
  TextureFormat.LuminanceFormat,
  TextureFormat.LuminanceAlphaFormat,
  TextureFormat.DepthFormat,
  TextureFormat.DepthStencilFormat
];