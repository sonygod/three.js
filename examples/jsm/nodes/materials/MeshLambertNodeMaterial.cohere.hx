import NodeMaterial from './NodeMaterial.hx';
import PhongLightingModel from '../functions/PhongLightingModel.hx';

import js__$MeshLambertMaterial from 'three/src/materials/MeshLambertMaterial.js';

class MeshLambertNodeMaterial extends NodeMaterial {
    public isMeshLambertNodeMaterial:Bool;
    public lights:Bool;
    public function new(parameters:Dynamic) {
        super();
        this.isMeshLambertNodeMaterial = true;
        this.lights = true;
        this.setDefaultValues(js__$MeshLambertMaterial.default);
        this.setValues(parameters);
    }
    public function setupLightingModel():PhongLightingModel {
        return new PhongLightingModel(false);
    }
}

static function addNodeMaterial(name:String, material:NodeMaterial) {
    // add material to the NodeMaterial registry
}

addNodeMaterial('MeshLambertNodeMaterial', MeshLambertNodeMaterial);

export { MeshLambertNodeMaterial };