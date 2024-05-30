import three.examples.jsm.nodes.materials.MeshStandardNodeMaterial;
import three.examples.jsm.nodes.materials.NodeMaterial;
import three.examples.jsm.nodes.accessors.NormalNode;
import three.examples.jsm.nodes.core.PropertyNode;
import three.examples.jsm.nodes.accessors.MaterialNode;
import three.examples.jsm.nodes.shadernode.ShaderNode;
import three.examples.jsm.nodes.accessors.AccessorsUtils;
import three.examples.jsm.functions.PhysicalLightingModel;
import three.MeshPhysicalMaterial;

class MeshPhysicalNodeMaterial extends MeshStandardNodeMaterial {

  public var clearcoatNode:Null<Float> = null;
  public var clearcoatRoughnessNode:Null<Float> = null;
  public var clearcoatNormalNode:Null<Float> = null;

  public var sheenNode:Null<Float> = null;
  public var sheenRoughnessNode:Null<Float> = null;

  public var iridescenceNode:Null<Float> = null;
  public var iridescenceIORNode:Null<Float> = null;
  public var iridescenceThicknessNode:Null<Float> = null;

  public var specularIntensityNode:Null<Float> = null;
  public var specularColorNode:Null<Float> = null;

  public var iorNode:Null<Float> = null;
  public var transmissionNode:Null<Float> = null;
  public var thicknessNode:Null<Float> = null;
  public var attenuationDistanceNode:Null<Float> = null;
  public var attenuationColorNode:Null<Float> = null;

  public var anisotropyNode:Null<Float> = null;

  public function new(parameters:Dynamic) {
    super();

    this.isMeshPhysicalNodeMaterial = true;

    this.clearcoatNode = null;
    this.clearcoatRoughnessNode = null;
    this.clearcoatNormalNode = null;

    this.sheenNode = null;
    this.sheenRoughnessNode = null;

    this.iridescenceNode = null;
    this.iridescenceIORNode = null;
    this.iridescenceThicknessNode = null;

    this.specularIntensityNode = null;
    this.specularColorNode = null;

    this.iorNode = null;
    this.transmissionNode = null;
    this.thicknessNode = null;
    this.attenuationDistanceNode = null;
    this.attenuationColorNode = null;

    this.anisotropyNode = null;

    this.setDefaultValues(new MeshPhysicalMaterial());

    this.setValues(parameters);
  }

  public function get useClearcoat():Bool {
    return this.clearcoat > 0 || this.clearcoatNode != null;
  }

  public function get useIridescence():Bool {
    return this.iridescence > 0 || this.iridescenceNode != null;
  }

  public function get useSheen():Bool {
    return this.sheen > 0 || this.sheenNode != null;
  }

  public function get useAnisotropy():Bool {
    return this.anisotropy > 0 || this.anisotropyNode != null;
  }

  public function get useTransmission():Bool {
    return this.transmission > 0 || this.transmissionNode != null;
  }

  public function setupSpecular() {
    var iorNode = this.iorNode != null ? this.iorNode : MaterialNode.ior;

    PropertyNode.ior.assign(iorNode);
    PropertyNode.specularColor.assign(ShaderNode.mix(ShaderNode.min(ShaderNode.pow2(PropertyNode.ior.sub(1.0).div(PropertyNode.ior.add(1.0))).mul(PropertyNode.specularColor), ShaderNode.vec3(1.0)).mul(PropertyNode.specularIntensity), PropertyNode.diffuseColor.rgb, PropertyNode.metalness));
    PropertyNode.specularF90.assign(ShaderNode.mix(PropertyNode.specularIntensity, 1.0, PropertyNode.metalness));
  }

  public function setupLightingModel(builder:Dynamic):Dynamic {
    return new PhysicalLightingModel(this.useClearcoat, this.useSheen, this.useIridescence, this.useAnisotropy, this.useTransmission);
  }

