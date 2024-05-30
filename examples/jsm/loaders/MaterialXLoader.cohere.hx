import haxe.xml.*;
import js.html.Xml;
import js.html.XmlNode;

import js.three.*;
import js.three.loaders.FileLoader;
import js.three.loaders.Loader;
import js.three.loaders.TextureLoader;
import js.three.textures.Texture;
import js.three.textures.Wrapping;

import js.three.materials.MeshBasicNodeMaterial;
import js.three.materials.MeshPhysicalNodeMaterial;

import js.three.nodes.*;

class MXElement {
    public var name:String;
    public var nodeFunc:Dynamic;
    public var params:Array<String>;

    public function new(name:String, nodeFunc:Dynamic, ?params:Array<String>) {
        this.name = name;
        this.nodeFunc = nodeFunc;
        this.params = params;
    }
}

class MtlXLibrary {
    public var elements:Map<String, MXElement>;

    public function new() {
        this.elements = new Map();
    }

    public function add(element:MXElement) {
        this.elements.set(element.name, element);
    }
}

class MaterialXLoader extends Loader {
    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var _onError = function(e:Dynamic) {
            if (onError != null) {
                onError(e);
            } else {
                trace(e);
            }
        };

        var fileLoader = new FileLoader(this.manager);
        fileLoader.path = this.path;
        fileLoader.load(url, function(text:String) {
            try {
                onLoad(this.parse(text));
            } catch(e:Dynamic) {
                _onError(e);
            }
        }, onProgress, _onError);
    }

    public function parse(text:String):Dynamic {
        return new MaterialX(this.manager, this.path).parse(text);
    }
}

class MaterialXNode {
    public var materialX:MaterialX;
    public var nodeXML:XmlNode;
    public var nodePath:String;

    public var parent:MaterialXNode;
    public var node:Dynamic;
    public var children:Array<MaterialXNode>;

    public function get element():String {
        return nodeXML.nodeName;
    }

    public function get nodeGraph():String {
        return this.getAttribute("nodegraph");
    }

    public function get nodeName():String {
        return this.getAttribute("nodename");
    }

    public function get interfaceName():String {
        return this.getAttribute("interfacename");
    }

    public function get output():String {
        return this.getAttribute("output");
    }

    public function get name():String {
        return this.getAttribute("name");
    }

    public function get type():String {
        return this.getAttribute("type");
    }

    public function get value():String {
        return this.getAttribute("value");
    }

    public function getNodeGraph():MaterialXNode {
        var nodeX = this;
        while (nodeX != null) {
            if (nodeX.element == "nodegraph") {
                break;
            }
            nodeX = nodeX.parent;
        }
        return nodeX;
    }

    public function getRoot():MaterialXNode {
        var nodeX = this;
        while (nodeX.parent != null) {
            nodeX = nodeX.parent;
        }
        return nodeX;
    }

    public function get referencePath():String {
        var referencePath = null;
        if (this.nodeGraph != null && this.output != null) {
            referencePath = this.nodeGraph + "/" + this.output;
        } else if (this.nodeName != null || this.interfaceName != null) {
            referencePath = this.getNodeGraph().nodePath + "/" + (this.nodeName ?? this.interfaceName);
        }
        return referencePath;
    }

    public function get hasReference():Bool {
        return this.referencePath != null;
    }

    public function get isConst():Bool {
        return this.element == "input" && this.value != null && this.type != "filename";
    }

    public function getColorSpaceNode():Dynamic {
        var csSource = this.getAttribute("colorspace");
        var csTarget = this.getRoot().getAttribute("colorspace");
        var nodeName = "mx_" + csSource + "_to_" + csTarget;
        return colorSpaceLib.get(nodeName);
    }

