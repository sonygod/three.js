package three.js.examples.jsm.nodes.materials;

import three.js.examples.jsm.nodes.materials.NodeMaterial;
import three.js.examples.jsm.accessors.NormalNode;
import three.js.examples.jsm.core.PropertyNode;
import three.js.examples.jsm.accessors.MaterialNode;
import three.js.examples.jsm.shadernode.ShaderNode;
import three.js.examples.jsm.accessors.AccessorsUtils;
import three.js.examples.jsm.functions.PhysicalLightingModel;
import three.js.examples.jsm.nodes.materials.MeshStandardNodeMaterial;
import three.js.examples.jsm.math.MathNode;
import three.MeshPhysicalMaterial;

class MeshPhysicalNodeMaterial extends MeshStandardNodeMaterial {
    public static var defaultValues = new MeshPhysicalMaterial();

    public var clearcoatNode:Null<FloatNode>;
    public var clearcoatRoughnessNode:Null<FloatNode>;
    public var clearcoatNormalNode:Null<Vec3Node>;

    public var sheenNode:Null<Vec3Node>;
    public var sheenRoughnessNode:Null<FloatNode>;

    public var iridescenceNode:Null<FloatNode>;
    public var iridescenceIORNode:Null<FloatNode>;
    public var iridescenceThicknessNode:Null<FloatNode>;

    public var specularIntensityNode:Null<FloatNode>;
    public var specularColorNode:Null<Vec3Node>;

    public var iorNode:Null<FloatNode>;
    public var transmissionNode:Null<FloatNode>;
    public var thicknessNode:Null<FloatNode>;
    public var attenuationDistanceNode:Null<FloatNode>;
    public var attenuationColorNode:Null<Vec3Node>;

    public var anisotropyNode:Null<Vec2Node>;

    public function new(parameters:Dynamic = null) {
        super();
        this.isMeshPhysicalNodeMaterial = true;

        this.setDefaultValues(defaultValues);
        this.setValues(parameters);
    }

    public var useClearcoat(get, never):Bool;
    inline function get_useClearcoat() return this.clearcoat > 0 || this.clearcoatNode !== null;

    public var useIridescence(get, never):Bool;
    inline function get_useIridescence() return this.iridescence > 0 || this.iridescenceNode !== null;

    public var useSheen(get, never):Bool;
    inline function get_useSheen() return this.sheen > 0 || this.sheenNode !== null;

    public var useAnisotropy(get, never):Bool;
    inline function get_useAnisotropy() return this.anisotropy > 0 || this.anisotropyNode !== null;

    public var useTransmission(get, never):Bool;
    inline function get_useTransmission() return this.transmission > 0 || this.transmissionNode !== null;

    public function setupSpecular() {
        var iorNode = this.iorNode != null ? this.iorNode : materialIOR;
        ior.assign(iorNode);
        specularColor.assign(mix(min(pow2(ior.sub(1.0).div(ior.add(1.0))).mul(materialSpecularColor), vec3(1.0)).mul(materialSpecularIntensity), diffuseColor.rgb, metalness));
        specularF90.assign(mix(materialSpecularIntensity, 1.0, metalness));
    }

    public function setupLightingModel(builder:Dynamic) {
        return new PhysicalLightingModel(this.useClearcoat, this.useSheen, this.useIridescence, this.useAnisotropy, this.useTransmission);
    }

    public override function setupVariants(builder:Dynamic) {
        super.setupVariants(builder);

        if (this.useClearcoat) {
            var clearcoatNode = this.clearcoatNode != null ? this.clearcoatNode : materialClearcoat;
            var clearcoatRoughnessNode = this.clearcoatRoughnessNode != null ? this.clearcoatRoughnessNode : materialClearcoatRoughness;
            clearcoat.assign(clearcoatNode);
            clearcoatRoughness.assign(clearcoatRoughnessNode);
        }

        // SHEEN
        if (this.useSheen) {
            var sheenNode = this.sheenNode != null ? this.sheenNode : materialSheen;
            var sheenRoughnessNode = this.sheenRoughnessNode != null ? this.sheenRoughnessNode : materialSheenRoughness;
            sheen.assign(sheenNode);
            sheenRoughness.assign(sheenRoughnessNode);
        }

        // IRIDESCENCE
        if (this.useIridescence) {
            var iridescenceNode = this.iridescenceNode != null ? this.iridescenceNode : materialIridescence;
            var iridescenceIORNode = this.iridescenceIORNode != null ? this.iridescenceIORNode : materialIridescenceIOR;
            var iridescenceThicknessNode = this.iridescenceThicknessNode != null ? this.iridescenceThicknessNode : materialIridescenceThickness;
            iridescence.assign(iridescenceNode);
            iridescenceIOR.assign(iridescenceIORNode);
            iridescenceThickness.assign(iridescenceThicknessNode);
        }

        // ANISOTROPY
        if (this.useAnisotropy) {
            var anisotropyV = (this.anisotropyNode != null ? this.anisotropyNode : materialAnisotropy).toVar();
            anisotropy.assign(anisotropyV.length());

            If(anisotropy.equal(0.0), () => {
                anisotropyV.assign(vec2(1.0, 0.0));
            }).Else(() => {
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
            var transmissionNode = this.transmissionNode != null ? this.transmissionNode : materialTransmission;
            var thicknessNode = this.thicknessNode != null ? this.thicknessNode : materialThickness;
            var attenuationDistanceNode = this.attenuationDistanceNode != null ? this.attenuationDistanceNode : materialAttenuationDistance;
            var attenuationColorNode = this.attenuationColorNode != null ? this.attenuationColorNode : materialAttenuationColor;

            transmission.assign(transmissionNode);
            thickness.assign(thicknessNode);
            attenuationDistance.assign(attenuationDistanceNode);
            attenuationColor.assign(attenuationColorNode);
        }
    }

    override public function setupNormal(builder:Dynamic) {
        super.setupNormal(builder);

        // CLEARCOAT NORMAL
        var clearcoatNormalNode = this.clearcoatNormalNode != null ? this.clearcoatNormalNode : materialClearcoatNormal;
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

addNodeMaterial('MeshPhysicalNodeMaterial', MeshPhysicalNodeMaterial);