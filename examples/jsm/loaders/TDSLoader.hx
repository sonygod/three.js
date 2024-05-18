import three.math.Color;
import three.math.Matrix4;
import three.objects.Group;
import three.objects.Mesh;
import three.objects.MeshPhongMaterial;
import three.textures.TextureLoader;
import three.core.BufferGeometry;
import three.core.FileLoader;
import three.core.Loader;
import three.core.LoaderUtils;
import three.core.Matrix4;

class TDSLoader extends Loader {

	public var debug:Bool;
	public var group:Group;
	public var materials:Array<MeshPhongMaterial>;
	public var meshes:Array<Mesh>;

	public function new(manager:Loader.Manager) {
		super(manager);
		this.debug = false;
		this.group = null;
		this.materials = [];
		this.meshes = [];
	}

	public override function load(url:String, onLoad:(Group) -> Void, onProgress:(Float) -> Void, onError:(Dynamic) -> Void):Void {
		var scope = this;
		var path = (this.path == '') ? LoaderUtils.extractUrlBase(url) : this.path;
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(data) {
			try {
				onLoad(scope.parse(data, path));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					trace(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(arraybuffer:ArrayBuffer, path:String):Group {
		this.group = new Group();
		this.materials = [];
		this.meshes = [];
		this.readFile(arraybuffer, path);
		for (i in 0...this.meshes.length) {
			this.group.add(this.meshes[i]);
		}
		return this.group;
	}

	public function readFile(arraybuffer:ArrayBuffer, path:String) {
		var data = new DataView(arraybuffer);
		var chunk = new Chunk(data, 0, this.debugMessage);
		if (chunk.id == MLIBMAGIC || chunk.id == CMAGIC || chunk.id == M3DMAGIC) {
			var next = chunk.readChunk();
			while (next != null) {
				if (next.id == M3D_VERSION) {
					var version = next.readDWord();
					this.debugMessage('3DS file version: ' + version);
				} else if (next.id == MDATA) {
					this.readMeshData(next, path);
				} else {
					this.debugMessage('Unknown main chunk: ' + next.hexId);
				}
				next = chunk.readChunk();
			}
		}
		this.debugMessage('Parsed ' + this.meshes.length + ' meshes');
	}

	public function readMeshData(chunk:Chunk, path:String) {
		var next = chunk.readChunk();
		while (next != null) {
			if (next.id == MESH_VERSION) {
				var version = next.readDWord();
				this.debugMessage('Mesh Version: ' + version);
			} else if (next.id == MASTER_SCALE) {
				var scale = next.readFloat();
				this.debugMessage('Master scale: ' + scale);
				this.group.scale.set(scale, scale, scale);
			} else if (next.id == NAMED_OBJECT) {
				this.debugMessage('Named Object');
				this.readNamedObject(next);
			} else if (next.id == MAT_ENTRY) {
				this.debugMessage('Material');
				this.readMaterialEntry(next, path);
			} else {
				this.debugMessage('Unknown MDATA chunk: ' + next.hexId);
			}
			next = chunk.readChunk();
		}
	}

	public function readNamedObject(chunk:Chunk) {
		var name = chunk.readString();
		var next = chunk.readChunk();
		while (next != null) {
			if (next.id == N_TRI_OBJECT) {
				var mesh = this.readMesh(next);
				mesh.name = name;
				this.meshes.push(mesh);
			} else {
				this.debugMessage('Unknown named object chunk: ' + next.hexId);
			}
			next = chunk.readChunk();
		}
	}

	public function readMaterialEntry(chunk:Chunk, path:String) {
		var next = chunk.readChunk();
		var material = new MeshPhongMaterial();
		while (next != null) {
			if (next.id == MAT_NAME) {
				material.name = next.readString();
				this.debugMessage('   Name: ' + material.name);
			} else if (next.id == MAT_WIRE) {
				this.debugMessage('   Wireframe');
				material.wireframe = true;
			} else if (next.id == MAT_WIRE_SIZE) {
				var value = next.readByte();
				material.wireframeLinewidth = value;
				this.debugMessage('   Wireframe Thickness: ' + value);
			} else if (next.id == MAT_TWO_SIDE) {
				material.side = DoubleSide;
				this.debugMessage('   DoubleSided');
			} else if (next.id == MAT_ADDITIVE) {
				this.debugMessage('   Additive Blending');
				material.blending = AdditiveBlending;
			} else if (next.id == MAT_DIFFUSE) {
				this.debugMessage('   Diffuse Color');
				material.color = this.readColor(next);
			} else if (next.id == MAT_SPECULAR) {
				this.debugMessage('   Specular Color');
				material.specular = this.readColor(next);
			} else if (next.id == MAT_AMBIENT) {
				this.debugMessage('   Ambient color');
				material.color = this.readColor(next);
			} else if (next.id == MAT_SHININESS) {
				var shininess = next.readPercentage();
				material.shininess = shininess * 100;
				this.debugMessage('   Shininess : ' + shininess);
			} else if (next.id == MAT_TRANSPARENCY) {
				var transparency = next.readPercentage();
				material.opacity = 1 - transparency;
				this.debugMessage('  Transparency : ' + transparency);
				material.transparent = (material.opacity < 1);
			} else if (next.id == MAT_TEXMAP) {
				this.debugMessage('   ColorMap');
				material.map = this.readMap(next, path);
			} else if (next.id == MAT_BUMPMAP) {
				this.debugMessage('   BumpMap');
				material.bumpMap = this.readMap(next, path);
			} else if (next.id == MAT_OPACMAP) {
				this.debugMessage('   OpacityMap');
				material.alphaMap = this.readMap(next, path);
			} else if (next.id == MAT_SPECMAP) {
				this.debugMessage('   SpecularMap');
				material.specularMap = this.readMap(next, path);
			} else {
				this.debugMessage('   Unknown material chunk: ' + next.hexId);
			}
			next = chunk.readChunk();
		}
		this.materials[material.name] = material;
	}

	public function readMesh(chunk:Chunk):Mesh {
		var next = chunk.readChunk();
		var geometry = new BufferGeometry();
		var material = new MeshPhongMaterial();
		var mesh = new Mesh(geometry, material);
		mesh.name = 'mesh';
		while (next != null) {
			if (next.id == POINT_ARRAY) {
				var points = next.readWord();
				this.debugMessage('   Vertex: ' + points);
				var vertices = [];
				for (i in 0...points) {
					vertices.push(next.readFloat());
					vertices.push(next.readFloat());
					vertices.push(next.readFloat());
				}
				geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
			} else if (next.id == FACE_ARRAY) {
				this.readFaceArray(next, mesh);
			} else if (next.id == TEX_VERTS) {
				var texels = next.readWord();
				this.debugMessage('   UV: ' + texels);
				var uvs = [];
				for (i in 0...texels) {
					uvs.push(next.readFloat());
					uvs.push(next.readFloat());
				}
				geometry.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
			} else if (next.id == MESH_MATRIX) {
				this.debugMessage('   Tranformation Matrix (TODO)');
				var values = [];
				for (i in 0...12) {
					values[i] = next.readFloat();
				}
				var matrix = new Matrix4();
				//X Line
				matrix.elements[0] = values[0];
				matrix.elements[1] = values[6];
				matrix.elements[2] = values[3];
				matrix.elements[3] = values[9];
				//Y Line
				matrix.elements[4] = values[2];
				matrix.elements[5] = values[8];
				matrix.elements[6] = values[5];
				matrix.elements[7] = values[11];
				//Z Line
				matrix.elements[8] = values[1];
				matrix.elements[9] = values[7];
				matrix.elements[10] = values[4];
				matrix.elements[11] = values[10];
				//W Line
				matrix.elements[12] = 0;
				matrix.elements[13] = 0;
				matrix.elements[14] = 0;
				matrix.elements[15] = 1;
				matrix.transpose();
				var inverse = new Matrix4();
				inverse.copy(matrix).invert();
				geometry.applyMatrix4(inverse);
				matrix.decompose(mesh.position, mesh.quaternion, mesh.scale);
			} else {
				this.debugMessage('   Unknown mesh chunk: ' + next.hexId);
			}
			next = chunk.readChunk();
		}
		geometry.computeVertexNormals();
		return mesh;
	}

	public function readFaceArray(chunk:Chunk, mesh:Mesh) {
		var next = chunk.readChunk();
		var index = [];
		while (next != null) {
			if (next.id == MSH_MAT_GROUP) {
				this.debugMessage('      Material Group');
				var group = this.readMaterialGroup(next);
				var count = group.index.length * 3; // assuming successive indices
				mesh.geometry.addGroup(0, count, group.materialIndex);
				var material = this.materials[group.name];
				if (Array.isArray(mesh.material) == false) mesh.material = [];
				if (material != undefined) {
					mesh.material.push(material);
				}
			} else {
				this.debugMessage('      Unknown face array chunk: ' + next.hexId);
			}
			next = chunk.readChunk();
		}
		if (mesh.material.length == 1) mesh.material = mesh.material[0]; // for backwards compatibility
	}

	public function readMap(chunk:Chunk, path:String):Texture {
		var next = chunk.readChunk();
		var texture = new Texture();
		while (next != null) {
			if (next.id == MAT_MAPNAME) {
				var name = next.readString();
				var loader = new TextureLoader(this.manager);
				loader.setPath(this.resourcePath or path).setCrossOrigin(this.crossOrigin);
				texture = loader.load(name);
				this.debugMessage('      File: ' + path + name);
			} else if (next.id == MAT_MAP_UOFFSET) {
				texture.offset.x = next.readFloat();
				this.debugMessage('      OffsetX: ' + texture.offset.x);
			} else if (next.id == MAT_MAP_VOFFSET) {
				texture.offset.y = next.readFloat();
				this.debugMessage('      OffsetY: ' + texture.offset.y);
			} else if (next.id == MAT_MAP_USCALE) {
				texture.repeat.x = next.readFloat();
				this.debugMessage('      RepeatX: ' + texture.repeat.x);
			} else if (next.id == MAT_MAP_VSCALE) {
				texture.repeat.y = next.readFloat();
				this.debugMessage('      RepeatY: ' + texture.repeat.y);
			} else {
				this.debugMessage('      Unknown map chunk: ' + next.hexId);
			}
			next = chunk.readChunk();
		}
		return texture;
	}

	public function readMaterialGroup(chunk:Chunk):{name:String, index:Array<Int>, materialIndex:Int} {
		var name = chunk.readString();
		var numFaces = chunk.readWord();
		this.debugMessage('         Name: ' + name);
		this.debugMessage('         Faces: ' + numFaces);
		var index = [];
		for (i in 0...numFaces) {
			index.push(chunk.readWord());
		}
		return {name:name, index:index, materialIndex:this.materials.length};
	}

	public function readColor(chunk:Chunk):Color {
		var subChunk = chunk.readChunk();
		var color = new Color();
		if (subChunk.id == COLOR_24 || subChunk.id == LIN_COLOR_24) {
			var r = subChunk.readByte();
			var g = subChunk.readByte();
			var b = subChunk.readByte();
			color.setRGB(r / 255, g / 255, b / 255);
			this.debugMessage('      Color: ' + color.r + ', ' + color.g + ', ' + color.b);
		} else if (subChunk.id == COLOR_F || subChunk.id == LIN_COLOR_F) {
			var r = subChunk.readFloat();
			var g = subChunk.readFloat();
			var b = subChunk.readFloat();
			color.setRGB(r, g, b);
			this.debugMessage('      Color: ' + color.r + ', ' + color.g + ', ' + color.b);
		} else {
			this.debugMessage('      Unknown color chunk: ' + subChunk.hexId);
		}
		return color;
	}

	public function readPercentage(chunk:Chunk):Float {
		var subChunk = chunk.readChunk();
		switch (subChunk.id) {
			case INT_PERCENTAGE:
				return (subChunk.readShort() / 100);
			case FLOAT_PERCENTAGE:
				return subChunk.readFloat();
			default:
				this.debugMessage('      Unknown percentage chunk: ' + subChunk.hexId);
				return 0;
		}
	}

	public function debugMessage(message:Dynamic) {
		if (this.debug) {
			trace(message);
		}
	}
}

class Chunk {
	public var data:DataView;
	public var offset:Int;
	public var position:Int;
	public var debugMessage:(Dynamic) -> Void;
	public var id:Int;
	public var size:Int;
	public var end:Int;
	
	public function new(data:DataView, position:Int, debugMessage:(Dynamic) -> Void) {
		this.data = data;
		this.offset = position;
		this.position = position;
		this.debugMessage = debugMessage;
		this.id = this.readWord();
		this.size = this.readDWord();
		this.end = this.offset + this.size;
		if (this.end > data.byteLength) {
			this.debugMessage('Bad chunk size for chunk at ' + position);
		}
	}
	
	public function readChunk():Chunk {
		if (this.endOfChunk) {
			return null;
		}
		try {
			var next = new Chunk(this.data, this.position, this.debugMessage);
			this.position += next.size;
			return next;
		} catch (e:Dynamic) {
			this.debugMessage('Unable to read chunk at ' + this.position);
			return null;
		}
	}
	
	public function endOfChunk():Bool {
		return this.position >= this.end;
	}
	
	public function readByte():Int {
		var v = this.data.getUint8(this.position, true);
		this.position += 1;
		return v;
	}
	
	public function readFloat():Float {
		var v = this.data.getFloat32(this.position, true);
		this.position += 4;
		return v;
	}
	
	public function readInt():Int {
		var v = this.data.getInt32(this.position, true);
		this.position += 4;
		return v;
	}
	
	public function readShort():Int {
		var v = this.data.getInt16(this.position, true);
		this.position += 2;
		return v;
	}
	
	public function readDWord():Int {
		var v = this.data.getUint32(this.position, true);
		this.position += 4;
		return v;
	}
	
	public function readWord():Int {
		var v = this.data.getUint16(this.position, true);
		this.position += 2;
		return v;
	}
	
	public function readString():String {
		var s = '';
		var c = this.readByte();
		while (c != 0) {
			s += String.fromCharCode(c);
			c = this.readByte();
		}
		return s;
	}
}

const M3DMAGIC = 0x4D4D;
const COLOR_F = 0x0010;
const COLOR_24 = 0x0011;
const LIN_COLOR_24 = 0x0012;
const LIN_COLOR_F = 0x0013;
const INT_PERCENTAGE = 0x0030;
const FLOAT_PERCENTAGE = 0x0031;
const MDATA = 0x3D3D;
const MESH_VERSION = 0x3D3E;
const MASTER_SCALE = 0x0100;
const COLOR_F = 0x0010;
const COLOR_24 = 0x0011;
const LIN_COLOR_24 = 0x0012;
const LIN_COLOR_F = 0x0013;
const INT_PERCENTAGE = 0x0030;
const FLOAT_PERCENTAGE = 0x0031;
const MAT_NAME = 0xA000;
const MAT_AMBIENT = 0xA010;
const MAT_DIFFUSE = 0xA020;
const MAT_SPECULAR = 0xA030;
const MAT_SHININESS = 0xA040;
const MAT_TWO_SIDE = 0xA081;
const MAT_ADDITIVE = 0xA083;
const MAT_WIRE = 0xA085;
const MAT_WIRE_SIZE = 0xA087;
const MAT_TEXMAP = 0xA200;
const MAT_MAPNAME = 0xA300;
const MAT_MAP_USCALE = 0xA354;
const MAT_MAP_VSCALE = 0xA356;
const MAT_MAP_UOFFSET = 0xA358;
const MAT_MAP_VOFFSET = 0xA35A;
const NAMED_OBJECT = 0x4000;
const N_TRI_OBJECT = 0x4100;
const POINT_ARRAY = 0x4110;
const FACE_ARRAY = 0x4120;
const MSH_MAT_GROUP = 0x4130;
const TEX_VERTS = 0x4140;
const MESH_MATRIX = 0x4160;

export class TDSLoader {}