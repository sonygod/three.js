import DataViewReader.hx;
import Debugger.hx;
import LWO2Parser.hx;
import LWO3Parser.hx;

class IFFParser {

	public var debugger:Debugger;
	public var reader:DataViewReader;
	public var tree:Dynamic;
	public var currentLayer:Dynamic;
	public var currentForm:Dynamic;
	public var currentSurface:Dynamic;
	public var currentPoints:Array<Float>;
	public var parser:Dynamic;

	public function new() {
		this.debugger = new Debugger();
		// this.debugger.enable(); // un-comment to log IFF hierarchy.
	}

	public function parse(buffer:ArrayBuffer):Dynamic {
		this.reader = new DataViewReader(buffer);

		this.tree = {
			materials: {},
			layers: [],
			tags: [],
			textures: [],
		};

		// start out at the top level to add any data before first layer is encountered
		this.currentLayer = this.tree;
		this.currentForm = this.tree;

		this.parseTopForm();

		if (this.tree.format === null) return;

		if (this.tree.format === 'LWO2') {

			this.parser = new LWO2Parser(this);
			while (!this.reader.endOfFile()) this.parser.parseBlock();

		} else if (this.tree.format === 'LWO3') {

			this.parser = new LWO3Parser(this);
			while (!this.reader.endOfFile()) this.parser.parseBlock();

		}

		this.debugger.offset = this.reader.offset;
		this.debugger.closeForms();

		return this.tree;
	}

	public function parseTopForm():Void {

		this.debugger.offset = this.reader.offset;

		var topForm = this.reader.getIDTag();

		if (topForm !== 'FORM') {

			trace('LWOLoader: Top-level FORM missing.');
			return;

		}

		var length = this.reader.getUint32();

		this.debugger.dataOffset = this.reader.offset;
		this.debugger.length = length;

		var type = this.reader.getIDTag();

		if (type === 'LWO2') {

			this.tree.format = type;

		} else if (type === 'LWO3') {

			this.tree.format = type;

		}

		this.debugger.node = 0;
		this.debugger.nodeID = type;
		this.debugger.log();

		return;
	}

	// FORM PARSING METHODS

	public function parseForm(length:Int):Void {
		var type = this.reader.getIDTag();

		switch (type) {

			// SKIPPED FORMS
			// if skipForm( length ) is called, the entire form and any sub forms and chunks are skipped
			case 'ISEQ': // Image sequence
			case 'ANIM': // plug in animation
			case 'STCC': // Color-cycling Still
			case 'VPVL':
			case 'VPRM':
			case 'NROT':
			case 'WRPW': // image wrap w ( for cylindrical and spherical projections)
			case 'WRPH': // image wrap h
			case 'FUNC':
			case 'FALL':
			case 'OPAC':
			case 'GRAD': // gradient texture
			case 'ENVS':
			case 'VMOP':
			case 'VMBG':

			// Car Material FORMS
			case 'OMAX':
			case 'STEX':
			case 'CKBG':
			case 'CKEY':
			case 'VMLA':
			case 'VMLB':
				this.debugger.skipped = true;
				this.skipForm(length); // not currently supported
				break;

			// if break; is called directly, the position in the lwoTree is not created
			// any sub chunks and forms are added to the parent form instead
			case 'META':
			case 'NNDS':
			case 'NODS':
			case 'NDTA':
			case 'ADAT':
			case 'AOVS':
			case 'BLOK':

			// used by texture nodes
			case 'IBGC': // imageBackgroundColor
			case 'IOPC': // imageOpacity
			case 'IIMG': // hold reference to image path
			case 'TXTR':
				// this.setupForm( type, length );
				this.debugger.length = 4;
				this.debugger.skipped = true;
				break;

			case 'IFAL': // imageFallof
			case 'ISCL': // imageScale
			case 'IPOS': // imagePosition
			case 'IROT': // imageRotation
			case 'IBMP':
			case 'IUTD':
			case 'IVTD':
				this.parseTextureNodeAttribute(type);
				break;

			case 'ENVL':
				this.parseEnvelope(length);
				break;

				// CLIP FORM AND SUB FORMS

			case 'CLIP':
				if (this.tree.format === 'LWO2') {

					this.parseForm(length);

				} else {

					this.parseClip(length);

				}

				break;

			case 'STIL':
				this.parseImage();
				break;

			case 'XREF': // clone of another STIL
				this.reader.skip(8); // unknown
				this.currentForm.referenceTexture = {
					index: this.reader.getUint32(),
					refName: this.reader.getString() // internal unique ref
				};
				break;

				// Not in spec, used by texture nodes

			case 'IMST':
				this.parseImageStateForm(length);
				break;

				// SURF FORM AND SUB FORMS

			case 'SURF':
				this.parseSurfaceForm(length);
				break;

			case 'VALU': // Not in spec
				this.parseValueForm(length);
				break;

			case 'NTAG':
				this.parseSubNode(length);
				break;

			case 'ATTR': // BSDF Node Attributes
			case 'SATR': // Standard Node Attributes
				this.setupForm('attributes', length);
				break;

			case 'NCON':
				this.parseConnections(length);
				break;

			case 'SSHA':
				this.parentForm = this.currentForm;
				this.currentForm = this.currentSurface;
				this.setupForm('surfaceShader', length);
				break;

			case 'SSHD':
				this.setupForm('surfaceShaderData', length);
				break;

			case 'ENTR': // Not in spec
				this.parseEntryForm(length);
				break;

				// Image Map Layer

			case 'IMAP':
				this.parseImageMap(length);
				break;

			case 'TAMP':
				this.parseXVAL('amplitude', length);
				break;

				//Texture Mapping Form

			case 'TMAP':
				this.setupForm('textureMap', length);
				break;

			case 'CNTR':
				this.parseXVAL3('center', length);
				break;

			case 'SIZE':
				this.parseXVAL3('scale', length);
				break;

			case 'ROTA':
				this.parseXVAL3('rotation', length);
				break;

			default:
				this.parseUnknownForm(type, length);

		}

		this.debugger.node = 0;
		this.debugger.nodeID = type;
		this.debugger.log();
	}

