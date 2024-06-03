import three.extras.loaders.BufferGeometryLoader;
import three.textures.CanvasTexture;
import three.constants.Wrapping;
import three.math.Color;
import three.lights.DirectionalLight;
import three.constants.Side;
import three.loaders.FileLoader;
import three.constants.Filters;
import three.objects.Line;
import three.materials.LineBasicMaterial;
import three.loaders.Loader;
import three.math.Matrix4;
import three.objects.Mesh;
import three.materials.MeshPhysicalMaterial;
import three.materials.MeshStandardMaterial;
import three.core.Object3D;
import three.lights.PointLight;
import three.objects.Points;
import three.materials.PointsMaterial;
import three.lights.RectAreaLight;
import three.objects.Sprite;
import three.materials.SpriteMaterial;
import three.textures.TextureLoader;
import three.extras.loaders.EXRLoader;

class Rhino3dmLoader extends Loader {
	public var libraryPath:String;
	public var libraryPending:Dynamic;
	public var libraryBinary:Dynamic;
	public var libraryConfig:Dynamic;
	public var url:String;
	public var workerLimit:Int;
	public var workerPool:Array<Dynamic>;
	public var workerNextTaskID:Int;
	public var workerSourceURL:String;
	public var workerConfig:Dynamic;
	public var materials:Array<Dynamic>;
	public var warnings:Array<Dynamic>;

	public function new(manager:Dynamic) {
		super(manager);

		this.libraryPath = "";
		this.libraryPending = null;
		this.libraryBinary = null;
		this.libraryConfig = {};

		this.url = "";

		this.workerLimit = 4;
		this.workerPool = [];
		this.workerNextTaskID = 1;
		this.workerSourceURL = "";
		this.workerConfig = {};

		this.materials = [];
		this.warnings = [];
	}

	public function setLibraryPath(path:String):Rhino3dmLoader {
		this.libraryPath = path;
		return this;
	}

	public function setWorkerLimit(workerLimit:Int):Rhino3dmLoader {
		this.workerLimit = workerLimit;
		return this;
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		var loader = new FileLoader(this.manager);

		loader.setPath(this.path);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(this.requestHeader);

		this.url = url;

		loader.load(url, (buffer) => {
			if (_taskCache.has(buffer)) {
				var cachedTask = _taskCache.get(buffer);
				cachedTask.promise.then(onLoad).catch(onError);
				return;
			}

			this.decodeObjects(buffer, url)
				.then(result => {
					result.userData.warnings = this.warnings;
					onLoad(result);
				})
				.catch(e => onError(e));
		}, onProgress, onError);
	}

	public function debug():Void {
		console.log("Task load: ", this.workerPool.map((worker) => worker._taskLoad));
	}

	public function decodeObjects(buffer:haxe.io.Bytes, url:String):Dynamic {
		var worker:Dynamic;
		var taskID:Int;

		var taskCost = buffer.length;

		var objectPending = this._getWorker(taskCost)
			.then((_worker) => {
				worker = _worker;
				taskID = this.workerNextTaskID++;
				return new Promise((resolve, reject) => {
					worker._callbacks[taskID] = {resolve:resolve, reject:reject};
					worker.postMessage({type:"decode", id:taskID, buffer:buffer}, [buffer]);
				});
			})
			.then((message) => this._createGeometry(message.data))
			.catch(e => {
				throw e;
			});

		objectPending
			.catch(() => true)
			.then(() => {
				if (worker && taskID) {
					this._releaseTask(worker, taskID);
				}
			});

		_taskCache.set(buffer, {
			url:url,
			promise:objectPending
		});

		return objectPending;
	}

	public function parse(data:haxe.io.Bytes, onLoad:Dynamic, onError:Dynamic):Void {
		this.decodeObjects(data, "")
			.then(result => {
				result.userData.warnings = this.warnings;
				onLoad(result);
			})
			.catch(e => onError(e));
	}

	public function _compareMaterials(material:Dynamic):Dynamic {
		var mat:Dynamic = {};
		mat.name = material.name;
		mat.color = {};
		mat.color.r = material.color.r;
		mat.color.g = material.color.g;
		mat.color.b = material.color.b;
		mat.type = material.type;
		mat.vertexColors = material.vertexColors;

		var json = haxe.Json.stringify(mat);

		for (var i = 0; i < this.materials.length; i++) {
			var m = this.materials[i];
			var _mat:Dynamic = {};
			_mat.name = m.name;
			_mat.color = {};
			_mat.color.r = m.color.r;
			_mat.color.g = m.color.g;
			_mat.color.b = m.color.b;
			_mat.type = m.type;
			_mat.vertexColors = m.vertexColors;

			if (haxe.Json.stringify(_mat) == json) {
				return m;
			}
		}

		this.materials.push(material);
		return material;
	}

