import three.materials.ShadowMaterial;
import three.materials.SpriteMaterial;
import three.materials.RawShaderMaterial;
import three.materials.ShaderMaterial;
import three.materials.PointsMaterial;
import three.materials.MeshPhysicalMaterial;
import three.materials.MeshStandardMaterial;
import three.materials.MeshPhongMaterial;
import three.materials.MeshToonMaterial;
import three.materials.MeshNormalMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.MeshDepthMaterial;
import three.materials.MeshDistanceMaterial;
import three.materials.MeshBasicMaterial;
import three.materials.MeshMatcapMaterial;
import three.materials.LineDashedMaterial;
import three.materials.LineBasicMaterial;
import three.materials.Material;

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



This code defines a class `Materials` which holds static variables for each material class, making them accessible through `Materials.MaterialName`. 

Here's what's done:

* **Imports:** We import all the material classes from the `three.materials` package.
* **Class `Materials`:** This class is created to organize all the materials.
* **Static Variables:** For each material class, a static variable is defined, giving it the same name as the class. This variable holds the class itself.

Now, you can use these materials like this:


var material = new Materials.MeshBasicMaterial();