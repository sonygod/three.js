package three.js.examples.jsm.nodes.loaders;

import NodeLoader from './NodeLoader';
import NodeMaterialLoader from './NodeMaterialLoader';
import three.ObjectLoader;

class NodeObjectLoader extends ObjectLoader {

    var _nodesJSON:Dynamic;

    public function new(manager:Dynamic) {
        super(manager);
        _nodesJSON = null;
    }

    override public function parse(json:Dynamic, onLoad:Void->Void):Dynamic {
        _nodesJSON = json.nodes;
        var data = super.parse(json, onLoad);
        _nodesJSON = null; // dispose
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

    public function parseMaterials(json:Array<Dynamic>, textures:Dynamic):Map<String, Dynamic> {
        var materials:Map<String, Dynamic> = new Map();
        if (json != null) {
            var nodes = parseNodes(_nodesJSON, textures);
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