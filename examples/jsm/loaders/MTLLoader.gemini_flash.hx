import three.loaders.Loader;
import three.loaders.FileLoader;
import three.loaders.LoaderUtils;
import three.math.Color;
import three.math.Vector2;
import three.materials.MeshPhongMaterial;
import three.materials.FrontSide;
import three.materials.RepeatWrapping;
import three.textures.TextureLoader;
import three.textures.SRGBColorSpace;

/**
 * Loads a Wavefront .mtl file specifying materials
 */
class MTLLoader extends Loader {

  public function new(manager:Loader = null) {
    super(manager);
  }

  /**
   * Loads and parses a MTL asset from a URL.
   *
   * @param {String} url - URL to the MTL file.
   * @param {Function} [onLoad] - Callback invoked with the loaded object.
   * @param {Function} [onProgress] - Callback for download progress.
   * @param {Function} [onError] - Callback for download errors.
   *
   * @see setPath setResourcePath
   *
   * @note In order for relative texture references to resolve correctly
   * you must call setResourcePath() explicitly prior to load.
   */
  public function load(url:String, onLoad:Dynamic->Void = null, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null):Void {
    var scope = this;
    var path = (this.path == "") ? LoaderUtils.extractUrlBase(url) : this.path;
    var loader = new FileLoader(this.manager);
    loader.setPath(this.path);
    loader.setRequestHeader(this.requestHeader);
    loader.setWithCredentials(this.withCredentials);
    loader.load(url, function(text:String) {
      try {
        onLoad(scope.parse(text, path));
      } catch (e:Dynamic) {
        if (onError != null) {
          onError(e);
        } else {
          console.error(e);
        }
        scope.manager.itemError(url);
      }
    }, onProgress, onError);
  }

  public function setMaterialOptions(value:Dynamic):MTLLoader {
    this.materialOptions = value;
    return this;
  }

  /**
   * Parses a MTL file.
   *
   * @param {String} text - Content of MTL file
   * @return {MaterialCreator}
   *
   * @see setPath setResourcePath
   *
   * @note In order for relative texture references to resolve correctly
   * you must call setResourcePath() explicitly prior to parse.
   */
  public function parse(text:String, path:String):MaterialCreator {
    var lines = text.split("\n");
    var info:Dynamic = {};
    var delimiter_pattern = ~/^\s+$/;
    var materialsInfo:Dynamic = {};

    for (i in 0...lines.length) {
      var line = lines[i];
      line = line.trim();
      if (line.length == 0 || line.charAt(0) == '#') {
        continue;
      }
      var pos = line.indexOf(' ');
      var key = (pos >= 0) ? line.substring(0, pos) : line;
      key = key.toLowerCase();
      var value = (pos >= 0) ? line.substring(pos + 1) : "";
      value = value.trim();
      if (key == 'newmtl') {
        info = {name: value};
        materialsInfo[value] = info;
      } else {
        if (key == 'ka' || key == 'kd' || key == 'ks' || key == 'ke') {
          var ss = value.split(delimiter_pattern, 3);
          info[key] = [Std.parseFloat(ss[0]), Std.parseFloat(ss[1]), Std.parseFloat(ss[2])];
        } else {
          info[key] = value;
        }
      }
    }

    var materialCreator = new MaterialCreator(this.resourcePath != null ? this.resourcePath : path, this.materialOptions);
    materialCreator.setCrossOrigin(this.crossOrigin);
    materialCreator.setManager(this.manager);
    materialCreator.setMaterials(materialsInfo);
    return materialCreator;
  }

}

/**
 * Create a new MTLLoader.MaterialCreator
 * @param baseUrl - Url relative to which textures are loaded
 * @param options - Set of options on how to construct the materials
 *                  side: Which side to apply the material
 *                        FrontSide (default), THREE.BackSide, THREE.DoubleSide
 *                  wrap: What type of wrapping to apply for textures
 *                        RepeatWrapping (default), THREE.ClampToEdgeWrapping, THREE.MirroredRepeatWrapping
 *                  normalizeRGB: RGBs need to be normalized to 0-1 from 0-255
 *                                Default: false, assumed to be already normalized
 *                  ignoreZeroRGBs: Ignore values of RGBs (Ka,Kd,Ks) that are all 0's
 *                                  Default: false
 * @constructor
 */
class MaterialCreator {

  public var baseUrl:String;
  public var options:Dynamic;
  public var materialsInfo:Dynamic;
  public var materials:Dynamic;
  public var materialsArray:Array<Dynamic>;
  public var nameLookup:Dynamic;
  public var crossOrigin:String;
  public var side:Int;
  public var wrap:Int;
  public var manager:Dynamic;

  public function new(baseUrl:String = "", options:Dynamic = {}) {
    this.baseUrl = baseUrl;
    this.options = options;
    this.materialsInfo = {};
    this.materials = {};
    this.materialsArray = [];
    this.nameLookup = {};
    this.crossOrigin = "anonymous";
    this.side = (this.options.side != null) ? this.options.side : FrontSide;
    this.wrap = (this.options.wrap != null) ? this.options.wrap : RepeatWrapping;
  }

  public function setCrossOrigin(value:String):MaterialCreator {
    this.crossOrigin = value;
    return this;
  }

  public function setManager(value:Dynamic):MaterialCreator {
    this.manager = value;
    return this;
  }

  public function setMaterials(materialsInfo:Dynamic):Void {
    this.materialsInfo = this.convert(materialsInfo);
    this.materials = {};
    this.materialsArray = [];
    this.nameLookup = {};
  }

