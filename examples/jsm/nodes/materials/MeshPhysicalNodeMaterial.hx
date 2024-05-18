package three.js.examples.jsm.nodes.materials;

import three.js.examples.jsm.nodes.NodeMaterial;
import three.js.examples.jsm.accessors.NormalNode;
import three.js.examples.jsm.core.PropertyNode;
import three.js.examples.jsm.accessors.MaterialNode;
import three.js.examples.jsm.shadernode.ShaderNode;
import three.js.examples.jsm.accessors.AccessorsUtils;
import three.js.examples.jsm.functions.PhysicalLightingModel;
import three.js.examples.jsm.nodes.MeshStandardNodeMaterial;
import three.js.examples.jsm.math.MathNode;
import three.js.MeshPhysicalMaterial;

class MeshPhysicalNodeMaterial extends MeshStandardNodeMaterial {

    public var clearcoatNode:Float;
    public var clearcoatRoughnessNode:Float;
    public var clearcoatNormalNode:Vec3;

    public var sheenNode:Vec3;
    public var sheenRoughnessNode:Float;

    public var iridescenceNode:Float;
    public var iridescenceIORNode:Float;
    public var iridescenceThicknessNode:Float;

    public var specularIntensityNode:Float;
    public var specularColorNode:Vec3;

    public var iorNode:Float;
    public var transmissionNode:Float;
    public var thicknessNode:Float;
    public var attenuationDistanceNode:Float;
    public var attenuationColorNode:Vec3;

    public var anisotropyNode:Vec2;

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

        var defaultValues:MeshPhysicalMaterial = new MeshPhysicalMaterial();

        this.setDefaultValues(defaultValues);

        this.setValues(parameters);
    }

    public function get_useClearcoat():Bool {
        return this.clearcoat > 0 || this.clearcoatNode != null;
    }

    public function get_useIridescence():Bool {
        return this.iridescence > 0 || this.iridescenceNode != null;
    }

    public function get_useSheen():Bool {
        return this.sheen > 0 || this.sheenNode != null;
    }

    public function get_useAnisotropy():Bool {
        return this.anisotropy > 0 || this.anisotropyNode != null;
    }

    public function get_useTransmission():Bool {
        return this.transmission > 0 || this.transmissionNode != null;
    }

    public function setupSpecular() {
        var iorNode:Float = this.iorNode != null ? float(this.iorNode) : materialIOR;
        ior.assign(iorNode);
        specularColor.assign(mix(min(pow2(ior.sub(1.0).div(ior.add(1.0))).mul(materialSpecularColor), vec3(1.0)).mul(materialSpecularIntensity), diffuseColor.rgb, metalness));
        specularF90.assign(mix(materialSpecularIntensity, 1.0, metalness));
    }

    public function setupLightingModel(builder:Dynamic) {
        return new PhysicalLightingModel(this.useClearcoat, this.useSheen, this.useIridescence, this.useAnisotropy, this.useTransmission);
    }

    public function setupVariants(builder:Dynamic) {
        super.setupVariants(builder);

        // CLEARCOAT
        if (this.useClearcoat) {
            var clearcoatNode:Float = this.clearcoatNode != null ? float(this.clearcoatNode) : materialClearcoat;
            var clearcoatRoughnessNode:Float = this.clearcoatRoughnessNode != null ? float(this.clearcoatRoughnessNode) : materialClearcoatRoughness;
            clearcoat.assign(clearcoatNode);
            clearcoatRoughness.assign(clearcoatRoughnessNode);
        }

        // SHEEN
        if (this.useSheen) {
            var sheenNode:Vec3 = this.sheenNode != null ? vec3(this.sheenNode) : materialSheen;
            var sheenRoughnessNode:Float = this.sheenRoughnessNode != null ? float(this.sheenRoughnessNode) : materialSheenRoughness;
            sheen.assign(sheenNode);
            sheenRoughness.assign(sheenRoughnessNode);
        }

        // IRIDESCENCE
        if (this.useIridescence) {
            var iridescenceNode:Float = this.iridescenceNode != null ? float(this.iridescenceNode) : materialIridescence;
            var iridescenceIORNode:Float = this.iridescenceIORNode != null ? float(this.iridescenceIORNode) : materialIridescenceIOR;
            var iridescenceThicknessNode:Float = this.iridescenceThicknessNode != null ? float(this.iridescenceThicknessNode) : materialIridescenceThickness;
            iridescence.assign(iridescenceNode);
            iridescenceIOR.assign(iridescenceIORNode);
            iridescenceThickness.assign(iridescenceThicknessNode);
        }

        // ANISOTROPY
        if (this.useAnisotropy) {
            var anisotropyV:Vec2 = (this.anisotropyNode != null ? vec2(this.anisotropyNode) : materialAnisotropy).toVar();
            anisotropy.assign(anisotropyV.length());
            If(anisotropy.equal(0.0), () => {
                anisotropyV.assign(vec2(1.0, 0.0));
            }).else(() => {
                anisotropyV.divAssign(anisotropy);
                anisotropy.assign(anisotropy.saturate());
            });
            alphaT.assign(anisotropy.pow2().mix(roughness.pow2(), 1.0));
            anisotropyT.assign(TBNViewMatrix[0].mul(anisotropyV.x).add(TBNViewMatrix[1].mul(anisotropyV.y)));
            anisotropyB.assign(TBNViewMatrix[1].mul(anisotropyV.x).sub(TBNViewMatrix[0].mul(anisotropyV.y)));
        }

        // TRANSMISSION
        if (this.useTransmission) {
            var transmissionNode:Float = this.transmissionNode != null ? float(this.transmissionNode) : materialTransmission;
            var thicknessNode:Float = this.thicknessNode != null ? float(this.thicknessNode) : materialThickness;
            var attenuationDistanceNode:Float = this.attenuationDistanceNode != null ? float(this.attenuationDistanceNode) : materialAttenuationDistance;
            var attenuationColorNode:Vec3 = this.attenuationColorNode != null ? vec3(this.attenuationColorNode) : materialAttenuationColor;
            transmission.assign(transmissionNode);
            thickness.assign(thicknessNode);
            attenuationDistance.assign(attenuationDistanceNode);
            attenuationColor.assign(attenuationColorNode);
        }
    }

    public function setupNormal(builder:Dynamic) {
        super.setupNormal(builder);
        // CLEARCOAT NORMAL
        var clearcoatNormalNode:Vec3 = this.clearcoatNormalNode != null ? vec3(this.clearcoatNormalNode) : materialClearcoatNormal;
        transformedClearcoatNormalView.assign(clearcoatNormalNode);
    }

    public function copy(source:MeshPhysicalNodeMaterial) {
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