import haxe.io.Bytes;
import haxe.io.Eof;
import haxe.io.Input;

class IFFParser {

    public var debugger:Debugger;
    public var reader:DataViewReader;
    public var tree:Dynamic;
    public var currentLayer:Dynamic;
    public var currentForm:Dynamic;
    public var currentSurface:Dynamic;
    public var parentForm:Dynamic;

    public function new() {
        this.debugger = new Debugger();
    }

    public function parse(buffer:Bytes):Dynamic {
        this.reader = new DataViewReader(buffer);

        this.tree = {
            materials: {},
            layers: [],
            tags: [],
            textures: [],
        };

        this.currentLayer = this.tree;
        this.currentForm = this.tree;

        this.parseTopForm();

        if (this.tree.format == undefined) return;

        switch (this.tree.format) {
            case 'LWO2':
                this.parser = new LWO2Parser(this);
                while (!this.reader.eof) this.parser.parseBlock();
                break;
            case 'LWO3':
                this.parser = new LWO3Parser(this);
                while (!this.reader.eof) this.parser.parseBlock();
                break;
        }

        this.debugger.offset = this.reader.offset;
        this.debugger.closeForms();

        return this.tree;
    }

    public function parseTopForm():Void {
        this.debugger.offset = this.reader.offset;

        if (this.reader.getIDTag() != "FORM") {
            console.warn("LWOLoader: Top-level FORM missing.");
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

    // Form parsing methods
    // FORM ::= 'FORM'[ID4], length[U4], type[ID4], ( chunk[CHUNK] | form[FORM] )
    public function parseForm(length:Int):Void {
        var type = this.reader.getIDTag();

        switch (type) {
            // Skipped forms
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
            case "OMAX":
            case "STEX":
            case "CKBG":
            case "CKEY":
            case "VMLA":
            case "VMLB":
                this.debugger.skipped = true;
                this.skipForm(length); // not currently supported
                break;
            // Other forms
            case "META":
            case "NNDS":
            case "NODS":
            case "NDTA":
            case "ADAT":
            case "AOVS":
            case "BLOK":
            case "IMST":
                this.debugger.length = 4;
                this.debugger.skipped = true;
                break;
            default:
                this.parseUnknownForm(type, length);
        }

        this.debugger.node = 0;
        this.debugger.nodeID = type;
        this.debugger.log();
    }

    // Other parsing methods

    // ...

}

// Other classes

// ...