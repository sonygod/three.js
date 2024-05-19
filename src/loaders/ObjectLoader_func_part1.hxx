import three.src.loaders.ObjectLoader_func_part1.*;

class ObjectLoader extends Loader {

	public function new(manager:Dynamic) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		var scope = this;
		var path = (this.path == "") ? LoaderUtils.extractUrlBase(url) : this.path;
		this.resourcePath = this.resourcePath || path;
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(text:String) {
			var json:Dynamic = null;
			try {
				json = Json.parse(text);
			} catch (error:Dynamic) {
				if (onError != undefined) onError(error);
				trace('THREE:ObjectLoader: Can\'t parse ' + url + '.', error.message);
				return;
			}
			var metadata:Dynamic = json.metadata;
			if (metadata == undefined || metadata.type == undefined || metadata.type.toLowerCase() == 'geometry') {
				if (onError != undefined) onError(new Error('THREE.ObjectLoader: Can\'t load ' + url));
				trace('THREE.ObjectLoader: Can\'t load ' + url);
				return;
			}
			scope.parse(json, onLoad);
		}, onProgress, onError);
	}

	public function loadAsync(url:String, onProgress:Dynamic):Dynamic {
		var scope = this;
		var path = (this.path == "") ? LoaderUtils.extractUrlBase(url) : this.path;
		this.resourcePath = this.resourcePath || path;
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		var text = await loader.loadAsync(url, onProgress);
		var json = Json.parse(text);
		var metadata:Dynamic = json.metadata;
		if (metadata == undefined || metadata.type == undefined || metadata.type.toLowerCase() == 'geometry') {
			throw new Error('THREE.ObjectLoader: Can\'t load ' + url);
		}
		return await scope.parseAsync(json);
	}

	public function parse(json:Dynamic, onLoad:Dynamic):Dynamic {
		var animations = this.parseAnimations(json.animations);
		var shapes = this.parseShapes(json.shapes);
		var geometries = this.parseGeometries(json.geometries, shapes);
		var images = this.parseImages(json.images, function() {
			if (onLoad != undefined) onLoad(object);
		});
		var textures = this.parseTextures(json.textures, images);
		var materials = this.parseMaterials(json.materials, textures);
		var object = this.parseObject(json.object, geometries, materials, textures, animations);
		var skeletons = this.parseSkeletons(json.skeletons, object);
		this.bindSkeletons(object, skeletons);
		if (onLoad != undefined) {
			var hasImages:Bool = false;
			for (uuid in images) {
				if (images[uuid].data instanceof HTMLImageElement) {
					hasImages = true;
					break;
				}
			}
			if (hasImages == false) onLoad(object);
		}
		return object;
	}

	public function parseAsync(json:Dynamic):Dynamic {
		var animations = this.parseAnimations(json.animations);
		var shapes = this.parseShapes(json.shapes);
		var geometries = this.parseGeometries(json.geometries, shapes);
		var images = await this.parseImagesAsync(json.images);
		var textures = this.parseTextures(json.textures, images);
		var materials = this.parseMaterials(json.materials, textures);
		var object = this.parseObject(json.object, geometries, materials, textures, animations);
		var skeletons = this.parseSkeletons(json.skeletons, object);
		this.bindSkeletons(object, skeletons);
		return object;
	}

	public function parseShapes(json:Dynamic):Dynamic {
		var shapes:Dynamic = {};
		if (json != undefined) {
			for (i in json) {
				var shape = new Shape().fromJSON(json[i]);
				shapes[shape.uuid] = shape;
			}
		}
		return shapes;
	}

	public function parseSkeletons(json:Dynamic, object:Dynamic):Dynamic {
		var skeletons:Dynamic = {};
		var bones:Dynamic = {};
		object.traverse(function(child:Dynamic) {
			if (child.isBone) bones[child.uuid] = child;
		});
		if (json != undefined) {
			for (i in json) {
				var skeleton = new Skeleton().fromJSON(json[i], bones);
				skeletons[skeleton.uuid] = skeleton;
			}
		}
		return skeletons;
	}

	public function parseGeometries(json:Dynamic, shapes:Dynamic):Dynamic {
		var geometries:Dynamic = {};
		if (json != undefined) {
			var bufferGeometryLoader = new BufferGeometryLoader();
			for (i in json) {
				var geometry:Dynamic;
				var data = json[i];
				switch (data.type) {
					case 'BufferGeometry':
					case 'InstancedBufferGeometry':
						geometry = bufferGeometryLoader.parse(data);
						break;
					default:
						if (data.type in Geometries) {
							geometry = Geometries[data.type].fromJSON(data, shapes);
						} else {
							trace(`THREE.ObjectLoader: Unsupported geometry type "${data.type}"`);
						}
				}
				geometry.uuid = data.uuid;
				if (data.name != undefined) geometry.name = data.name;
				if (data.userData != undefined) geometry.userData = data.userData;
				geometries[data.uuid] = geometry;
			}
		}
		return geometries;
	}

	public function parseMaterials(json:Dynamic, textures:Dynamic):Dynamic {
		var cache:Dynamic = {}; // MultiMaterial
		var materials:Dynamic = {};
		if (json != undefined) {
			var loader = new MaterialLoader();
			loader.setTextures(textures);
			for (i in json) {
				var data = json[i];
				if (cache[data.uuid] == undefined) {
					cache[data.uuid] = loader.parse(data);
				}
				materials[data.uuid] = cache[data.uuid];
			}
		}
		return materials;
	}

	public function parseAnimations(json:Dynamic):Dynamic {
		var animations:Dynamic = {};
		if (json != undefined) {
			for (i in json) {
				var data = json[i];
				var clip = AnimationClip.parse(data);
				animations[clip.uuid] = clip;
			}
		}
		return animations;
	}

	public function parseImages(json:Dynamic, onLoad:Dynamic):Dynamic {
		var scope = this;
		var images:Dynamic = {};
		var loader:Dynamic;
		function loadImage(url:String):Dynamic {
			scope.manager.itemStart(url);
			return loader.load(url, function() {
				scope.manager.itemEnd(url);
			}, undefined, function() {
				scope.manager.itemError(url);
				scope.manager.itemEnd(url);
			});
		}
		function deserializeImage(image:Dynamic):Dynamic {
			if (typeof image == "string") {
				var url = image;
				var path = /^(\/\/)|([a-z]+:(\/\/)?)/i.test(url) ? url : scope.resourcePath + url;
				return loadImage(path);
			} else {
				if (image.data) {
					return {
						data: getTypedArray(image.type, image.data),
						width: image.width,
						height: image.height
					};
				} else {
					return null;
				}
			}
		}
		if (json != undefined && json.length > 0) {
			var manager = new LoadingManager(onLoad);
			loader = new ImageLoader(manager);
			loader.setCrossOrigin(this.crossOrigin);
			for (i in json) {
				var image = json[i];
				var url = image.url;
				if (Array.isArray(url)) {
					var imageArray:Array<Dynamic> = [];
					for (j in url) {
						var currentUrl = url[j];
						var deserializedImage = deserializeImage(currentUrl);
						if (deserializedImage != null) {
							if (deserializedImage instanceof HTMLImageElement) {
								imageArray.push(deserializedImage);
							} else {
								imageArray.push(new DataTexture(deserializedImage.data, deserializedImage.width, deserializedImage.height));
							}
						}
					}
					images[image.uuid] = new Source(imageArray);
				} else {
					var deserializedImage = deserializeImage(image.url);
					images[image.uuid] = new Source(deserializedImage);
				}
			}
		}
		return images;
	}
}