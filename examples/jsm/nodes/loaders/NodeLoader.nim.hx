import three.examples.jsm.nodes.core.Node.createNodeFromType;
import three.examples.jsm.nodes.shadernode.ShaderNode.nodeObject;
import three.FileLoader;
import three.Loader;

class NodeLoader extends Loader {

	public var textures:Map<String, Dynamic>;

	public function new(manager:Loader.LoaderManager) {
		super(manager);
		this.textures = new Map<String, Dynamic>();
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(this.parse(Json.parse(text)));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					trace(e);
				}
				this.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parseNodes(json:Array<Dynamic>) {
		var nodes = new Map<String, Dynamic>();
		if (json != null) {
			for (nodeJSON in json) {
				var {uuid, type} = nodeJSON;
				nodes.set(uuid, nodeObject(createNodeFromType(type)));
				nodes.get(uuid).uuid = uuid;
			}
			var meta = {nodes: nodes, textures: this.textures};
			for (nodeJSON in json) {
				nodeJSON.meta = meta;
				var node = nodes.get(nodeJSON.uuid);
				node.deserialize(nodeJSON);
				delete nodeJSON.meta;
			}
		}
		return nodes;
	}

	public function parse(json:Dynamic) {
		var node = nodeObject(createNodeFromType(json.type));
		node.uuid = json.uuid;
		var nodes = this.parseNodes(json.nodes);
		var meta = {nodes: nodes, textures: this.textures};
		json.meta = meta;
		node.deserialize(json);
		delete json.meta;
		return node;
	}

	public function setTextures(value:Map<String, Dynamic>) {
		this.textures = value;
		return this;
	}

}