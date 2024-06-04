import three.core.Node;
import three.shadernode.ShaderNode;
import three.loaders.FileLoader;
import three.loaders.Loader;

class NodeLoader extends Loader {

	public var textures:Map<String,Dynamic>;

	public function new(manager:Loader = null) {
		super(manager);
		textures = new Map();
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null):Void {
		var loader = new FileLoader(manager);
		loader.setPath(path);
		loader.setRequestHeader(requestHeader);
		loader.setWithCredentials(withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(parse(Json.parse(text)));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					Sys.println(e);
				}
				manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parseNodes(json:Array<Dynamic>):Map<String,ShaderNode> {
		var nodes = new Map<String,ShaderNode>();
		if (json != null) {
			for (nodeJSON in json) {
				var uuid = nodeJSON.uuid;
				var type = nodeJSON.type;
				nodes.set(uuid, ShaderNode.nodeObject(Node.createNodeFromType(type)));
				nodes.get(uuid).uuid = uuid;
			}
			var meta = {nodes:nodes, textures:textures};
			for (nodeJSON in json) {
				nodeJSON.meta = meta;
				var node = nodes.get(nodeJSON.uuid);
				node.deserialize(nodeJSON);
				delete nodeJSON.meta;
			}
		}
		return nodes;
	}

	public function parse(json:Dynamic):ShaderNode {
		var node = ShaderNode.nodeObject(Node.createNodeFromType(json.type));
		node.uuid = json.uuid;
		var nodes = parseNodes(json.nodes);
		var meta = {nodes:nodes, textures:textures};
		json.meta = meta;
		node.deserialize(json);
		delete json.meta;
		return node;
	}

	public function setTextures(value:Map<String,Dynamic>):NodeLoader {
		textures = value;
		return this;
	}

}