import haxe.Serializer;
import haxe.Unserializer;

class NodeLoader {
    var textures: { [key: String]: Dynamic } = {};

    public function new(manager: Manager) {
        // ...
    }

    public function load(url: String, onLoad: Function, onProgress: Function, onError: Function): Void {
        var loader = new FileLoader(manager);
        loader.path = this.path;
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, (text: String) -> {
            try {
                onLoad(this.parse(unserialize(text)));
            } catch (e: Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                manager.itemError(url);
            }
        }, onProgress, onError);
    }

    private function parseNodes(json: Dynamic): { [key: String]: Dynamic } {
        var nodes: { [key: String]: Dynamic } = {};
        if (json != null) {
            for (nodeJSON in json) {
                var uuid = nodeJSON.uuid;
                var type = nodeJSON.type;
                nodes[uuid] = nodeObject(createNodeFromType(type));
                nodes[uuid].uuid = uuid;
            }
            var meta = { nodes, textures: this.textures };
            for (nodeJSON in json) {
                nodeJSON.meta = meta;
                var node = nodes[nodeJSON.uuid];
                node.deserialize(nodeJSON);
                nodeJSON.meta = null;
            }
        }
        return nodes;
    }

    private function parse(json: Dynamic): Dynamic {
        var node = nodeObject(createNodeFromType(json.type));
        node.uuid = json.uuid;
        var nodes = this.parseNodes(json.nodes);
        var meta = { nodes, textures: this.textures };
        json.meta = meta;
        node.deserialize(json);
        json.meta = null;
        return node;
    }

    public function setTextures(value: Dynamic): NodeLoader {
        this.textures = value;
        return this;
    }
}

function unserialize(text: String): Dynamic {
    var unserializer = new Unserializer(text);
    return unserializer.unserialize();
}

class Node {
    public var uuid: String;

    public function new() {
        // ...
    }

    public function deserialize(json: Dynamic): Void {
        // ...
    }
}

function nodeObject(type: Int): Node {
    // ...
    return new Node();
}

function createNodeFromType(type: String): Int {
    // ...
    return 0;
}

class Manager {
    // ...
}

class FileLoader {
    public function new(manager: Manager) {
        // ...
    }

    public var path: String;
    public var requestHeader: String;
    public var withCredentials: Bool;

    public function load(url: String, onLoad: Function, onProgress: Function, onError: Function): Void {
        // ...
    }
}