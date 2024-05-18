package three.js.examples.jsm.objects;

import three.Mesh;
import three.geometries.InstancedPointsGeometry;
import three.nodes.materials.InstancedPointsNodeMaterial;

class InstancedPoints extends Mesh {

    public var isInstancedPoints:Bool = true;

    public var type:String = 'InstancedPoints';

    public function new(?geometry:InstancedPointsGeometry = new InstancedPointsGeometry(), ?material:InstancedPointsNodeMaterial = new InstancedPointsNodeMaterial()) {
        super(geometry, material);
    }

}