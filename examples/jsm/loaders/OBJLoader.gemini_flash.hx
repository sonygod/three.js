import three.core.BufferGeometry;
import three.loaders.FileLoader;
import three.core.Float32BufferAttribute;
import three.core.Group;
import three.materials.LineBasicMaterial;
import three.objects.LineSegments;
import three.loaders.Loader;
import three.materials.Material;
import three.objects.Mesh;
import three.materials.MeshPhongMaterial;
import three.objects.Points;
import three.materials.PointsMaterial;
import three.math.Vector3;
import three.math.Color;

class ParserState {
	public objects:Array<Dynamic> = [];
	public object:Dynamic = {};

	public vertices:Array<Float> = [];
	public normals:Array<Float> = [];
	public colors:Array<Float> = [];
	public uvs:Array<Float> = [];

	public materials:Dynamic = {};
	public materialLibraries:Array<String> = [];

	public startObject(name:String, fromDeclaration:Bool) {
		if (this.object != null && cast(this.object, { fromDeclaration: Bool }).fromDeclaration == false) {
			cast(this.object, { name: String }).name = name;
			cast(this.object, { fromDeclaration: Bool }).fromDeclaration = (fromDeclaration != false);
			return;
		}

		var previousMaterial = (this.object != null && Reflect.hasField(this.object, 'currentMaterial') ? Reflect.field(this.object, 'currentMaterial') : null);

		if (this.object != null && Reflect.hasField(this.object, '_finalize')) {
			Reflect.callMethod(this.object, '_finalize', [true]);
		}

		this.object = {
			name: name == null ? "" : name,
			fromDeclaration: (fromDeclaration != false),

			geometry: {
				vertices: [],
				normals: [],
				colors: [],
				uvs: [],
				hasUVIndices: false
			},
			materials: [],
			smooth: true,

			startMaterial: function(name:String, libraries:Array<String>) {
				var previous = this._finalize(false);

				if (previous != null && ((previous.inherited == true) || (previous.groupCount <= 0))) {
					this.materials.splice(previous.index, 1);
				}

				var material = {
					index: this.materials.length,
					name: name == null ? "" : name,
					mtllib: (libraries.length > 0 ? libraries[libraries.length - 1] : ""),
					smooth: (previous != null ? previous.smooth : this.smooth),
					groupStart: (previous != null ? previous.groupEnd : 0),
					groupEnd: -1,
					groupCount: -1,
					inherited: false,

					clone: function(index:Int) {
						var cloned = {
							index: (index != null ? index : this.index),
							name: this.name,
							mtllib: this.mtllib,
							smooth: this.smooth,
							groupStart: 0,
							groupEnd: -1,
							groupCount: -1,
							inherited: false
						};
						cloned.clone = this.clone.bind(cloned);
						return cloned;
					}
				};

				this.materials.push(material);

				return material;
			},

			currentMaterial: function() {
				if (this.materials.length > 0) {
					return this.materials[this.materials.length - 1];
				}

				return null;
			},

			_finalize: function(end:Bool) {
				var lastMultiMaterial = this.currentMaterial();
				if (lastMultiMaterial != null && lastMultiMaterial.groupEnd == -1) {
					lastMultiMaterial.groupEnd = this.geometry.vertices.length / 3;
					lastMultiMaterial.groupCount = lastMultiMaterial.groupEnd - lastMultiMaterial.groupStart;
					lastMultiMaterial.inherited = false;
				}

				if (end && this.materials.length > 1) {
					for (var mi = this.materials.length - 1; mi >= 0; mi--) {
						if (this.materials[mi].groupCount <= 0) {
							this.materials.splice(mi, 1);
						}
					}
				}

				if (end && this.materials.length == 0) {
					this.materials.push({
						name: "",
						smooth: this.smooth
					});
				}

				return lastMultiMaterial;
			}
		};

		if (previousMaterial != null && previousMaterial.name != null && Reflect.hasField(previousMaterial, 'clone')) {
			var declared = Reflect.callMethod(previousMaterial, 'clone', [0]);
			cast(declared, { inherited: Bool }).inherited = true;
			this.object.materials.push(declared);
		}

		this.objects.push(this.object);
	}