    public function getTexture():Texture {
        var filePrefix = this.getRecursiveAttribute("fileprefix");
        var loader = this.materialX.textureLoader;
        var uri = filePrefix + this.value;
        var handler = this.materialX.manager.getHandler(uri);
        if (handler != null) {
            loader = handler;
        }
        var texture = loader.load(uri);
        texture.wrapS = texture.wrapT = Wrapping.RepeatWrapping;
        texture.flipY = false;
        return texture;
    }

    public function getClassFromType(type:String):Dynamic {
        var nodeClass = null;
        switch (type) {
            case "integer":
                nodeClass = IntNode;
                break;
            case "float":
                nodeClass = FloatNode;
                break;
            case "vector2":
                nodeClass = Vec2Node;
                break;
            case "vector3":
                nodeClass = Vec3Node;
                break;
            case "vector4":
            case "color4":
                nodeClass = Vec4Node;
                break;
            case "color3":
                nodeClass = ColorNode;
                break;
            case "boolean":
                nodeClass = BoolNode;
                break;
        }
        return nodeClass;
    }

    public function getNode():Dynamic {
        var node = this.node;
        if (node != null) {
            return node;
        }
        var type = this.type;
        if (this.isConst) {
            var nodeClass = this.getClassFromType(type);
            node = nodeClass.fromArray(this.getVector());
        } else if (this.hasReference) {
            node = this.materialX.getMaterialXNode(this.referencePath).getNode();
        } else {
            var element = this.element;
            if (element == "convert") {
                var nodeClass = this.getClassFromType(type);
                node = Reflect.callMethod(nodeClass, "fromNode", [this.getNodeByName("in")]);
            } else if (element == "constant") {
                node = this.getNodeByName("value");
            } else if (element == "position") {
                var space = this.getAttribute("space");
                node = space == "world" ? positionWorld : positionLocal;
            } else if (element == "normal") {
                var space = this.getAttribute("space");
                node = space == "world" ? normalWorld : normalLocal;
            } else if (element == "tangent") {
                var space = this.getAttribute("space");
                node = space == "world" ? tangentWorld : tangentLocal;
            } else if (element == "texcoord") {
                var indexNode = this.getChildByName("index");
                var index = indexNode != null ? Std.parseInt(indexNode.value) : 0;
                node = uv(index);
            } else if (element == "geomcolor") {
                var indexNode = this.getChildByName("index");
                var index = indexNode != null ? Std.parseInt(indexNode.value) : 0;
                node = vertexColor(index);
            } else if (element == "tiledimage") {
                var file = this.getChildByName("file");
                var textureFile = file.getTexture();
                var uvTiling = mx_transform_uv(...this.getNodesByNames(["uvtiling", "uvoffset"]));
                node = texture(textureFile, uvTiling);
                var colorSpaceNode = file.getColorSpaceNode();
                if (colorSpaceNode != null) {
                    node = colorSpaceNode(node);
                }
            } else if (element == "image") {
                var file = this.getChildByName("file");
                var uvNode = this.getNodeByName("texcoord");
                var textureFile = file.getTexture();
                node = texture(textureFile, uvNode);
                var colorSpaceNode = file.getColorSpaceNode();
                if (colorSpaceNode != null) {
                    node = colorSpaceNode(node);
                }
            } else if (MtlXLibrary.elements.exists(element)) {
                var nodeElement = MtlXLibrary.elements.get(element);
                node = nodeElement.nodeFunc(...this.getNodesByNames(...nodeElement.params));
            }
        }
        if (node == null) {
            trace("Unexpected node " + nodeXML.toString());
            node = FloatNode.fromScalar(0);
        }
        var nodeToTypeClass = this.getClassFromType(type);
        if (nodeToTypeClass != null) {
            node = Reflect.callMethod(nodeToTypeClass, "fromNode", [node]);
        }
        node.name = this.name;
        this.node = node;
        return node;
    }

    public function getChildByName(name:String):MaterialXNode {
        for (input in children) {
            if (input.name == name) {
                return input;
            }
        }
        return null;
    }

    public function getNodes():Map<String, Dynamic> {
        var nodes = new Map<String, Dynamic>();
        for (input in children) {
            var node = input.getNode();
            nodes.set(node.name, node);
        }
        return nodes;
    }

