import three.math.Color;
import three.core.BufferGeometry;
import three.core.FileLoader;
import three.core.Float32BufferAttribute;
import three.objects.Group;
import three.objects.Mesh;
import three.materials.MeshPhongMaterial;
import js.typedarrays.Uint8Array;
import js.typedarrays.DataView;
import js.xml.XML;
import js.xml.parser.DOMParser;
import js.text.TextDecoder;
import three.loaders.Loader;
import three.loaders.LoaderUtils;

class AMFLoader extends Loader {

	public function new(manager:Loader.Manager)
	{
		super(manager);
	}

	override public function load(url:String, onLoad:Void -> Void, onProgress:Float -> Void, onError:Dynamic -> Void):Void {
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(text:ArrayBuffer) {
			try {
				onLoad(this.parse(text));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				this.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(data:ArrayBuffer):Group {
		function loadDocument(data:ArrayBuffer):XML {
			var view = new DataView(data);
			var magic = LoaderUtils.decodeText(new Uint8Array([view.getUint8(0), view.getUint8(1)]));
			if (magic == "PK") {
				var zip = null;
				var file = null;
				console.log("THREE.AMFLoader: Loading Zip");
				try {
					zip = fflate.unzipSync(new Uint8Array(data));
				} catch (e:Dynamic) {
					if (Std.is(e, js.typedarrays.ReferenceError)) {
						console.log("THREE.AMFLoader: fflate missing and file is compressed.");
						return null;
					}
				}
				for (file in zip) {
					if (file.toLowerCase().slice(-4) === ".amf") {
						break;
					}
				}
				console.log("THREE.AMFLoader: Trying to load file asset: " + file);
				view = new DataView(zip[file].buffer);
			}
			var fileText = new TextDecoder().decode(view);
			var xmlData = new DOMParser().parseFromString(fileText, "application/xml");
			if (xmlData.documentElement.nodeName.toLowerCase() !== "amf") {
				console.log("THREE.AMFLoader: Error loading AMF - no AMF document found.");
				return null;
			}
			return xmlData;
		}
		function loadDocumentScale(node:XML):Float {
			var scale = 1.0;
			var unit = "millimeter";
			if (node.documentElement.attributes.unit != undefined) {
				unit = node.documentElement.attributes.unit.value.toLowerCase();
			}
			var scaleUnits = {
				millimeter: 1.0,
				inch: 25.4,
				feet: 304.8,
				meter: 1000.0,
				micron: 0.001
			};
			if (scaleUnits[unit] != undefined) {
				scale = scaleUnits[unit];
			}
			console.log("THREE.AMFLoader: Unit scale: " + scale);
			return scale;
		}
		function loadMaterials(node:XML):Array<Dynamic>