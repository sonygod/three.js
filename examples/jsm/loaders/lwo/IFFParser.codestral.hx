package three.js.examples.jsm.loaders.lwo;

import three.js.examples.jsm.loaders.lwo.LWO2Parser;
import three.js.examples.jsm.loaders.lwo.LWO3Parser;

class IFFParser {
    var debugger: Debugger;
    var reader: DataViewReader;
    var tree: Dynamic;
    var currentLayer: Dynamic;
    var currentForm: Dynamic;
    var currentFormEnd: Int;
    var parentForm: Dynamic;
    var currentSurface: Dynamic;
    var currentNode: Dynamic;
    var currentPoints: Array<Float>;
    var parser: LWO2Parser | LWO3Parser;

    public function new() {
        debugger = new Debugger();
        // debugger.enable(); // uncomment to log IFF hierarchy.
    }

    public function parse(buffer: ArrayBuffer): Dynamic {
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

        if (tree.format == null) return null;

        if (tree.format == 'LWO2') {
            parser = new LWO2Parser(this);
            while (!reader.endOfFile()) parser.parseBlock();
        } else if (tree.format == 'LWO3') {
            parser = new LWO3Parser(this);
            while (!reader.endOfFile()) parser.parseBlock();
        }

        debugger.offset = reader.offset;
        debugger.closeForms();

        return tree;
    }

    public function parseTopForm(): Void {
        debugger.offset = reader.offset;

        var topForm: String = reader.getIDTag();

        if (topForm != 'FORM') {
            trace('LWOLoader: Top-level FORM missing.');
            return;
        }

        var length: Int = reader.getUint32();

        debugger.dataOffset = reader.offset;
        debugger.length = length;

        var type: String = reader.getIDTag();

        if (type == 'LWO2') {
            tree.format = type;
        } else if (type == 'LWO3') {
            tree.format = type;
        }

        debugger.node = 0;
        debugger.nodeID = type;
        debugger.log();
    }

    // Other methods would be translated similarly, following the same naming conventions and structure.
}