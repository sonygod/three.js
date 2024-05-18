import three.js.loaders.FileLoader;
import three.js.loaders.Loader;
import three.js.loaders.TextureLoader;
import three.js.materials.MeshBasicNodeMaterial;
import three.js.materials.MeshPhysicalNodeMaterial;
import three.js.math.Color;
import three.js.math.Matrix4;
import three.js.math.Quaternion;
import three.js.math.Vector2;
import three.js.math.Vector3;
import three.js.math.Vector4;
import three.js.textures.Texture;

class MaterialXLoader extends Loader {

 public function new(manager:LoaderManager) {
 super(manager);
 }

 public override function load(url:String, onLoad:(result:Dynamic) -> Void, onProgress:(progress:Float) -> Void, onError:(error:Dynamic) -> Void):MaterialXLoader {
 var _onError = function(e) {
 if (onError != null) {
 onError(e);
 } else {
 console.error(e);
 }
 };

 new FileLoader(manager)
 .setPath(path)
 .load(url, function(text) {
 try {
 onLoad(parse(text));
 } catch (e) {
 _onError(e);
 }
 }, onProgress, _onError);

 return this;
 }

 public function parse(text:String):Dynamic {
 return new MaterialX(manager, path).parse(text);
 }
}

class MaterialX {

 public var manager:LoaderManager;
 public var path:String;
 public var resourcePath:String;

 public var nodesXLib:Map<String, MaterialXNode>;

 public function new(manager:LoaderManager, path:String) {
 super();
 this.manager = manager;
 this.path = path;
 this.nodesXLib = new Map<String, MaterialXNode>();
 }

 public function addMaterialXNode(materialXNode:MaterialXNode) {
 this.nodesXLib.set(materialXNode.nodePath, materialXNode);
 }

 public function parseNode(nodeXML:XML, nodePath:String = ""):MaterialXNode {
 var materialXNode = new MaterialXNode(this, nodeXML, nodePath);
 if (materialXNode.nodePath != null) this.addMaterialXNode(materialXNode);

 for (node in nodeXML.children()) {
 var childMXNode = this.parseNode(node, materialXNode.nodePath);
 materialXNode.add(childMXNode);
 }

 return materialXNode;
 }

 public function parse(text:String):Dynamic {
 var rootXML = new DOMParser().parseFromString(text, "application/xml").documentElement;

 this.parseNode(rootXML);

 return {};
 }
}

class MaterialXNode {

 public var materialX:MaterialX;
 public var nodeXML:XML;
 public var nodePath:String;

 public var parent:MaterialXNode;

 public var children:Array<MaterialXNode>;

 public var element:String;
 public var nodeGraph:String;
 public var nodeName:String;
 public var interfaceName:String;
 public var output:String;
 public var name:String;
 public var type:String;
 public var value:String;

 public function new(materialX:MaterialX, nodeXML:XML, nodePath:String = "") {
 this.materialX = materialX;
 this.nodeXML = nodeXML;
 this.nodePath = nodePath;

 this.parent = null;

 this.children = [];

 this.element = nodeXML.name();
 this.nodeGraph = nodeXML.attribute("nodegraph");
 this.nodeName = nodeXML.attribute("nodename");
 this.interfaceName = nodeXML.attribute("interfacename");
 this.output = nodeXML.attribute("output");
 this.name = nodeXML.attribute("name");
 this.type = nodeXML.attribute("type");
 this.value = nodeXML.attribute("value");
 }

 // Implement the rest of the MaterialXNode class methods here
}