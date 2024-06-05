import three.loaders.MaterialLoader;
import materials.Materials;

class NodeMaterialLoader extends MaterialLoader {

	public var nodes:Dynamic;

	public function new(manager:Dynamic) {
		super(manager);
		this.nodes = {};
	}

	override public function parse(json:Dynamic):Dynamic {
		var material = super.parse(json);
		var nodes = this.nodes;
		var inputNodes = json.inputNodes;

		for (property in inputNodes) {
			var uuid = inputNodes[property];
			material[property] = nodes[uuid];
		}

		return material;
	}

	public function setNodes(value:Dynamic):NodeMaterialLoader {
		this.nodes = value;
		return this;
	}
}

var superFromTypeFunction = MaterialLoader.createMaterialFromType;

MaterialLoader.createMaterialFromType = function(type:Dynamic):Dynamic {
	var material = Materials.createNodeMaterialFromType(type);
	if (material != null) {
		return material;
	}
	return superFromTypeFunction.call(this, type);
};

class NodeMaterialLoader {
	static public function create():NodeMaterialLoader {
		return new NodeMaterialLoader();
	}
}