	public function setupForm(type:String, length:Int):Void {
		if (!this.currentForm) this.currentForm = this.currentNode;

		this.currentFormEnd = this.reader.offset + length;
		this.parentForm = this.currentForm;

		if (!this.currentForm[type]) {
			this.currentForm[type] = {};
			this.currentForm = this.currentForm[type];
		} else {
			// should never see this unless there's a bug in the reader
			trace('LWOLoader: form already exists on parent: ', type, this.currentForm);
			this.currentForm = this.currentForm[type];
		}
	}

	public function skipForm(length:Int):Void {
		this.reader.skip(length - 4);
	}

	public function parseUnknownForm(type:String, length:Int):Void {
		trace('LWOLoader: unknown FORM encountered: ' + type, length);
		this.reader.skip(length - 4);
	}

	public function parseSurfaceForm(length:Int):Void {
		this.reader.skip(8); // unknown Uint32 x2
		var name = this.reader.getString();
		var surface = {
			attributes: {}, // LWO2 style non-node attributes will go here
			connections: {},
			name: name,
			inputName: name,
			nodes: {},
			source: this.reader.getString(),
		};
		this.tree.materials[name] = surface;
		this.currentSurface = surface;
		this.parentForm = this.tree.materials;
		this.currentForm = surface;
		this.currentFormEnd = this.reader.offset + length;
	}

	public function parseSurfaceLwo2(length:Int):Void {
		var name = this.reader.getString();
		var surface = {
			attributes: {}, // LWO2 style non-node attributes will go here
			connections: {},
			name: name,
			nodes: {},
			source: this.reader.getString(),
		};
		this.tree.materials[name] = surface;
		this.currentSurface = surface;
		this.parentForm = this.tree.materials;
		this.currentForm = surface;
		this.currentFormEnd = this.reader.offset + length;
	}

	public function parseSubNode(length:Int):Void {
		// parse the NRNM CHUNK of the subnode FORM to get
		// a meaningful name for the subNode
		// some subnodes can be renamed, but Input and Surface cannot
		this.reader.skip(8); // NRNM + length
		var name = this.reader.getString();
		var node = {
			name: name
		};
		this.currentForm = node;
		this.currentNode = node;
		this.currentFormEnd = this.reader.offset + length;
	}

	// collect attributes from all nodes at the top level of a surface
	public function parseConnections(length:Int):Void {
		this.currentFormEnd = this.reader.offset + length;
		this.parentForm = this.currentForm;
		this.currentForm = this.currentSurface.connections;
	}

