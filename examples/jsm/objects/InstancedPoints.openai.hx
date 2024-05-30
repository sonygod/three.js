package three.objects;

import three.core.Mesh;
import three.geometries.InstancedPointsGeometry;
import three.nodes.materials.InstancedPointsNodeMaterial;

class InstancedPoints extends Mesh {

	public function new(?geometry:InstancedPointsGeometry = new InstancedPointsGeometry(), ?material:InstancedPointsNodeMaterial = new InstancedPointsNodeMaterial()) {
		super(geometry, material);

		this.isInstancedPoints = true;
		this.type = 'InstancedPoints';
	}

}

@if (haxe_ver < 4) @:native('-three.InstancedPoints') @end
extern class InstancedPoints {}