import haxe.ds.StringMap;
import js.html.FileLoader;
import js.html.FileLoaderEvents;
import js.typedarray.TypedArrays;

class LDrawParsedCache {

	private var _cache:StringMap<Dynamic>;
	public var loader:Dynamic;

	public function new(loader:Dynamic) {
		this._cache = new StringMap<Dynamic>();
		this.loader = loader;
	}

	public function cloneResult(original:Dynamic):Dynamic {
		var result = {};
		// vertices are transformed and normals computed before being converted to geometry
		// so these pieces must be cloned.
		result.faces = original.faces.map(face => {
			return {
				colorCode: face.colorCode,
				material: face.material,
				vertices: face.vertices.map(v => TypedArrays.copy(v)),
				normals: face.normals.map( () => null ),
				faceNormal: null
			};
		});

		result.conditionalSegments = original.conditionalSegments.map(face => {
			return {
				colorCode: face.colorCode,
				material: face.material,
				vertices: face.vertices.map(v => TypedArrays.copy(v)),
				controlPoints: face.controlPoints.map(v => TypedArrays.copy(v))
			};
		});

		result.lineSegments = original.lineSegments.map(face => {
			return {
				colorCode: face.colorCode,
				material: face.material,
				vertices: face.vertices.map(v => TypedArrays.copy(v))
			};
		});

		// none if this is subsequently modified
		result.type = original.type;
		result.category = original.category;
		result.keywords = original.keywords;
		result.author = original.author;
		result.subobjects = original.subobjects;
		result.fileName = original.fileName;
		result.totalFaces = original.totalFaces;
		result.startingBuildingStep = original.startingBuildingStep;
		result.materials = original.materials;
		result.group = null;
		return result;
	}

	public function fetchData(fileName:String):Dynamic {
		var triedLowerCase = false;
		var locationState = 0;
		while (locationState != 5) {
			var subobjectURL = fileName;
			switch (locationState) {
				case 0:
					locationState = 1;
					break;

				case 1:
					subobjectURL = 'parts/' + subobjectURL;
					locationState = 2;
					break;

				case 2:
					subobjectURL = 'p/' + subobjectURL;
					locationState = 3;
					break;

				case 3:
					subobjectURL = 'models/' + subobjectURL;
					locationState = 4;
					break;

				case 4:
					subobjectURL = fileName.substring(0, fileName.lastIndexOf('/') + 1) + subobjectURL;
					locationState = 5;
					break;

				case 5:

					if (triedLowerCase) {
						// Try absolute path
						locationState = 5;

					} else {

						// Next attempt is lower case
						fileName = fileName.toLowerCase();
						subobjectURL = fileName;
						triedLowerCase = true;
						locationState = 1;

					}

					break;

			}

			var fileLoader = new FileLoader(loader.manager);
			fileLoader.setPath(loader.partsLibraryPath);
			fileLoader.setRequestHeader(loader.requestHeader);
			fileLoader.setWithCredentials(loader.withCredentials);
			fileLoader.addEventListener(FileLoaderEvents.LOAD, (event:Dynamic) => {
				return this.onLoad(event, fileName);
			});
			fileLoader.load(subobjectURL);
		}
		throw new Error('LDrawLoader: Subobject "' + fileName + '" could not be loaded.');
	}

	public function onLoad(event:Dynamic, fileName:String):Void {
		this._cache[fileName.toLowerCase()] = event.target.response;
	}

	public function parse(text:String, fileName:String = null):Dynamic {
		// final results
		var faces = [];
		var lineSegments = [];
		var conditionalSegments = [];
		var subobjects = [];
		var materials = {};

		public function getLocalMaterial(colorCode:String):Dynamic {
			return materials[colorCode] || null;
		}

		var type = 'Model';
		var category = null;
		var keywords = null;
		var author = null;
		var totalFaces = 0;

		// split into lines
		if (text.indexOf('\r\n') != -1) {
			// This is faster than String.split with regex that splits on both
			text = text.replace(/