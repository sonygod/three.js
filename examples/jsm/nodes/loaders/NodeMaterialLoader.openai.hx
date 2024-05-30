package three.js.examples.jsm.nodes.loaders;

import three.MaterialLoader;
import three.materials.Materials;

class NodeMaterialLoader extends MaterialLoader {
  var nodes:Map<String, Dynamic>;

  public function new(manager:Dynamic) {
    super(manager);
    nodes = new Map();
  }

  override public function parse(json:Dynamic):Dynamic {
    var material:Dynamic = super.parse(json);
    var inputNodes:Dynamic = json.inputNodes;
    for (property in inputNodes.keys()) {
      var uuid:String = inputNodes[property];
      material[property] = nodes[uuid];
    }
    return material;
  }

  public function setNodes(value:Dynamic):NodeMaterialLoader {
    nodes = value;
    return this;
  }

  static function createMaterialFromType(type:Dynamic):Dynamic {
    var material:Dynamic = createNodeMaterialFromType(type);
    if (material != null) {
      return material;
    }
    return MaterialLoader.createMaterialFromType(type);
  }
}

// static extension
class MaterialLoaderExtension {
  static var superFromTypeFunction:Dynamic = MaterialLoader.createMaterialFromType;

  static function createMaterialFromType(type:Dynamic):Dynamic {
    return NodeMaterialLoader.createMaterialFromType(type);
  }
}

// Static initialization
MaterialLoader.createMaterialFromType = MaterialLoaderExtension.createMaterialFromType;