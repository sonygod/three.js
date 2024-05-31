import three.core.BufferGeometry;
import three.core.Group;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.materials.MeshPhongMaterial;
import three.math.Color;
import three.objects.Mesh;
import three.core.BufferAttribute;

// Import fflate in a way that works for your Haxe setup,
// for example using an extern or a Haxe library.
// Here's a placeholder assuming a Haxe library named "fflate":
import fflate.Inflate;

/**
 * Description: Early release of an AMF Loader following the pattern of the
 * example loaders in the three.js project.
 *
 * Usage:
 *	var loader = new AMFLoader();
 *	loader.load('/path/to/project.amf', function(objecttree) {
 *		scene.add(objecttree);
 *	});
 *
 * Materials now supported, material colors supported
 * Zip support, requires fflate
 * No constellation support (yet)!
 */
class AMFLoader extends Loader {

	public function new(manager:Loader = null) {
		super(manager);
	}

	override public function load(url:String, onLoad:FileLoader->Void->Void, ?onProgress:FileLoader->Int->Void, ?onError:FileLoader->String->Void):Void {
		var loader = new FileLoader(manager);
		loader.setPath(path);
		loader.setResponseType("arraybuffer");
		loader.setRequestHeader(requestHeader);
		loader.setWithCredentials(withCredentials);
		loader.load(url, function(data:Dynamic) {
			try {
				onLoad(parse(data));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					trace('Error: $e');
				}
				manager.itemError(url);
			}
		}, onProgress, onError);
	}

	private function parse(data:js.lib.ArrayBuffer):Group {
		function loadDocument(data:js.lib.ArrayBuffer):Xml {
			var view = new DataView(data);
			var magic = String.fromCharCode(view.getUint8(0), view.getUint8(1));

			if (magic == "PK") {
				var zip = null;
				var file = null;

				trace("THREE.AMFLoader: Loading Zip");

				try {
					// Assuming fflate.unzipSync returns a Map<String, Bytes>
					zip = Inflate.inflate(haxe.io.Bytes.ofData(data)).toString();
				} catch (e:Dynamic) {
					trace('Error: $e');
					return null;
				}

				for (key in zip.keys()) {
					file = key;
					if (file.toLowerCase().substr(-4) == ".amf") {
						break;
					}
				}

				trace("THREE.AMFLoader: Trying to load file asset: " + file);
				// Assuming zip[file] gives you access to the file content as Bytes
				view = new DataView(zip.get(file).getData().buffer);
			}

			var fileText:String = new haxe.io.Utf8(view).toString();
			var xmlData = Xml.parse(fileText);

			if (xmlData.nodeType != Xml.Document || xmlData.firstElement().nodeName.toLowerCase() != "amf") {
				trace("THREE.AMFLoader: Error loading AMF - no AMF document found.");
				return null;
			}

			return xmlData;
		}

		function loadDocumentScale(node:Xml):Float {
			var scale = 1.0;
			var unit = "millimeter";

			if (node.exists("@unit")) {
				unit = node.get("unit").toLowerCase();
			}

			var scaleUnits = {
				"millimeter": 1.0,
				"inch": 25.4,
				"feet": 304.8,
				"meter": 1000.0,
				"micron": 0.001
			};

			if (scaleUnits.exists(unit)) {
				scale = scaleUnits[unit];
			}

			trace("THREE.AMFLoader: Unit scale: " + scale);
			return scale;
		}

		function loadMaterials(node:Xml):{id:String, material:MeshPhongMaterial} {
			var matName = "AMF Material";
			var matId = node.get("id");
			var color = {r: 1.0, g: 1.0, b: 1.0, a: 1.0};

			for (matChildEl in node.elements()) {
				if (matChildEl.nodeName == "metadata" && matChildEl.exists("@type")) {
					if (matChildEl.get("type") == "name") {
						matName = matChildEl.innerHTML();
					}
				} else if (matChildEl.nodeName == "color") {
					color = loadColor(matChildEl);
				}
			}

			var loadedMaterial = new MeshPhongMaterial({
				flatShading: true,
				color: new Color(color.r, color.g, color.b),
				name: matName
			});

			if (color.a != 1.0) {
				loadedMaterial.transparent = true;
				loadedMaterial.opacity = color.a;
			}

			return {id: matId, material: loadedMaterial};
		}

		function loadColor(node:Xml):{r:Float, g:Float, b:Float, a:Float} {
			var color = {r: 1.0, g: 1.0, b: 1.0, a: 1.0};

			for (matColor in node.elements()) {
				switch (matColor.nodeName) {
					case "r":
						color.r = Std.parseFloat(matColor.innerHTML());
					case "g":
						color.g = Std.parseFloat(matColor.innerHTML());
					case "b":
						color.b = Std.parseFloat(matColor.innerHTML());
					case "a":
						color.a = Std.parseFloat(matColor.innerHTML());
				}
			}

			return color;
		}
        
		function loadMeshVolume(node:Xml):{name:String, triangles:Array<Int>, materialId:String} {
			var volume = {name: "", triangles: [], materialId: null};
			var currVolumeNode = node.firstChild();

			if (node.exists("@materialid")) {
				volume.materialId = node.get("materialid");
			}

			while (currVolumeNode != null) {
				switch (currVolumeNode.nodeName) {
					case "metadata":
						if (currVolumeNode.exists("@type") && currVolumeNode.get("type") == "name") {
							volume.name = currVolumeNode.innerHTML();
						}
					case "triangle":
						var v1 = Std.parseInt(currVolumeNode.elementsNamed("v1").next().innerHTML());
						var v2 = Std.parseInt(currVolumeNode.elementsNamed("v2").next().innerHTML());
						var v3 = Std.parseInt(currVolumeNode.elementsNamed("v3").next().innerHTML());
						volume.triangles.push(v1, v2, v3);
				}
				currVolumeNode = currVolumeNode.nextSibling();
			}
            
			return volume;
		}

		function loadMeshVertices(node:Xml):{vertices:Array<Float>, normals:Array<Float>} {
			var vertArray = [];
			var normalArray = [];
			var currVerticesNode = node.firstChild();

			while (currVerticesNode != null) {
				if (currVerticesNode.nodeName == "vertex") {
					var vNode = currVerticesNode.firstChild();
					while (vNode != null) {
						switch (vNode.nodeName) {
							case "coordinates":
								var x = Std.parseFloat(vNode.elementsNamed("x").next().innerHTML());
								var y = Std.parseFloat(vNode.elementsNamed("y").next().innerHTML());
								var z = Std.parseFloat(vNode.elementsNamed("z").next().innerHTML());
								vertArray.push(x, y, z);
							case "normal":
								var nx = Std.parseFloat(vNode.elementsNamed("nx").next().innerHTML());
								var ny = Std.parseFloat(vNode.elementsNamed("ny").next().innerHTML());
								var nz = Std.parseFloat(vNode.elementsNamed("nz").next().innerHTML());
								normalArray.push(nx, ny, nz);
						}
						vNode = vNode.nextSibling();
					}
				}
				currVerticesNode = currVerticesNode.nextSibling();
			}

			return {vertices: vertArray, normals: normalArray};
		}

		function loadObject(node:Xml):{id:String, obj:{name:String, meshes:Array<Dynamic>}} {
			var objId = node.get("id");
			var loadedObject = {name: "amfobject", meshes: []};
			var currColor = null;
			var currObjNode = node.firstChild();

			while (currObjNode != null) {
				switch (currObjNode.nodeName) {
					case "metadata":
						if (currObjNode.exists("@type") && currObjNode.get("type") == "name") {
							loadedObject.name = currObjNode.innerHTML();
						}
					case "color":
						currColor = loadColor(currObjNode);
					case "mesh":
						var currMeshNode = currObjNode.firstChild();
						var mesh = {vertices: [], normals: [], volumes: [], color: currColor};

						while (currMeshNode != null) {
							switch (currMeshNode.nodeName) {
								case "vertices":
									var loadedVertices = loadMeshVertices(currMeshNode);
									mesh.normals = mesh.normals.concat(loadedVertices.normals);
									mesh.vertices = mesh.vertices.concat(loadedVertices.vertices);
								case "volume":
									mesh.volumes.push(loadMeshVolume(currMeshNode));
							}
							currMeshNode = currMeshNode.nextSibling();
						}
						loadedObject.meshes.push(mesh);
				}
				currObjNode = currObjNode.nextSibling();
			}
			return {id: objId, obj: loadedObject};
		}

		var xmlData:Xml = loadDocument(data);
		var amfName = "";
		var amfAuthor = "";
		var amfScale = loadDocumentScale(xmlData);
		var amfMaterials = new Map<String, MeshPhongMaterial>();
		var amfObjects = new Map<String, Dynamic>();

		for (child in xmlData.firstElement().elements()) {
			switch (child.nodeName) {
				case "metadata":
					if (child.exists("@type")) {
						switch (child.get("type")) {
							case "name":
								amfName = child.innerHTML();
							case "author":
								amfAuthor = child.innerHTML();
						}
					}
				case "material":
					var loadedMaterial = loadMaterials(child);
					amfMaterials.set(loadedMaterial.id, loadedMaterial.material);
				case "object":
					var loadedObject = loadObject(child);
					amfObjects.set(loadedObject.id, loadedObject.obj);
			}
		}

		var sceneObject = new Group();
		var defaultMaterial = new MeshPhongMaterial({
			name: Loader.DEFAULT_MATERIAL_NAME,
			color: new Color(0xaaaaff),
			flatShading: true
		});
        
		sceneObject.name = amfName;
		sceneObject.userData.author = amfAuthor;
		sceneObject.userData.loader = "AMF";

		for (id in amfObjects.keys()) {
			var part = amfObjects.get(id);
			var meshes:Array<Dynamic> = part.meshes;
			var newObject = new Group();
			newObject.name = part.name;

			for (i in 0...meshes.length) {
				var objDefaultMaterial = defaultMaterial;
				var mesh:Dynamic = meshes[i];
				var vertices = new BufferAttribute(new Float32Array(mesh.vertices), 3);
				var normals = null;
                
				if (mesh.normals.length > 0) {
					normals = new BufferAttribute(new Float32Array(mesh.normals), 3);
				}

				if (mesh.color != null) {
					var color = mesh.color;
					objDefaultMaterial = defaultMaterial.clone();
					objDefaultMaterial.color = new Color(color.r, color.g, color.b);
					if (color.a != 1.0) {
						objDefaultMaterial.transparent = true;
						objDefaultMaterial.opacity = color.a;
					}
				}
                
				var volumes:Array<Dynamic> = mesh.volumes;

				for (j in 0...volumes.length) {
					var volume:Dynamic = volumes[j];
					var newGeometry = new BufferGeometry();
					var material = objDefaultMaterial;

					newGeometry.setIndex(new BufferAttribute(new Uint16Array(volume.triangles), 1));
					newGeometry.setAttribute("position", vertices.clone());

					if (normals != null) {
						newGeometry.setAttribute("normal", normals.clone());
					}

					if (amfMaterials.exists(volume.materialId)) {
						material = amfMaterials.get(volume.materialId);
					}

					newGeometry.scale(amfScale, amfScale, amfScale);
					newObject.add(new Mesh(newGeometry, material.clone()));
				}
			}

			sceneObject.add(newObject);
		}

		return sceneObject;
	}
}