    public function getNodeByName(name:String):Dynamic {
        var child = this.getChildByName(name);
        return child != null ? child.getNode() : null;
    }

    public function getNodesByNames(...names:Array<String>):Array<Dynamic> {
        var nodes = [];
        for (name in names) {
            var node = this.getNodeByName(name);
            if (node != null) {
                nodes.push(node);
            }
        }
        return nodes;
    }

    public function getValue():String {
        return this.value.trim();
    }

    public function getVector():Array<Float> {
        var vector = [];
        for (value in this.getValue().split(#[","|"\s"], "")) {
            if (value != "") {
                vector.push(Std.parseFloat(value.trim()));
            }
        }
        return vector;
    }

    public function getAttribute(name:String):String {
        return this.nodeXML.getAttribute(name);
    }

    public function getRecursiveAttribute(name:String):String {
        var attribute = this.nodeXML.getAttribute(name);
        if (attribute == null && this.parent != null) {
            attribute = this.parent.getRecursiveAttribute(name);
        }
        return attribute;
    }

    public function setStandardSurfaceToGltfPBR(material:MeshPhysicalNodeMaterial) {
        var inputs = this.getNodes();
        var colorNode = null;
        if (inputs.exists("base") && inputs.exists("base_color")) {
            colorNode = mul(inputs.get("base"), inputs.get("base_color"));
        } else if (inputs.exists("base")) {
            colorNode = inputs.get("base");
        } else if (inputs.exists("base_color")) {
            colorNode = inputs.get("base_color");
        }
        var roughnessNode = inputs.get("specular_roughness");
        var metalnessNode = inputs.get("metalness");
        var clearcoatNode = inputs.get("coat");
        var clearcoatRoughnessNode = inputs.get("coat_roughness");
        if (inputs.exists("coat_color")) {
            colorNode = colorNode != null ? mul(colorNode, inputs.get("coat_color")) : colorNode;
        }
        var normalNode = inputs.get("normal");
        var emissiveNode = inputs.get("emission");
        var emissionColor = inputs.get("emissionColor");
        if (emissionColor != null) {
            emissiveNode = emissiveNode != null ? mul(emissiveNode, emissionColor) : emissiveNode;
        }
        material.colorNode = colorNode ?? color(0.8, 0.8, 0.8);
        material.roughnessNode = roughnessNode ?? FloatNode.fromScalar(0.2);
        material.metalnessNode = metalnessNode ?? FloatNode.fromScalar(0);
        material.clearcoatNode = clearcoatNode ?? FloatNode.fromScalar(0);
        material.clearcoatRoughnessNode = clearcoatRoughnessNode ?? FloatNode.fromScalar(0);
        if (normalNode != null) {
            material.normalNode = normalNode;
        }
        if (emissiveNode != null) {
            material.emissiveNode = emissiveNode;
        }
    }

    public function setMaterial(material:MeshPhysicalNodeMaterial) {
        var element = this.element;
        if (element == "gltf_pbr") {
            // TODO: Implement gltf_pbr
        } else if (element == "standard_surface") {
            this.setStandardSurfaceToGltfPBR(material);
        }
    }

    public function toBasicMaterial():MeshBasicNodeMaterial {
        var material = new MeshBasicNodeMaterial();
        material.name = this.name;
        for (nodeX in children.reversed()) {
            if (nodeX.name == "out") {
                material.colorNode = nodeX.getNode();
                break;
            }
        }
        return material;
    }

    public function toPhysicalMaterial():MeshPhysicalNodeMaterial {
        var material = new MeshPhysicalNodeMaterial();
        material.name = this.name;
        for (nodeX in children) {
            var shaderProperties = this.materialX.getMaterialXNode(nodeX.nodeName);
            shaderProperties.setMaterial(material);
        }
        return material;
    }

    public function toMaterials():Map<String, MeshPhysicalNodeMaterial> {
        var materials = new Map<String, MeshPhysicalNodeMaterial>();
        var isUnlit = true;
        for (nodeX in children) {
            if (nodeX.element == "surfacematerial") {
                var material = nodeX.toPhysicalMaterial();
                materials.set(material.name, material);
                isUnlit = false;
            }
        }
        if (isUnlit) {
            for (nodeX in children) {
                if (nodeX.element == "nodegraph") {
                    var material = nodeX.toBasicMaterial();
                    materials.set(material.name, material);
                }
            }
        }
        return materials;
    }

    public function add(materialXNode:MaterialXNode) {
        materialXNode.parent = this;
        this.children.push(materialXNode);
    }

    public function new(materialX:MaterialX, nodeXML:XmlNode, ?nodePath:String) {
        this.materialX = materialX;
        this.nodeXML = nodeXML;
        this.nodePath = nodePath != null ? nodePath + "/" + this.name : this.name;
        this.parent = null;
        this.node = null;
        this.children = [];
    }
}

class MaterialX {
    public var manager:Dynamic;
    public var path:String;
    public var resourcePath:String;
    public var nodesXLib:Map<String, MaterialXNode>;
    public var textureLoader:TextureLoader;

