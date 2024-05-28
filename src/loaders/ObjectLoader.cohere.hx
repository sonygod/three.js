import haxe.io.Bytes;
import js.Browser;
import js.html.Image;
import js.html.Window;
import js.node.Fs;
import js.node.buffer.Buffer;
import js.node.buffer.BufferView;
import js.typed_array.ArrayBufferView;
import js.typed_array.Float32Array;
import js.typed_array.Int16Array;
import js.typed_array.TypedArray;
import js.typed_array.Uint16Array;
import js.typed_array.Uint32Array;
import js.typed_array.Uint8Array;
import js.WebGL.WebGLRenderingContext;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DBufferUsage;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.Context3DMipFilter;
import openfl.display3D.Context3DProgramFormat;
import openfl.display3D.Context3DProfile;
import openfl.display3D.Context3DTextureFilter;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.Context3DTriangleFace;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.Context3DVertexBufferAtOffset;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.CubeTexture;
import openfl.display3D.textures.RectangleTexture;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.TextureBase;
import openfl.display3D.textures.VideoTexture;
import openfl.display3D.IndexBuffer3DBufferUsage;
import openfl.display3D.VertexBuffer3DBufferUsage;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix3D;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;
import openfl.utils.IByteArray;

class ObjectLoader extends Loader {
	public function new(manager:LoadingManager) {
		super(manager);
	}

	public function load(url:String, onLoad:Function, onProgress:Function, onError:Function):Void {
		var scope = this;
		var path = (this.path == '') ? LoaderUtils.extractUrlBase(url) : this.path;
		this.resourcePath = this.resourcePath != null ? this.resourcePath : path;
		var loader = new FileLoader(this.manager);
		loader.path = this.path;
		loader.requestHeader = this.requestHeader;
		loader.withCredentials = this.withCredentials;
		loader.load(url, function(text) {
			var json = null;
			try {
				json = Json.parse(text);
			} catch(error) {
				if (onError != null) onError(error);
				trace('THREE:ObjectLoader: Can\'t parse $url.', error.message);
				return;
			}
			var metadata = json.metadata;
			if (metadata == null || metadata.type == null || HxOverrides.strToLower(metadata.type) == 'geometry') {
				if (onError != null) onError(new Error('THREE.ObjectLoader: Can\'t load $url'));
				trace('THREE.ObjectLoader: Can\'t load $url');
				return;
			}
			scope.parse(json, onLoad);
		}, onProgress, onError);
	}

	public function loadAsync(url:String, onProgress:Function):Async<Dynamic> {
		var scope = this;
		var path = (this.path == '') ? LoaderUtils.extractUrlBase(url) : this.path;
		this.resourcePath = this.resourcePath != null ? this.resourcePath : path;
		var loader = new FileLoader(this.manager);
		loader.path = this.path;
		loader.requestHeader = this.requestHeader;
		loader.withCredentials = this.withCredentials;
		return loader.loadAsync(url, onProgress).then(function(text) {
			var json = Json.parse(text);
			var metadata = json.metadata;
			if (metadata == null || metadata.type == null || HxOverrides.strToLower(metadata.type) == 'geometry') {
				throw new Error('THREE.ObjectLoader: Can\'t load $url');
			}
			return scope.parseAsync(json);
		});
	}

	public function parse(json:Dynamic, onLoad:Dynamic):Dynamic {
		var animations = this.parseAnimations(json.animations);
		var shapes = this.parseShapes(json.shapes);
		var geometries = this.parseGeometries(json.geometries, shapes);
		var images = this.parseImages(json.images, function() {
			if (onLoad != null) onLoad(object);
		});
		var textures = this.parseTextures(json.textures, images);
		var materials = this.parseMaterials(json.materials, textures);
		var object = this.parseObject(json.object, geometries, materials, textures, animations);
		var skeletons = this.parseSkeletons(json.skeletons, object);
		this.bindSkeletons(object, skeletons);
		if (onLoad != null) {
			var hasImages = false;
			var uuid in images;
			while(uuid != null) {
				var image = images[uuid];
				if (Reflect.hasField(image, 'data') && Std.is(image.data, Html.Image)) {
					hasImages = true;
					break;
				}
				uuid = try { field(images, uuid); } catch( _g ) { null; }
			}
			if (hasImages == false) onLoad(object);
		}
		return object;
	}

