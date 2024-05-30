package three.js.modes.materials;

import three.js.nodes.NodeMaterial;
import three.js.functions.PhongLightingModel;
import three.js.materials.MeshLambertMaterial;

class MeshLambertNodeMaterial extends NodeMaterial {
    public var isMeshLambertNodeMaterial:Bool = true;

    public function new(parameters:Dynamic = null) {
        super();
        this.lights = true;
        this.setDefaultValues(new MeshLambertMaterial());
        this.setValues(parameters);
    }

    override public function setupLightingModel(builder:Dynamic):PhongLightingModel {
        return new PhongLightingModel(false); // (specular) -> force lambert
    }
}

registerNodeMaterial('MeshLambertNodeMaterial', MeshLambertNodeMaterial);