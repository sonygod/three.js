import NodeLoader from './NodeLoader.hx';
import NodeMaterialLoader from './NodeMaterialLoader.hx';
import ObjectLoader from 'three/src/loaders/ObjectLoader.hx';

class NodeObjectLoader extends ObjectLoader {
    public var _nodesJSON:Null<Json>;

    public function new(manager:LoadingManager) {
        super(manager);
        this._nodesJSON = null;
    }

    public function parse(json:Json, onLoad:OnLoad) : Object3D {
        this._nodesJSON = json.nodes;
        var data = super.parse(json, onLoad);
        this._nodesJSON = null; // dispose
        return data;
    }

    public function parseNodes(json:Json, textures:TextureMap) : NodeMap {
        if (json != null) {
            var loader = new NodeLoader();
            loader.setTextures(textures);
            return loader.parseNodes(json);
        }
        return {};
    }

    public function parseMaterials(json:Json, textures:TextureMap) : MaterialMap {
        var materials = cast {};
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

class OnLoad {
    public function new() {}
    public function onLoad(data:Object3D) : Void {}
}

class TextureMap {
    public function new() {}
}

class NodeMap {
    public function new() {}
}

class MaterialMap {
    public function new() {}
}