	public function parseAsync(json:Dynamic):Async<Dynamic> {
		var animations = this.parseAnimations(json.animations);
		var shapes = this.parseShapes(json.shapes);
		var geometries = this.parseGeometries(json.geometries, shapes);
		return this.parseImagesAsync(json.images).then(function(images) {
			var textures = this.parseTextures(json.textures, images);
			var materials = this.parseMaterials(json.materials, textures);
			var object = this.parseObject(json.object, geometries, materials, textures, animations);
			var skeletons = this.parseSkeletons(json.skeletons, object);
			this.bindSkeletons(object, skeletons);
			return object;
		});
	}

	public function parseShapes(json:Dynamic):Dynamic {
		var shapes = new haxe.ds.StringMap();
		if (json != null) {
			var _g = 0;
			while(_g < json.length) {
				var i = _g++;
				var shape = new Shape();
				shape.fromJSON(Std.string(json[i]));
				shapes[shape.uuid] = shape;
			}
		}
		return shapes;
	}

	public function parseSkeletons(json:Dynamic, object:Dynamic):Dynamic {
		var skeletons = new haxe.ds.StringMap();
		var bones = new haxe.ds.StringMap();
		object.traverse(function(child) {
			if (child.isBone) bones[child.uuid] = child;
		});
		if (json != null) {
			var _g = 0;
			while(_g < json.length) {
				var i = _g++;
				var skeleton = new Skeleton();
				skeleton.fromJSON(Std.string(json[i]), bones);
				skeletons[skeleton.uuid] = skeleton;
			}
		}
		return skeletons;
	}

	public function parseGeometries(json:Dynamic, shapes:Dynamic):Dynamic {
		var geometries = new haxe.ds.StringMap();
		if (json != null) {
			var bufferGeometryLoader = new BufferGeometryLoader();
			var _g = 0;
			while(_g < json.length) {
				var i = _g++;
				var data = json[i];
				var geometry;
				switch(data.type) {
				case "BufferGeometry":
				case "InstancedBufferGeometry":
					geometry = bufferGeometryLoader.parse(data);
					break;
				default:
					if (Reflect.hasField(Geometries, data.type)) {
						geometry = Reflect.field(Geometries, data.type).fromJSON(data, shapes);
					} else {
						trace('THREE.ObjectLoader: Unsupported geometry type "${data.type}"');
					}
				}
				geometry.uuid = data.uuid;
				if (data.name != null) geometry.name = data.name;
				if (data.userData != null) geometry.userData = data.userData;
				geometries[data.uuid] = geometry;
			}
		}
		return geometries;
	}

	public function parseMaterials(json:Dynamic, textures:Dynamic):Dynamic {
		var cache = new haxe.ds.StringMap();
		var materials = new haxe.ds.StringMap();
		if (json != null) {
			var loader = new MaterialLoader();
			loader.textures = textures;
			var _g = 0;
			while(_g < json.length) {
				var i = _g++;
				var data = json[i];
				if (cache.exists(data.uuid)) continue;
				cache[data.uuid] = loader.parse(data);
				materials[data.uuid] = cache[data.uuid];
			}
		}
		return materials;
	}

	public function parseAnimations(json:Dynamic):Dynamic {
		var animations = new haxe.ds.StringMap();
		if (json != null) {
			var _g = 0;
			while(_g < json.length) {
				var i = _g++;
				var data = json[i];
				var clip = AnimationClip.parse(data);
				animations[clip.uuid] = clip;
			}
		}
		return animations;
	}