	public function _createMaterial(material:Dynamic, renderEnvironment:Dynamic):Dynamic {
		if (material == null) {
			return new MeshStandardMaterial({
				color:new Color(1, 1, 1),
				metalness:0.8,
				name:Loader.DEFAULT_MATERIAL_NAME,
				side:Side.DoubleSide
			});
		}

		var mat = new MeshPhysicalMaterial({
			color:new Color(material.diffuseColor.r / 255.0, material.diffuseColor.g / 255.0, material.diffuseColor.b / 255.0),
			emissive:new Color(material.emissionColor.r, material.emissionColor.g, material.emissionColor.b),
			flatShading:material.disableLighting,
			ior:material.indexOfRefraction,
			name:material.name,
			reflectivity:material.reflectivity,
			opacity:1.0 - material.transparency,
			side:Side.DoubleSide,
			specularColor:material.specularColor,
			transparent:material.transparency > 0 ? true : false
		});

		mat.userData.id = material.id;

		if (material.pbrSupported) {
			var pbr = material.pbr;
			mat.anisotropy = pbr.anisotropic;
			mat.anisotropyRotation = pbr.anisotropicRotation;
			mat.color = new Color(pbr.baseColor.r, pbr.baseColor.g, pbr.baseColor.b);
			mat.clearcoat = pbr.clearcoat;
			mat.clearcoatRoughness = pbr.clearcoatRoughness;
			mat.metalness = pbr.metallic;
			mat.transmission = 1 - pbr.opacity;
			mat.roughness = pbr.roughness;
			mat.sheen = pbr.sheen;
			mat.specularIntensity = pbr.specular;
			mat.thickness = pbr.subsurface;
		}

		if (material.pbrSupported && material.pbr.opacity == 0 && material.transparency == 1) {
			mat.opacity = 0.2;
			mat.transmission = 1.00;
		}

		var textureLoader = new TextureLoader();

		for (var i = 0; i < material.textures.length; i++) {
			var texture = material.textures[i];

			if (texture.image != null) {
				var map = textureLoader.load(texture.image);

				switch (texture.type) {
					case "Bump":
						mat.bumpMap = map;
						break;
					case "Diffuse":
						mat.map = map;
						break;
					case "Emap":
						mat.envMap = map;
						break;
					case "Opacity":
						mat.transmissionMap = map;
						break;
					case "Transparency":
						mat.alphaMap = map;
						mat.transparent = true;
						break;
					case "PBR_Alpha":
						mat.alphaMap = map;
						mat.transparent = true;
						break;
					case "PBR_AmbientOcclusion":
						mat.aoMap = map;
						break;
					case "PBR_Anisotropic":
						mat.anisotropyMap = map;
						break;
					case "PBR_BaseColor":
						mat.map = map;
						break;
					case "PBR_Clearcoat":
						mat.clearcoatMap = map;
						break;
					case "PBR_ClearcoatBump":
						mat.clearcoatNormalMap = map;
						break;
					case "PBR_ClearcoatRoughness":
						mat.clearcoatRoughnessMap = map;
						break;
					case "PBR_Displacement":
						mat.displacementMap = map;
						break;
					case "PBR_Emission":
						mat.emissiveMap = map;
						break;
					case "PBR_Metallic":
						mat.metalnessMap = map;
						break;
					case "PBR_Roughness":
						mat.roughnessMap = map;
						break;
					case "PBR_Sheen":
						mat.sheenColorMap = map;
						break;
					case "PBR_Specular":
						mat.specularColorMap = map;
						break;
					case "PBR_Subsurface":
						mat.thicknessMap = map;
						break;
					default:
						this.warnings.push({
							message:"THREE.3DMLoader: No conversion exists for 3dm ${texture.type}.",
							type:"no conversion"
						});
						break;
				}

				map.wrapS = texture.wrapU == 0 ? Wrapping.Repeat : Wrapping.ClampToEdge;
				map.wrapT = texture.wrapV == 0 ? Wrapping.Repeat : Wrapping.ClampToEdge;

				if (texture.repeat) {
					map.repeat.set(texture.repeat[0], texture.repeat[1]);
				}
			}
		}

		if (renderEnvironment) {
			new EXRLoader().load(renderEnvironment.image, function(texture) {
				texture.mapping = THREE.EquirectangularReflectionMapping;
				mat.envMap = texture;
			});
		}

		return mat;
	}

