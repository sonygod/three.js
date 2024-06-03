import three.nodes.core.Node;
import three.nodes.shadernode.ShaderNode;
import three.loaders.FileLoader;
import three.loaders.Loader;

class NodeLoader extends Loader {

    public var textures:Map<String, Dynamic> = new Map<String, Dynamic>();

    public function new(manager:Loader.Manager) {
        super(manager);
    }

    public function load(url:String, onLoad:(node:Node) -> Void, onProgress:(event:ProgressEvent) -> Void, onError:(event:ErrorEvent) -> Void) {
        var loader:FileLoader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, (text:String) => {
            try {
                onLoad(this.parse(JSON.parse(text)));
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

    public function parseNodes(json:Array<Dynamic>):Map<String, Node> {
        var nodes:Map<String, Node> = new Map<String, Node>();
        if (json != null) {
            for (nodeJSON in json) {
                var uuid:String = nodeJSON.uuid;
                var type:String = nodeJSON.type;
                nodes.set(uuid, ShaderNode.nodeObject(Node.createNodeFromType(type)));
                nodes.get(uuid).uuid = uuid;
            }

            var meta:Dynamic = { nodes: nodes, textures: this.textures };

            for (nodeJSON in json) {
                nodeJSON.meta = meta;
                var node:Node = nodes.get(nodeJSON.uuid);
                node.deserialize(nodeJSON);
                Reflect.deleteField(nodeJSON, "meta");
            }
        }
        return nodes;
    }

    public function parse(json:Dynamic):Node {
        var node:Node = ShaderNode.nodeObject(Node.createNodeFromType(json.type));
        node.uuid = json.uuid;
        var nodes:Map<String, Node> = this.parseNodes(json.nodes);
        var meta:Dynamic = { nodes: nodes, textures: this.textures };
        json.meta = meta;
        node.deserialize(json);
        Reflect.deleteField(json, "meta");
        return node;
    }

    public function setTextures(value:Map<String, Dynamic>):NodeLoader {
        this.textures = value;
        return this;
    }
}