	public finalize() {
		if (this.object != null && Reflect.hasField(this.object, '_finalize')) {
			Reflect.callMethod(this.object, '_finalize', [true]);
		}
	}

	public parseVertexIndex(value:String, len:Int):Int {
		var index = Std.parseInt(value);
		return (index >= 0 ? index - 1 : index + len / 3) * 3;
	}

	public parseNormalIndex(value:String, len:Int):Int {
		var index = Std.parseInt(value);
		return (index >= 0 ? index - 1 : index + len / 3) * 3;
	}

	public parseUVIndex(value:String, len:Int):Int {
		var index = Std.parseInt(value);
		return (index >= 0 ? index - 1 : index + len / 2) * 2;
	}

	public addVertex(a:Int, b:Int, c:Int) {
		var src = this.vertices;
		var dst = cast(this.object.geometry, { vertices: Array<Float> }).vertices;

		dst.push(src[a + 0], src[a + 1], src[a + 2]);
		dst.push(src[b + 0], src[b + 1], src[b + 2]);
		dst.push(src[c + 0], src[c + 1], src[c + 2]);
	}

	public addVertexPoint(a:Int) {
		var src = this.vertices;
		var dst = cast(this.object.geometry, { vertices: Array<Float> }).vertices;

		dst.push(src[a + 0], src[a + 1], src[a + 2]);
	}

	public addVertexLine(a:Int) {
		var src = this.vertices;
		var dst = cast(this.object.geometry, { vertices: Array<Float> }).vertices;

		dst.push(src[a + 0], src[a + 1], src[a + 2]);
	}

	public addNormal(a:Int, b:Int, c:Int) {
		var src = this.normals;
		var dst = cast(this.object.geometry, { normals: Array<Float> }).normals;

		dst.push(src[a + 0], src[a + 1], src[a + 2]);
		dst.push(src[b + 0], src[b + 1], src[b + 2]);
		dst.push(src[c + 0], src[c + 1], src[c + 2]);
	}

	public addFaceNormal(a:Int, b:Int, c:Int) {
		var src = this.vertices;
		var dst = cast(this.object.geometry, { normals: Array<Float> }).normals;

		var _vA = new Vector3();
		var _vB = new Vector3();
		var _vC = new Vector3();

		var _ab = new Vector3();
		var _cb = new Vector3();

		_vA.fromArray(src, a);
		_vB.fromArray(src, b);
		_vC.fromArray(src, c);

		_cb.subVectors(_vC, _vB);
		_ab.subVectors(_vA, _vB);
		_cb.cross(_ab);

		_cb.normalize();

		dst.push(_cb.x, _cb.y, _cb.z);
		dst.push(_cb.x, _cb.y, _cb.z);
		dst.push(_cb.x, _cb.y, _cb.z);
	}

	public addColor(a:Int, b:Int, c:Int) {
		var src = this.colors;
		var dst = cast(this.object.geometry, { colors: Array<Float> }).colors;

		if (src[a] != null) dst.push(src[a + 0], src[a + 1], src[a + 2]);
		if (src[b] != null) dst.push(src[b + 0], src[b + 1], src[b + 2]);
		if (src[c] != null) dst.push(src[c + 0], src[c + 1], src[c + 2]);
	}

	public addUV(a:Int, b:Int, c:Int) {
		var src = this.uvs;
		var dst = cast(this.object.geometry, { uvs: Array<Float> }).uvs;

		dst.push(src[a + 0], src[a + 1]);
		dst.push(src[b + 0], src[b + 1]);
		dst.push(src[c + 0], src[c + 1]);
	}