	public function _createGeometry(data:Dynamic):Dynamic {
		var object = new Object3D();
		var instanceDefinitionObjects:Array<Dynamic> = [];
		var instanceDefinitions:Array<Dynamic> = [];
		var instanceReferences:Array<Dynamic> = [];

		object.userData['layers'] = data.layers;
		object.userData['groups'] = data.groups;
		object.userData['settings'] = data.settings;
		object.userData.settings['renderSettings'] = data.renderSettings;
		object.userData['objectType'] = "File3dm";
		object.userData['materials'] = null;

		object.name = this.url;

		var objects = data.objects;
		var materials = data.materials;

		for (var i = 0; i < objects.length; i++) {
			var obj = objects[i];
			var attributes = obj.attributes;

			switch (obj.objectType) {
				case "InstanceDefinition":
					instanceDefinitions.push(obj);
					break;
				case "InstanceReference":
					instanceReferences.push(obj);
					break;
				default:
					var matId:Int = null;

					switch (attributes.materialSource.name) {
						case "ObjectMaterialSource_MaterialFromLayer":
							if (attributes.layerIndex >= 0) {
								matId = data.layers[attributes.layerIndex].renderMaterialIndex;
							}
							break;
						case "ObjectMaterialSource_MaterialFromObject":
							if (attributes.materialIndex >= 0) {
								matId = attributes.materialIndex;
							}
							break;
					}

					var material:Dynamic = null;

					if (matId >= 0) {
						var rMaterial = materials[matId];
						material = this._createMaterial(rMaterial, data.renderEnvironment);
					}

					var _object = this._createObject(obj, material);

					if (_object == null) {
						continue;
					}

					var layer = data.layers[attributes.layerIndex];
					_object.visible = layer ? data.layers[attributes.layerIndex].visible : true;

					if (attributes.isInstanceDefinitionObject) {
						instanceDefinitionObjects.push(_object);
					} else {
						object.add(_object);
					}

					break;
			}
		}

		for (var i = 0; i < instanceDefinitions.length; i++) {
			var iDef = instanceDefinitions[i];

			objects = [];

			for (var j = 0; j < iDef.attributes.objectIds.length; j++) {
				var objId = iDef.attributes.objectIds[j];

				for (var p = 0; p < instanceDefinitionObjects.length; p++) {
					var idoId = instanceDefinitionObjects[p].userData.attributes.id;

					if (objId == idoId) {
						objects.push(instanceDefinitionObjects[p]);
					}
				}
			}

			for (var j = 0; j < instanceReferences.length; j++) {
				var iRef = instanceReferences[j];

				if (iRef.geometry.parentIdefId == iDef.attributes.id) {
					var iRefObject = new Object3D();
					var xf = iRef.geometry.xform.array;

					var matrix = new Matrix4();
					matrix.set(...xf);

					iRefObject.applyMatrix4(matrix);

					for (var p = 0; p < objects.length; p++) {
						iRefObject.add(objects[p].clone(true));
					}

					object.add(iRefObject);
				}
			}
		}

		object.userData['materials'] = this.materials;
		object.name = "";
		return object;
	}

