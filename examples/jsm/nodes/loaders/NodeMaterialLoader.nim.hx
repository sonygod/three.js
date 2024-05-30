import three.MaterialLoader;
import three.nodes.materials.Materials;

typedef MaterialLoaderSuper = {
  public function createMaterialFromType(type:String):Dynamic;
}

var superFromTypeFunction:MaterialLoaderSuper = cast MaterialLoader.createMaterialFromType;

MaterialLoader.createMaterialFromType = function(type:String) {
  var material:Dynamic = Materials.createNodeMaterialFromType(type);
  if (material != null) {
    return material;
  }
  return superFromTypeFunction.createMaterialFromType(type);
};

class NodeMaterialLoader extends MaterialLoader {
  public var nodes:Map<String, Dynamic>;

  public function new(manager:Dynamic) {
    super(manager);
    this.nodes = new Map<String, Dynamic>();
  }

  public function parse(json:Dynamic):Dynamic {
    var material:Dynamic = super.parse(json);
    var inputNodes:Dynamic = json.inputNodes;
    for (property in inputNodes) {
      var uuid:String = inputNodes[property];
      material[property] = this.nodes[uuid];
    }
    return material;
  }

  public function setNodes(value:Map<String, Dynamic>):NodeMaterialLoader {
    this.nodes = value;
    return this;
  }
}