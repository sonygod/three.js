import js.three.MaterialLoader;
import js.createNodeMaterialFromType from '../materials/Materials.hx';

var superFromTypeFunction = MaterialLoader.createMaterialFromType;

MaterialLoader.createMaterialFromType = function(type) {
  var material = createNodeMaterialFromType(type);
  if (material != null) {
    return material;
  }
  return superFromTypeFunction.call(this, type);
};

class NodeMaterialLoader extends MaterialLoader {
  public var nodes:Dynamic;

  public function new(manager:Dynamic) {
    super(manager);
    this.nodes = {};
  }

  public function parse(json:Dynamic) {
    var material = super.parse(json);
    var nodes = this.nodes;
    var inputNodes = json.inputNodes;
    for (var property in inputNodes) {
      var uuid = inputNodes[$property];
      material[$property] = nodes[uuid];
    }
    return material;
  }

  public function setNodes(value:Dynamic) {
    this.nodes = value;
    return this;
  }
}

class js__$NodeMaterialLoader_NodeMaterialLoader_$Impl_ {
  public static function __new(manager:Dynamic) {
    var this1 = new NodeMaterialLoader();
    this1.new(manager);
    return this1;
  }
}