	// surface node attribute data, e.g. specular, roughness etc
	public function parseEntryForm(length:Int):Void {
		this.reader.skip(8); // NAME + length
		var name = this.reader.getString();
		this.currentForm = this.currentNode.attributes;
		this.setupForm(name, length);
	}

	// parse values from material - doesn't match up to other LWO3 data types
	// sub form of entry form
	public function parseValueForm():Void {
		this.reader.skip(8); // unknown + length
		var valueType = this.reader.getString();
		if (valueType === 'double') {
			this.currentForm.value = this.reader.getUint64();
		} else if (valueType === 'int') {
			this.currentForm.value = this.reader.getUint32();
		} else if (valueType === 'vparam') {
			this.reader.skip(24);
			this.currentForm.value = this.reader.getFloat64();
		} else if (valueType === 'vparam3') {
			this.reader.skip(24);
			this.currentForm.value = this.reader.getFloat64Array(3);
		}
	}

	// holds various data about texture node image state
	// Data other thanmipMapLevel unknown
	public function parseImageStateForm():Void {
		this.reader.skip(8); // unknown
		this.currentForm.mipMapLevel = this.reader.getFloat32();
	}

	// LWO2 style image data node OR LWO3 textures defined at top level in editor (not as SURF node)
	public function parseImageMap(length:Int):Void {
		this.currentFormEnd = this.reader.offset + length;
		this.parentForm = this.currentForm;
		if (!this.currentForm.maps) this.currentForm.maps = [];
		var map = {};
		this.currentForm.maps.push(map);
		this.currentForm = map;
		this.reader.skip(10); // unknown, could be an issue if it contains a VX
	}

	public function parseTextureNodeAttribute(type:String):Void {
		this.reader.skip(28); // FORM + length + VPRM + unknown + Uint32 x2 + float32
		this.reader.skip(20); // FORM + length + VPVL + float32 + Uint32
		switch (type) {
			case 'ISCL':
				this.currentNode.scale = this.reader.getFloat32Array(3);
				break;
			case 'IPOS':
				this.currentNode.position = this.reader.getFloat32Array(3);
				break;
			case 'IROT':
				this.currentNode.rotation = this.reader.getFloat32Array(3);
				break;
			case 'IFAL':
				this.currentNode.falloff = this.reader.getFloat32Array(3);
				break;
			case 'IBMP':
				this.currentNode.amplitude = this.reader.getFloat32();
				break;
			case 'IUTD':
				this.currentNode.uTiles = this.reader.getFloat32();
				break;
			case 'IVTD':
				this.currentNode.vTiles = this.reader.getFloat32();
				break;
		}
		this.reader.skip(2); // unknown
	}

	// ENVL forms are currently ignored
	public function parseEnvelope(length:Int):Void {
		this.reader.skip(length - 4); // skipping  entirely for now
	}

	// CHUNK PARSING METHODS

	// clips can either be defined inside a surface node, or at the top
	// level and they have a different format in each case
	public function parseClip(length:Int):Void {
		var tag = this.reader.getIDTag();
		// inside surface node
		if (tag === 'FORM') {
			this.reader.skip(16);
			this.currentNode.fileName = this.reader.getString();
			return;
		}
		// otherwise top level
		this.reader.setOffset(this.reader.offset - 4);
		this.currentFormEnd = this.reader.offset + length;
		this.parentForm = this.currentForm;
		this.reader.skip(8); // unknown
		var texture = {
			index: this.reader.getUint32()
		};
		this.tree.textures.push(texture);
		this.currentForm = texture;
	}

	public function parseClipLwo2(length:Int):Void {
		var texture = {
			index: this.reader.getUint32(),
			fileName: ''
		};
		// seach STIL block
		while (true) {
			var tag = this.reader.getIDTag();
			var n_length = this.reader.getUint16();
			if (tag === 'STIL') {
				texture.fileName = this.reader.getString();
				break;
			}
			if (n_length >= length) {
				break;
			}
		}
		this.tree.textures.push(texture);
		this.currentForm = texture;
	}

	public function parseImage():Void {
		this.reader.skip(8); // unknown
		this.currentForm.fileName = this.reader.getString();
	}

	public function parseXVAL(type:String, length:Int):Void {
		var endOffset = this.reader.offset + length - 4;
		this.reader.skip(8);
		this.currentForm[type] = this.reader.getFloat32();
		this.reader.setOffset(endOffset); // set end offset directly to skip optional envelope
	}

