import three.js.examples.jsm.nodes.materials.NodeMaterial;
import three.js.examples.jsm.accessors.NormalNode;
import three.js.examples.jsm.core.PropertyNode;
import three.js.examples.jsm.accessors.MaterialNode;
import three.js.examples.jsm.shadernode.ShaderNode;
import three.js.examples.jsm.accessors.AccessorsUtils;
import three.js.examples.jsm.functions.PhysicalLightingModel;
import three.js.examples.jsm.nodes.materials.MeshStandardNodeMaterial;
import three.js.examples.jsm.math.MathNode;
import three.js.MeshPhysicalMaterial;

var defaultValues = new MeshPhysicalMaterial();

class MeshPhysicalNodeMaterial extends MeshStandardNodeMaterial {

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

        this.setDefaultValues(defaultValues);

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
        var iorNode = this.iorNode ? ShaderNode.float(this.iorNode) : MaterialNode.materialIOR;

        PropertyNode.ior.assign(iorNode);
        PropertyNode.specularColor.assign(MathNode.mix(
            MathNode.min(MathNode.pow2(PropertyNode.ior.sub(1.0).div(PropertyNode.ior.add(1.0)))).mul(MaterialNode.materialSpecularColor),
            ShaderNode.vec3(1.0)
        ).mul(MaterialNode.materialSpecularIntensity), PropertyNode.diffuseColor.rgb, PropertyNode.metalness));
        PropertyNode.specularF90.assign(MathNode.mix(MaterialNode.materialSpecularIntensity, 1.0, PropertyNode.metalness));
    }

    public function setupLightingModel():PhysicalLightingModel {
        return new PhysicalLightingModel(this.useClearcoat, this.useSheen, this.useIridescence, this.useAnisotropy, this.useTransmission);
    }

    public function setupVariants(builder:Dynamic) {
        super.setupVariants(builder);

        // CLEARCOAT

        if (this.useClearcoat) {
            var clearcoatNode = this.clearcoatNode ? ShaderNode.float(this.clearcoatNode) : MaterialNode.materialClearcoat;
            var clearcoatRoughnessNode = this.clearcoatRoughnessNode ? ShaderNode.float(this.clearcoatRoughnessNode) : MaterialNode.materialClearcoatRoughness;

            PropertyNode.clearcoat.assign(clearcoatNode);
            PropertyNode.clearcoatRoughness.assign(clearcoatRoughnessNode);
        }

        // SHEEN

        if (this.useSheen) {
            var sheenNode = this.sheenNode ? ShaderNode.vec3(this.sheenNode) : MaterialNode.materialSheen;
            var sheenRoughnessNode = this.sheenRoughnessNode ? ShaderNode.float(this.sheenRoughnessNode) : MaterialNode.materialSheenRoughness;

            PropertyNode.sheen.assign(sheenNode);
            PropertyNode.sheenRoughness.assign(sheenRoughnessNode);
        }

        // IRIDESCENCE

        if (this.useIridescence) {
            var iridescenceNode = this.iridescenceNode ? ShaderNode.float(this.iridescenceNode) : MaterialNode.materialIridescence;
            var iridescenceIORNode = this.iridescenceIORNode ? ShaderNode.float(this.iridescenceIORNode) : MaterialNode.materialIridescenceIOR;
            var iridescenceThicknessNode = this.iridescenceThicknessNode ? ShaderNode.float(this.iridescenceThicknessNode) : MaterialNode.materialIridescenceThickness;

            PropertyNode.iridescence.assign(iridescenceNode);
            PropertyNode.iridescenceIOR.assign(iridescenceIORNode);
            PropertyNode.iridescenceThickness.assign(iridescenceThicknessNode);
        }

        // ANISOTROPY

        if (this.useAnisotropy) {
            var anisotropyV = (this.anisotropyNode ? ShaderNode.vec2(this.anisotropyNode) : MaterialNode.materialAnisotropy).toVar();

            PropertyNode.anisotropy.assign(anisotropyV.length());

            ShaderNode.If(PropertyNode.anisotropy.equal(0.0), () => {
                anisotropyV.assign(ShaderNode.vec2(1.0, 0.0));
            }).else(() => {
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
            var transmissionNode = this.transmissionNode ? ShaderNode.float(this.transmissionNode) : MaterialNode.materialTransmission;
            var thicknessNode = this.thicknessNode ? ShaderNode.float(this.thicknessNode) : MaterialNode.materialThickness;
            var attenuationDistanceNode = this.attenuationDistanceNode ? ShaderNode.float(this.attenuationDistanceNode) : MaterialNode.materialAttenuationDistance;
            var attenuationColorNode = this.attenuationColorNode ? ShaderNode.vec3(this.attenuationColorNode) : MaterialNode.materialAttenuationColor;

            PropertyNode.transmission.assign(transmissionNode);
            PropertyNode.thickness.assign(thicknessNode);
            PropertyNode.attenuationDistance.assign(attenuationDistanceNode);
            PropertyNode.attenuationColor.assign(attenuationColorNode);
        }
    }

    public function setupNormal(builder:Dynamic) {
        super.setupNormal(builder);

        // CLEARCOAT NORMAL

        var clearcoatNormalNode = this.clearcoatNormalNode ? ShaderNode.vec3(this.clearcoatNormalNode) : MaterialNode.materialClearcoatNormal;

        NormalNode.transformedClearcoatNormalView.assign(clearcoatNormalNode);
    }

    public function copy(source:MeshPhysicalNodeMaterial):MeshStandardNodeMaterial {
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

NodeMaterial.addNodeMaterial("MeshPhysicalNodeMaterial", MeshPhysicalNodeMaterial);