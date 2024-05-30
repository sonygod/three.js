import NodeLoader from './NodeLoader.hx';
import NodeMaterialLoader from './NodeMaterialLoader.hx';
import three.ObjectLoader;

class NodeObjectLoader extends ObjectLoader {

	var _nodesJSON:Null<Dynamic>;

	public function new(manager:Dynamic) {
		super(manager);
		_nodesJSON = null;
	}

	public function parse(json:Dynamic, onLoad:Dynamic):Dynamic {
		_nodesJSON = json.nodes;
		var data = super.parse(json, onLoad);
		_nodesJSON = null; // dispose
		return data;
	}

	public function parseNodes(json:Dynamic, textures:Dynamic):Dynamic {
		if (json !== null) {
			var loader = new NodeLoader();
			loader.setTextures(textures);
			return loader.parseNodes(json);
		}
		return {};
	}

	public function parseMaterials(json:Dynamic, textures:Dynamic):Dynamic {
		var materials:Dynamic = {};
		if (json !== null) {
			var nodes = this.parseNodes(_nodesJSON, textures);
			var loader = new NodeMaterialLoader();
			loader.setTextures(textures);
			loader.setNodes(nodes);
			for (i in 0...json.length) {
				var data = json[i];
				materials[data.uuid] = loader.parse(data);
			}
		}
		return materials;
	}

}

typedef NodeObjectLoader = NodeObjectLoader;