  public function setupVariants(builder:Dynamic) {
    super.setupVariants(builder);

    // CLEARCOAT
    if (this.useClearcoat) {
      var clearcoatNode = this.clearcoatNode != null ? this.clearcoatNode : MaterialNode.clearcoat;
      var clearcoatRoughnessNode = this.clearcoatRoughnessNode != null ? this.clearcoatRoughnessNode : MaterialNode.clearcoatRoughness;

      PropertyNode.clearcoat.assign(clearcoatNode);
      PropertyNode.clearcoatRoughness.assign(clearcoatRoughnessNode);
    }

    // SHEEN
    if (this.useSheen) {
      var sheenNode = this.sheenNode != null ? this.sheenNode : MaterialNode.sheen;
      var sheenRoughnessNode = this.sheenRoughnessNode != null ? this.sheenRoughnessNode : MaterialNode.sheenRoughness;

      PropertyNode.sheen.assign(sheenNode);
      PropertyNode.sheenRoughness.assign(sheenRoughnessNode);
    }

    // IRIDESCENCE
    if (this.useIridescence) {
      var iridescenceNode = this.iridescenceNode != null ? this.iridescenceNode : MaterialNode.iridescence;
      var iridescenceIORNode = this.iridescenceIORNode != null ? this.iridescenceIORNode : MaterialNode.iridescenceIOR;
      var iridescenceThicknessNode = this.iridescenceThicknessNode != null ? this.iridescenceThicknessNode : MaterialNode.iridescenceThickness;

      PropertyNode.iridescence.assign(iridescenceNode);
      PropertyNode.iridescenceIOR.assign(iridescenceIORNode);
      PropertyNode.iridescenceThickness.assign(iridescenceThicknessNode);
    }

    // ANISOTROPY
    if (this.useAnisotropy) {
      var anisotropyV = (this.anisotropyNode != null ? this.anisotropyNode : MaterialNode.anisotropy).toVar();

      PropertyNode.anisotropy.assign(anisotropyV.length());

      ShaderNode.If(PropertyNode.anisotropy.equal(0.0), () -> {
        anisotropyV.assign(ShaderNode.vec2(1.0, 0.0));
      }).else(() -> {
        anisotropyV.divAssign(PropertyNode.anisotropy);
        PropertyNode.anisotropy.assign(PropertyNode.anisotropy.saturate());
      });

      // Roughness along the anisotropy bitangent is the material roughness, while the tangent roughness increases with anisotropy.
      PropertyNode.alphaT.assign(PropertyNode.anisotropy.pow2().mix(PropertyNode.roughness.pow2(), 1.0));

      PropertyNode.anisotropyT.assign(AccessorsUtils.TBNViewMatrix[0].mul(anisotropyV.x).add(AccessorsUtils.TBNViewMatrix[1].mul(anisotropyV.y)));
      PropertyNode.anisotropyB.assign(AccessorsUtils.TBNViewMatrix[1].mul(anisotropyV.x).sub(AccessorsUtils.TBNViewMatrix[0].mul(anisotropyV.y)));
    }

    // TRANSMISSION
    if (this.useTransmission) {
      var transmissionNode = this.transmissionNode != null ? this.transmissionNode : MaterialNode.transmission;
      var thicknessNode = this.thicknessNode != null ? this.thicknessNode : MaterialNode.thickness;
      var attenuationDistanceNode = this.attenuationDistanceNode != null ? this.attenuationDistanceNode : MaterialNode.attenuationDistance;
      var attenuationColorNode = this.attenuationColorNode != null ? this.attenuationColorNode : MaterialNode.attenuationColor;

      PropertyNode.transmission.assign(transmissionNode);
      PropertyNode.thickness.assign(thicknessNode);
      PropertyNode.attenuationDistance.assign(attenuationDistanceNode);
      PropertyNode.attenuationColor.assign(attenuationColorNode);
    }
  }

  public function setupNormal(builder:Dynamic) {
    super.setupNormal(builder);

    // CLEARCOAT NORMAL
    var clearcoatNormalNode = this.clearcoatNormalNode != null ? this.clearcoatNormalNode : MaterialNode.clearcoatNormal;

    NormalNode.transformedClearcoatNormalView.assign(clearcoatNormalNode);
  }

  public function copy(source:Dynamic):Dynamic {
    this.clearcoatNode = source.clearcoatNode;
    this.clearcoatRoughnessNode = source.clearcoatRoughnessNode;
    this.clearcoatNormalNode = source.clearcoatNormalNode;

    this.sheenNode = source.sheenNode;
    this.sheenRoughnessNode = source.sheenRoughnessNode;

    this.iridescenceNode = source.iridescenceNode;
    this.iridescenceIORNode = source.iridescenceIORNode;
    this.iridescenceThicknessNode = source.iridescenceThicknessNode;

    this.specularIntensityNode = source.specularIntensityNode;
    this.specularColorNode = source.specularColorNode;

    this.transmissionNode = source.transmissionNode;
    this.thicknessNode = source.thicknessNode;
    this.attenuationDistanceNode = source.attenuationDistanceNode;
    this.attenuationColorNode = source.attenuationColorNode;

    this.anisotropyNode = source.anisotropyNode;

    return super.copy(source);
  }
}

NodeMaterial.addNodeMaterial('MeshPhysicalNodeMaterial', MeshPhysicalNodeMaterial);