  public function convert(materialsInfo:Dynamic):Dynamic {
    if (this.options == null) return materialsInfo;
    var converted:Dynamic = {};
    for (mn in materialsInfo) {
      var mat = materialsInfo[mn];
      var covmat:Dynamic = {};
      converted[mn] = covmat;
      for (prop in mat) {
        var save = true;
        var value = mat[prop];
        var lprop = prop.toLowerCase();
        switch (lprop) {
          case 'kd':
          case 'ka':
          case 'ks':
            if (this.options != null && this.options.normalizeRGB) {
              value = [value[0] / 255, value[1] / 255, value[2] / 255];
            }
            if (this.options != null && this.options.ignoreZeroRGBs) {
              if (value[0] == 0 && value[1] == 0 && value[2] == 0) {
                save = false;
              }
            }
            break;
          default:
            break;
        }
        if (save) {
          covmat[lprop] = value;
        }
      }
    }
    return converted;
  }

  public function preload():Void {
    for (mn in this.materialsInfo) {
      this.create(mn);
    }
  }

  public function getIndex(materialName:String):Int {
    return this.nameLookup[materialName];
  }

  public function getAsArray():Array<Dynamic> {
    var index = 0;
    for (mn in this.materialsInfo) {
      this.materialsArray[index] = this.create(mn);
      this.nameLookup[mn] = index;
      index++;
    }
    return this.materialsArray;
  }

  public function create(materialName:String):Dynamic {
    if (this.materials[materialName] == null) {
      this.createMaterial_(materialName);
    }
    return this.materials[materialName];
  }

  public function createMaterial_(materialName:String):Dynamic {
    var scope = this;
    var mat = this.materialsInfo[materialName];
    var params:Dynamic = {
      name: materialName,
      side: this.side
    };
    function resolveURL(baseUrl:String, url:String):String {
      if (Std.typeof(url) != 'string' || url == "")
        return "";
      if (url.match(/^https?:\/\//i) != null) return url;
      return baseUrl + url;
    }
    function setMapForType(mapType:String, value:String):Void {
      if (params[mapType] != null) return;
      var texParams = scope.getTextureParams(value, params);
      var map = scope.loadTexture(resolveURL(scope.baseUrl, texParams.url));
      map.repeat.copy(texParams.scale);
      map.offset.copy(texParams.offset);
      map.wrapS = scope.wrap;
      map.wrapT = scope.wrap;
      if (mapType == 'map' || mapType == 'emissiveMap') {
        map.colorSpace = SRGBColorSpace;
      }
      params[mapType] = map;
    }
    for (prop in mat) {
      var value = mat[prop];
      var n:Float;
      if (value == "") continue;
      switch (prop.toLowerCase()) {
        case 'kd':
          params.color = new Color().fromArray(value).convertSRGBToLinear();
          break;
        case 'ks':
          params.specular = new Color().fromArray(value).convertSRGBToLinear();
          break;
        case 'ke':
          params.emissive = new Color().fromArray(value).convertSRGBToLinear();
          break;
        case 'map_kd':
          setMapForType('map', value);
          break;
        case 'map_ks':
          setMapForType('specularMap', value);
          break;
        case 'map_ke':
          setMapForType('emissiveMap', value);
          break;
        case 'norm':
          setMapForType('normalMap', value);
          break;
        case 'map_bump':
        case 'bump':
          setMapForType('bumpMap', value);
          break;
        case 'map_d':
          setMapForType('alphaMap', value);
          params.transparent = true;
          break;
        case 'ns':
          params.shininess = Std.parseFloat(value);
          break;
        case 'd':
          n = Std.parseFloat(value);
          if (n < 1) {
            params.opacity = n;
            params.transparent = true;
          }
          break;
        case 'tr':
          n = Std.parseFloat(value);
          if (this.options != null && this.options.invertTrProperty) n = 1 - n;
          if (n > 0) {
            params.opacity = 1 - n;
            params.transparent = true;
          }
          break;
        default:
          break;
      }
    }
    this.materials[materialName] = new MeshPhongMaterial(params);
    return this.materials[materialName];
  }

  public function getTextureParams(value:String, matParams:Dynamic):Dynamic {
    var texParams:Dynamic = {
      scale: new Vector2(1, 1),
      offset: new Vector2(0, 0)
    };
    var items = value.split(/\s+/);
    var pos:Int;
    pos = items.indexOf('-bm');
    if (pos >= 0) {
      matParams.bumpScale = Std.parseFloat(items[pos + 1]);
      items.splice(pos, 2);
    }
    pos = items.indexOf('-s');
    if (pos >= 0) {
      texParams.scale.set(Std.parseFloat(items[pos + 1]), Std.parseFloat(items[pos + 2]));
      items.splice(pos, 4);
    }
    pos = items.indexOf('-o');
    if (pos >= 0) {
      texParams.offset.set(Std.parseFloat(items[pos + 1]), Std.parseFloat(items[pos + 2]));
      items.splice(pos, 4);
    }
    texParams.url = items.join(' ').trim();
    return texParams;
  }

  public function loadTexture(url:String, mapping:Dynamic = null, onLoad:Dynamic->Void = null, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null):Dynamic {
    var manager = (this.manager != null) ? this.manager : null;
    var loader = manager.getHandler(url);
    if (loader == null) {
      loader = new TextureLoader(manager);
    }
    if (loader.setCrossOrigin != null) loader.setCrossOrigin(this.crossOrigin);
    var texture = loader.load(url, onLoad, onProgress, onError);
    if (mapping != null) texture.mapping = mapping;
    return texture;
  }

}