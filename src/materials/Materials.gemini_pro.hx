import ShadowMaterial from "ShadowMaterial";
import SpriteMaterial from "SpriteMaterial";
import RawShaderMaterial from "RawShaderMaterial";
import ShaderMaterial from "ShaderMaterial";
import PointsMaterial from "PointsMaterial";
import MeshPhysicalMaterial from "MeshPhysicalMaterial";
import MeshStandardMaterial from "MeshStandardMaterial";
import MeshPhongMaterial from "MeshPhongMaterial";
import MeshToonMaterial from "MeshToonMaterial";
import MeshNormalMaterial from "MeshNormalMaterial";
import MeshLambertMaterial from "MeshLambertMaterial";
import MeshDepthMaterial from "MeshDepthMaterial";
import MeshDistanceMaterial from "MeshDistanceMaterial";
import MeshBasicMaterial from "MeshBasicMaterial";
import MeshMatcapMaterial from "MeshMatcapMaterial";
import LineDashedMaterial from "LineDashedMaterial";
import LineBasicMaterial from "LineBasicMaterial";
import Material from "Material";

class Materials {
	public static var ShadowMaterial:Class<ShadowMaterial> = ShadowMaterial;
	public static var SpriteMaterial:Class<SpriteMaterial> = SpriteMaterial;
	public static var RawShaderMaterial:Class<RawShaderMaterial> = RawShaderMaterial;
	public static var ShaderMaterial:Class<ShaderMaterial> = ShaderMaterial;
	public static var PointsMaterial:Class<PointsMaterial> = PointsMaterial;
	public static var MeshPhysicalMaterial:Class<MeshPhysicalMaterial> = MeshPhysicalMaterial;
	public static var MeshStandardMaterial:Class<MeshStandardMaterial> = MeshStandardMaterial;
	public static var MeshPhongMaterial:Class<MeshPhongMaterial> = MeshPhongMaterial;
	public static var MeshToonMaterial:Class<MeshToonMaterial> = MeshToonMaterial;
	public static var MeshNormalMaterial:Class<MeshNormalMaterial> = MeshNormalMaterial;
	public static var MeshLambertMaterial:Class<MeshLambertMaterial> = MeshLambertMaterial;
	public static var MeshDepthMaterial:Class<MeshDepthMaterial> = MeshDepthMaterial;
	public static var MeshDistanceMaterial:Class<MeshDistanceMaterial> = MeshDistanceMaterial;
	public static var MeshBasicMaterial:Class<MeshBasicMaterial> = MeshBasicMaterial;
	public static var MeshMatcapMaterial:Class<MeshMatcapMaterial> = MeshMatcapMaterial;
	public static var LineDashedMaterial:Class<LineDashedMaterial> = LineDashedMaterial;
	public static var LineBasicMaterial:Class<LineBasicMaterial> = LineBasicMaterial;
	public static var Material:Class<Material> = Material;
}

export {Materials};


**Explanation:**

* **Haxe imports:** Instead of `import { ... } from './...';`, we use `import ... from "..."`, assuming that you have your material classes defined in separate files within your Haxe project.
* **Static properties:** We create a class `Materials` with static properties for each material class. This provides a central point of access for all the materials.
* **Class references:** We use `Class<T>` to store the class references, which is the recommended way in Haxe for working with classes.
* **Exporting:** We export the `Materials` class so that you can access the material classes through it.

**How to use:**


import Materials from "Materials";

var material:MeshBasicMaterial = new Materials.MeshBasicMaterial();