import three.core.Object3D;
import three.objects.Group;
import three.objects.Mesh;
import three.objects.SkinnedMesh;
import three.objects.Bone;
import three.objects.Skeleton;
import three.objects.Sprite;
import three.objects.Points;
import three.objects.Line;
import three.objects.LineLoop;
import three.objects.LineSegments;
import three.objects.LOD;
import three.objects.InstancedMesh;
import three.objects.BatchedMesh;
import three.lights.AmbientLight;
import three.lights.DirectionalLight;
import three.lights.PointLight;
import three.lights.SpotLight;
import three.lights.HemisphereLight;
import three.lights.RectAreaLight;
import three.lights.LightProbe;
import three.cameras.PerspectiveCamera;
import three.cameras.OrthographicCamera;
import three.scenes.Scene;
import three.textures.CubeTexture;
import three.textures.Texture;
import three.textures.DataTexture;
import three.textures.Source;
import three.math.Color;
import three.math.Box3;
import three.math.Sphere;
import three.core.InstancedBufferAttribute;
import three.extras.core.Shape;
import three.scenes.Fog;
import three.scenes.FogExp2;
import three.animation.AnimationClip;
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
import three.loaders.Loader;
import three.loaders.FileLoader;
import three.loaders.LoaderUtils;
import three.loaders.BufferGeometryLoader;
import three.loaders.ImageLoader;
import three.loaders.LoadingManager;
import three.geometries.Geometries;
import three.utils.Utils;