	public addDefaultUV() {
		var dst = cast(this.object.geometry, { uvs: Array<Float> }).uvs;

		dst.push(0, 0);
		dst.push(0, 0);
		dst.push(0, 0);
	}

	public addUVLine(a:Int) {
		var src = this.uvs;
		var dst = cast(this.object.geometry, { uvs: Array<Float> }).uvs;

		dst.push(src[a + 0], src[a + 1]);
	}

	public addFace(a:String, b:String, c:String, ua:String, ub:String, uc:String, na:String, nb:String, nc:String) {
		var vLen = this.vertices.length;

		var ia = this.parseVertexIndex(a, vLen);
		var ib = this.parseVertexIndex(b, vLen);
		var ic = this.parseVertexIndex(c, vLen);

		this.addVertex(ia, ib, ic);
		this.addColor(ia, ib, ic);

		if (na != null && na != "") {
			var nLen = this.normals.length;

			ia = this.parseNormalIndex(na, nLen);
			ib = this.parseNormalIndex(nb, nLen);
			ic = this.parseNormalIndex(nc, nLen);

			this.addNormal(ia, ib, ic);
		} else {
			this.addFaceNormal(ia, ib, ic);
		}

		if (ua != null && ua != "") {
			var uvLen = this.uvs.length;

			ia = this.parseUVIndex(ua, uvLen);
			ib = this.parseUVIndex(ub, uvLen);
			ic = this.parseUVIndex(uc, uvLen);

			this.addUV(ia, ib, ic);

			cast(this.object.geometry, { hasUVIndices: Bool }).hasUVIndices = true;
		} else {
			this.addDefaultUV();
		}
	}

	public addPointGeometry(vertices:Array<String>) {
		cast(this.object.geometry, { type: String }).type = "Points";

		var vLen = this.vertices.length;

		for (var vi = 0; vi < vertices.length; vi++) {
			var index = this.parseVertexIndex(vertices[vi], vLen);

			this.addVertexPoint(index);
			this.addColor(index);
		}
	}

	public addLineGeometry(vertices:Array<String>, uvs:Array<String>) {
		cast(this.object.geometry, { type: String }).type = "Line";

		var vLen = this.vertices.length;
		var uvLen = this.uvs.length;

		for (var vi = 0; vi < vertices.length; vi++) {
			this.addVertexLine(this.parseVertexIndex(vertices[vi], vLen));
		}

		for (var uvi = 0; uvi < uvs.length; uvi++) {
			this.addUVLine(this.parseUVIndex(uvs[uvi], uvLen));
		}
	}
}

class OBJLoader extends Loader {
	public materials:Dynamic = null;

	public new(manager:Dynamic) {
		super(manager);
	}

