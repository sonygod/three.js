import three.MaterialLoader;
import three.jsm.nodes.materials.Materials;

class NodeMaterialLoader extends MaterialLoader {

    var superFromTypeFunction:Dynamic = MaterialLoader.createMaterialFromType;

    static function createMaterialFromType(type:String):Dynamic {
        var material = Materials.createNodeMaterialFromType(type);
        if (material != null) {
            return material;
        }
        return superFromTypeFunction.call(this, type);
    }

    public function new(manager:Dynamic) {
        super(manager);
        this.nodes = {};
    }

    public function parse(json:Dynamic):Dynamic {
        var material = super.parse(json);
        var nodes = this.nodes;
        var inputNodes = json.inputNodes;
        for (property in inputNodes) {
            var uuid = inputNodes[property];
            material[property] = nodes[uuid];
        }
        return material;
    }

    public function setNodes(value:Dynamic):NodeMaterialLoader {
        this.nodes = value;
        return this;
    }

}

typedef NodeMaterialLoader = NodeMaterialLoader;