package three.js.examples.jvm.nodes.materials;

import three.js.examples.jvm.nodes.NodeMaterial;

import three.js.loaders.Material;

class MeshBasicNodeMaterial extends NodeMaterial {

    public var isMeshBasicNodeMaterial:Bool = true;

    public var lights:Bool = false;
    //public var normals:Bool = false; // @TODO: normals usage by context

    public function new(?parameters:Dynamic) {
        super();

        var defaultValues:MeshBasicMaterial = new MeshBasicMaterial();
        this.setDefaultValues(defaultValues);

        this.setValues(parameters);
    }

    public static function main() {
        NodeMaterial.addNodeMaterial('MeshBasicNodeMaterial', MeshBasicNodeMaterial);
    }

}