	public load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
		var scope = this;

		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(scope.parse(text));
			} catch (e) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}

				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public setMaterials(materials:Dynamic):OBJLoader {
		this.materials = materials;

		return this;
	}

	public parse(text:String):Group {
		var state = new ParserState();

		if (text.indexOf("\r\n") != -1) {
			text = text.replace(/\r\n/g, "\n");
		}

		if (text.indexOf("\\\n") != -1) {
			text = text.replace(/\\\n/g, "");
		}

		var lines = text.split("\n");
		var result:Array<Dynamic> = [];

		for (var i = 0; i < lines.length; i++) {
			var line = lines[i].trim();

			if (line.length == 0) continue;

			var lineFirstChar = line.charAt(0);

			if (lineFirstChar == "#") continue;

			if (lineFirstChar == "v") {
				var data = line.split(/\s+/);

				switch (data[0]) {
					case "v":
						state.vertices.push(Std.parseFloat(data[1]), Std.parseFloat(data[2]), Std.parseFloat(data[3]));
						if (data.length >= 7) {
							var _color = new Color();
							_color.setRGB(Std.parseFloat(data[4]), Std.parseFloat(data[5]), Std.parseFloat(data[6])).convertSRGBToLinear();
							state.colors.push(_color.r, _color.g, _color.b);
						} else {
							state.colors.push(null, null, null);
						}

						break;
					case "vn":
						state.normals.push(Std.parseFloat(data[1]), Std.parseFloat(data[2]), Std.parseFloat(data[3]));
						break;
					case "vt":
						state.uvs.push(Std.parseFloat(data[1]), Std.parseFloat(data[2]));
						break;
				}
			} else if (lineFirstChar == "f") {
				var lineData = line.substring(1).trim();
				var vertexData = lineData.split(/\s+/);
				var faceVertices:Array<Array<String>> = [];

				for (var j = 0; j < vertexData.length; j++) {
					var vertex = vertexData[j];

					if (vertex.length > 0) {
						var vertexParts = vertex.split("/");
						faceVertices.push(vertexParts);
					}
				}

				var v1 = faceVertices[0];

				for (var j = 1; j < faceVertices.length - 1; j++) {
					var v2 = faceVertices[j];
					var v3 = faceVertices[j + 1];

					state.addFace(v1[0], v2[0], v3[0], v1[1], v2[1], v3[1], v1[2], v2[2], v3[2]);
				}
			} else if (lineFirstChar == "l") {
				var lineParts = line.substring(1).trim().split(" ");
				var lineVertices:Array<String> = [];
				var lineUVs:Array<String> = [];

				if (line.indexOf("/") == -1) {
					lineVertices = lineParts;
				} else {
					for (var li = 0; li < lineParts.length; li++) {
						var parts = lineParts[li].split("/");

						if (parts[0] != "") lineVertices.push(parts[0]);
						if (parts[1] != "") lineUVs.push(parts[1]);
					}
				}

				state.addLineGeometry(lineVertices, lineUVs);
			} else if (lineFirstChar == "p") {
				var lineData = line.substring(1).trim();
				var pointData = lineData.split(" ");

				state.addPointGeometry(pointData);
			} else if ((result = line.match(/^[og]\s*(.+)?/)) != null) {
				var name = (" " + result[0].substring(1).trim()).substring(1);

				state.startObject(name);
			} else if (line.match(/^usemtl /) != null) {
				state.object.startMaterial(line.substring(7).trim(), state.materialLibraries);
			} else if (line.match(/^mtllib /) != null) {
				state.materialLibraries.push(line.substring(7).trim());
			} else if (line.match(/^usemap /) != null) {
				console.warn("THREE.OBJLoader: Rendering identifier \"usemap\" not supported. Textures must be defined in MTL files.");
			} else if (lineFirstChar == "s") {
				result = line.split(" ");

				if (result.length > 1) {
					var value = result[1].trim().toLowerCase();
					cast(state.object, { smooth: Bool }).smooth = (value != "0" && value != "off");
				} else {
					cast(state.object, { smooth: Bool }).smooth = true;
				}

				var material = state.object.currentMaterial();
				if (material != null) cast(material, { smooth: Bool }).smooth = cast(state.object, { smooth: Bool }).smooth;
			} else {
				if (line == "\0") continue;

				console.warn("THREE.OBJLoader: Unexpected line: \"" + line + "\"");
			}
		}

		state.finalize();

		var container = new Group();
		container.materialLibraries = state.materialLibraries.copy();

		var hasPrimitives = !(state.objects.length == 1 && cast(state.objects[0].geometry, { vertices: Array<Float> }).vertices.length == 0);

		if (hasPrimitives == true) {
			for (var i = 0; i < state.objects.length; i++) {
				var object = state.objects[i];
				var geometry = object.geometry;
				var materials = object.materials;
				var isLine = (cast(geometry, { type: String }).type == "Line");
				var isPoints = (cast(geometry, { type: String }).type == "Points");
				var hasVertexColors = false;

				if (cast(geometry, { vertices: Array<Float> }).vertices.length == 0) continue;

				var buffergeometry = new BufferGeometry();

				buffergeometry.setAttribute("position", new Float32BufferAttribute(cast(geometry, { vertices: Array<Float> }).vertices, 3));

				if (cast(geometry, { normals: Array<Float> }).normals.length > 0) {
					buffergeometry.setAttribute("normal", new Float32BufferAttribute(cast(geometry, { normals: Array<Float> }).normals, 3));
				}

				if (cast(geometry, { colors: Array<Float> }).colors.length > 0) {
					hasVertexColors = true;
					buffergeometry.setAttribute("color", new Float32BufferAttribute(cast(geometry, { colors: Array<Float> }).colors, 3));
				}

				if (cast(geometry, { hasUVIndices: Bool }).hasUVIndices == true) {
					buffergeometry.setAttribute("uv", new Float32BufferAttribute(cast(geometry, { uvs: Array<Float> }).uvs, 2));
				}

				var createdMaterials:Array<Dynamic> = [];

				for (var mi = 0; mi < materials.length; mi++) {
					var sourceMaterial = materials[mi];
					var materialHash = sourceMaterial.name + "_" + sourceMaterial.smooth + "_" + hasVertexColors;
					var material = cast(state.materials, { [materialHash]: Dynamic })[materialHash];

					if (this.materials != null) {
						material = this.materials.create(sourceMaterial.name);

						if (isLine && material != null && !(material is LineBasicMaterial)) {
							var materialLine = new LineBasicMaterial();
							Material.prototype.copy.call(materialLine, material);
							materialLine.color.copy(material.color);
							material = materialLine;
						} else if (isPoints && material != null && !(material is PointsMaterial)) {
							var materialPoints = new PointsMaterial({ size: 10, sizeAttenuation: false });
							Material.prototype.copy.call(materialPoints, material);
							materialPoints.color.copy(material.color);
							materialPoints.map = material.map;
							material = materialPoints;
						}
					}

					if (material == null) {
						if (isLine) {
							material = new LineBasicMaterial();
						} else if (isPoints) {
							material = new PointsMaterial({ size: 1, sizeAttenuation: false });
						} else {
							material = new MeshPhongMaterial();
						}

						material.name = sourceMaterial.name;
						material.flatShading = sourceMaterial.smooth ? false : true;
						material.vertexColors = hasVertexColors;

						cast(state.materials, { [materialHash]: Dynamic })[materialHash] = material;
					}

					createdMaterials.push(material);
				}

				var mesh:Dynamic;

				if (createdMaterials.length > 1) {
					for (var mi = 0; mi < materials.length; mi++) {
						var sourceMaterial = materials[mi];
						buffergeometry.addGroup(sourceMaterial.groupStart, sourceMaterial.groupCount, mi);
					}

					if (isLine) {
						mesh = new LineSegments(buffergeometry, createdMaterials);
					} else if (isPoints) {
						mesh = new Points(buffergeometry, createdMaterials);
					} else {
						mesh = new Mesh(buffergeometry, createdMaterials);
					}
				} else {
					if (isLine) {
						mesh = new LineSegments(buffergeometry, createdMaterials[0]);
					} else if (isPoints) {
						mesh = new Points(buffergeometry, createdMaterials[0]);
					} else {
						mesh = new Mesh(buffergeometry, createdMaterials[0]);
					}
				}

				mesh.name = object.name;

				container.add(mesh);
			}
		} else {
			if (cast(state.vertices, { length: Int }).length > 0) {
				var material = new PointsMaterial({ size: 1, sizeAttenuation: false });

				var buffergeometry = new BufferGeometry();

				buffergeometry.setAttribute("position", new Float32BufferAttribute(state.vertices, 3));

				if (cast(state.colors, { length: Int }).length > 0 && state.colors[0] != null) {
					buffergeometry.setAttribute("color", new Float32BufferAttribute(state.colors, 3));
					material.vertexColors = true;
				}

				var points = new Points(buffergeometry, material);
				container.add(points);
			}
		}

		return container;
	}
}