import three.math.Color;
import three.math.Matrix4;
import three.objects.BufferGeometry;
import three.objects.Line;
import three.objects.LineBasicMaterial;
import three.objects.Mesh;
import three.objects.MeshPhysicalMaterial;
import three.objects.Object3D;
import three.objects.Points;
import three.objects.PointsMaterial;
import three.scenes.Scene;
import three.textures.CanvasTexture;
import three.textures.Texture;
import three.textures.TextureLoader;

class Rhino3dmLoader extends Loader {

	public var libraryPath:String;
	public var libraryPending:Future<Dynamic>;
	public var libraryConfig:Dynamic;
	public var workerPool:Array<Worker>;
	public var workerNextTaskID:Int;
	public var workerSourceURL:String;
	public var workerConfig:Dynamic;
	public var materials:Array<MeshPhysicalMaterial>;
	public var warnings:Array<Dynamic>;

	public function new(manager:LoaderManager) {
		super(manager);
		this.libraryPath = '';
		this.libraryPending = null;
		this.libraryBinary = null;
		this.libraryConfig = {};
		this.url = '';
		this.workerLimit = 4;
		this.workerPool = [];
		this.workerNextTaskID = 1;
		this.workerSourceURL = '';
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

	override public function load(url:String, onLoad:(result:Dynamic) -> Void, onProgress:(event:Dynamic) -> Void, onError:(event:Dynamic) -> Void):Void {
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(this.requestHeader);
		this.url = url;
		loader.load(url, (buffer:Dynamic) -> {
			var task = this.decodeObjects(buffer, url);
			task.then(result => {
				result.userData.warnings = this.warnings;
				onLoad(result);
			}).catch(e => onError(e));
		}, onProgress, onError);
	}

	public function debug():Void {
		trace('Task load: ', this.workerPool.map(worker => worker._taskLoad));
	}

	private function decodeObjects(buffer:Dynamic, url:String):Future<Dynamic> {
		var worker = this._getWorker(buffer.byteLength);
		var taskID = this.workerNextTaskID ++;
		var objectPending = worker.then(worker => {
			worker._callbacks[taskID] = {resolve: (result:Dynamic) -> Void, reject: (e:Dynamic) -> Void};
			worker.postMessage({type: 'decode', id: taskID, buffer}, [buffer]);
			return worker._taskLoad;
		}).then(message => this._createGeometry(message.data));
		objectPending.handleError(e => {
			trace('Error decoding objects:', e);
			throw e;
		}).handleSuccess(result => {
			_taskCache.set(buffer, {url: url, promise: objectPending});
		});
		return objectPending;
	}

	private function parse(data:Dynamic, onLoad:(result:Dynamic) -> Void, onError:(e:Dynamic) -> Void):Void {
		this.decodeObjects(data, '').then(result => {
			result.userData.warnings = this.warnings;
			onLoad(result);
		}).catch(e => onError(e));
	}

	private function _compareMaterials(material:MeshPhysicalMaterial):MeshPhysicalMaterial {
		var mat = new MeshPhysicalMaterial();
		mat.name = material.name;
		mat.color = new Color(material.color.r, material.color.g, material.color.b);
		mat.type = material.type;
		mat.vertexColors = material.vertexColors;
		return mat;
	}

	private function _createMaterial(material:Dynamic, renderEnvironment:Dynamic):MeshPhysicalMaterial {
		if (!material) {
			return new MeshPhysicalMaterial({
				color: new Color(1, 1, 1),
				metalness: 0.8,
				name: Loader.DEFAULT_MATERIAL_NAME,
				side: DoubleSide
			});
		}
		var mat = new MeshPhysicalMaterial({
			color: new Color(material.diffuseColor.r / 255.0, material.diffuseColor.g / 255.0, material.diffuseColor.b / 255.0),
			emissive: new Color(material.emissionColor.r, material.emissionColor.g, material.emissionColor.b),
			flatShading: material.disableLighting,
			ior: material.indexOfRefraction,
			name: material.name,
			reflectivity: material.reflectivity,
			opacity: 1.0 - material.transparency,
			side: DoubleSide,
			specularColor: material.specularColor,
			transparent: material.transparency > 0 ? true : false
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
		if (material.pbrSupported && material.pbr.opacity === 0 && material.transparency === 1) {
			mat.opacity = 0.2;
			mat.transmission = 1.00;
		}
		return mat;
	}

	private function _createGeometry(message:Dynamic):Dynamic {
		var object = new Object3D();
		var instanceDefinitionObjects = [];
		var instanceDefinitions = [];
		var instanceReferences = [];
		object.userData.warnings = this.warnings;
		object.userData.materials = this.materials;
		object.name = this.url;
		var data = message.data;
		var objects = data.objects;
		var materials = data.materials;
		for (i in 0...objects.length) {
			var obj = objects[i];
			var attributes = obj.attributes;
			var material = this._createMaterial(attributes.materialSource.material, null);
			var geometry = new BufferGeometry();
			var vertices = new Array<Vector3>();
			var uvs = new Array<Vector2>();
			var indices = new Array<Int>();
			for (j in 0...obj.vertices.length) {
				vertices.push(new Vector3(obj.vertices[j].x, obj.vertices[j].y, obj.vertices[j].z));
				uvs.push(new Vector2(obj.uvs[j].u, obj.uvs[j].v));
			}
			for (j in 0...vertices.length) {
				indices.push(j);
			}
			geometry.setIndex(indices);
			geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
			geometry.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
			var mesh = new Mesh(geometry, material);
			object.add(mesh);
		}
		return object;
	}

	private function _getWorker(taskCost:Int):Future<Worker> {
		return Future.sequence([this.libraryPending, Future.nothing()]).map(() -> {
			var worker = new Worker(this.workerSourceURL);
			worker.onmessage = e => {
				var message = e.data;
				switch (message.type) {
					case 'warning':
						this.warnings.push(message.data);
						trace(message.data);
						break;
					case 'decode':
						worker._callbacks[message.id].resolve(message);
						break;
					case 'error':
						worker._callbacks[message.id].reject(message);
						break;
				}
			};
			return worker;
		});
	}

}