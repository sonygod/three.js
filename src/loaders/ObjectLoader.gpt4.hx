```haxe
import three.constants.UVMapping;
import three.constants.CubeReflectionMapping;
import three.constants.CubeRefractionMapping;
import three.constants.EquirectangularReflectionMapping;
import three.constants.EquirectangularRefractionMapping;
import three.constants.CubeUVReflectionMapping;

import three.constants.RepeatWrapping;
import three.constants.ClampToEdgeWrapping;
import three.constants.MirroredRepeatWrapping;

import three.constants.NearestFilter;
import three.constants.NearestMipmapNearestFilter;
import three.constants.NearestMipmapLinearFilter;
import three.constants.LinearFilter;
import three.constants.LinearMipmapNearestFilter;
import three.constants.LinearMipmapLinearFilter;

import three.core.InstancedBufferAttribute;
import three.math.Color;
import three.core.Object3D;
import three.objects.Group;
import three.objects.InstancedMesh;
import three.objects.BatchedMesh;
import three.objects.Sprite;
import three.objects.Points;
import three.objects.Line;
import three.objects.LineLoop;
import three.objects.LineSegments;
import three.objects.LOD;
import three.objects.Mesh;
import three.objects.SkinnedMesh;
import three.objects.Bone;
import three.objects.Skeleton;
import three.extras.core.Shape;
import three.scenes.Fog;
import three.scenes.FogExp2;
import three.lights.HemisphereLight;
import three.lights.SpotLight;
import three.lights.PointLight;
import three.lights.DirectionalLight;
import three.lights.AmbientLight;
import three.lights.RectAreaLight;
import three.lights.LightProbe;
import three.cameras.OrthographicCamera;
import three.cameras.PerspectiveCamera;
import three.scenes.Scene;
import three.textures.CubeTexture;
import three.textures.Texture;
import three.textures.Source;
import three.textures.DataTexture;
import three.loaders.ImageLoader;
import three.loaders.LoadingManager;
import three.animation.AnimationClip;
import three.loaders.MaterialLoader;
import three.loaders.LoaderUtils;
import three.loaders.BufferGeometryLoader;
import three.loaders.Loader;
import three.loaders.FileLoader;
import three.geometries.Geometries;
import three.utils.TypedArrayUtils;
import three.math.Box3;
import three.math.Sphere;

class ObjectLoader extends Loader {

	public function new(manager:LoadingManager) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		var scope = this;
		var path = (this.path == '') ? LoaderUtils.extractUrlBase(url) : this.path;
		this.resourcePath = this.resourcePath != null ? this.resourcePath : path;

		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(text:String):Void {
			var json = null;
			try {
				json = JSON.parse(text);
			} catch (error:Dynamic) {
				if (onError != null) onError(error);
				trace('THREE:ObjectLoader: Can\'t parse ' + url + '.', error.message);
				return;
			}

			var metadata = json.metadata;
			if (metadata == null || metadata.type == null || metadata.type.toLowerCase() == 'geometry') {
				if (onError != null) onError(new Error('THREE.ObjectLoader: Can\'t load ' + url));
				trace('THREE.ObjectLoader: Can\'t load ' + url);
				return;
			}

			scope.parse(json, onLoad);
		}, onProgress, onError);
	}

	public function loadAsync(url:String, onProgress:Dynamic):Promise<Dynamic> {
		var scope = this;
		var path = (this.path == '') ? LoaderUtils.extractUrlBase(url) : this.path;
		this.resourcePath = this.resourcePath != null ? this.resourcePath : path;

		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);

		return loader.loadAsync(url, onProgress).then(function(text:String):Dynamic {
			var json = JSON.parse(text);
			var metadata = json.metadata;

			if (metadata == null || metadata.type == null || metadata.type.toLowerCase() == 'geometry') {
				throw new Error('THREE.ObjectLoader: Can\'t load ' + url);
			}

			return scope.parseAsync(json);
		});
	}

	public function parse(json:Dynamic, onLoad:Dynamic):Object3D {
		var animations = this.parseAnimations(json.animations);
		var shapes = this.parseShapes(json.shapes);
		var geometries = this.parseGeometries(json.geometries, shapes);

		var images = this.parseImages(json.images, function():Void {
			if (onLoad != null) onLoad(object);
		});

		var textures = this.parseTextures(json.textures, images);
		var materials = this.parseMaterials(json.materials, textures);

		var object = this.parseObject(json.object, geometries, materials, textures, animations);
		var skeletons = this.parseSkeletons(json.skeletons, object);

		this.bindSkeletons(object, skeletons);

		if (onLoad != null) {
			var hasImages = false;
			for (uuid in images) {
				if (Std.is(images[uuid].data, Image)) {
					hasImages = true;
					break;
				}
			}

			if (!hasImages) onLoad(object);
		}

		return object;
	}

	public function parseAsync(json:Dynamic):Promise<Object3D> {
		var animations = this.parseAnimations(json.animations);
		var shapes = this.parseShapes(json.shapes);
		var geometries = this.parseGeometries(json.geometries, shapes);

		return this.parseImagesAsync(json.images).then(function(images:Dynamic):Dynamic {
			var textures = this.parseTextures(json.textures, images);
			var materials = this.parseMaterials(json.materials, textures);

			var object = this.parseObject(json.object, geometries, materials, textures, animations);
			var skeletons = this.parseSkeletons(json.skeletons, object);

			this.bindSkeletons(object, skeletons);

			return object;
		}.bind(this));
	}

	public function parseShapes(json:Dynamic):Map<String, Shape> {
		var shapes = new Map<String, Shape>();

		if (json != null) {
			for (i in 0...json.length) {
				var shape = new Shape().fromJSON(json[i]);
				shapes.set(shape.uuid, shape);
			}
		}

		return shapes;
	}

	public function parseSkeletons(json:Dynamic, object:Object3D):Map<String, Skeleton> {
		var skeletons = new Map<String, Skeleton>();
		var bones = new Map<String, Bone>();

		object.traverse(function(child:Object3D):Void {
			if (child.isBone) bones.set(child.uuid, child);
		});

		if (json != null) {
			for (i in 0...json.length) {
				var skeleton = new Skeleton().fromJSON(json[i], bones);
				skeletons.set(skeleton.uuid, skeleton);
			}
		}

		return skeletons;
	}

	public function parseGeometries(json:Dynamic, shapes:Map<String, Shape>):Map<String, Dynamic> {
		var geometries = new Map<String, Dynamic>();

		if (json != null) {
			var bufferGeometryLoader = new BufferGeometryLoader();

			for (i in 0...json.length) {
				var geometry;
				var data = json[i];

				switch (data.type) {
					case 'BufferGeometry', 'InstancedBufferGeometry':
						geometry = bufferGeometryLoader.parse(data);
						break;
					default:
						if (Reflect.hasField(Geometries, data.type)) {
							geometry = Reflect.field(Geometries, data.type).fromJSON(data, shapes);
						} else {
							trace('THREE.ObjectLoader: Unsupported geometry type "' + data.type + '"');
						}
				}

				geometry.uuid = data.uuid;
				if (data.name != null) geometry.name = data.name;
				if (data.userData != null) geometry.userData = data.userData;

				geometries.set(data.uuid, geometry);
			}
		}

		return geometries;
	}

	public function parseMaterials(json:Dynamic, textures:Map<String, Texture>):Map<String, Dynamic> {
		var cache = new Map<String, Dynamic>();
		var materials = new Map<String, Dynamic>();

		if (json != null) {
			var loader = new MaterialLoader();
			loader.setTextures(textures);

			for (i in 0...json.length) {
				var data = json[i];

				if (!cache.exists(data.uuid)) {
					cache.set(data.uuid, loader.parse(data));
				}

				materials.set(data.uuid, cache.get(data.uuid));
			}
		}

		return materials;
	}

	public function parseAnimations(json:Dynamic):Map<String, AnimationClip> {
		var animations = new Map<String, AnimationClip>();

		if (json != null) {
			for (i in 0...json.length) {
				var data = json[i];
				var clip = AnimationClip.parse(data);
				animations.set(clip.uuid, clip);
			}
		}

		return animations;
	}

	public function parseImages(json:Dynamic, onLoad:Dynamic):Map<String, Source> {
		var scope = this;
		var images = new Map<String, Source>();
		var loader:ImageLoader;

		function loadImage(url:String):Void {
			scope.manager.itemStart(url);
			loader.load(url, function():Void {
				scope.manager.itemEnd(url);
			