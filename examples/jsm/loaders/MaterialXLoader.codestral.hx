import three.FileLoader;
import three.Loader;
import three.TextureLoader;
import three.RepeatWrapping;

import Nodes.*;

class MXElement {
    public var name: String;
    public var nodeFunc: Dynamic;
    public var params: Array<String>;

    public function new(name: String, nodeFunc: Dynamic, params: Array<String> = null) {
        this.name = name;
        this.nodeFunc = nodeFunc;
        this.params = params;
    }
}

// Math functions
var mx_add = function(in1: FloatNode, in2: FloatNode = float(0)): FloatNode { return add(in1, in2); }
var mx_subtract = function(in1: FloatNode, in2: FloatNode = float(0)): FloatNode { return sub(in1, in2); }
var mx_multiply = function(in1: FloatNode, in2: FloatNode = float(1)): FloatNode { return mul(in1, in2); }
var mx_divide = function(in1: FloatNode, in2: FloatNode = float(1)): FloatNode { return div(in1, in2); }
var mx_modulo = function(in1: FloatNode, in2: FloatNode = float(1)): FloatNode { return mod(in1, in2); }
var mx_power = function(in1: FloatNode, in2: FloatNode = float(1)): FloatNode { return pow(in1, in2); }
var mx_atan2 = function(in1: FloatNode = float(0), in2: FloatNode = float(1)): FloatNode { return atan2(in1, in2); }

// Define MXElements
var MXElements: Array<MXElement> = [
    // ...
];

var MtlXLibrary: Map<String, MXElement> = new Map<String, MXElement>();
for (element in MXElements) MtlXLibrary.set(element.name, element);

class MaterialXLoader extends Loader {
    public function new(manager: LoaderManager) {
        super(manager);
    }

    public function load(url: String, onLoad: Null<(materialX: MaterialX) -> Void>, onProgress: Null<(request: ProgressEvent) -> Void>, onError: Null<(event: ErrorEvent) -> Void>): MaterialXLoader {
        // ...
    }

    public function parse(text: String): MaterialX {
        return new MaterialX(this.manager, this.path).parse(text);
    }
}

class MaterialXNode {
    // ...
}

class MaterialX {
    // ...
}

export { MaterialXLoader };