	public function parseXVAL3(type:String, length:Int):Void {
		var endOffset = this.reader.offset + length - 4;
		this.reader.skip(8);
		this.currentForm[type] = {
			x: this.reader.getFloat32(),
			y: this.reader.getFloat32(),
			z: this.reader.getFloat32(),
		};
		this.reader.setOffset(endOffset);
	}

	// Tags associated with an object
	// OTAG { type[ID4], tag-string[S0] }
	public function parseObjectTag():Void {
		if (!this.tree.objectTags) this.tree.objectTags = {};
		this.tree.objectTags[this.reader.getIDTag()] = {
			tagString: this.reader.getString()
		};
	}

	// Signals the start of a new layer. All the data chunks which follow will be included in this layer until another layer chunk is encountered.
	// LAYR: number[U2], flags[U2], pivot[VEC12], name[S0], parent[U2]
	public function parseLayer(length:Int):Void {
		var number = this.reader.getUint16();
		var flags = this.reader.getUint16(); // If the least significant bit of flags is set, the layer is hidden.
		var pivot = this.reader.getFloat32Array(3); // Note: this seems to be superflous, as the geometry is translated when pivot is present
		var layer = {
			number: number,
			flags: flags, // If the least significant bit of flags is set, the layer is hidden.
			pivot: [-pivot[0], pivot[1], pivot[2]], // Note: this seems to be superflous, as the geometry is translated when pivot is present
			name: this.reader.getString(),
		};
		this.tree.layers.push(layer);
		this.currentLayer = layer;
		var parsedLength = 16 + stringOffset(this.currentLayer.name); // index ( 2 ) + flags( 2 ) + pivot( 12 ) + stringlength
		// if we have not reached then end of the layer block, there must be a parent defined
		this.currentLayer.parent = (parsedLength < length) ? this.reader.getUint16() : -1; // omitted or -1 for no parent
	}

	// VEC12 * ( F4 + F4 + F4 ) array of x,y,z vectors
	// Converting from left to right handed coordinate system:
	// x -> -x and switch material FrontSide -> BackSide
	public function parsePoints(length:Int):Void {
		this.currentPoints = [];
		for (var i = 0; i < length / 4; i += 3) {
			// x -> -x to match three.js right handed coords
			this.currentPoints.push(-this.reader.getFloat32(), this.reader.getFloat32(), this.reader.getFloat32());
		}
	}

	// parse VMAP or VMAD
	// Associates a set of floating-point vectors with a set of points.
	// VMAP: { type[ID4], dimension[U2], name[S0], ( vert[VX], value[F4] # dimension ) * }
	// VMAD Associates a set of floating-point vectors with the vertices of specific polygons.
	// Similar to VMAPs, but associates with polygon vertices rather than points
	// to solve to problem of UV seams:  VMAD chunks are paired with VMAPs of the same name,
	// if they exist. The vector values in the VMAD will then replace those in the
	// corresponding VMAP, but only for calculations involving the specified polygons.
	// VMAD { type[ID4], dimension[U2], name[S0], ( vert[VX], poly[VX], value[F4] # dimension ) * }
	public function parseVertexMapping(length:Int, discontinuous:Bool):Void {
		var finalOffset = this.reader.offset + length;
		var channelName = this.reader.getString();
		if (this.reader.offset === finalOffset) {
			// then we are in a texture node and the VMAP chunk is just a reference to a UV channel name
			this.currentForm.UVChannel = channelName;
			return;
		}
		// otherwise reset to initial length and parse normal VMAP CHUNK
		this.reader.setOffset(this.reader.offset - stringOffset(channelName));
		var type = this.reader.getIDTag();
		this.reader.getUint16(); // dimension
		var name = this.reader.getString();
		var remainingLength = length - 6 - stringOffset(name);
		switch (type) {
			case 'TXUV':
				this.parseUVMapping(name, finalOffset, discontinuous);
				break;
			case 'MORF':
			case 'SPOT':
				this.parseMorphTargets(name, finalOffset, type); // can't be discontinuous
				break;
			// unsupported VMAPs
			case 'APSL':
			case 'NORM':
			case 'WGHT':
			case 'MNVW':
			case 'PICK':
			case 'RGB ':
			case 'RGBA':
				this.reader.skip(remainingLength);
				break;
			default:
				trace('LWOLoader: unknown vertex map type: ' + type);
				this.reader.skip(remainingLength);
		}
	}

