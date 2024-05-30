package three.js.examples.jvm.nodes.materials;

import NodeMaterial;
import PropertyNode;
import MathNode;
import MaterialNode;
import ShaderNode;

class MeshStandardNodeMaterial extends NodeMaterial {
  public var isMeshStandardNodeMaterial:Bool = true;

  public var emissiveNode:Null<Float> = null;
  public var metalnessNode:Null<Float> = null;
  public var roughnessNode:Null<Float> = null;

  public function new(?parameters:Dynamic) {
    super();
    setDefaultValues(new MeshStandardMaterial());
    setValues(parameters);
  }

  public function setupLightingModel(?builder:Dynamic):PhysicalLightingModel {
    return new PhysicalLightingModel();
  }

  public function setupSpecular():Void {
    var specularColorNode = MathNode.mix(Vector3.create(0.04), diffuseColor.rgb, metalness);
    specularColor.assign(specularColorNode);
    specularF90.assign(1.0);
  }

  public function setupVariants():Void {
    // METALNESS
    var metalnessNode:Float = if (this.metalnessNode != null) this.metalnessNode else materialMetalness;
    metalness.assign(metalnessNode);

    // ROUGHNESS
    var roughnessNode:Float = if (this.roughnessNode != null) this.roughnessNode else materialRoughness;
    roughnessNode = getRoughness({ roughness: roughnessNode });
    roughness.assign(roughnessNode);

    // SPECULAR COLOR
    setupSpecular();

    // DIFFUSE COLOR
    diffuseColor.assign(Vector4.create(diffuseColor.rgb.mul(metalnessNode.oneMinus()), diffuseColor.a));
  }

  public override function copy(source:MeshStandardNodeMaterial):MeshStandardNodeMaterial {
    emissiveNode = source.emissiveNode;
    metalnessNode = source.metalnessNode;
    roughnessNode = source.roughnessNode;
    return super.copy(source);
  }
}

addClass("MeshStandardNodeMaterial", MeshStandardNodeMaterial);