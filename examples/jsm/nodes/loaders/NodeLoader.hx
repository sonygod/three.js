package three.js.examples.jsm.nodes.loaders;

import three(js.html.FileLoader);
import three(js.core.Loader);
import three(js.shadernode.ShaderNode);
import three(js.core.Node);

class NodeLoader extends Loader {
    public var textures:Dynamic = {};

    public function new(manager:Loader) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var loader:FileLoader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(text:String) {
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

    public function parseNodes(json:Array<Dynamic>):Dynamic<String, Node> {
        var nodes:Dynamic<String, Node> = {};
        if (json != null) {
            for (nodeJSON in json) {
                var node:Node = nodeObject(createNodeFromType(nodeJSON.type));
                node.uuid = nodeJSON.uuid;
                nodes[node.uuid] = node;
            }
            var meta:Dynamic = { nodes: nodes, textures: this.textures };
            for (nodeJSON in json) {
                nodeJSON.meta = meta;
                var node:Node = nodes[nodeJSON.uuid];
                node.deserialize(nodeJSON);
                Reflect.deleteField(nodeJSON, "meta");
            }
        }
        return nodes;
    }

    public function parse(json:Dynamic):Node {
        var node:Node = nodeObject(createNodeFromType(json.type));
        node.uuid = json.uuid;
        var nodes:Dynamic<String, Node> = this.parseNodes(json.nodes);
        var meta:Dynamic = { nodes: nodes, textures: this.textures };
        json.meta = meta;
        node.deserialize(json);
        Reflect.deleteField(json, "meta");
        return node;
    }

    public function setTextures(value:Dynamic):NodeLoader {
        this.textures = value;
        return this;
    }
}