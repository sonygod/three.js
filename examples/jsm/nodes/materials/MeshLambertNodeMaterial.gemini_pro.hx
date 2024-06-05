import NodeMaterial from "./NodeMaterial";
import PhongLightingModel from "../functions/PhongLightingModel";
import three.materials.MeshLambertMaterial;

class MeshLambertNodeMaterial extends NodeMaterial {

	public var isMeshLambertNodeMaterial:Bool = true;
	public var lights:Bool = true;

	public function new(parameters:Dynamic = null) {
		super();

		this.setDefaultValues(new MeshLambertMaterial());
		this.setValues(parameters);
	}

	override function setupLightingModel(/*builder*/):PhongLightingModel {
		return new PhongLightingModel(false); // ( specular ) -> force lambert
	}
}

// Add to NodeMaterial registry
NodeMaterial.addNodeMaterial("MeshLambertNodeMaterial", MeshLambertNodeMaterial);