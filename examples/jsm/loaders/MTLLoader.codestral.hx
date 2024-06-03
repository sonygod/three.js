import three.Color;
import three.DefaultLoadingManager;
import three.FileLoader;
import three.FrontSide;
import three.Loader;
import three.LoaderUtils;
import three.MeshPhongMaterial;
import three.RepeatWrapping;
import three.TextureLoader;
import three.Vector2;
import three.SRGBColorSpace;

class MTLLoader extends Loader {
    public function new(manager:LoadingManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Null<Function>, onProgress:Null<Function>, onError:Null<Function>):Void {
        var path:String = (this.path == '') ? LoaderUtils.extractUrlBase(url) : this.path;
        var loader:FileLoader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(text:String) {
            try {
                onLoad(this.parse(text, path));
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

    public function setMaterialOptions(value:Dynamic):MTLLoader {
        this.materialOptions = value;
        return this;
    }

    public function parse(text:String, path:String):MaterialCreator {
        var lines:Array<String> = text.split('\n');
        var info:Dynamic = {};
        var delimiter_pattern:EReg = /\s+/;
        var materialsInfo:Dynamic = {};

        for (i in 0...lines.length) {
            var line:String = lines[i];
            line = line.trim();

            if (line.length == 0 || line.charAt(0) == '#') {
                continue;
            }

            var pos:Int = line.indexOf(' ');
            var key:String = (pos >= 0) ? line.substring(0, pos) : line;
            key = key.toLowerCase();
            var value:String = (pos >= 0) ? line.substring(pos + 1) : '';
            value = value.trim();

            if (key == 'newmtl') {
                info = {name: value};
                materialsInfo[value] = info;
            } else {
                if (key == 'ka' || key == 'kd' || key == 'ks' || key == 'ke') {
                    var ss:Array<String> = value.split(delimiter_pattern, 3);
                    info[key] = [Std.parseFloat(ss[0]), Std.parseFloat(ss[1]), Std.parseFloat(ss[2])];
                } else {
                    info[key] = value;
                }
            }
        }

        var materialCreator:MaterialCreator = new MaterialCreator(this.resourcePath != null ? this.resourcePath : path, this.materialOptions != null ? this.materialOptions : {});
        materialCreator.setCrossOrigin(this.crossOrigin != null ? this.crossOrigin : 'anonymous');
        materialCreator.setManager(this.manager);
        materialCreator.setMaterials(materialsInfo);
        return materialCreator;
    }
}

class MaterialCreator {
    public var baseUrl:String;
    public var options:Dynamic;
    public var materialsInfo:Dynamic;
    public var materials:Dynamic;
    public var materialsArray:Array<MeshPhongMaterial>;
    public var nameLookup:Dynamic;
    public var crossOrigin:String;
    public var side:Int;
    public var wrap:Int;
    public var manager:LoadingManager;

    public function new(baseUrl:String = '', options:Dynamic = {}) {
        this.baseUrl = baseUrl;
        this.options = options;
        this.materialsInfo = {};
        this.materials = {};
        this.materialsArray = [];
        this.nameLookup = {};
        this.crossOrigin = 'anonymous';
        this.side = (this.options.side != null) ? this.options.side : FrontSide;
        this.wrap = (this.options.wrap != null) ? this.options.wrap : RepeatWrapping;
    }

    public function setCrossOrigin(value:String):MaterialCreator {
        this.crossOrigin = value;
        return this;
    }

    public function setManager(value:LoadingManager):Void {
        this.manager = value;
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

        for (mn in Reflect.fields(materialsInfo)) {
            var mat:Dynamic = Reflect.field(materialsInfo, mn);
            var covmat:Dynamic = {};
            converted[mn] = covmat;

            for (prop in Reflect.fields(mat)) {
                var save:Bool = true;
                var value:Dynamic = Reflect.field(mat, prop);
                var lprop:String = prop.toLowerCase();

                switch (lprop) {
                    case 'kd':
                    case 'ka':
                    case 'ks':
                        if (this.options.normalizeRGB) {
                            value = [value[0] / 255, value[1] / 255, value[2] / 255];
                        }

                        if (this.options.ignoreZeroRGBs) {
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
        for (mn in Reflect.fields(this.materialsInfo)) {
            this.create(mn);
        }
    }

    public function getIndex(materialName:String):Int {
        return this.nameLookup[materialName];
    }

    public function getAsArray():Array<MeshPhongMaterial> {
        var index:Int = 0;

        for (mn in Reflect.fields(this.materialsInfo)) {
            this.materialsArray[index] = this.create(mn);
            this.nameLookup[mn] = index;
            index++;
        }

        return this.materialsArray;
    }

    public function create(materialName:String):MeshPhongMaterial {
        if (this.materials[materialName] == null) {
            this.createMaterial_(materialName);
        }

        return this.materials[materialName];
    }

    public function createMaterial_(materialName:String):MeshPhongMaterial {
        var mat:Dynamic = this.materialsInfo[materialName];
        var params:Dynamic = {
            name: materialName,
            side: this.side
        };

        function resolveURL(baseUrl:String, url:String):String {
            if (url == null || url == '' || (url is String && Std.string(url).match(/^https?:\/\//i) != null)) {
                return '';
            }

            return baseUrl + url;
        }

        function setMapForType(mapType:String, value:String):Void {
            if (params[mapType] != null) return;

            var texParams:Dynamic = this.getTextureParams(value, params);
            var map:Texture = this.loadTexture(resolveURL(this.baseUrl, texParams.url));

            map.repeat.copy(texParams.scale);
            map.offset.copy(texParams.offset);

            map.wrapS = this.wrap;
            map.wrapT = this.wrap;

            if (mapType == 'map' || mapType == 'emissiveMap') {
                map.colorSpace = SRGBColorSpace;
            }

            params[mapType] = map;
        }

        for (prop in Reflect.fields(mat)) {
            var value:Dynamic = Reflect.field(mat, prop);

            if (value == '') continue;

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
                    var n:Float = Std.parseFloat(value);

                    if (n < 1) {
                        params.opacity = n;
                        params.transparent = true;
                    }

                    break;
                case 'tr':
                    var n:Float = Std.parseFloat(value);

                    if (this.options.invertTrProperty) n = 1 - n;

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

        var items:Array<String> = value.split(/\s+/);
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

    public function loadTexture(url:String, mapping:Int = null, onLoad:Null<Function> = null, onProgress:Null<Function> = null, onError:Null<Function> = null):Texture {
        var manager:LoadingManager = (this.manager != null) ? this.manager : DefaultLoadingManager;
        var loader:TextureLoader = manager.getHandler(url);

        if (loader == null) {
            loader = new TextureLoader(manager);
        }

        if (loader.setCrossOrigin != null) loader.setCrossOrigin(this.crossOrigin);

        var texture:Texture = loader.load(url, onLoad, onProgress, onError);

        if (mapping != null) texture.mapping = mapping;

        return texture;
    }
}