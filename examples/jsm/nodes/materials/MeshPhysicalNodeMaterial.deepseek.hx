package three.js.examples.jsm.nodes.materials;

import three.js.examples.jsm.nodes.accessors.NormalNode;
import three.js.examples.jsm.nodes.core.PropertyNode;
import three.js.examples.jsm.nodes.accessors.MaterialNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.accessors.AccessorsUtils;
import three.js.examples.jsm.nodes.functions.PhysicalLightingModel;
import three.js.examples.jsm.nodes.math.MathNode;
import three.js.MeshPhysicalMaterial;

class MeshPhysicalNodeMaterial extends MeshStandardNodeMaterial {

    public var clearcoatNode:Float = null;
    public var clearcoatRoughnessNode:Float = null;
    public var clearcoatNormalNode:Vec3 = null;

    public var sheenNode:Vec3 = null;
    public var sheenRoughnessNode:Float = null;

    public var iridescenceNode:Float = null;
    public var iridescenceIORNode:Float = null;
    public var iridescenceThicknessNode:Float = null;

    public var specularIntensityNode:Float = null;
    public var specularColorNode:Vec3 = null;

    public var iorNode:Float = null;
    public var transmissionNode:Float = null;
    public var thicknessNode:Float = null;
    public var attenuationDistanceNode:Float = null;
    public var attenuationColorNode:Vec3 = null;

    public var anisotropyNode:Vec2 = null;

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
        return this.clearcoat > 0 || this.clearcoatNode !== null;
    }

    public function get useIridescence():Bool {
        return this.iridescence > 0 || this.iridescenceNode !== null;
    }

    public function get useSheen():Bool {
        return this.sheen > 0 || this.sheenNode !== null;
    }

    public function get useAnisotropy():Bool {
        return this.anisotropy > 0 || this.anisotropyNode !== null;
    }

    public function get useTransmission():Bool {
        return this.transmission > 0 || this.transmissionNode !== null;
    }

    public function setupSpecular() {
        var iorNode = this.iorNode ? float(this.iorNode) : materialIOR;

        ior.assign(iorNode);
        specularColor.assign(mix(min(pow2(ior.sub(1.0).div(ior.add(1.0))).mul(materialSpecularColor), vec3(1.0)).mul(materialSpecularIntensity), diffuseColor.rgb, metalness));
        specularF90.assign(mix(materialSpecularIntensity, 1.0, metalness));
    }

    public function setupLightingModel():PhysicalLightingModel {
        return new PhysicalLightingModel(this.useClearcoat, this.useSheen, this.useIridescence, this.useAnisotropy, this.useTransmission);
    }

    public function setupVariants(builder:Dynamic) {
        super.setupVariants(builder);

        // CLEARCOAT
        if (this.useClearcoat) {
            var clearcoatNode = this.clearcoatNode ? float(this.clearcoatNode) : materialClearcoat;
            var clearcoatRoughnessNode = this.clearcoatRoughnessNode ? float(this.clearcoatRoughnessNode) : materialClearcoatRoughness;

            clearcoat.assign(clearcoatNode);
            clearcoatRoughness.assign(clearcoatRoughnessNode);
        }

        // SHEEN
        if (this.useSheen) {
            var sheenNode = this.sheenNode ? vec3(this.sheenNode) : materialSheen;
            var sheenRoughnessNode = this.sheenRoughnessNode ? float(this.sheenRoughnessNode) : materialSheenRoughness;

            sheen.assign(sheenNode);
            sheenRoughness.assign(sheenRoughnessNode);
        }

        // IRIDESCENCE
        if (this.useIridescence) {
            var iridescenceNode = this.iridescenceNode ? float(this.iridescenceNode) : materialIridescence;
            var iridescenceIORNode = this.iridescenceIORNode ? float(this.iridescenceIORNode) : materialIridescenceIOR;
            var iridescenceThicknessNode = this.iridescenceThicknessNode ? float(this.iridescenceThicknessNode) : materialIridescenceThickness;

            iridescence.assign(iridescenceNode);
            iridescenceIOR.assign(iridescenceIORNode);
            iridescenceThickness.assign(iridescenceThicknessNode);
        }

        // ANISOTROPY
        if (this.useAnisotropy) {
            var anisotropyV = (this.anisotropyNode ? vec2(this.anisotropyNode) : materialAnisotropy).toVar();

            anisotropy.assign(anisotropyV.length());

            If(anisotropy.equal(0.0), () -> {
                anisotropyV.assign(vec2(1.0, 0.0));
            }).else(() -> {
                anisotropyV.divAssign(anisotropy);
                anisotropy.assign(anisotropy.saturate());
            });

            // Roughness along the anisotropy bitangent is the material roughness, while the tangent roughness increases with anisotropy.
            alphaT.assign(anisotropy.pow2().mix(roughness.pow2(), 1.0));

            anisotropyT.assign(TBNViewMatrix[0].mul(anisotropyV.x).add(TBNViewMatrix[1].mul(anisotropyV.y)));
            anisotropyB.assign(TBNViewMatrix[1].mul(anisotropyV.x).sub(TBNViewMatrix[0].mul(anisotropyV.y)));
        }

        // TRANSMISSION
        if (this.useTransmission) {
            var transmissionNode = this.transmissionNode ? float(this.transmissionNode) : materialTransmission;
            var thicknessNode = this.thicknessNode ? float(this.thicknessNode) : materialThickness;
            var attenuationDistanceNode = this.attenuationDistanceNode ? float(this.attenuationDistanceNode) : materialAttenuationDistance;
            var attenuationColorNode = this.attenuationColorNode ? vec3(this.attenuationColorNode) : materialAttenuationColor;

            transmission.assign(transmissionNode);
            thickness.assign(thicknessNode);
            attenuationDistance.assign(attenuationDistanceNode);
            attenuationColor.assign(attenuationColorNode);
        }
    }

    public function setupNormal(builder:Dynamic) {
        super.setupNormal(builder);

        // CLEARCOAT NORMAL
        var clearcoatNormalNode = this.clearcoatNormalNode ? vec3(this.clearcoatNormalNode) : materialClearcoatNormal;

        transformedClearcoatNormalView.assign(clearcoatNormalNode);
    }

    public function copy(source:MeshPhysicalNodeMaterial):MeshPhysicalNodeMaterial {
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

addNodeMaterial('MeshPhysicalNodeMaterial', MeshPhysicalNodeMaterial);