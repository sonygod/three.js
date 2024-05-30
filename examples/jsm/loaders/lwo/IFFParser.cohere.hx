/**
 * == IFFParser ==
 * - Parses data from the IFF buffer.
 * - LWO3 files are in IFF format and can contain the following data types, referred to by shorthand codes
 *
 * ATOMIC DATA TYPES
 *  ID Tag - 4x 7 bit uppercase ASCII chars: ID4
 *  signed integer, 1, 2, or 4 byte length: I1, I2, I4
 *  unsigned integer, 1, 2, or 4 byte length: U1, U2, U4
 *  float, 4 byte length: F4
 *  string, series of ASCII chars followed by null byte (If the length of the string including the null terminating byte is odd, an extra null is added so that the data that follows will begin on an even byte boundary): S0
 *
 * COMPOUND DATA TYPES
 *  Variable-length Index (index into an array or collection): U2 or U4 : VX
 *  Color (RGB): F4 + F4 + F4: COL12
 *  Coordinate (x, y, z): F4 + F4 + F4: VEC12
 *  Percentage F4 data type from 0->1 with 1 = 100%: FP4
 *  Angle in radian F4: ANG4
 *  Filename (string) S0: FNAM0
 *  XValue F4 + index (VX) + optional envelope( ENVL ): XVAL
 *  XValue vector VEC12 + index (VX) + optional envelope( ENVL ): XVAL3
 *
 *  The IFF file is arranged in chunks:
 *  CHUNK = ID4 + length (U4) + length X bytes of data + optional 0 pad byte
 *  optional 0 pad byte is there to ensure chunk ends on even boundary, not counted in size
 *
 * COMPOUND DATA TYPES
 * - Chunks are combined in Forms (collections of chunks)
 * - FORM = string 'FORM' (ID4) + length (U4) + type (ID4) + optional ( CHUNK | FORM )
 * - CHUNKS and FORMS are collectively referred to as blocks
 * - The entire file is contained in one top level FORM
 *
 **/

import haxe.io.Bytes;

class IFFParser {

    public function new() {
        this.debugger = new Debugger();
        // this.debugger.enable(); // un-comment to log IFF hierarchy.
    }

    public function parse(buffer: Bytes): Void {
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

        if (this.tree.format == null) return;

        if (this.tree.format == "LWO2") {
            this.parser = new LWO2Parser(this);
            while (!this.reader.endOfFile()) this.parser.parseBlock();
        } else if (this.tree.format == "LWO3") {
            this.parser = new LWO3Parser(this);
            while (!this.reader.endOfFile()) this.parser.parseBlock();
        }

        this.debugger.offset = this.reader.offset;
        this.debugger.closeForms();
    }

    public function parseTopForm(): Void {
        this.debugger.offset = this.reader.offset;

        var topForm = this.reader.getIDTag();

        if (topForm != "FORM") {
            trace("LWOLoader: Top-level FORM missing.");
            return;
        }

        var length = this.reader.getUint32();

        this.debugger.dataOffset = this.reader.offset;
        this.debugger.length = length;

        var type = this.reader.getIDTag();

        if (type == "LWO2") {
            this.tree.format = type;
        } else if (type == "LWO3") {
            this.tree.format = type;
        }

        this.debugger.node = 0;
        this.debugger.nodeID = type;
        this.debugger.log();
    }

    ///
    // FORM PARSING METHODS
    ///

