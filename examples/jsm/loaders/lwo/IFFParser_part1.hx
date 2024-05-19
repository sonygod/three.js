import haxe.io.Eof;
import haxe.io.Input;

class IFFParser {

	private var reader:DataViewReader;
	private var debugger:Debugger;
	private var tree:Dynamic;
	private var currentLayer:Dynamic;
	private var currentForm:Dynamic;

	public function new() {
		debugger = new Debugger();
		// debugger.enable(); // un-comment to log IFF hierarchy.
	}

	public function parse(buffer:ArrayBuffer):Dynamic {
		reader = new DataViewReader(buffer);

		tree = {
			materials: {},
			layers: [],
			tags: [],
			textures: [],
		};

		currentLayer = tree;
		currentForm = tree;

		parseTopForm();

		if (tree.format == undefined) return;

		if (tree.format == 'LWO2') {
			var parser:Dynamic = new LWO2Parser(this);
			while (true) {
				try {
					parser.parseBlock();
				} catch (e:Eof) {
					break;
				}
			}
		} else if (tree.format == 'LWO3') {
			var parser:Dynamic = new LWO3Parser(this);
			while (true) {
				try {
					parser.parseBlock();
				} catch (e:Eof) {
					break;
				}
			}
		}

		debugger.offset = reader.offset;
		debugger.closeForms();

		return tree;
	}

	private function parseTopForm():Void {
		debugger.offset = reader.offset;

		var topForm:String = reader.getIDTag();

		if (topForm != 'FORM') {
			console.warn('LWOLoader: Top-level FORM missing.');
			return;
		}

		var length:Int = reader.getUint32();

		debugger.dataOffset = reader.offset;
		debugger.length = length;

		var type:String = reader.getIDTag();

		if (type == 'LWO2') {
			tree.format = type;
		} else if (type == 'LWO3') {
			tree.format = type;
		}

		debugger.node = 0;
		debugger.nodeID = type;
		debugger.log();
	}

	// FORM PARSING METHODS
	private function parseForm(length:Int):Void {
		var type:String = reader.getIDTag();

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
				debugger.skipped = true;
				skipForm(length); // not currently supported
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
				debugger.length = 4;
				debugger.skipped = true;
				break;

			case 'IFAL': // imageFallof
			case 'ISCL': // imageScale
			case 'IPOS': // imagePosition
			case 'IROT': // imageRotation
			case 'IBMP':
			case 'IUTD':
			case 'IVTD':
				parseTextureNodeAttribute(type);
				break;

			case 'ENVL':
				parseEnvelope(length);
				break;

			// CLIP FORM AND SUB FORMS

			case 'CLIP':
				if (tree.format == 'LWO2') {
					parseForm(length);
				} else {
					parseClip(length);
				}

				break;

			case 'STIL':
				parseImage();
				break;

			case 'XREF': // clone of another STIL
				reader.skip(8); // unknown
				currentForm.referenceTexture = {
					index: reader.getUint32(),
					refName: reader.getString() // internal unique ref
				};
				break;

				// Not in spec, used by texture nodes

			case 'IMST':
				parseImageStateForm(length);
				break;

				// SURF FORM AND SUB FORMS

			case 'SURF':
				parseSurfaceForm(length);
				break;

			case 'VALU': // Not in spec
				parseValueForm(length);
				break;

			case 'NTAG':
				parseSubNode(length);
				break;

			case 'ATTR': // BSDF Node Attributes
			case 'SATR': // Standard Node Attributes
				setupForm(type, length);
				break;

			case 'NCON':
				parseConnections(length);
				break;

			case 'SSHA':
				parentForm = currentForm;
				currentForm = currentSurface;
				setupForm('surfaceShader', length);
				break;

			case 'SSHD':
				setupForm('surfaceShaderData', length);
				break;

			case 'ENTR': // Not in spec
				parseEntryForm(length);
				break;

				// Image Map Layer

			case 'IMAP':
				parseImageMap(length);
				break;

			case 'TAMP':
				parseXVAL('amplitude', length);
				break;

				//Texture Mapping Form

			case 'TMAP':
				setupForm('textureMap', length);
				break;

			case 'CNTR':
				parseXVAL3('center', length);
				break;

			case 'SIZE':
				parseXVAL3('scale', length);
				break;

			case 'ROTA':
				parseXVAL3('rotation', length);
				break;

			default:
				parseUnknownForm(type, length);

		}

		debugger.node = 0;
		debugger.nodeID = type;
		debugger.log();
	}

	private function setupForm(type:String, length:Int):Void {
		if (!currentForm) currentForm = currentNode;

		var currentFormEnd:Int = reader.offset + length;
		parentForm = currentForm;

		if (!currentForm[type]) {
			currentForm[type] = {};
			currentForm = currentForm[type];

		} else {

			// should never see this unless there's a bug in the reader
			console.warn('LWOLoader: form already exists on parent: ', type, currentForm);

			currentForm = currentForm[type];

		}

	}

	private function skipForm(length:Int):Void {
		reader.skip(length - 4);
	}

	private function parseUnknownForm(type:String, length:Int):Void {
		console.warn('LWOLoader: unknown FORM encountered: ' + type, length);

		var view:DataView = reader.dv;
		var arr:Array<Int> = new Array<Int>(length - 4);
		for (i in 0...arr.length) {
			arr[i] = view.getUint8(reader.offset + i);
		}
		trace(arr);
		reader.skip(length - 4);
	}

	// Other parsing methods follow

}