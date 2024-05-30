import three.js.examples.jsm.loaders.FileLoader;
import three.js.examples.jsm.loaders.Loader;
import three.js.examples.jsm.loaders.TextureLoader;
import three.js.examples.jsm.loaders.RepeatWrapping;

import three.js.examples.jsm.nodes.Nodes;

class MXElement {

    public var name:String;
    public var nodeFunc:Dynamic;
    public var params:Array<String>;

    public function new(name:String, nodeFunc:Dynamic, params:Array<String>) {
        this.name = name;
        this.nodeFunc = nodeFunc;
        this.params = params;
    }
}

class MXElements {

    public var mx_add:Dynamic;
    public var mx_subtract:Dynamic;
    public var mx_multiply:Dynamic;
    public var mx_divide:Dynamic;
    public var mx_modulo:Dynamic;
    public var mx_power:Dynamic;
    public var mx_atan2:Dynamic;

    public function new() {
        this.mx_add = function(in1:Dynamic, in2:Dynamic = 0) return Nodes.add(in1, in2);
        this.mx_subtract = function(in1:Dynamic, in2:Dynamic = 0) return Nodes.sub(in1, in2);
        this.mx_multiply = function(in1:Dynamic, in2:Dynamic = 1) return Nodes.mul(in1, in2);
        this.mx_divide = function(in1:Dynamic, in2:Dynamic = 1) return Nodes.div(in1, in2);
        this.mx_modulo = function(in1:Dynamic, in2:Dynamic = 1) return Nodes.mod(in1, in2);
        this.mx_power = function(in1:Dynamic, in2:Dynamic = 1) return Nodes.pow(in1, in2);
        this.mx_atan2 = function(in1:Dynamic = 0, in2:Dynamic = 1) return Nodes.atan2(in1, in2);
    }
}

class MtlXLibrary {

    public var elements:Map<String, MXElement>;

    public function new() {
        this.elements = new Map<String, MXElement>();
    }

    public function addElement(element:MXElement) {
        this.elements.set(element.name, element);
    }
}

class MaterialXLoader extends Loader {

    public function new(manager:Loader.LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Loader {
        var _onError = function(e:Dynamic) {
            if (onError != null) {
                onError(e);
            } else {
                trace(e);
            }
        };

        new FileLoader(this.manager)
            .setPath(this.path)
            .load(url, function(text:String) {
                try {
                    onLoad(this.parse(text));
                } catch (e:Dynamic) {
                    _onError(e);
                }
            }, onProgress, _onError);

        return this;
    }

    public function parse(text:String):Dynamic {
        return new MaterialX(this.manager, this.path).parse(text);
    }
}

class MaterialX {

    public var manager:Loader.LoaderManager;
    public var path:String;
    public var resourcePath:String;

    public var nodesXLib:Map<String, MaterialXNode>;
    public var textureLoader:TextureLoader;

    public function new(manager:Loader.LoaderManager, path:String) {
        this.manager = manager;
        this.path = path;
        this.resourcePath = '';

        this.nodesXLib = new Map<String, MaterialXNode>();
        this.textureLoader = new TextureLoader(manager);
    }

    public function addMaterialXNode(materialXNode:MaterialXNode) {
        this.nodesXLib.set(materialXNode.nodePath, materialXNode);
    }

    public function getMaterialXNode(...names:Array<String>):MaterialXNode {
        return this.nodesXLib.get(names.join('/'));
    }

    public function parseNode(nodeXML:Xml, nodePath:String = ''):MaterialXNode {
        var materialXNode = new MaterialXNode(this, nodeXML, nodePath);
        if (materialXNode.nodePath != null) this.addMaterialXNode(materialXNode);

        for (nodeXMLChild in nodeXML.children()) {
            var childMXNode = this.parseNode(nodeXMLChild, materialXNode.nodePath);
            materialXNode.add(childMXNode);
        }

        return materialXNode;
    }

    public function parse(text:String):Dynamic {
        var rootXML = Xml.parse(text);

        this.textureLoader.setPath(this.path);

        var materials = this.parseNode(rootXML).toMaterials();

        return {materials: materials};
    }
}