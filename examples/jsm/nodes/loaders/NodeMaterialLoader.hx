package three.js.examples.jsm.nodes.loaders;

import three.MaterialLoader;
import three.materials.Materials;

class NodeMaterialLoader extends MaterialLoader {
    public var nodes:Map<String, Dynamic>;

    public function new(manager:Dynamic) {
        super(manager);
        this.nodes = new Map<String, Dynamic>();
    }

    override public function parse(json:Dynamic):Material {
        var material:Material = super.parse(json);
        var inputNodes:Dynamic = json.inputNodes;
        for (property in inputNodes.keys()) {
            var uuid:String = inputNodes.get(property);
            material.set(property, nodes.get(uuid));
        }
        return material;
    }

    public function setNodes(value:Map<String, Dynamic>):NodeMaterialLoader {
        this.nodes = value;
        return this;
    }

    static function createNodeMaterialFromType(type:Dynamic):Material {
        // implementation of createNodeMaterialFromType function
        // you may need to adjust this part according to your Haxe setup
        return Materials.createNodeMaterialFromType(type);
    }

    static function main() {
        var superFromTypeFunction:Dynamic = MaterialLoader.createMaterialFromType;
        MaterialLoader.createMaterialFromType = function(type:Dynamic) {
            var material:Material = createNodeMaterialFromType(type);
            if (material != null) {
                return material;
            }
            return superFromTypeFunction(type);
        };
    }
}