    public function getMaterialXNode(...names:Array<String>):MaterialXNode {
        return this.nodesXLib.get(names.join("/"));
    }

    public function parseNode(nodeXML:XmlNode, ?nodePath:String):MaterialXNode {
        var materialXNode = new MaterialXNode(this, nodeXML, nodePath);
        if (materialXNode.nodePath != null) {
            this.nodesXLib.set(materialXNode.nodePath, materialXNode);
        }
        for (childNodeXML in nodeXML.children) {
            var childMXNode = this.parseNode(childNodeXML, materialXNode.nodePath);
            materialXNode.add(childMXNode);
        }
        return materialXNode;
    }

    public function parse(text:String):Dynamic {
        var rootXML = Xml.parse(text).documentElement;
        this.textureLoader.path = this.path;
        var materials = this.parseNode(rootXML).toMaterials();
        return { materials: materials };
    }

    public function new(manager:Dynamic, path:String) {
        this.manager = manager;
        this.path = path;
        this.resourcePath = "";
        this.nodesXLib = new Map();
        this.textureLoader = new TextureLoader(manager);
    }
}

var colorSpaceLib = {
    "mx_srgb_texture_to_lin_rec709": mx_srgb_texture_to_lin_rec709
};

var MXElements = [
    // << Math >>
    new MXElement("add", mx_add, ["in1", "in2"]),
    new MXElement("subtract", mx_subtract, ["in1", "in2"]),
    new MXElement("multiply", mx_multiply, ["in1", "in2"]),
    new MXElement("divide", mx_divide, ["in1", "in2"]),
    new MXElement("modulo", mx_modulo, ["in1", "in2"]),
    new MXElement("absval", abs, ["in1", "in2"]),
    new MXElement("sign", sign, ["in1", "in2"]),
    new MXElement("floor", floor, ["in1", "in2"]),
    new MXElement("ceil", ceil, ["in1", "in2"]),
    new MXElement("round", round, ["in1", "in2"]),
    new MXElement("power", mx_power, ["in1", "in2"]),
    new MXElement("sin", sin, ["in"]),
    new MXElement("cos", cos, ["in"]),
    new MXElement
    ("tan", tan, ["in"]),
    new MXElement("asin", asin, ["in"]),
    new MXElement("acos", acos, ["in"]),
    new MXElement("atan2", mx_atan2, ["in1", "in2"]),
    new MXElement("sqrt", sqrt, ["in"]),
    new MXElement("exp", exp, ["in"]),
    new MXElement("clamp", clamp, ["in", "low", "high"]),
    new MXElement("min", min, ["in1", "in2"]),
    new MXElement("max", max, ["in1", "in2"]),
    new MXElement("normalize", normalize, ["in"]),
    new MXElement("magnitude", length, ["in1", "in2"]),
    new MXElement("dotproduct", dot, ["in1", "in2"]),
    new MXElement("crossproduct", cross, ["in"]),
    new MXElement("normalmap", normalMap, ["in", "scale"]),
    new MXElement("remap", remap, ["in", "inlow", "inhigh", "outlow", "outhigh"]),
    new MXElement("smoothstep", smoothstep, ["in", "low", "high"]),
    new MXElement("luminance", luminance, ["in", "lumacoeffs"]),
    new MXElement("rgbtohsv", mx_rgbtohsv, ["in"]),
    new MXElement("hsvtorgb", mx_hsvtorgb, ["in"]),
    new MXElement("mix", mix, ["bg", "fg", "mix"]),
    new MXElement("combine2", vec2, ["in1", "in2"]),
    new MXElement("combine3", vec3, ["in1", "in2", "in3"]),
    new MXElement("combine4", vec4, ["in1", "in2", "in3", "in4"]),
    new MXElement("ramplr", mx_ramplr, ["valuel", "valuer", "texcoord"]),
    new MXElement("ramptb", mx_ramptb, ["valuet", "valueb", "texcoord"]),
    new MXElement("splitlr", mx_splitlr, ["valuel", "valuer", "texcoord"]),
    new MXElement("splittb", mx_splittb, ["valuet", "valueb", "texcoord"]),
    new MXElement("noise2d", mx_noise_float, ["texcoord", "amplitude", "pivot"]),
    new MXElement("noise3d", mx_noise_float, ["texcoord", "amplitude", "pivot"]),
    new MXElement("fractal3d", mx_fractal_noise_float, ["position", "octaves", "lacunarity", "diminish", "amplitude"]),
    new MXElement("cellnoise2d", mx_cell_noise_float, ["texcoord"]),
    new MXElement("cellnoise3d", mx_cell_noise_float, ["texcoord"]),
    new MXElement("worleynoise2d", mx_worley_noise_float, ["texcoord", "jitter"]),
    new MXElement("worleynoise3d", mx_worley_noise_float, ["texcoord", "jitter"]),
    new MXElement("safepower", mx_safepower, ["in1", "in2"]),
    new MXElement("contrast", mx_contrast, ["in", "amount", "pivot"]),
    new MXElement("saturate", saturation, ["in", "amount"])
];

var MtlXLibrary = new MtlXLibrary();
for (element in MXElements) {
    MtlXLibrary.add(element);
}

class mx_add {
    public function __call__(in1:Dynamic, ?in2:Dynamic):Dynamic {
        return add(in1, in2 ?? FloatNode.fromScalar(0));
    }
}

class mx_subtract {
    public function __call__(in1:Dynamic, ?in2:Dynamic):Dynamic {
        return sub(in1, in2 ?? FloatNode.fromScalar(0));
    }
}

class mx_multiply {
    public function __call__(in1:Dynamic, ?in2:Dynamic):Dynamic {
        return mul(in1, in2 ?? FloatNode.fromScalar(1));
    }
}

class mx_divide {
    public function __call__(in1:Dynamic, ?in2:Dynamic):Dynamic {
        return div(in1, in2 ?? FloatNode.fromScalar(1));
    }
}

class mx_modulo {
    public function __call__(in1:Dynamic, ?in2:Dynamic):Dynamic {
        return mod(in1, in2 ?? FloatNode.fromScalar(1));
    }
}

class mx_power {
    public function __call__(in1:Dynamic, ?in2:Dynamic):Dynamic {
        return pow(in1, in2 ?? FloatNode.fromScalar(1));
    }
}

class mx_atan2 {
    public function __call__(?in1:Dynamic, ?in2:Dynamic):Dynamic {
        return atan2(in1 ?? FloatNode.fromScalar(0), in2 ?? FloatNode.fromScalar(1));
    }
}

export { MaterialXLoader };