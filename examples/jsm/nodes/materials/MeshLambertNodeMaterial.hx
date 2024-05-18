package three.js.examples.jvm.nodes.materials;

import three.js.nodes.NodeMaterial;
import three.js.functions.PhongLightingModel;

import three.js.Materials.MeshLambertMaterial;

class MeshLambertNodeMaterial extends NodeMaterial {

    public var isMeshLambertNodeMaterial:Bool = true;

    public function new(parameters:Dynamic = null) {
        super();
        lights = true;
        setDefaultValues(new MeshLambertMaterial());
        setValues(parameters);
    }

    public function setupLightingModel(builder:Dynamic = null):PhongLightingModel {
        return new PhongLightingModel(false); // (specular) -> force lambert
    }

}

// Add the material to the registry
NodeMaterial.addNodeMaterial('MeshLambertNodeMaterial', MeshLambertNodeMaterial);