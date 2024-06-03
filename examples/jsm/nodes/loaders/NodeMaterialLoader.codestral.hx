import three.MaterialLoader;
import three.nodes.materials.Materials;

var superFromTypeFunction:Function = MaterialLoader.createMaterialFromType;

MaterialLoader.createMaterialFromType = function(type:String) {
    var material = Materials.createNodeMaterialFromType(type);

    if (material !== null) {
        return material;
    }

    return haxe.lang.Function.call(superFromTypeFunction, this, [type]);
};

class NodeMaterialLoader extends MaterialLoader {
    public var nodes:haxe.ds.StringMap<Dynamic>;

    public function new(manager:three.LoadingManager) {
        super(manager);
        this.nodes = new haxe.ds.StringMap();
    }

    override public function parse(json:Dynamic) {
        var material = super.parse(json);

        var inputNodes = json.inputNodes;

        for (property in Reflect.fields(inputNodes)) {
            var uuid = inputNodes[property];
            material[property] = nodes.get(uuid);
        }

        return material;
    }

    public function setNodes(value:haxe.ds.StringMap<Dynamic>):NodeMaterialLoader {
        this.nodes = value;
        return this;
    }
}