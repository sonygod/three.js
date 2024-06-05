import NodeMaterial from "./NodeMaterial";
import ToonLightingModel from "../functions/ToonLightingModel";
import MeshToonMaterial from "three/materials/MeshToonMaterial";

class MeshToonNodeMaterial extends NodeMaterial {

	public var isMeshToonNodeMaterial:Bool = true;
	public var lights:Bool = true;

	public function new(parameters:Dynamic) {
		super();
		this.setDefaultValues(cast MeshToonMaterial.fromValue(defaultValues));
		this.setValues(parameters);
	}

	override public function setupLightingModel(builder:Dynamic):ToonLightingModel {
		return new ToonLightingModel();
	}

}

class DefaultValues {
	public static var value:MeshToonMaterial = new MeshToonMaterial();
}

var defaultValues = DefaultValues.value;

addNodeMaterial("MeshToonNodeMaterial", MeshToonNodeMaterial);