    // Forms are organisational and can contain any number of sub chunks and sub forms
    // FORM ::= 'FORM'[ID4], length[U4], type[ID4], ( chunk[CHUNK] | form[FORM] ) * }
    public function parseForm(length: Int): Void {
        var type = this.reader.getIDTag();

        switch (type) {
            // SKIPPED FORMS
            // if skipForm( length ) is called, the entire form and any sub forms and chunks are skipped

            case "ISEQ": // Image sequence
            case "ANIM": // plug in animation
            case "STCC": // Color-cycling Still
            case "VPVL":
            case "VPRM":
            case "NROT":
            case "WRPW": // image wrap w ( for cylindrical and spherical projections)
            case "WRPH": // image wrap h
            case "FUNC":
            case "FALL":
            case "OPAC":
            case "GRAD": // gradient texture
            case "ENVS":
            case "VMOP":
            case "VMBG":

                // Car Material FORMS
                case "OMAX":
                case "STEX":
                case "CKBG":
                case "CKEY":
                case "VMLA":
                case "VMLB":
                    this.debugger.skipped = true;
                    this.skipForm(length); // not currently supported
                    break;

                // if break; is called directly, the position in the lwoTree is not created
                // any sub chunks and forms are added to the parent form instead
                case "META":
                case "NNDS":
                case "NODS":
                case "NDTA":
                case "ADAT":
                case "AOVS":
                case "BLOK":

                // used by texture nodes
                case "IBGC": // imageBackgroundColor
                case "IOPC": // imageOpacity
                case "IIMG": // hold reference to image path
                case "TXTR":
                    // this.setupForm( type, length );
                    this.debugger.length = 4;
                    this.debugger.skipped = true;
                    break;

                case "IFAL": // imageFallof
                case "ISCL": // imageScale
                case "IPOS": // imagePosition
                case "IROT": // imageRotation
                case "IBMP":
                case "IUTD":
                case "IVTD":
                    this.parseTextureNodeAttribute(type);
                    break;

                case "ENVL":
                    this.parseEnvelope(length);
                    break;

                    // CLIP FORM AND SUB FORMS

                case "CLIP":
                    if (this.tree.format == "LWO2") {
                        this.parseForm(length);
                    } else {
                        this.parseClip(length);
                    }

                    break;

                case "STIL":
                    this.parseImage();
                    break;

                case "XREF": // clone of another STIL
                    this.reader.skip(8); // unknown
                    this.currentForm.referenceTexture = {
                        index: this.reader.getUint32(),
                        refName: this.reader.getString() // internal unique ref
                    };
                    break;

                    // Not in spec, used by texture nodes

                case "IMST":
                    this.parseImageStateForm(length);
                    break;

                    // SURF FORM AND SUB FORMS

                case "SURF":
                    this.parseSurfaceForm(length);
                    break;

                case "VALU": // Not in spec
                    this.parseValueForm(length);
                    break;

                case "NTAG":
                    this.parseSubNode(length);
                    break;

                case "ATTR": // BSDF Node Attributes
                case "SATR": // Standard Node Attributes
                    this.setupForm("attributes", length);
                    break;

                case "NCON":
                    this.parseConnections(length);
                    break;

                case "SSHA":
                    this.parentForm = this.currentForm;
                    this.currentForm = this.currentSurface;
                    this.setupForm("surfaceShader", length);
                    break;

                case "SSHD":
                    this.setupForm("surfaceShaderData", length);
                    break;

                case "ENTR": // Not in spec
                    this.parseEntryForm(length);
                    break;

                    // Image Map Layer

                case "IMAP":
                    this.parseImageMap(length);
                    break;

                case "TAMP":
                    this.parseXVAL("amplitude", length);
                    break;

                    //Texture Mapping Form

                case "TMAP":
                    this.setupForm("textureMap", length);
                    break;

                case "CNTR":
                    this.parseXVAL3("center", length);
                    break;

                case "SIZE":
                    this.parseXVAL3("scale", length);
                    break;

                case "ROTA":
                    this.parseXVAL3("rotation", length);
                    break;

                default:
                    this.parseUnknownForm(type, length);
        }

        this.debugger.node = 0;
        this.debugger.nodeID = type;
        this.debugger.log();
    }

    public function setupForm(type: String, length: Int): Void {
        if (this.currentForm == null) this.currentForm = this.currentNode;

        this.currentFormEnd = this.reader.offset + length;
        this.parentForm = this.currentForm;

        if (this.currentForm.exists(type) == false) {
            this.currentForm[type] = {};
            this.currentForm = this.currentForm[type];
        } else {
            // should never see this unless there's a bug in the reader
            trace("LWOLoader: form already exists on parent: " + type + ", " + this.currentForm);

            this.currentForm = this.currentForm[type];
        }
    }

    public function skipForm(length: Int): Void {
        this.reader.skip(length - 4);
    }

    public function parseUnknownForm(type: String, length: Int): Void {
        trace("LWOLoader: unknown FORM encountered: " + type + ", " + length);

        printBuffer(this.reader.dv.buffer, this.reader.offset, length - 4);
        this.reader.skip(length - 4);
    }

