import NodeMaterial;
import addNodeMaterial from './NodeMaterial';
import PhongLightingModel from '../functions/PhongLightingModel';
import MeshLambertMaterial from 'three.MeshLambertMaterial';

class MeshLambertNodeMaterial extends NodeMaterial {
    public var isMeshLambertNodeMaterial:Bool = true;
    public var lights:Bool = true;

    public function new(parameters:Dynamic) {
        super();

        var defaultValues = new MeshLambertMaterial();
        this.setDefaultValues(defaultValues);
        this.setValues(parameters);
    }

    public function setupLightingModel():PhongLightingModel {
        return new PhongLightingModel(false); // (specular) -> force lambert
    }
}

// Note: Haxe does not have an equivalent to JavaScript's default export,
// so we have to define the class separately and then add it manually.
addNodeMaterial('MeshLambertNodeMaterial', MeshLambertNodeMaterial);