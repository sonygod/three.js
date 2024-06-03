import three.MeshBasicMaterial;
import nodes.NodeMaterial;
import nodes.materials.NodeMaterials;

class MeshBasicNodeMaterial extends NodeMaterial {
    public var isMeshBasicNodeMaterial:Bool = true;
    public var lights:Bool = false;
    //public var normals:Bool = false; @TODO: normals usage by context

    public function new(parameters:Dynamic) {
        super();
        var defaultValues = new MeshBasicMaterial();
        this.setDefaultValues(defaultValues);
        this.setValues(parameters);
    }
}

typedef MeshBasicNodeMaterialType = MeshBasicNodeMaterial;

class NodeMaterials {
    public static function addNodeMaterial(name:String, material:Class<MeshBasicNodeMaterial>) {
        // implementation here
    }
}

NodeMaterials.addNodeMaterial('MeshBasicNodeMaterial', MeshBasicNodeMaterialType);