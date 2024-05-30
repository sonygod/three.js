import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.FileLoader;
import three.js.Loader;

class NodeLoader extends Loader {

	public function new(manager:Dynamic) {
		super(manager);
		this.textures = {};
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(this.parse(haxe.Json.parse(text)));
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

	public function parseNodes(json:Dynamic):Dynamic {
		var nodes = {};
		if (json != null) {
			for (nodeJSON in json) {
				var uuid = nodeJSON.uuid;
				var type = nodeJSON.type;
				nodes[uuid] = ShaderNode.nodeObject(Node.createNodeFromType(type));
				nodes[uuid].uuid = uuid;
			}
			var meta = {nodes:nodes, textures:this.textures};
			for (nodeJSON in json) {
				nodeJSON.meta = meta;
				var node = nodes[nodeJSON.uuid];
				node.deserialize(nodeJSON);
				delete nodeJSON.meta;
			}
		}
		return nodes;
	}

	public function parse(json:Dynamic):Dynamic {
		var node = ShaderNode.nodeObject(Node.createNodeFromType(json.type));
		node.uuid = json.uuid;
		var nodes = this.parseNodes(json.nodes);
		var meta = {nodes:nodes, textures:this.textures};
		json.meta = meta;
		node.deserialize(json);
		delete json.meta;
		return node;
	}

	public function setTextures(value:Dynamic):NodeLoader {
		this.textures = value;
		return this;
	}
}