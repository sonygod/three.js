import NodeLoader.NodeLoader;
import NodeMaterialLoader.NodeMaterialLoader;
import three.ObjectLoader;

class NodeObjectLoader extends ObjectLoader {

	public var _nodesJSON:Null<Dynamic>;

	public function new(manager:Null<Dynamic>) {

		super(manager);

		this._nodesJSON = null;

	}

	public function parse(json:Dynamic, onLoad:Dynamic->Void):Dynamic {

		this._nodesJSON = json.nodes;

		var data = super.parse(json, onLoad);

		this._nodesJSON = null; // dispose

		return data;

	}

	public function parseNodes(json:Dynamic, textures:Dynamic):Dynamic {

		if (json != null) {

			var loader = new NodeLoader();
			loader.setTextures(textures);

			return loader.parseNodes(json);

		}

		return {};

	}

	public function parseMaterials(json:Dynamic, textures:Dynamic):Dynamic {

		var materials = {};

		if (json != null) {

			var nodes = this.parseNodes(this._nodesJSON, textures);

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