	public function parseImages(json:Dynamic, onLoad:Dynamic):Dynamic {
		var scope = this;
		var images = new haxe.ds.StringMap();
		var loadImage = function(url) {
			scope.manager.itemStart(url);
			return loader.load(url, function() {
				scope.manager.itemEnd(url);
			}, null, function() {
				scope.manager.itemError(url);
				scope.manager.itemEnd(url);
			});
		};
		var deserializeImage = function(image) {
			if (typeof(image) == 'string') {
				var url = image;
				var path = Url.urlDecode(url);
				if (Url.urlMatch(path, '^(\\/\\/)|([a-z]+:\\/\\/)')) path = scope.resourcePath + url;
				return loadImage(path);
			} else {
				if (image.data != null) {
					return { data : getTypedArray(image.type, image.data), width : image.width, height : image.height};
				} else {
					return null;
				}
			}
		};
		if (json != null && json.length > 0) {
			var manager = new LoadingManager(onLoad);
			loader = new ImageLoader(manager);
			loader.crossOrigin = this.crossOrigin;
			var _g = 0;
			while(_g < json.length) {
				var i = _g++;
				var image = json[i];
				var url = image.url;
				if (Reflect.isArray(url)) {
					var imageArray = [];
					var _g1 = 0;
					while(_g1 < url.length) {
						var j = _g1++;
						var currentUrl = url[j];
						var deserializedImage = deserializeImage(currentUrl);
						if (deserializedImage != null) {
							if (Std.is(deserializedImage, Html.Image)) {
								imageArray.push(deserializedImage);
							} else {
								var dataTexture = new DataTexture(deserializedImage.data, deserializedImage.width, deserializedImage.height);
								imageArray.push(dataTexture);
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

	public function parseImagesAsync(json:Dynamic):Async<Dynamic> {
		var scope = this;
		var images = new haxe.ds.StringMap();
		var deserializeImage = function(image) {
			if (typeof(image) == 'string') {
				var url = image;
				var path = Url.urlDecode(url);
				if (Url.urlMatch(path, '^(\\/\\/)|([a-z]+:\\/\\/)')) path = scope.resourcePath + url;
				return loader.loadAsync(path);
			} else {
				if (image.data != null) {
					return { data : getTypedArray(image.type, image.data), width : image.width, height : image.height};
				} else {
					return null;
				}
			}
		};
		if (json != null && json.length > 0) {
			loader = new ImageLoader(this.manager);
			loader.crossOrigin = this.crossOrigin;
			var _g = 0;
			while(_g < json.length) {
				var i = _g++;
				var image = json[i];
				var url = image.url;
				if (Reflect.isArray(url)) {
					var imageArray = [];
					var _g1 = 0;
					while(_g1 < url.length) {
						var j = _g1++;
						var currentUrl = url[j];
						var deserializedImage = deserializeImage(currentUrl);
						if (deserializedImage != null) {
							if (Std.is(deserializedImage, Html.Image)) {
								imageArray.push(deserializedImage);
							} else {
								var dataTexture = new DataTexture(deserializedImage.data, deserializedImage.width, deserializedImage.height);
								imageArray.push(dataTexture);
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

	public function parseTextures(json:Dynamic, images:Dynamic):Dynamic {
		var parseConstant = function(value, type) {
			if (typeof(value) == ValueType.TNumber) return value;
			trace('THREE.ObjectLoader.parseTexture: Constant should be in numeric form.', value);
			return Reflect.field(type, value);
		};
		var textures = new haxe.ds.StringMap();
		if (json != null) {
			var _g = 0;
			while(_g < json.length) {
				var i = _g++;
				var data = json[i];
				if (data.image == null) {
					trace('THREE.ObjectLoader: No "image" specified for', data.uuid);
				}
				if (images[data.image] == null) {
					trace('THREE.ObjectLoader: Undefined image', data.image);
				}
				var source = images[data.image];
				var image = source.data;
				var texture;
				if (Reflect.isArray(image)) {
					texture = new CubeTexture();
					if (image.length == 6) texture.needsUpdate = true;
				} else {
					if (image.data != null) {
						texture = new DataTexture();
					} else {
						texture = new Texture();
					}
					if (image != null) texture.needsUpdate =