	public function parseUVMapping(name:String, finalOffset:Int, discontinuous:Bool):Void {
		var uvIndices = [];
		var polyIndices = [];
		var uvs = [];
		while (this.reader.offset < finalOffset) {
			uvIndices.push(this.reader.getVariableLengthIndex());
			if (discontinuous) polyIndices.push(this.reader.getVariableLengthIndex());
			uvs.push(this.reader.getFloat32(), this.reader.getFloat32());
		}
		if (discontinuous) {
			if (!this.currentLayer.discontinuousUVs) this.currentLayer.discontinuousUVs = {};
			this.currentLayer.discontinuousUVs[name] = {
				uvIndices: uvIndices,
				polyIndices: polyIndices,
				uvs: uvs,
			};
		} else {
			if (!this.currentLayer.uvs) this.currentLayer.uvs = {};
			this.currentLayer.uvs[name] = {
				uvIndices: uvIndices,
				uvs: uvs,
			};
		}
	}

	public function parseMorphTargets(name:String, finalOffset:Int, type:String):Void {
		var indices = [];
		var points = [];
		type = (type === 'MORF') ? 'relative' : 'absolute';
		while (this.reader.offset < finalOffset) {
			indices.push(this.reader.getVariableLengthIndex());
			// z -> -z to match three.js right handed coords
			points.push(this.reader.getFloat32(), this.reader.getFloat32(), -this.reader.getFloat32());
		}
		if (!this.currentLayer.morphTargets) this.currentLayer.morphTargets = {};
		this.currentLayer.morphTargets[name] = {
			indices: indices,
			points: points,
			type: type,
		};
	}

	// A list of polygons for the current layer.
	// POLS { type[ID4], ( numvert+flags[U2], vert[VX] # numvert ) * }
	public function parsePolygonList(length:Int):Void {
		var finalOffset = this.reader.offset + length;
		var type = this.reader.getIDTag();
		var indices = [];
		// hold a list of polygon sizes, to be split up later
		var polygonDimensions = [];
		while (this.reader.offset < finalOffset) {
			var numverts = this.reader.getUint16();
			//var flags = numverts & 64512; // 6 high order bits are flags - ignoring for now
			numverts = numverts & 1023; // remaining ten low order bits are vertex num
			polygonDimensions.push(numverts);
			for (var j = 0; j < numverts; j++) indices.push(this.reader.getVariableLengthIndex());
		}
		var geometryData = {
			type: type,
			vertexIndices: indices,
			polygonDimensions: polygonDimensions,
			points: this.currentPoints
		};
		// Note: assuming that all polys will be lines or points if the first is
		if (polygonDimensions[0] === 1) geometryData.type = 'points';
		else if (polygonDimensions[0] === 2) geometryData.type = 'lines';
		this.currentLayer.geometry = geometryData;
	}

	// Lists the tag strings that can be associated with polygons by the PTAG chunk.
	// TAGS { tag-string[S0] * }
	public function parseTagStrings(length:Int):Void {
		this.tree.tags = this.reader.getStringArray(length);
	}

	// Associates tags of a given type with polygons in the most recent POLS chunk.
	// PTAG { type[ID4], ( poly[VX], tag[U2] ) * }
	public function parsePolygonTagMapping(length:Int):Void {
		var finalOffset = this.reader.offset + length;
		var type = this.reader.getIDTag();
		if (type === 'SURF') this.parseMaterialIndices(finalOffset);
		else { //PART, SMGP, COLR not supported
			this.reader.skip(length - 4);
		}
	}

	public function parseMaterialIndices(finalOffset:Int):Void {
		// array holds polygon index followed by material index
		this.currentLayer.geometry.materialIndices = [];
		while (this.reader.offset < finalOffset) {
			var polygonIndex = this.reader.getVariableLengthIndex();
			var materialIndex = this.reader.getUint16();
			this.currentLayer.geometry.materialIndices.push(polygonIndex, materialIndex);
		}
	}

	public function parseUnknownCHUNK(blockID:String, length:Int):Void {
		trace('LWOLoader: unknown chunk type: ' + blockID + ' length: ' + length);
		// print the chunk plus some bytes padding either side
		// printBuffer( this.reader.dv.buffer, this.reader.offset - 20, length + 40 );
		var data = this.reader.getString(length);
		this.currentForm[blockID] = data;
	}

}