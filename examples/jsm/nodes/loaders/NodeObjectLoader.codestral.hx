import NodeLoader from './NodeLoader.hx';
import NodeMaterialLoader from './NodeMaterialLoader.hx';
import three.ObjectLoader;

class NodeObjectLoader extends ObjectLoader {

    private var _nodesJSON:Dynamic;

    public function new(manager:AssetManager) {
        super(manager);

        this._nodesJSON = null;
    }

    override public function parse(json:Dynamic, onLoad:Null<Function>):Dynamic {
        this._nodesJSON = json.nodes;

        var data = super.parse(json, onLoad);

        this._nodesJSON = null; // dispose

        return data;
    }

    public function parseNodes(json:Dynamic, textures:Dynamic):Dynamic {
        if (json !== undefined) {
            var loader = new NodeLoader();
            loader.setTextures(textures);

            return loader.parseNodes(json);
        }

        return {};
    }

    public function parseMaterials(json:Dynamic, textures:Dynamic):Dynamic {
        var materials = new Dynamic();

        if (json !== undefined) {
            var nodes = this.parseNodes(this._nodesJSON, textures);

            var loader = new NodeMaterialLoader();
            loader.setTextures(textures);
            loader.setNodes(nodes);

            for (var i = 0; i < json.length; i++) {
                var data = json[i];

                materials[data.uuid] = loader.parse(data);
            }
        }

        return materials;
    }
}