	public function _createObject(obj:Dynamic, mat:Dynamic):Dynamic {
		var loader = new BufferGeometryLoader();

		var attributes = obj.attributes;

		var geometry:Dynamic, material:Dynamic, _color:Dynamic, color:Dynamic;

		switch (obj.objectType) {
			case "Point":
			case "PointSet":
				geometry = loader.parse(obj.geometry);

				if (geometry.attributes.hasOwnProperty('color')) {
					material = new PointsMaterial({vertexColors:true, sizeAttenuation:false, size:2});
				} else {
					_color = attributes.drawColor;
					color = new Color(_color.r / 255.0, _color.g / 255.0, _color.b / 255.0);
					material = new PointsMaterial({color:color, sizeAttenuation:false, size:2});
				}

				material = this._compareMaterials(material);

				var points = new Points(geometry, material);
				points.userData['attributes'] = attributes;
				points.userData['objectType'] = obj.objectType;

				if (attributes.name) {
					points.name = attributes.name;
				}

				return points;
			case "Mesh":
			case "Extrusion":
			case "SubD":
			case "Brep":
				if (obj.geometry == null) return null;

				geometry = loader.parse(obj.geometry);

				if (mat == null) {
					mat = this._createMaterial();
				}

				if (geometry.attributes.hasOwnProperty('color')) {
					mat.vertexColors = true;
				}

				mat = this._compareMaterials(mat);

				var mesh = new Mesh(geometry, mat);
				mesh.castShadow = attributes.castsShadows;
				mesh.receiveShadow = attributes.receivesShadows;
				mesh.userData['attributes'] = attributes;
				mesh.userData['objectType'] = obj.objectType;

				if (attributes.name) {
					mesh.name = attributes.name;
				}

				return mesh;
			case "Curve":
				geometry = loader.parse(obj.geometry);

				_color = attributes.drawColor;
				color = new Color(_color.r / 255.0, _color.g / 255.0, _color.b / 255.0);

				material = new LineBasicMaterial({color:color});
				material = this._compareMaterials(material);

				var lines = new Line(geometry, material);
				lines.userData['attributes'] = attributes;
				lines.userData['objectType'] = obj.objectType;

				if (attributes.name) {
					lines.name = attributes.name;
				}

				return lines;
			case "TextDot":
				geometry = obj.geometry;

				var ctx = document.createElement('canvas').getContext('2d');
				var font = `${geometry.fontHeight}px ${geometry.fontFace}`;
				ctx.font = font;
				var width = ctx.measureText(geometry.text).width + 10;
				var height = geometry.fontHeight + 10;

				var r = window.devicePixelRatio;

				ctx.canvas.width = width * r;
				ctx.canvas.height = height * r;
				ctx.canvas.style.width = width + "px";
				ctx.canvas.style.height = height + "px";
				ctx.setTransform(r, 0, 0, r, 0, 0);

				ctx.font = font;
				ctx.textBaseline = "middle";
				ctx.textAlign = "center";
				color = attributes.drawColor;
				ctx.fillStyle = `rgba(${color.r},${color.g},${color.b},${color.a})`;
				ctx.fillRect(0, 0, width, height);
				ctx.fillStyle = "white";
				ctx.fillText(geometry.text, width / 2, height / 2);

				var texture = new CanvasTexture(ctx.canvas);
				texture.minFilter = Filters.Linear;
				texture.wrapS = Wrapping.ClampToEdge;
				texture.wrapT = Wrapping.ClampToEdge;

				material = new SpriteMaterial({map:texture, depthTest:false});
				var sprite = new Sprite(material);
				sprite.position.set(geometry.point[0], geometry.point[1], geometry.point[2]);
				sprite.scale.set(width / 10, height / 10, 1.0);

				sprite.userData['attributes'] = attributes;
				sprite.userData['objectType'] = obj.objectType;

				if (attributes.name) {
					sprite.name = attributes.name;
				}

				return sprite;
			case "Light":
				geometry = obj.geometry;

				var light:Dynamic;

				switch (geometry.lightStyle.name) {
					case "LightStyle_WorldPoint":
						light = new PointLight();
						light.castShadow = attributes.castsShadows;
						light.position.set(geometry.location[0], geometry.location[1], geometry.location[2]);
						light.shadow.normalBias = 0.1;
						break;
					case "LightStyle_WorldSpot":
						light = new SpotLight();
						light.castShadow = attributes.castsShadows;
						light.position.set(geometry.location[0], geometry.location[1], geometry.location[2]);
						light.target.position.set(geometry.direction[0], geometry.direction[1], geometry.direction[2]);
						light.angle = geometry.spotAngleRadians;
						light.shadow.normalBias = 0.1;
						break;
					case "LightStyle_WorldRectangular":
						light = new RectAreaLight();
						var width = Math.abs(geometry.width[2]);
						var height = Math.abs(geometry.length[0]);
						light.position.set(geometry.location[0] - (height / 2), geometry.location[1], geometry.location[2] - (width / 2));
						light.height = height;
						light.width = width;
						light.lookAt(geometry.direction[0], geometry.direction[1], geometry.direction[2]);
						break;
					case "LightStyle_WorldDirectional":
						light = new DirectionalLight();
						light.castShadow = attributes.castsShadows;
						light.position.set(geometry.location[0], geometry.location[1], geometry.location[2]);
						light.target.position.set(geometry.direction[0], geometry.direction[1], geometry.direction[2]);
						light.shadow.normalBias = 0.1;
						break;
					case "LightStyle_WorldLinear":
						break;
					default:
						break;
				}

				if (light) {
					light.intensity = geometry.intensity;
					_color = geometry.diffuse;
					color = new Color(_color.r / 255.0, _color.g / 255.0, _color.b / 255.0);
					light.color = color;
					light.userData['attributes'] = attributes;
					light.userData['objectType'] = obj.objectType;
				}

				return light;
		}

		return null;
	}

	public function _initLibrary():Dynamic {
		if (this.libraryPending == null) {
			var jsLoader = new FileLoader(this.manager);
			jsLoader.setPath(this.libraryPath);
			var jsContent = new Promise((resolve, reject) => {
				jsLoader.load("rhino3dm.js", resolve, null, reject);
			});

			var binaryLoader = new FileLoader(this.manager);
			binaryLoader.setPath(this.libraryPath);
			binaryLoader.setResponseType('arraybuffer');
			var binaryContent = new Promise((resolve, reject) => {
				binaryLoader.load("rhino3dm.wasm", resolve, null, reject);
			});

			this.libraryPending = Promise.all([jsContent, binaryContent])
				.then(([jsContent, binaryContent]) => {
					this.libraryConfig.wasmBinary = binaryContent;

					var fn = Rhino3dmWorker.toString();
					var body = [
						"/* rhino3dm.js */",
						jsContent,
						"/* worker */",
						fn.substring(fn.indexOf('{') + 1, fn.lastIndexOf('}'))
					].join("\n");

					this.workerSourceURL = URL.createObjectURL(new Blob([body]));
				});
		}

		return this.libraryPending;
	}

	public function _getWorker(taskCost:Int):Dynamic {
		return this._initLibrary().then(() => {
			if (this.workerPool.length < this.workerLimit) {
				var worker = new Worker(this.workerSourceURL);
				worker._callbacks = {};
				worker._taskCosts = {};
				worker._taskLoad = 0;

				worker.postMessage({
					type:"init",
					libraryConfig:this.libraryConfig
				});

				worker.onmessage = e => {
					var message = e.data;

					switch (message.type) {
						case "warning":
							this.warnings.push(message.data);
							console.warn(message.data);
							break;
						case "decode":
							worker._callbacks[message.id].resolve(message);
							break;
						case "error":
							worker._callbacks[message.id].reject(message);
							break;
						default:
							console.error("THREE.Rhino3dmLoader: Unexpected message, \"" + message.type + "\"");
					}
				};

				this.workerPool.push(worker);
			} else {
				this.workerPool.sort(function(a, b) {
					return a._taskLoad > b._taskLoad ? -1 : 1;
				});
			}

			var worker = this.workerPool[this.workerPool.length - 1];
			worker._taskLoad += taskCost;
			return worker;
		});
	}

