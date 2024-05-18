import three.math.Color;
import three.core.DefaultLoadingManager;
import three.textures.Texture;
import three.textures.TextureUtils;
import three.materials.Material;
import three.materials.MeshPhongMaterial;
import three.math.Vector2;
import three.math.Vector3;
import three.core.Loader;
import three.core.LoaderUtils;
import three.core.FileLoader;
import three.core.FrontSide;
import three.materials.RepeatWrapping;
import three.textures.SRGBColorSpace;

class MTLLoader extends Loader {

	public var materialOptions:Dynamic;

	public function new(manager:Loader) {
		super(manager);
	}

	public override function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		var scope = this;
		var path = (this.path == '') ? LoaderUtils.extractUrlBase(url) : this.path;
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function (text) {
			try {
				onLoad(scope.parse(text, path));
			} catch (e) {
				if (onError != null) {
					onError(e);
				} else {
					trace(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function setMaterialOptions(value:Dynamic):MTLLoader {
		this.materialOptions = value;
		return this;
	}

	public function parse(text:String, path:String):MaterialCreator {
		var lines = text.split('\n');
		var info:Dynamic = {};
		var delimiter_pattern = /\s+/;
		var materialsInfo:Dynamic = {};

		for (i in 0...lines.length) {
			var line = lines[i];
			line = line.trim();

			if (line.length == 0 || line.charAt(0) == '#') {
				// Blank line or comment ignore
				continue;
			}

			var pos = line.indexOf(' ');

			var key = (pos >= 0) ? line.substring(0, pos) : line;
			key = key.toLowerCase();

			var value = (pos >= 0) ? line.substring(pos + 1) : '';
			value = value.trim();

			if (key == 'newmtl') {

				// New material

				info = {name: value};
				materialsInfo[value] = info;

			} else {

				if (key == 'ka' || key == 'kd' || key == 'ks' || key == 'ke') {

					var ss = value.split(delimiter_pattern, 3);
					info[key] = [Float.parseFloat(ss[0]), Float.parseFloat(ss[1]), Float.parseFloat(ss[2])];

				} else {

					info[key] = value;

				}

			}

		}

		var materialCreator = new MaterialCreator(this.resourcePath || path, this.materialOptions);
		materialCreator.setCrossOrigin(this.crossOrigin);
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
	public var materialsArray:Array<Dynamic>;
	public var nameLookup:Dynamic;

	public var crossOrigin:String;

	public function new(baseUrl:String = '', options:Dynamic = {}) {
		this.baseUrl = baseUrl;
		this.options = options;
		this.materialsInfo = {};
		this.materials = {};
		this.materialsArray = [];
		this.nameLookup = {};

		this.crossOrigin = 'anonymous';

		this.side = (this.options.side !== undefined) ? this.options.side : FrontSide;
		this.wrap = (this.options.wrap !== undefined) ? this.options.wrap : RepeatWrapping;
	}

	public function setCrossOrigin(value:String):MaterialCreator {
		this.crossOrigin = value;
		return this;
	}

	public function setManager(value:Dynamic):MaterialCreator {
		this.manager = value;
		return this;
	}

	public function setMaterials(materialsInfo:Dynamic):MaterialCreator {
		this.materialsInfo = this.convert(materialsInfo);
		this.materials = {};
		this.materialsArray = [];
		this.nameLookup = {};
		return this;
	}

	public function convert(materialsInfo:Dynamic):Dynamic {
		if (this.options == null) return materialsInfo;

		var converted:Dynamic = {};

		for (mn in materialsInfo) {
			// Convert materials info into normalized form based on options

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

						// Diffuse color (color under white light) using RGB values

						if (this.options && this.options.normalizeRGB) {
							value = [value[0] / 255, value[1] / 255, value[2] / 255];
						}

						if (this.options && this.options.ignoreZeroRGBs) {
							if (value[0] == 0 && value[1] == 0 && value[2] == 0) {
								// ignore

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

	public function preload():MaterialCreator {
		for (mn in this.materialsInfo) {
			this.create(mn);
		}
		return this;
	}

	public function getIndex(materialName:String):Int {
		return this.nameLookup[materialName];
	}

	public function getAsArray():Array<Dynamic> {
		let index = 0;

		for (mn in this.materialsInfo) {
			this.materialsArray[index] = this.create(mn);
			this.nameLookup[mn] = index;
			index++;
		}

		return this.materialsArray;
	}

	public function create(materialName:String):Dynamic {
		if (this.materials[materialName] == undefined) {
			this.createMaterial_(materialName);
		}

		return this.materials[materialName];
	}

	public function createMaterial_(materialName:String):Dynamic {
		// Create material

		var scope = this;
		var mat = this.materialsInfo[materialName];
		var params:Dynamic = {
			name: materialName,
			side: this.side
		};

		function resolveURL(baseUrl:String, url:String):String {
			if (Type.typeof(url) != String || url == '') return '';

			// Absolute URL
			if (~url.indexOf('://')) return url;

			return baseUrl + url;
		}

		function setMapForType(mapType:String, value:String) {
			if (params[mapType]) return; // Keep the first encountered texture

			var texParams = scope.getTextureParams(value, params);
			var map = TextureUtils.loadTexture(resolveURL(scope.baseUrl, texParams.url));

			map.repeat.set(texParams.scale.x, texParams.scale.y);
			map.offset.set(texParams.offset.x, texParams.offset.y);

			map.wrapS = this.wrap;
			map.wrapT = this.wrap;

			if (mapType == 'map' || mapType == 'emissiveMap') {
				map.colorSpace = SRGBColorSpace;
			}

			params[mapType] = map;
		}

		for (prop in mat) {
			var value = mat[prop];
			var n:Float;

			if (value == '') continue;

			switch (prop.toLowerCase()) {

				// Ns is material specular exponent

				case 'kd':

					// Diffuse color (color under white light) using RGB values

					params.color = new Color().fromArray(value);

					break;

				case 'ks':

					// Specular color (color when light is reflected from shiny surface) using RGB values
					params.specular = new Color().fromArray(value);

					break;

				case 'ke':

					// Emissive using RGB values
					params.emissive = new Color().fromArray(value);

					break;

				case 'map_kd':

					// Diffuse texture map

					setMapForType('map', value);

					break;

				case 'map_ks':

					// Specular map

					setMapForType('specularMap', value);

					break;

				case 'map_ke':

					// Emissive map

					setMapForType('emissiveMap', value);

					break;

				case 'norm':

					setMapForType('normalMap', value);

					break;

				case 'map_bump':
				case 'bump':

					// Bump texture map

					setMapForType('bumpMap', value);

					break;

				case 'map_d':

					// Alpha map

					setMapForType('alphaMap', value);
					params.transparent = true;

					break;

				case 'ns':

					// The specular exponent (defines the focus of the specular highlight)
					// A high exponent results in a tight, concentrated highlight. Ns values normally range from 0 to 1000.

					params.shininess = value;

					break;

				case 'd':
					n = Float.parseFloat(value);

					if (n < 1) {
						params.opacity = n;
						params.transparent = true;

					}

					break;

				case 'tr':
					n = Float.parseFloat(value);

					if (this.options && this.options.invertTrProperty) n = 1 - n;

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
		var pos;

		pos = items.indexOf('-bm');

		if (pos >= 0) {
			matParams.bumpScale = Float.parseFloat(items[pos + 1]);
			items.splice(pos, 2);

		}

		pos = items.indexOf('-s');

		if (pos >= 0) {
			texParams.scale.set(Float.parseFloat(items[pos + 1]), Float.parseFloat(items[pos + 2]));
			items.splice(pos, 4); // we expect 3 parameters here!

		}

		pos = items.indexOf('-o');

		if (pos >= 0) {
			texParams.offset.set(Float.parseFloat(items[pos + 1]), Float.parseFloat(items[pos + 2]));
			items.splice(pos, 4); // we expect 3 parameters here!

		}

		texParams.url = items.join(' ').trim();
		return texParams;

	}

	public function loadTexture(url:String, mapping:Int = 0, onLoad:Dynamic = null, onProgress:Dynamic = null, onError:Dynamic = null):Texture {

		var manager = (this.manager != undefined) ? this.manager : DefaultLoadingManager;
		var loader = manager.getHandler(url);

		if (loader == null) {

			loader = new TextureLoader(manager);

		}

		if (loader.setCrossOrigin != null) loader.setCrossOrigin(this.crossOrigin);

		var texture = loader.load(url, onLoad, onProgress, onError);

		if (mapping != 0) texture.mapping = mapping;

		return texture;
	}
}