import three.math._Vector3;
import three.math._Matrix4;
import three.core.Loader;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.materials.Material;
import three.materials.MeshPhongMaterial;
import three.materials.MeshStandardMaterial;
import three.geometries.Group;
import three.textures.TextureLoader;
import three.textures.Texture;
import three.textures.SRGBColorSpace;
import js.Lib;
import js.Browser;
import js.typedarrays.ArrayBuffer;
import js.typedarrays.ArrayBufferView;
import js.typedarrays.ArrayView;
import js.typedarrays.DataView;
import js.zip.Inflate;
import js.zip.Deflate;
import js.zip.ZipFile;
import js.zip.ZipEntries;
import js.zip.ZipEntry;
import js.xml.DOMParser;
import js.xml.XMLDocument;
import js.xml.XMLNode;
import js.xml.XMLNsMap;
import js.xml.XMLException;
import js.util.TextDecoder;

class ThreeMFLoader extends Loader {

	public var availableExtensions:Array<Dynamic>;

	public function new(manager:Dynamic) {
		super(manager);
		this.availableExtensions = [];
	}

	public override function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		var scope = this;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function (buffer:ArrayBufferView) {
			try {
				onLoad(scope.parse(buffer));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					Browser.alert(Js<String>("Error: " + e.toString()));
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(data:ArrayBufferView):Dynamic {
		var scope = this;
		var textureLoader = new TextureLoader(this.manager);

		function loadDocument(data:ArrayBufferView):Dynamic {
			var zip:Dynamic = null;
			var file:Dynamic = null;

			var relsName:String;
			var modelRelsName:String;
			var modelPartNames:Array<String>;
			var texturesPartNames:Array<String>;

			var modelRels:Array<Dynamic>;
			var modelParts:Object;
			var printTicketParts:Object;
			var texturesParts:Object;

			var textDecoder = new TextDecoder();

			try {

				zip = Inflate.inflate(new Uint8Array(data));

			} catch (e:Dynamic) {

				if (e instanceof ReferenceError) {
					console.error("THREE.3MFLoader: fflate missing and file is compressed.");
					return null;
				}

			}

			var zipFile = new ZipFile(zip);
			var entries = zipFile.getEntries();

			for (entry in entries) {
				if (entry.name.match(/_rels\/.rels$/)) {
					relsName = entry.name;
				} else if (entry.name.match(/3D\/_rels\/.*\.model\.rels$/)) {
					modelRelsName = entry.name;
				} else if (entry.name.match(/^3D\/.*\.model$/)) {
					modelPartNames.push(entry.name);
				} else if (entry.name.match(/^3D\/Textures?\/.*$/)) {
					texturesPartNames.push(entry.name);
				}
			}

			if (relsName === undefined) throw new Error("THREE.ThreeMFLoader: Cannot find relationship file `rels` in 3MF archive.");

			//

			var relsView = zipFile.getEntry(relsName).getData();
			var relsFileText = textDecoder.decode(relsView);
			var rels = parseRelsXml(relsFileText);

			//

			if (modelRelsName) {
				var relsView = zipFile.getEntry(modelRelsName).getData();
				var relsFileText = textDecoder.decode(relsView);
				modelRels = parseRelsXml(relsFileText);
			}

			//

			modelPartNames.sort();
			texturesPartNames.sort();

			modelParts = {};
			printTicketParts = {};
			texturesParts = {};

			for (var i = 0; i < modelPartNames.length; i++) {
				var modelPart = modelPartNames[i];
				var view = zipFile.getEntry(modelPart).getData();
				var fileText = textDecoder.decode(view);
				var xmlData = new DOMParser().parseFromString(fileText, 'application/xml');

				var modelNode = xmlData.querySelector('model');
				var extensions = {};

				for (var i = 0; i < modelNode.attributes.length; i++) {
					var attr = modelNode.attributes[i];
					if (attr.name.match(/^xmlns:(.+)$/)) {
						extensions[attr.value] = RegExp.$1;
					}
				}

				var modelData = parseModelNode(modelNode);
				modelData['xml'] = modelNode;

				if (0 < Object.keys(extensions).length) {
					modelData['extensions'] = extensions;
				}

				modelParts[modelPart] = modelData;
			}

			//

			for (var i = 0; i < texturesPartNames.length; i++) {
				var texturesPartName = texturesPartNames[i];
				texturesParts[texturesPartName] = zipFile.getEntry(texturesPartName).getData();
			}

			return {
				rels: rels,
				modelRels: modelRels,
				model: modelParts,
				printTicket: printTicketParts,
				texture: texturesParts
			};
		}

		// ... (other functions are omitted for brevity)

		function buildTexture(texture2dgroup:Dynamic, objects:Object, modelData:Object, textureData:Object, objectData:Object):Texture {
			// ... (function body is omitted for brevity)
		}

		function buildObjects(data3mf:Dynamic):Object {
			// ... (function body is omitted for brevity)
		}

		function fetch3DModelPart(rels:Array<Dynamic>):Dynamic {
			// ... (function body is omitted for brevity)
		}

		function build(objects:Object, data3mf:Dynamic):Group {
			// ... (function body is omitted for brevity)
		}

		function parseRelsXml(relsFileText:String):Array<Dynamic> {
			// ... (function body is omitted for brevity)
		}

		function parseModelNode(modelNode:XMLNode):Dynamic {
			// ... (function body is omitted for brevity)
		}

		function parseMetadataNodes(metadataNodes:Array<XMLNode>):Object {
			// ... (function body is omitted for brevity)
		}

		function parseBasematerialsNode(basematerialsNode:XMLNode):Dynamic {
			// ... (function body is omitted for brevity)
		}

		function parseTexture2DNode(texture2DNode:XMLNode):Dynamic {
			// ... (function body is omitted for brevity)
		}

		function parseTextures2DGroupNode(texture2DGroupNode:XMLNode):Dynamic {
			// ... (function body is omitted for brevity)
		}

		function parseColorGroupNode(colorGroupNode:XMLNode):Dynamic {
			// ... (function body is omitted for brevity)
		}

		function parseMetallicDisplaypropertiesNode(metallicDisplaypropetiesNode:XMLNode):Dynamic {
			// ... (function body is omitted for brevity)
		}

		function parseBasematerialNode(basematerialNode:XMLNode):Dynamic {
			// ... (function body is omitted for brevity)
		}

		function parseMeshNode(meshNode:XMLNode):Dynamic {
			// ... (function body is omitted for brevity)
		}

		function parseComponentsNode(componentsNode:XMLNode):Array<Dynamic> {
			// ... (function body is omitted for brevity)
		}

		function parseComponentNode(componentNode:XMLNode):Dynamic {
			// ... (function body is omitted for brevity)
		}

		function parseTransform(transform:String):_Matrix4 {
			// ... (function body is omitted for brevity)
		}

		function parseObjectNode(objectNode:XMLNode):Dynamic {
			// ... (function body is omitted for brevity)
		}

		function parseResourcesNode(resourcesNode:XMLNode):Object {
			// ... (function body is omitted for brevity)
		}

		function parseBuildNode(buildNode:XMLNode):Array<Dynamic> {
			// ... (function body is omitted for brevity)
		}

		function applyExtensions(extensions:Dynamic, meshData:Dynamic, modelXml:XMLDocument) {
			// ... (function body is omitted for brevity)
		}

		function getBuild(data:Dynamic, objects:Object, modelData:Object, textureData:Object, objectData:Object, builder:Dynamic):Dynamic {
			// ... (function body is omitted for brevity)
		}

		function buildBasematerialsMeshes(basematerials:Dynamic, triangleProperties:Array<Dynamic>, meshData:Dynamic, objects:Object, modelData:Object, textureData:Object, objectData:Dynamic):Array<Group> {
			// ... (function body is omitted for brevity)
		}

		function buildTexturedMesh(texture2dgroup:Dynamic, triangleProperties:Array<Dynamic>, meshData:Dynamic, objects:Object, modelData:Object, textureData:Object, objectData:Dynamic):Mesh {
			// ... (function body is omitted for brevity)
		}

		function buildVertexColorMesh(colorgroup:Dynamic, triangleProperties:Array<Dynamic>, meshData:Dynamic, objectData:Dynamic):Mesh {
			// ... (function body is omitted for brevity)
		}

		function buildDefaultMesh(meshData:Dynamic):Mesh {
			// ... (function body is omitted for brevity)
		}

		function buildMeshes(resourceMap:Object, meshData:Dynamic, objects:Object, modelData:Object, textureData:Object, objectData:Dynamic):Array<Group> {
			// ... (function body is omitted for brevity)
		}

		function getResourceType(pid:String, modelData:Object):String {
			// ... (function body is omitted for brevity)
		}

		function analyzeObject(meshData:Dynamic, objectData:Dynamic):Object {
			// ... (function body is omitted for brevity)
		}

		function buildGroup(meshData:Dynamic, objects:Object, modelData:Object, textureData:Object, objectData:Dynamic):Group {
			// ... (function body is omitted for brevity)
		}

		return loadDocument(data);
	}

	public function addExtension(extension:Dynamic) {
		this.availableExtensions.push(extension);
	}
}