import NodeMaterial from './NodeMaterial';
import NodeMaterialExt from './NodeMaterialExt';
import three from 'three';

class LineBasicNodeMaterial extends NodeMaterial {

    public function new(parameters:Dynamic) {

        super();

        this.isLineBasicNodeMaterial = true;

        this.lights = false;
        this.normals = false;

        var defaultValues = new three.LineBasicMaterial();
        this.setDefaultValues(defaultValues);

        this.setValues(parameters);

    }

}

NodeMaterialExt.addNodeMaterial('LineBasicNodeMaterial', LineBasicNodeMaterial);