    public function parseSurfaceForm(length: Int): Void {
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

    public function parseSurfaceLwo2(length: Int): Void {
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

    public function parseSubNode(length: Int): Void {
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
    public function parseConnections(length: Int): Void {
        this.currentFormEnd = this.reader.offset + length;
        this.parentForm = this.currentForm;

        this.currentForm = this.currentSurface.connections;
    }

    // surface node attribute data, e.g. specular, roughness etc
    public function parseEntryForm(length: Int): Void {
        this.reader.skip(8); // NAME + length
        var name = this.reader.getString();
        this.currentForm = this.currentNode.attributes;

        this.setupForm(name, length);
    }

    // parse values from material - doesn't match up to other LWO3 data types
    // sub form of entry form
    public function parseValueForm(): Void {
        this.reader.skip(8); // unknown + length

        var valueType = this.reader.getString();

        if (valueType == "double") {
            this.currentForm.value = this.reader.getUint64();
        } else if (valueType == "int") {
            this.currentForm.value = this.reader.getUint32();
        } else if (valueType == "vparam") {
            this.reader.skip(24);
            this.currentForm.value = this.reader.getFloat64();
        } else if (valueType == "vparam3") {
            this.reader.skip(24);
            this.currentForm.value = this.reader.getFloat64Array(3);
        }
    }

    // holds various data about texture node image state
    // Data other thanmipMapLevel unknown
    public function parseImageStateForm(): Void {
        this.reader.skip(8); // unknown

        this.currentForm.mipMapLevel = this.reader.getFloat32();
    }

    // LWO2 style image data node OR LWO3 textures defined at top level in editor (not as SURF node)
    public function parseImageMap(length: Int): Void {
        this.currentFormEnd = this.reader.offset + length;
        this.parentForm = this.currentForm;

        if (this.currentForm.maps == null) this.currentForm.maps = [];

        var map = {};
        this.currentForm.maps.push(map);
        this.currentForm = map;

        this.reader.skip(10); // unknown, could be an issue if it contains a VX
    }

    public function parseTextureNodeAttribute(type: String): Void {
        this.reader.skip(28); // FORM + length + VPRM + unknown + Uint32 x2 + float32

        this.reader.skip(20); // FORM + length + VPVL + float32 + Uint32

        switch (type) {
            case "ISCL":
                this.currentNode.scale = this.reader.getFloat32Array(3);
                break;
            case "IPOS":
                this.currentNode.position = this.reader.getFloat32Array(3);
                break;
            case "IROT":
                this.currentNode.rotation = this.reader.getFloat32Array(3);
                break;
            case "IFAL":
                this.currentNode.falloff = this.reader.getFloat32Array(3);
                break;

            case "IBMP":
                this.currentNode.amplitude = this.reader.getFloat32();
                break;
            case "IUTD":
                this.currentNode.uTiles = this.reader.getFloat32();
                break;
            case "IVTD":
                this.currentNode.vTiles = this.reader.getFloat32();
                break;
        }

        this.reader.skip(2); // unknown
    }

    // ENVL forms are currently ignored
    public function parseEnvelope(length: Int): Void {
        this.reader.skip(length - 4); // skipping entirely for now
    }

    ///
    // CHUNK PARSING METHODS
    ///

    // clips can either be defined inside a surface node, or at the top
    // level and they have a different format in each case
    public function parseClip(length: Int): Void {
        var tag = this.reader.getIDTag();

        // inside surface node
        if (tag == "FORM") {
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

    public function parseClipLwo2(length: Int): Void {
        var texture = {
            index: this.reader.getUint32(),
            fileName: ""
        };

        // seach STIL block
        while (true) {
            var tag = this.reader.getIDTag();
            var n_length = this.reader.getUint16();
            if (tag == "STIL") {
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

    public function parseImage(): Void {
        this.reader.skip(8); // unknown
        this.currentForm.fileName = this.reader.getString();
    }

    public function parseXVAL(type: String, length: Int): Void {
        var endOffset = this.reader.offset + length - 4;
        this.reader.skip(8);

        this.currentForm[type] = this.reader