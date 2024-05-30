import haxe.io.Bytes;
import js.Browser;
import js.html.ArrayBuffer;
import js.html.DataView;
import js.html.Float32Array;
import js.html.Float64Array;
import js.html.Int16Array;
import js.html.Int32Array;
import js.html.Int8Array;
import js.html.Uint16Array;
import js.html.Uint32Array;
import js.html.Uint8Array;
import js.html.Uint8ClampedArray;
import js.html.Window;

class MTLLoader extends Loader {
	public function new(manager:DefaultLoadingManager) {
		super(manager);
	}

	public function load(url:String, onLoad:Function, onProgress:Function, onError:Function):Void {
		var scope = this;
		var path = (this.path == '') ? LoaderUtils.extractUrlBase(url) : this.path;
		var loader = new FileLoader(this.manager);
		loader.path = this.path;
		loader.requestHeader = this.requestHeader;
		loader.withCredentials = this.withCredentials;
		loader.load(url, function(text) {
			try {
				onLoad(scope.parse(text, path));
			} catch(e) {
				if (onError) {
					onError(e);
				} else {
					trace(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function setMaterialOptions(value:MaterialOptions):MTLLoader {
		this.materialOptions = value;
		return this;
	}

	public function parse(text:String, path:String):MaterialCreator {
		var lines = text.split('\n');
		var info = { };
		var delimiter_pattern = ~/\s+/;
		var materialsInfo = { };

		for (i in 0...lines.length) {
			var line = lines[i].trim();

			if (line.length == 0 || line.charAt(0) == '#') {
				continue;
			}

			var pos = line.indexOf(' ');
			var key = (pos >= 0) ? line.substring(0, pos) : line;
			key = key.toLowerCase();
			var value = (pos >= 0) ? line.substring(pos + 1) : '';
			value = value.trim();

			switch(key) {
				case 'newmtl':
					info = { name: value };
					materialsInfo[value] = info;
					break;

				case 'ka':
				case 'kd':
				case 'ks':
				case 'ke':
					var ss = value.split(delimiter_pattern, 3);
					info[key] = [ Std.parseFloat(ss[0]), Std.parseFloat(ss[1]), Std.parseFloat(ss[2]) ];
					break;

				default:
					info[key] = value;
					break;
			}
		}

		var materialCreator = new MaterialCreator(this.resourcePath != null ? this.resourcePath : path, this.materialOptions);
		materialCreator.crossOrigin = this.crossOrigin;
		materialCreator.manager = this.manager;
		materialCreator.materialsInfo = materialsInfo;
		return materialCreator;
	}
}

class MaterialCreator {
	public var baseUrl:String;
	public var options:MaterialOptions;
	public var materialsInfo:Dynamic;
	public var materials:Dynamic;
	public var materialsArray:Array<Dynamic>;
	public var nameLookup:Dynamic;
	public var crossOrigin:String;
	public var side:Int;
	public var wrap:Int;
	public var manager:DefaultLoadingManager;

	public function new(baseUrl:String = '', options:MaterialOptions = null) {
		this.baseUrl = baseUrl;
		this.options = options != null ? options : { };
		this.materialsInfo = { };
		this.materials = { };
		this.materialsArray = [];
		this.nameLookup = { };
		this.crossOrigin = 'anonymous';
		this.side = (this.options.side != null) ? this.options.side : FrontSide;
		this.wrap = (this.options.wrap != null) ? this.options.wrap : RepeatWrapping;
	}

	public function setCrossOrigin(value:String):MaterialCreator {
		this.crossOrigin = value;
		return this;
	}

	public function setManager(value:DefaultLoadingManager):Void {
		this.manager = value;
	}

	public function setMaterials(materialsInfo:Dynamic):Void {
		this.materialsInfo = this.convert(materialsInfo);
		this.materials = { };
		this.materialsArray = [];
		this.nameLookup = { };
	}

	public function convert(materialsInfo:Dynamic):Dynamic {
		if (this.options == null) return materialsInfo;

		var converted = { };

		for (mn in materialsInfo) {
			var mat = materialsInfo[mn];
			var covmat = { };
			converted[mn] = covmat;

			for (prop in mat) {
				var save = true;
				var value = mat[prop];
				var lprop = prop.toLowerCase();

				switch(lprop) {
					case 'kd':
					case 'ka':
					case 'ks':
						if (this.options.normalizeRGB) {
							value = [ value[0] / 255, value[1] / 255, value[2] / 255 ];
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

	public function createMaterial_(materialName:String):Void {
		var scope = this;
		var mat = this.materialsInfo[materialName];
		var params = {
			name: materialName,
			side: this.side
		};

		function resolveURL(baseUrl:String, url:String):String {
			if (url == null || url == '') return '';

			if (/^https?:\/\//i.test(url)) return url;

			return baseUrl + url;
		}

		function setMapForType(mapType:String, value:String):Void {
			if (params[mapType] != null) return; // Keep the first encountered texture

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

			if (value == '') continue;

			switch(prop.toLowerCase()) {
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
					var n = Std.parseFloat(value);

					if (n < 1) {
						params.opacity = n;
						params.transparent = true;
					}

					break;

				case 'tr':
					var n = Std.parseFloat(value);

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
	}

	public function getTextureParams(value:String, matParams:Dynamic):Dynamic {
		var texParams = {
			scale: new Vector2(1, 1),
			offset: new Vector2(0, 0)
		};

		var items = value.split(/\s+/);
		var pos = items.indexOf('-bm');

		if (pos >= 0) {
			matParams.bumpScale = Std.parseFloat(items[pos + 1]);
			items.splice(pos, 2);
		}

		pos = items.indexOf('-s');

		if (pos >= 0) {
			texParams.scale.set(Std.parseFloat(items[pos + 1]), Std.parseFloat(items[pos + 2]));
			items.splice(pos, 4); // we expect 3 parameters here!
		}

		pos = items.indexOf('-o');

		if (pos >= 0) {
			texParams.offset.set(Std.parseFloat(items[pos + 1]), Std.parseFloat(items[pos + 2]));
			items.splice(pos, 4); // we expect 3 parameters here!
		}

		texParams.url = items.join(' ').trim();
		return texParams;
	}

	public function loadTexture(url:String, mapping:Int, onLoad:Function, onProgress:Function, onError:Function):Dynamic {
		var manager = (this.manager != null) ? this.manager : DefaultLoadingManager.instance;
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

class Color {
	public function fromArray(array:Array<Float>):Color {
		return null;
	}

	public function convertSRGBToLinear():Color {
		return null;
	}
}

class Loader {
	public var manager:DefaultLoadingManager;
	public var path:String;
	public var requestHeader:String;
	public var withCredentials:Bool;

	public function new(manager:DefaultLoadingManager) {

	}
}

class LoaderUtils {
	public static function extractUrlBase(url:String):String {
		return '';
	}
}

class MaterialOptions {
	public var side:Int;
	public var wrap:Int;
	public var normalizeRGB:Bool;
	public var ignoreZeroRGBs:Bool;
	public var invertTrProperty:Bool;
}

class MeshPhongMaterial {
	public function new(parameters:Dynamic) {

	}
}

class RepeatWrapping {

}

class SRGBColorSpace {

}

class TextureLoader {
	public var crossOrigin:String;

	public function load(url:String, onLoad:Function, onProgress:Function, onError:Function):Dynamic {
		return null;
	}

	public function setCrossOrigin(value:String):Void {

	}
}

class Vector2 {
	public function copy(v:Vector2):Vector2 {
		return null;
	}

	public function set(x:Float, y:Float):Vector2 {
		return null;
	}
}

class FrontSide {

}

class DefaultLoadingManager {
	public static var instance:DefaultLoadingManager;

	public function getHandler(url:String):Dynamic {
		return null;
	}
}

class FileLoader {
	public function new(manager:DefaultLoadingManager) {

	}

	public function load(url:String, callback:Function, onProgress:Function, onError:Function):Void {

	}

	public var path:String;
	public var requestHeader:String;
	public var withCredentials:Bool;

	public function setPath(value:String):Void {

	}

	public function setRequestHeader(value:String):Void {

	}

	public function setWithCredentials(value:Bool):Void {

	}
}