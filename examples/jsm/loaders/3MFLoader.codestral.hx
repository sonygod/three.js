import three.BufferAttribute;
import three.BufferGeometry;
import three.ClampToEdgeWrapping;
import three.Color;
import three.FileLoader;
import three.Float32BufferAttribute;
import three.Group;
import three.LinearFilter;
import three.LinearMipmapLinearFilter;
import three.Loader;
import three.Matrix4;
import three.Mesh;
import three.MeshPhongMaterial;
import three.MeshStandardMaterial;
import three.MirroredRepeatWrapping;
import three.NearestFilter;
import three.RepeatWrapping;
import three.TextureLoader;
import three.SRGBColorSpace;
import fflate.Zip;
import js.html.XMLDocument;
import js.html.XMLHttpRequest;
import js.html.DOMParser;
import js.html.FormData;
import js.html.URL;
import js.html.Blob;

class ThreeMFLoader {

	var COLOR_SPACE_3MF:String = SRGBColorSpace;
	var availableExtensions:Array<Dynamic> = [];
	var manager:Loader;
	var path:String;
	var requestHeader:js.html.RequestHeader;
	var withCredentials:Bool;

	public function new(manager:Loader = null) {
		this.manager = manager != null ? manager : new Loader();
	}

	public function load(url:String, onLoad:Dynamic -> Void, onProgress:(event:ProgressEvent) -> Void, onError:Dynamic -> Void) {
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, (_:js.html.FormData, event:js.html.ProgressEvent) -> {
			var request:XMLHttpRequest = event.target;
			if (request.readyState === 4) {
				if (request.status === 200) {
					try {
						var data = request.response;
						onLoad(this.parse(data));
					} catch (e:Dynamic) {
						if (onError != null) {
							onError(e);
						} else {
							trace(e);
						}
						this.manager.itemError(url);
					}
				} else if (onError != null) {
					onError(request.status);
				}
			} else if (onProgress != null) {
				onProgress(event);
			}
		});
	}

	public function parse(data:ArrayBuffer):Group {
		var textureLoader = new TextureLoader(this.manager);

		function loadDocument(data:ArrayBuffer):Dynamic {
			var zip:Zip = null;
			var file:String = null;

			var relsName:String;
			var modelRelsName:String;
			var modelPartNames:Array<String> = [];
			var texturesPartNames:Array<String> = [];

			var modelRels:Dynamic;
			var modelParts:Dynamic = {};
			var printTicketParts:Dynamic = {};
			var texturesParts:Dynamic = {};

			try {
				zip = Zip.unzip(data);
			} catch (e:Dynamic) {
				if (js.Boot.getClass(e) == js.Boot.getClass(ReferenceError)) {
					trace('THREE.3MFLoader: fflate missing and file is compressed.');
					return null;
				}
			}

			for (file in zip.files) {
				if (file.match(/\_rels\/.rels$/)) {
					relsName = file;
				} else if (file.match(/3D\/_rels\/.*\.model\.rels$/)) {
					modelRelsName = file;
				} else if (file.match(/^3D\/.*\.model$/)) {
					modelPartNames.push(file);
				} else if (file.match(/^3D\/Textures?\/.*/)) {
					texturesPartNames.push(file);
				}
			}

			if (relsName == null) throw new Error('THREE.ThreeMFLoader: Cannot find relationship file `rels` in 3MF archive.');

			// Parse rels file
			var relsFileText = zip.getFileText(relsName);
			var rels = parseRelsXml(relsFileText);

			// Parse modelRels file
			if (modelRelsName != null) {
				var relsFileText = zip.getFileText(modelRelsName);
				modelRels = parseRelsXml(relsFileText);
			}

			// Parse model parts
			for (var i = 0; i < modelPartNames.length; i++) {
				var modelPart = modelPartNames[i];
				var fileText = zip.getFileText(modelPart);
				var xmlData = new DOMParser().parseFromString(fileText, 'application/xml');

				if (xmlData.documentElement.nodeName.toLowerCase() !== 'model') {
					trace('THREE.3MFLoader: Error loading 3MF - no 3MF document found: ' + modelPart);
				}

				var modelNode = xmlData.querySelector('model');
				var extensions:Dynamic = {};

				for (var i = 0; i < modelNode.attributes.length; i++) {
					var attr = modelNode.attributes[i];
					if (attr.name.match(/^xmlns:(.+)$/)) {
						extensions[attr.value] = RegExp.$1;
					}
				}

				var modelData = parseModelNode(modelNode);
				modelData['xml'] = modelNode;

				if (js.Boot.keyField(extensions) != null) {
					modelData['extensions'] = extensions;
				}

				modelParts[modelPart] = modelData;
			}

			// Parse textures parts
			for (var i = 0; i < texturesPartNames.length; i++) {
				var texturesPartName = texturesPartNames[i];
				texturesParts[texturesPartName] = zip.getFileData(texturesPartName).buffer;
			}

			return {
				rels: rels,
				modelRels: modelRels,
				model: modelParts,
				printTicket: printTicketParts,
				texture: texturesParts
			};
		}

		function parseRelsXml(relsFileText:String):Array<Dynamic> {
			// Implementation omitted for brevity
		}

		// Other functions omitted for brevity

		var data3mf = loadDocument(data);
		var objects = buildObjects(data3mf);

		return build(objects, data3mf);
	}

	public function addExtension(extension:Dynamic) {
		this.availableExtensions.push(extension);
	}

}