class ObjectLoader extends Loader {
	public function new(manager:LoadingManager) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var scope = this;
		var path = (this.path == "") ? LoaderUtils.extractUrlBase(url) : this.path;
		this.resourcePath = this.resourcePath != null ? this.resourcePath : path;
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(text:String) {
			var json:Dynamic;
			try {
				json = JSON.parse(text);
			} catch (error:Dynamic) {
				if (onError != null) onError(error);
				console.error('THREE:ObjectLoader: Can\'t parse ' + url + '.', error.message);
				return;
			}
			var metadata = json.metadata;
			if (metadata == null || metadata.type == null || metadata.type.toLowerCase() == "geometry") {
				if (onError != null) onError(new Error('THREE.ObjectLoader: Can\'t load ' + url));
				console.error('THREE.ObjectLoader: Can\'t load ' + url);
				return;
			}
			scope.parse(json, onLoad);
		}, onProgress, onError);
	}

	public function loadAsync(url:String, onProgress:Dynamic->Void):Dynamic {
		var scope = this;
		var path = (this.path == "") ? LoaderUtils.extractUrlBase(url) : this.path;
		this.resourcePath = this.resourcePath != null ? this.resourcePath : path;
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		return loader.loadAsync(url, onProgress).then(function(text:String) {
			var json = JSON.parse(text);
			var metadata = json.metadata;
			if (metadata == null || metadata.type == null || metadata.type.toLowerCase() == "geometry") {
				throw new Error('THREE.ObjectLoader: Can\'t load ' + url);
			}
			return scope.parseAsync(json);
		});
	}

	public function parse(json:Dynamic, onLoad:Dynamic->Void):Object3D {
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
			for (uuid in images) {
				if (images[uuid].data.isInstanceOf(HTMLImageElement)) {
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
		return this.parseImagesAsync(json.images).then(function(images:Dynamic) {
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
			for (i in 0...json.length) {
				var shape = new Shape().fromJSON(json[i]);
				shapes.set(shape.uuid, shape);
			}
		}
		return shapes;
	}

	public function parseSkeletons(json:Dynamic, object:Object3D):Dynamic {
		var skeletons = new haxe.ds.StringMap();
		var bones = new haxe.ds.StringMap();
		object.traverse(function(child:Object3D) {
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

	public function parseGeometries(json:Dynamic, shapes:Dynamic):Dynamic {
		var geometries = new haxe.ds.StringMap();
		if (json != null) {
			var bufferGeometryLoader = new BufferGeometryLoader();
			for (i in 0...json.length) {
				var geometry:Dynamic;
				var data = json[i];
				switch (data.type) {
					case "BufferGeometry":
					case "InstancedBufferGeometry":
						geometry = bufferGeometryLoader.parse(data);
						break;
					default:
						if (data.type in Geometries) {
							geometry = Reflect.callMethod(Geometries[data.type], "fromJSON", [data, shapes]);
						} else {
							console.warn('THREE.ObjectLoader: Unsupported geometry type "${data.type}"');
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

	public function parseMaterials(json:Dynamic, textures:Dynamic):Dynamic {
		var cache = new haxe.ds.StringMap();
		var materials = new haxe.ds.StringMap();
		if (json != null) {
			var loader = new MaterialLoader();
			loader.setTextures(textures);
			for (i in 0...json.length) {
				var data = json[i];
				if (cache.exists(data.uuid) == false) {
					cache.set(data.uuid, loader.parse(data));
				}
				materials.set(data.uuid, cache.get(data.uuid));
			}
		}
		return materials;
	}

	public function parseAnimations(json:Dynamic):Dynamic {
		var animations = new haxe.ds.StringMap();
		if (json != null) {
			for (i in 0...json.length) {
				var data = json[i];
				var clip = AnimationClip.parse(data);
				animations.set(clip.uuid, clip);
			}
		}
		return animations;
	}

	public function parseImages(json:Dynamic, onLoad:Dynamic->Void):Dynamic {
		var scope = this;
		var images = new haxe.ds.StringMap();
		var loader:ImageLoader;
		function loadImage(url:String):Dynamic {
			scope.manager.itemStart(url);
			return loader.load(url, function() {
				scope.manager.itemEnd(url);
			}, null, function() {
				scope.manager.itemError(url);
				scope.manager.itemEnd(url);
			});
		}
		function deserializeImage(image:Dynamic):Dynamic {
			if (typeof image == "string") {
				var url = image;
				var path = StringTools.startsWith(url, "//") || StringTools.match(url, /^[a-z]+:(\/\/)?/i) != null ? url : scope.resourcePath + url;
				return loadImage(path);
			} else {
				if (image.data != null) {
					return {
						data: Utils.getTypedArray(image.type, image.data),
						width: image.width,
						height: image.height
					};
				} else {
					return null;
				}
			}
		}
		if (json != null && json.length > 0) {
			var manager = new LoadingManager(onLoad);
			loader = new ImageLoader(manager);
			loader.setCrossOrigin(this.crossOrigin);
			for (i in 0...json.length) {
				var image = json[i];
				var url = image.url;
				if (Array.isOf(url)) {
					var imageArray = [];
					for (j in 0...url.length) {
						var currentUrl = url[j];
						var deserializedImage = deserializeImage(currentUrl);
						if (deserializedImage != null) {
							if (deserializedImage.isInstanceOf(HTMLImageElement)) {
								imageArray.push(deserializedImage);
							} else {
								imageArray.push(new DataTexture(deserializedImage.data, deserializedImage.width, deserializedImage.height));
							}
						}
					}
					images.set(image.uuid, new Source(imageArray));
				} else {
					var deserializedImage = deserializeImage(image.url);
					images.set(image.uuid, new Source(deserializedImage));
				}
			}
		}
		return images;
	}

	public function parseImagesAsync(json:Dynamic):Dynamic {
		var scope = this;
		var images = new haxe.ds.StringMap();
		var loader:ImageLoader;
		async function deserializeImage(image:Dynamic):Dynamic {
			if (typeof image == "string") {
				var url = image;
				var path = StringTools.startsWith(url, "//") || StringTools.match(url, /^[a-z]+:(\/\/)?/i) != null ? url : scope.resourcePath + url;
				return await loader.loadAsync(path);
			} else {
				if (image.data != null) {
					return {
						data: Utils.getTypedArray(image.type, image.data),
						width: image.width,
						height: image.height
					};
				} else {
					return null;
				}
			}
		}
		if (json != null && json.length > 0) {
			loader = new ImageLoader(this.manager);
			loader.setCrossOrigin(this.crossOrigin);
			for (i in 0...json.length) {
				var image = json[i];
				var url = image.url;
				if (Array.isOf(url)) {
					var imageArray = [];
					for (j in 0...url.length) {
						var currentUrl = url[j];
						var deserializedImage = await deserializeImage(currentUrl);
						if (deserializedImage != null) {
							if (deserializedImage.isInstanceOf(HTMLImageElement)) {
								imageArray.push(deserializedImage);
							} else {
								imageArray.push(new DataTexture(deserializedImage.data, deserializedImage.width, deserializedImage.height));
							}
						}
					}
					images.set(image.uuid, new Source(imageArray));
				} else {
					var deserializedImage = await deserializeImage(image.url);
					images.set(image.uuid, new Source(deserializedImage));
				}
			}
		}
		return images;
	}

	public function parseTextures(json:Dynamic, images:Dynamic):Dynamic {
		function parseConstant(value:Dynamic, type:Dynamic):Dynamic {
			if (typeof value == "number") return value;
			console.warn('THREE.ObjectLoader.parseTexture: Constant should be in numeric form.', value);
			return type[value];
		}
		var textures = new haxe.ds.StringMap();
		if (json != null) {
			for (i in 0...json.length) {
				var data = json[i];
				if (data.image == null) {
					console.warn('THREE.ObjectLoader: No "image" specified for', data.uuid);
				}
				if (images.exists(data.image) == false) {
					console.warn('THREE.ObjectLoader: Undefined image', data.image);
				}
				var source = images.get(data.image);
				var image = source.data;
				var texture:Dynamic;
				if (Array.isOf(image)) {
					texture = new CubeTexture();
					if (image.length == 6) texture.needsUpdate = true;
				} else {
					if (image != null && image.data != null) {
						texture = new DataTexture();
					} else {
						texture = new Texture();
					}
					if (image != null) texture.needsUpdate = true;
				}
				texture.source = source;
				texture.uuid = data.uuid;
				if (data.name != null) texture.name = data.name;
				if (data.mapping != null) texture.mapping = parseConstant(data.mapping, TEXTURE_MAPPING);
				if (data.channel != null) texture.channel = data.channel;
				if (data.offset != null) texture.offset.fromArray(data.offset);
				if (data.repeat != null) texture.repeat.fromArray(data.repeat);
				if (data.center != null) texture.center.fromArray(data.center);
				if (data.rotation != null) texture.rotation = data.rotation;
				if (data.wrap != null) {
					texture.wrapS = parseConstant(data.wrap[0], TEXTURE_WRAPPING);
					texture.wrapT = parseConstant(data.wrap[1], TEXTURE_WRAPPING);
				}
				if (data.format != null) texture.format = data.format;
				if (data.internalFormat != null) texture.internalFormat = data.internalFormat;
				if (data.type != null) texture.type = data.type;
				if (data.colorSpace != null) texture.colorSpace = data.colorSpace;
				if (data.minFilter != null) texture.minFilter = parseConstant(data.minFilter, TEXTURE_FILTER);
				if (data.magFilter != null) texture.magFilter = parseConstant(data.magFilter, TEXTURE_FILTER);
				if (data.anisotropy != null) texture.anisotropy = data.anisotropy;
				if (data.flipY != null) texture.flipY = data.flipY;
				if (data.generateMipmaps != null) texture.generateMipmaps = data.generateMipmaps;
				if (data.premultiplyAlpha != null) texture.premultiplyAlpha = data.premultiplyAlpha;
				if (data.unpackAlignment != null) texture.unpackAlignment = data.unpackAlignment;
				if (data.compareFunction != null) texture.compareFunction = data.compareFunction;
				if (data.userData != null) texture.userData = data.userData;
				textures.set(data.uuid, texture);
			}
		}
		return textures;
	}

	public function parseObject(data:Dynamic, geometries:Dynamic, materials:Dynamic, textures:Dynamic, animations:Dynamic):Object3D {
		var object:Object3D;
		function getGeometry(name:String):Dynamic {
			if (geometries.exists(name) == false) {
				console.warn('THREE.ObjectLoader: Undefined geometry', name);
			}
			return geometries.get(name);
		}
		function getMaterial(name:Dynamic):Dynamic {
			if (name == null) return null;
			if (Array.isOf(name)) {
				var array = [];
				for (i in 0...name.length) {
					var uuid = name[i];
					if (materials.exists(uuid) == false) {
						console.warn('THREE.ObjectLoader: Undefined material', uuid);
					}
					array.push(materials.get(uuid));
				}
				return array;
			}
			if (materials.exists(name) == false) {
				console.warn('THREE.ObjectLoader: Undefined material', name);
			}
			return materials.get(name);
		}
		function getTexture(uuid:String):Dynamic {
			if (textures.exists(uuid) == false) {
				console.warn('THREE.ObjectLoader: Undefined texture', uuid);
			}
			return textures.get(uuid);
		}
		var geometry:Dynamic;
		var material:Dynamic;
		switch (data.type) {
			case "Scene":
				object = new Scene();
				if (data.background != null) {
					if (Std.is(data.background, Int)) {
						object.background = new Color(data.background);
					} else {
						object.background = getTexture(data.background);
					}
				}
				if (data.environment != null) {
					object.environment = getTexture(data.environment);
				}
				if (data.fog != null) {
					if (data.fog.type == "Fog") {
						object.fog = new Fog(data.fog.color, data.fog.near, data.fog.far);
					} else if (data.fog.type == "FogExp2") {
						object.fog = new FogExp2(data.fog.color, data.fog.density);
					}
					if (data.fog.name != "") {
						object.fog.name = data.fog.name;
					}
				}
				if (data.backgroundBlurriness != null) object.backgroundBlurriness = data.backgroundBlurriness;
				if (data.backgroundIntensity != null) object.backgroundIntensity = data.backgroundIntensity;
				if (data.backgroundRotation != null) object.backgroundRotation.fromArray(data.backgroundRotation);
				if (data.environmentIntensity != null) object.environmentIntensity = data.environmentIntensity;
				if (data.environmentRotation != null) object.environmentRotation.fromArray(data.environmentRotation);
				break;
			case "PerspectiveCamera":
				object = new PerspectiveCamera(data.fov, data.aspect, data.near, data.far);
				if (data.focus != null) object.focus = data.focus;
				if (data.zoom != null) object.zoom = data.zoom;
				if (data.filmGauge != null) object.filmGauge = data.filmGauge;
				if (data.filmOffset != null) object.filmOffset = data.filmOffset;
				if (data.view != null) object.view = haxe.ds.StringMap.fromObject(data.view);
				break;
			case "OrthographicCamera":
				object = new OrthographicCamera(data.left, data.right, data.top, data.bottom, data.near, data.far);
				if (data.zoom != null) object.zoom = data.zoom;
				if (data.view != null) object.view = haxe.ds.StringMap.fromObject(data.view);
				break;
			case "AmbientLight":
				object = new AmbientLight(data.color, data.intensity);
				break;
			case "DirectionalLight":
				object = new DirectionalLight(data.color, data.intensity);
				break;
			case "PointLight":
				object = new PointLight(data.color, data.intensity, data.distance, data.decay);
				break;
			case "RectAreaLight":
				object = new RectAreaLight(data.color, data.intensity, data.width, data.height);
				break;
			case "SpotLight":
				object = new SpotLight(data.color, data.intensity, data.distance, data.angle, data.penumbra, data.decay);
				break;
			case "HemisphereLight":
				object = new HemisphereLight(data.color, data.groundColor, data.intensity);
				break;
			case "LightProbe":
				object = new LightProbe().fromJSON(data);
				break;
			case "SkinnedMesh":
				geometry = getGeometry(data.geometry);
				material = getMaterial(data.material);
				object = new SkinnedMesh(geometry, material);
				if (data.bindMode != null) object.bindMode = data.bindMode;
				if (data.bindMatrix != null) object.bindMatrix.fromArray(data.bindMatrix);
				if (data.skeleton != null) object.skeleton = data.skeleton;
				break;
			case "Mesh":
				geometry = getGeometry(data.geometry);
				material = getMaterial(data.material);
				object = new Mesh(geometry, material);
				break;
			case "InstancedMesh":
				geometry = getGeometry(data.geometry);
				material = getMaterial(data.material);
				var count = data.count;
				var instanceMatrix = data.instanceMatrix;
				var instanceColor = data.instanceColor;
				object = new InstancedMesh(geometry, material, count);
				object.instanceMatrix = new InstancedBufferAttribute(new Float32Array(instanceMatrix.array), 16);
				if (instanceColor != null) object.instanceColor = new InstancedBufferAttribute(new Float32Array(instanceColor.array), instanceColor.itemSize);
				break;
			case "BatchedMesh":
				geometry = getGeometry(data.geometry);
				material = getMaterial(data.material);
				object = new BatchedMesh(data.maxGeometryCount, data.maxVertexCount, data.maxIndexCount, material);
				object.geometry = geometry;
				object.perObjectFrustumCulled = data.perObjectFrustumCulled;
				object.sortObjects = data.sortObjects;
				object._drawRanges = data.drawRanges;
				object._reservedRanges = data.reservedRanges;
				object._visibility = data.visibility;
				object._active = data.active;
				object._bounds = data.bounds.map(function(bound:Dynamic) {
					var box = new Box3();
					box.min.fromArray(bound.boxMin);
					box.max.fromArray(bound.boxMax);
					var sphere = new Sphere();
					sphere.radius = bound.sphereRadius;
					sphere.center.fromArray(bound.sphereCenter);
					return {
						boxInitialized: bound.boxInitialized,
						box: box,
						sphereInitialized: bound.sphereInitialized,
						sphere: sphere
					};
				});
				object._maxGeometryCount = data.maxGeometryCount;
				object._maxVertexCount = data.maxVertexCount;
				object._maxIndexCount = data.maxIndexCount;
				object._geometryInitialized = data.geometryInitialized;
				object._geometryCount = data.geometryCount;
				object._matricesTexture = getTexture(data.matricesTexture.uuid);
				if (data.colorsTexture != null) object._colorsTexture = getTexture(data.colorsTexture.uuid);
				break;
			case "LOD":
				object = new LOD();
				break;
			case "Line":
				object = new Line(getGeometry(data.geometry), getMaterial(data.material));
				break;
			case "LineLoop":
				object = new LineLoop(getGeometry(data.geometry), getMaterial(data.material));
				break;
			case "LineSegments":
				object = new LineSegments(getGeometry(data.geometry), getMaterial(data.material));
				break;
			case "PointCloud":
			case "Points":
				object = new Points(getGeometry(data.geometry), getMaterial(data.material));
				break;
			case "Sprite":
				object = new Sprite(getMaterial(data.material));
				break;
			case "Group":
				object = new Group();
				break;
			case "Bone":
				object = new Bone();
				break;
			default:
				object = new Object3D();
		}
		object.uuid = data.uuid;
		if (data.name != null) object.name = data.name;
		if (data.matrix != null) {
			object.matrix.fromArray(data.matrix);
			if (data.matrixAutoUpdate != null) object.matrixAutoUpdate = data.matrixAutoUpdate;
			if (object.matrixAutoUpdate) object.matrix.decompose(object.position, object.quaternion, object.scale);
		} else {
			if (data.position != null) object.position.fromArray(data.position);
			if (data.rotation != null) object.rotation.fromArray(data.rotation);
			if (data.quaternion != null) object.quaternion.fromArray(data.quaternion);
			if (data.scale != null) object.scale.fromArray(data.scale);
		}
		if (data.up != null) object.up.fromArray(data.up);
		if (data.castShadow != null) object.castShadow = data.castShadow;
		if (data.receiveShadow != null) object.receiveShadow = data.receiveShadow;
		if (data.shadow != null) {
			if (data.shadow.bias != null) object.shadow.bias = data.shadow.bias;
			if (data.shadow.normalBias != null) object.shadow.normalBias = data.shadow.normalBias;
			if (data.shadow.radius != null) object.shadow.radius = data.shadow.radius;
			if (data.shadow.mapSize != null) object.shadow.mapSize.fromArray(data.shadow.mapSize);
			if (data.shadow.camera != null) object.shadow.camera = this.parseObject(data.shadow.camera);
		}
		if (data.visible != null) object.visible = data.visible;
		if (data.frustumCulled != null) object.frustumCulled = data.frustumCulled;
		if (data.renderOrder != null) object.renderOrder = data.renderOrder;
		if (data.userData != null) object.userData = data.userData;
		if (data.layers != null) object.layers.mask = data.layers;
		if (data.children != null) {
			var children = data.children;
			for (i in 0...children.length) {
				object.add(this.parseObject(children[i], geometries, materials, textures, animations));
			}
		}
		if (data.animations != null) {
			var objectAnimations = data.animations;
			for (i in 0...objectAnimations.length) {
				var uuid = objectAnimations[i];
				object.animations.push(animations.get(uuid));
			}
		}
		if (data.type == "LOD") {
			if (data.autoUpdate != null) object.autoUpdate = data.autoUpdate;
			var levels = data.levels;
			for (l in 0...levels.length) {
				var level = levels[l];
				var child = object.getObjectByProperty("uuid", level.object);
				if (child != null) {
					object.addLevel(child, level.distance, level.hysteresis);
				}
			}
		}
		return object;
	}

	public function bindSkeletons(object:Object3D, skeletons:Dynamic):Void {
		if (skeletons.keys().length == 0) return;
		object.traverse(function(child:Object3D) {
			if (child.isSkinnedMesh && child.skeleton != null) {
				var skeleton = skeletons.get(child.skeleton);
				if (skeleton == null) {
					console.warn('THREE.ObjectLoader: No skeleton found with UUID:', child.skeleton);
				} else {
					child.bind(skeleton, child.bindMatrix);
				}
			}
		});
	}
}

var TEXTURE_MAPPING = {
	UVMapping: UVMapping,
	CubeReflectionMapping: CubeReflectionMapping,
	CubeRefractionMapping: CubeRefractionMapping,
	EquirectangularReflectionMapping: EquirectangularReflectionMapping,
	EquirectangularRefractionMapping: EquirectangularRefractionMapping,
	CubeUVReflectionMapping: CubeUVReflectionMapping
};

var TEXTURE_WRAPPING = {
	RepeatWrapping: RepeatWrapping,
	ClampToEdgeWrapping: ClampToEdgeWrapping,
	MirroredRepeatWrapping: MirroredRepeatWrapping
};

var TEXTURE_FILTER = {
	NearestFilter: NearestFilter,
	NearestMipmapNearestFilter: NearestMipmapNearestFilter,
	NearestMipmapLinearFilter: NearestMipmapLinearFilter,
	LinearFilter: LinearFilter,
	LinearMipmapNearestFilter: LinearMipmapNearestFilter,
	LinearMipmapLinearFilter: LinearMipmapLinearFilter
};