	public function _releaseTask(worker:Dynamic, taskID:Int):Void {
		worker._taskLoad -= worker._taskCosts[taskID];
		delete worker._callbacks[taskID];
		delete worker._taskCosts[taskID];
	}

	public function dispose():Rhino3dmLoader {
		for (var i = 0; i < this.workerPool.length; i++) {
			this.workerPool[i].terminate();
		}

		this.workerPool.length = 0;

		return this;
	}
}

class Rhino3dmWorker {
	static public function main():Void {
		var libraryPending:Dynamic;
		var libraryConfig:Dynamic;
		var rhino:Dynamic;
		var taskID:Int;

		onmessage = function(e) {
			var message = e.data;

			switch (message.type) {
				case "init":
					libraryConfig = message.libraryConfig;
					var wasmBinary = libraryConfig.wasmBinary;
					var RhinoModule:Dynamic;
					libraryPending = new Promise(function(resolve) {
						RhinoModule = {wasmBinary:wasmBinary, onRuntimeInitialized:resolve};
						rhino3dm(RhinoModule); // eslint-disable-line no-undef
					}).then(() => {
						rhino = RhinoModule;
					});
					break;
				case "decode":
					taskID = message.id;
					var buffer = message.buffer;
					libraryPending.then(() => {
						try {
							var data = decodeObjects(rhino, buffer);
							self.postMessage({type:"decode", id:message.id, data:data});
						} catch (error) {
							self.postMessage({type:"error", id:message.id, error:error});
						}
					});
					break;
			}
		};

		function decodeObjects(rhino:Dynamic, buffer:haxe.io.Bytes):Dynamic {
			var arr = new Uint8Array(buffer);
			var doc = rhino.File3dm.fromByteArray(arr);

			var objects:Array<Dynamic> = [];
			var materials:Array<Dynamic> = [];
			var layers:Array<Dynamic> = [];
			var views:Array<Dynamic> = [];
			var namedViews:Array<Dynamic> = [];
			var groups:Array<Dynamic> = [];
			var strings:Array<Dynamic> = [];

			var objs = doc.objects();
			var cnt = objs.count;

			for (var i = 0; i < cnt; i++) {
				var _object = objs.get(i);
				var object = extractObjectData(_object, doc);
				_object.delete();

				if (object) {
					objects.push(object);
				}
			}

			for (var i = 0; i < doc.instanceDefinitions().count; i++) {
				var idef = doc.instanceDefinitions().get(i);
				var idefAttributes = extractProperties(idef);
				idefAttributes.objectIds = idef.getObjectIds();
				objects.push({geometry:null, attributes:idefAttributes, objectType:"InstanceDefinition"});
			}

			var textureTypes = [
				// rhino.TextureType.Bitmap,
				rhino.TextureType.Diffuse,
				rhino.TextureType.Bump,
				rhino.TextureType.Transparency,
				rhino.TextureType.Opacity,
				rhino.TextureType.Emap
			];

			var pbrTextureTypes = [
				rhino.TextureType.PBR_BaseColor,
				rhino.TextureType.PBR_Subsurface,
				rhino.TextureType.PBR_SubsurfaceScattering,
				rhino.TextureType.PBR_SubsurfaceScatteringRadius,
				rhino.TextureType.PBR_Metallic,
				rhino.TextureType.PBR_Specular,
				rhino.TextureType.PBR_SpecularTint,
				rhino.TextureType.PBR_Roughness,
				rhino.TextureType.PBR_Anisotropic,
				rhino.TextureType.PBR_Anisotropic_Rotation,
				rhino.TextureType.PBR_Sheen,
				rhino.TextureType.PBR_SheenTint,
				rhino.TextureType.PBR_Clearcoat,
				rhino.TextureType.PBR_ClearcoatBump,
				rhino.TextureType.PBR_ClearcoatRoughness,
				rhino.TextureType.PBR_OpacityIor,
				rhino.TextureType.PBR_OpacityRoughness,
				rhino.TextureType.PBR_Emission,
				rhino.TextureType.PBR_AmbientOcclusion,
				rhino.TextureType.PBR_Displacement
			];

			for (var i = 0; i < doc.materials().count; i++) {
				var _material = doc.materials().get(i);
				var material = extractProperties(_material);
				var textures:Array<Dynamic> = [];

				textures.push(...extractTextures(_material, textureTypes, doc));

				material.pbrSupported = _material.physicallyBased().supported;

				if (material.pbrSupported) {
					textures.push(...extractTextures(_material, pbrTextureTypes, doc));
					material.pbr = extractProperties(_material.physicallyBased());
				}

				material.textures = textures;
				materials.push(material);
				_material.delete();
			}

			for (var i = 0; i < doc.layers().count; i++) {
				var _layer = doc.layers().get(i);
				var layer = extractProperties(_layer);
				layers.push(layer);
				_layer.delete();
			}

			for (var i = 0; i < doc.views().count; i++) {
				var _view = doc.views().get(i);
				var view = extractProperties(_view);
				views.push(view);
				_view.delete();
			}

			for (var i = 0; i < doc.namedViews().count; i++) {
				var _namedView = doc.namedViews().get(i);
				var namedView = extractProperties(_namedView);
				namedViews.push(namedView);
				_namedView.delete();
			}

			for (var i = 0; i < doc.groups().count; i++) {
				var _group = doc.groups().get(i);
				var group = extractProperties(_group);
				groups.push(group);
				_group.delete();
			}

			var settings = extractProperties(doc.settings());

			var strings_count = doc.strings().count;

			for (var i = 0; i < strings_count; i++) {
				strings.push(doc.strings().get(i));
			}

			var reflectionId = doc.settings().renderSettings().renderEnvironments.reflectionId;

			var rc = doc.renderContent();

			var renderEnvironment:Dynamic = null;

			for (var i = 0; i < rc.count; i++) {
				var content = rc.get(i);

				switch (content.kind) {
					case "environment":
						var id = content.id;
						if (id != reflectionId) break;

						var renderTexture = content.findChild('texture');
						var fileName = renderTexture.fileName;

						for (var j = 0; j < doc.embeddedFiles().count; j++) {
							var _fileName = doc.embeddedFiles().get(j).fileName;

							if (fileName == _fileName) {
								var background = doc.getEmbeddedFileAsBase64(fileName);
								var backgroundImage = 'data:image/png;base64,' + background;
								renderEnvironment = {type:"renderEnvironment", image:backgroundImage, name:fileName};
							}
						}

						break;
				}
			}

			var renderSettings:Dynamic = {
				ambientLight:doc.settings().renderSettings().ambientLight,
				backgroundColorTop:doc.settings().renderSettings().backgroundColorTop,
				backgroundColorBottom:doc.settings().renderSettings().backgroundColorBottom,
				useHiddenLights:doc.settings().renderSettings().useHiddenLights,
				depthCue:doc.settings().renderSettings().depthCue,
				flatShade:doc.settings().renderSettings().flatShade,
				renderBackFaces:doc.settings().renderSettings().renderBackFaces,
				renderPoints:doc.settings().renderSettings().renderPoints,
				renderCurves:doc.settings().renderSettings().renderCurves,
				renderIsoParams:doc.settings().renderSettings().renderIsoParams,
				renderMeshEdges:doc.settings().renderSettings().renderMeshEdges,
				renderAnnotations:doc.settings().renderSettings().renderAnnotations,
				useViewportSize:doc.settings().renderSettings().useViewportSize,
				scaleBackgroundToFit:doc.settings().renderSettings().scaleBackgroundToFit,
				transparentBackground:doc.settings().renderSettings().transparentBackground,
				imageDpi:doc.settings().renderSettings().imageDpi,
				shadowMapLevel:doc.settings().renderSettings().shadowMapLevel,
				namedView:doc.settings().renderSettings().namedView,
				snapShot:doc.settings().renderSettings().snapShot,
				specificViewport:doc.settings().renderSettings().specificViewport,
				groundPlane:extractProperties(doc.settings().renderSettings().groundPlane),
				safeFrame:extractProperties(doc.settings().renderSettings().safeFrame),
				dithering:extractProperties(doc.settings().renderSettings().dithering),
				skylight:extractProperties(doc.settings().renderSettings().skylight),
				linearWorkflow:extractProperties(doc.settings().renderSettings().linearWorkflow),
				renderChannels:extractProperties(doc.settings().renderSettings().renderChannels),
				sun:extractProperties(doc.settings().renderSettings().sun),
				renderEnvironments:extractProperties(doc.settings().renderSettings().renderEnvironments),
				postEffects:extractProperties(doc.settings
				specificViewport:doc.settings().renderSettings().specificViewport,
				groundPlane:extractProperties(doc.settings().renderSettings().groundPlane),
				safeFrame:extractProperties(doc.settings().renderSettings().safeFrame),
				dithering:extractProperties(doc.settings().renderSettings().dithering),
				skylight:extractProperties(doc.settings().renderSettings().skylight),
				linearWorkflow:extractProperties(doc.settings().renderSettings().linearWorkflow),
				renderChannels:extractProperties(doc.settings().renderSettings().renderChannels),
				sun:extractProperties(doc.settings().renderSettings().sun),
				renderEnvironments:extractProperties(doc.settings().renderSettings().renderEnvironments),
				postEffects:extractProperties(doc.settings().renderSettings().postEffects),

			};

			doc.delete();

			return {objects, materials, layers, views, namedViews, groups, strings, settings, renderSettings, renderEnvironment};

		}

		function extractTextures(m:Dynamic, tTypes:Array<Dynamic>, d:Dynamic):Array<Dynamic> {

			var textures:Array<Dynamic> = [];

			for (var i = 0; i < tTypes.length; i++) {

				var _texture = m.getTexture(tTypes[i]);
				if (_texture) {

					var textureType = tTypes[i].constructor.name;
					textureType = textureType.substring(12, textureType.length);
					var texture = extractTextureData(_texture, textureType, d);
					textures.push(texture);
					_texture.delete();

				}

			}

			return textures;

		}

		function extractTextureData(t:Dynamic, tType:String, d:Dynamic):Dynamic {

			var texture:Dynamic = {type:tType};

			var image = d.getEmbeddedFileAsBase64(t.fileName);

			texture.wrapU = t.wrapU;
			texture.wrapV = t.wrapV;
			texture.wrapW = t.wrapW;
			var uvw = t.uvwTransform.toFloatArray(true);

			texture.repeat = [uvw[0], uvw[5]];

			if (image) {

				texture.image = 'data:image/png;base64,' + image;

			} else {

				self.postMessage({type:'warning', id:taskID, data:{
					message:`THREE.3DMLoader: Image for ${tType} texture not embedded in file.`,
					type:'missing resource'
				}});

				texture.image = null;

			}

			return texture;

		}

		function extractObjectData(object:Dynamic, doc:Dynamic):Dynamic {

			var _geometry = object.geometry();
			var _attributes = object.attributes();
			var objectType = _geometry.objectType;
			var geometry:Dynamic, attributes:Dynamic, position:Dynamic, data:Dynamic, mesh:Dynamic;

			// skip instance definition objects
			//if( _attributes.isInstanceDefinitionObject ) { continue; }

			// TODO: handle other geometry types
			switch (objectType) {

				case rhino.ObjectType.Curve:

					var pts = curveToPoints(_geometry, 100);

					position = {};
					attributes = {};
					data = {};

					position.itemSize = 3;
					position.type = 'Float32Array';
					position.array = [];

					for (var j = 0; j < pts.length; j++) {

						position.array.push(pts[j][0]);
						position.array.push(pts[j][1]);
						position.array.push(pts[j][2]);

					}

					attributes.position = position;
					data.attributes = attributes;

					geometry = {data};

					break;

				case rhino.ObjectType.Point:

					var pt = _geometry.location;

					position = {};
					var color:Dynamic = {};
					attributes = {};
					data = {};

					position.itemSize = 3;
					position.type = 'Float32Array';
					position.array = [pt[0], pt[1], pt[2]];

					var _color = _attributes.drawColor(doc);

					color.itemSize = 3;
					color.type = 'Float32Array';
					color.array = [_color.r / 255.0, _color.g / 255.0, _color.b / 255.0];

					attributes.position = position;
					attributes.color = color;
					data.attributes = attributes;

					geometry = {data};

					break;

				case rhino.ObjectType.PointSet:
				case rhino.ObjectType.Mesh:

					geometry = _geometry.toThreejsJSON();

					break;

				case rhino.ObjectType.Brep:

					var faces = _geometry.faces();
					mesh = new rhino.Mesh();

					for (var faceIndex = 0; faceIndex < faces.count; faceIndex++) {

						var face = faces.get(faceIndex);
						var _mesh = face.getMesh(rhino.MeshType.Any);

						if (_mesh) {

							mesh.append(_mesh);
							_mesh.delete();

						}

						face.delete();

					}

					if (mesh.faces().count > 0) {

						mesh.compact();
						geometry = mesh.toThreejsJSON();
						faces.delete();

					}

					mesh.delete();

					break;

				case rhino.ObjectType.Extrusion:

					mesh = _geometry.getMesh(rhino.MeshType.Any);

					if (mesh) {

						geometry = mesh.toThreejsJSON();
						mesh.delete();

					}

					break;

				case rhino.ObjectType.TextDot:

					geometry = extractProperties(_geometry);

					break;

				case rhino.ObjectType.Light:

					geometry = extractProperties(_geometry);

					if (geometry.lightStyle.name == 'LightStyle_WorldLinear') {

						self.postMessage({type:'warning', id:taskID, data:{
							message:`THREE.3DMLoader: No conversion exists for ${objectType.constructor.name} ${geometry.lightStyle.name}`,
							type:'no conversion',
							guid:_attributes.id
						}});

					}

					break;

				case rhino.ObjectType.InstanceReference:

					geometry = extractProperties(_geometry);
					geometry.xform = extractProperties(_geometry.xform);
					geometry.xform.array = _geometry.xform.toFloatArray(true);

					break;

				case rhino.ObjectType.SubD:

					// TODO: precalculate resulting vertices and faces and warn on excessive results
					_geometry.subdivide(3);
					mesh = rhino.Mesh.createFromSubDControlNet(_geometry, false);
					if (mesh) {

						geometry = mesh.toThreejsJSON();
						mesh.delete();

					}

					break;

					/*
					case rhino.ObjectType.Annotation:
					case rhino.ObjectType.Hatch:
					case rhino.ObjectType.ClipPlane:
					*/

				default:

					self.postMessage({type:'warning', id:taskID, data:{
						message:`THREE.3DMLoader: Conversion not implemented for ${objectType.constructor.name}`,
						type:'not implemented',
						guid:_attributes.id
					}});

					break;

			}

			if (geometry) {

				attributes = extractProperties(_attributes);
				attributes.geometry = extractProperties(_geometry);

				if (_attributes.groupCount > 0) {

					attributes.groupIds = _attributes.getGroupList();

				}

				if (_attributes.userStringCount > 0) {

					attributes.userStrings = _attributes.getUserStrings();

				}

				if (_geometry.userStringCount > 0) {

					attributes.geometry.userStrings = _geometry.getUserStrings();

				}

				if (_attributes.decals().count > 0) {

					self.postMessage({type:'warning', id:taskID, data:{
						message:'THREE.3DMLoader: No conversion exists for the decals associated with this object.',
						type:'no conversion',
						guid:_attributes.id
					}});

				}

				attributes.drawColor = _attributes.drawColor(doc);

				objectType = objectType.constructor.name;
				objectType = objectType.substring(11, objectType.length);

				return {geometry, attributes, objectType};

			} else {

				self.postMessage({type:'warning', id:taskID, data:{
					message:`THREE.3DMLoader: ${objectType.constructor.name} has no associated mesh geometry.`,
					type:'missing mesh',
					guid:_attributes.id
				}});

			}

		}

		function extractProperties(object:Dynamic):Dynamic {

			var result:Dynamic = {};

			for (var property in object) {

				var value = object[property];

				if (typeof value != 'function') {

					if (typeof value == 'object' && value != null && value.hasOwnProperty('constructor')) {

						result[property] = {name:value.constructor.name, value:value.value};

					} else if (typeof value == 'object' && value != null) {

						result[property] = extractProperties(value);

					} else {

						result[property] = value;

					}

				} else {

					// these are functions that could be called to extract more data.
					//console.log( `${property}: ${object[ property ].constructor.name}` );

				}

			}

			return result;

		}

		function curveToPoints(curve:Dynamic, pointLimit:Int):Array<Dynamic> {

			var pointCount = pointLimit;
			var rc:Array<Dynamic> = [];
			var ts:Array<Dynamic> = [];

			if (curve instanceof rhino.LineCurve) {

				return [curve.pointAtStart, curve.pointAtEnd];

			}

			if (curve instanceof rhino.PolylineCurve) {

				pointCount = curve.pointCount;
				for (var i = 0; i < pointCount; i++) {

					rc.push(curve.point(i));

				}

				return rc;

			}

			if (curve instanceof rhino.PolyCurve) {

				var segmentCount = curve.segmentCount;

				for (var i = 0; i < segmentCount; i++) {

					var segment = curve.segmentCurve(i);
					var segmentArray = curveToPoints(segment, pointCount);
					rc = rc.concat(segmentArray);
					segment.delete();

				}

				return rc;

			}

			if (curve instanceof rhino.ArcCurve) {

				pointCount = Math.floor(curve.angleDegrees / 5);
				pointCount = pointCount < 2 ? 2 : pointCount;
				// alternative to this hardcoded version: https://stackoverflow.com/a/18499923/2179399

			}

			if (curve instanceof rhino.NurbsCurve && curve.degree == 1) {

				var pLine = curve.tryGetPolyline();

				for (var i = 0; i < pLine.count; i++) {

					rc.push(pLine.get(i));

				}

				pLine.delete();

				return rc;

			}

			var domain = curve.domain;
			var divisions = pointCount - 1.0;

			for (var j = 0; j < pointCount; j++) {

				var t = domain[0] + (j / divisions) * (domain[1] - domain[0]);

				if (t == domain[0] || t == domain[1]) {

					ts.push(t);
					continue;

				}

				var tan = curve.tangentAt(t);
				var prevTan = curve.tangentAt(ts.slice(-1)[0]);

				// Duplicated from THREE.Vector3
				// How to pass imports to worker?

				var tS = tan[0] * tan[0] + tan[1] * tan[1] + tan[2] * tan[2];
				var ptS = prevTan[0] * prevTan[0] + prevTan[1] * prevTan[1] + prevTan[2] * prevTan[2];

				var denominator = Math.sqrt(tS * ptS);

				var angle:Float;

				if (denominator == 0) {

					angle = Math.PI / 2;

				} else {

					var theta = (tan.x * prevTan.x + tan.y * prevTan.y + tan.z * prevTan.z) / denominator;
					angle = Math.acos(Math.max(-1, Math.min(1, theta)));

				}

				if (angle < 0.1) continue;

				ts.push(t);

			}

			rc = ts.map(t => curve.pointAt(t));
			return rc;

		}

	}

}

export {Rhino3dmLoader};