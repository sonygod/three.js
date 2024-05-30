import haxe.ds.StringMap;

import js.Node;
import js.NodeMaterial;
import js.accessor.NormalNode;
import js.core.PropertyNode;
import js.accessor.MaterialNode;
import js.shadernode.ShaderNode;
import js.accessors.AccessorsUtils;
import js.functions.PhysicalLightingModel;
import js.MeshStandardNodeMaterial;
import js.math.MathNode;
import js.MeshPhysicalMaterial;

class MeshPhysicalNodeMaterial extends MeshStandardNodeMaterial {
    public var isMeshPhysicalNodeMaterial:Bool;
    public var clearcoatNode:Node;
    public var clearcoatRoughnessNode:Node;
    public var clearcoatNormalNode:Node;
    public var sheenNode:Node;
    public var sheenRoughnessNode:Node;
    public var iridescenceNode:Node;
    public var iridescenceIORNode:Node;
    public var iridescenceThicknessNode:Node;
    public var specularIntensityNode:Node;
    public var specularColorNode:Node;
    public var iorNode:Node;
    public var transmissionNode:Node;
    public var thicknessNode:Node;
    public var attenuationDistanceNode:Node;
    public var attenuationColorNode:Node;
    public var anisotropyNode:Node;

    public function new(parameters:Dynamic) {
        super();
        isMeshPhysicalNodeMaterial = true;
        setDefaultValues(defaultValues);
        setValues(parameters);
    }

    public function setupSpecular() {
        var iorNode = iorNode != null ? ShaderNode.float(iorNode) : MaterialNode.materialIOR;
        ior.assign(iorNode);
        specularColor.assign(MathNode.mix(MathNode.min(MathNode.pow2(ior.sub(1.0).div(ior.add(1.0)))).mul(MaterialNode.materialSpecularColor)).mul(MaterialNode.materialSpecularIntensity).rgb, diffuseColor, metalness));
        specularF90.assign(MathNode.mix(MaterialNode.materialSpecularIntensity, 1.0, metalness));
    }

    public function setupLightingModel(builder:Dynamic) {
        return new PhysicalLightingModel(useClearcoat, useSheen, useIridescence, useAnisotropy, useTransmission);
    }

    public function setupVariants(builder:Dynamic) {
        super.setupVariants(builder);
        if (useClearcoat) {
            var clearcoatNode = clearcoatNode != null ? ShaderNode.float(clearcoatNode) : MaterialNode.materialClearcoat;
            var clearcoatRoughnessNode = clearcoatRoughnessNode != null ? ShaderNode.float(clearcoatRoughnessNode) : MaterialNode.materialClearcoatRoughness;
            clearcoat.assign(clearcoatNode);
            clearcoatRoughness.assign(clearcoatRoughnessNode);
        }
        if (useSheen) {
            var sheenNode = sheenNode != null ? ShaderNode.vec3(sheenNode) : MaterialNode.materialSheen;
            var sheenRoughnessNode = sheenRoughnessNode != null ? ShaderNode.float(sheenRoughnessNode) : MaterialNode.materialSheenRoughness;
            sheen.assign(sheenNode);
            sheenRoughness.assign(sheenRoughnessNode);
        }
        if (useIridescence) {
            var iridescenceNode = iridescenceNode != null ? ShaderNode.float(iridescenceNode) : MaterialNode.materialIridescence;
            var iridescenceIORNode = iridescenceIORNode != null ? ShaderNode.float(iridescenceIORNode) : MaterialNode.materialIridescenceIOR;
            var iridescenceThicknessNode = iridescenceThicknessNode != null ? ShaderNode.float(iridescenceThicknessNode) : MaterialNode.materialIridescenceThickness;
            iridescence.assign(iridescenceNode);
            iridescenceIOR.assign(iridescenceIORNode);
            iridescenceThickness.assign(iridescenceThicknessNode);
        }
        if (useAnisotropy) {
            var anisotropyV = (anisotropyNode != null ? ShaderNode.vec2(anisotropyNode) : MaterialNode.materialAnisotropy).toVar();
            anisotropy.assign(anisotropyV.length());
            if (anisotropy.equal(0.0)) {
                anisotropyV.assign(ShaderNode.vec2(1.0, 0.0));
            } else {
                anisotropyV.divAssign(anisotropy);
                anisotropy.assign(anisotropy.saturate());
            }
            alphaT.assign(MathNode.pow2(anisotropy).mix(MathNode.pow2(roughness), 1.0));
            anisotropyT.assign(AccessorsUtils.TBNViewMatrix[0].mul(anisotropyV.x).add(AccessorsUtils.TBNViewMatrix[1].mul(anisotropyV.y)));
            anisotropyB.assign(AccessorsUtils.TBNViewMatrix[1].mul(anisotropyV.x).sub(AccessorsUtils.TBNViewMatrix[0].mul(anisotropyV.y)));
        }
        if (useTransmission) {
            var transmissionNode = transmissionNode != null ? ShaderNode.float(transmissionNode) : MaterialNode.materialTransmission;
            var thicknessNode = thicknessNode != null ? ShaderNode.float(thicknessNode) : MaterialNode.materialThickness;
            var attenuationDistanceNode = attenuationDistanceNode != null ? ShaderNode.float(attenuationDistanceNode) : MaterialNode.materialAttenuationDistance;
            var attenuationColorNode = attenuationColorNode != null ? ShaderNode.vec3(attenuationColorNode) : MaterialNode.materialAttenuationColor;
            transmission.assign(transmissionNode);
            thickness.assign(thicknessNode);
            attenuationDistance.assign(attenuationDistanceNode);
            attenuationColor.assign(attenuationColorNode);
        }
    }

    public function setupNormal(builder:Dynamic) {
        super.setupNormal(builder);
        var clearcoatNormalNode = clearcoatNormalNode != null ? ShaderNode.vec3(clearcoatNormalNode) : MaterialNode.materialClearcoatNormal;
        transformedClearcoatNormalView.assign(clearcoatNormalNode);
    }

    public function copy(source:MeshPhysicalNodeMaterial) {
        clearcoatNode = source.clearcoatNode;
        clearcoatRoughnessNode = source.clearcoatRoughnessNode;
        clearcoatNormalNode = source.clearcoatNormalNode;
        sheenNode = source.sheenNode;
        sheenRoughnessNode = source.sheenRoughnessNode;
        iridescenceNode = source.iridescenceNode;
        iridescenceIORNode = source.iridescenceIORNode;
        iridescenceThicknessNode = source.iridescenceThicknessNode;
        specularIntensityNode = source.specularIntensityNode;
        specularColorNode = source.specularColorNode;
        transmissionNode = source.transmissionNode;
        thicknessNode = source.thicknessNode;
        attenuationDistanceNode = source.attenuationDistanceNode;
        attenuationColorNode = source.attenuationColorNode;
        anisotropyNode = source.anisotropyNode;
        return super.copy(source);
    }

    public function get_useClearcoat():Bool {
        return clearcoat > 0 || clearcoatNode != null;
    }

    public function get_useIridescence():Bool {
        return iridescence > 0 || iridescenceNode != null;
    }

    public function get_useSheen():Bool {
        return sheen > 0 || sheenNode != null;
    }

    public function get_useAnisotropy():Bool {
        return anisotropy > 0 || anisotropyNode != null;
    }

    public function get_useTransmission():Bool {
        return transmission > 0 || transmissionNode != null;
    }
}

function defaultValues():MeshPhysicalMaterial {
    return new MeshPhysicalMaterial();
}

static function addNodeMaterial(name:String, material:MeshPhysicalNodeMaterial) {
    NodeMaterial.addNodeMaterial(name, material);
}

static var clearcoat:Float = PropertyNode.clearcoat;
static var clearcoatRoughness:Float = PropertyNode.clearcoatRoughness;
static var sheen:Float = PropertyNode.sheen;
static var sheenRoughness:Float = PropertyNode.sheenRoughness;
static var iridescence:Float = PropertyNode.iridescence;
static var iridescenceIOR:Float = PropertyNode.iridescenceIOR;
static var iridescenceThickness:Float = PropertyNode.iridescenceThickness;
static var specularIntensity:Float = PropertyNode.specularIntensity;
static var specularColor:Float = PropertyNode.specularColor;
static var metalness:Float = PropertyNode.metalness;
static var roughness:Float = PropertyNode.roughness;
static var anisotropy:Float = PropertyNode.anisotropy;
static var alphaT:Float = PropertyNode.alphaT;
static var anisotropyT:Float = PropertyNode.anisotropyT;
static var anisotropyB:Float = PropertyNode.anisotropyB;
static var ior:Float = PropertyNode.ior;
static var transmission:Float = PropertyNode.transmission;
static var thickness:Float = PropertyNode.thickness;
static var attenuationDistance:Float = PropertyNode.attenuationDistance;
static var attenuationColor:Float = PropertyNode.attenuationColor;
static var transformedClearcoatNormalView:Float = NormalNode.transformedClearcoatNormalView;
static var materialClearcoat:Float = MaterialNode.materialClearcoat;
static var materialClearcoatRoughness:Float = MaterialNode.materialClearcoatRoughness;
static var materialSheen:Float = MaterialNode.materialSheen;
static var materialSheenRoughness:Float = MaterialNode.materialSheenRoughness;
static var materialIridescence:Float = MaterialNode.materialIridescence;
static var materialIridescenceIOR:Float = MaterialNode.materialIridescenceIOR;
static var materialIridescenceThickness:Float = MaterialNode.materialIridescenceThickness;
static var materialSpecularIntensity:Float = MaterialNode.materialSpecularIntensity;
static var materialSpecularColor:Float = MaterialNode.materialSpecularColor;
static var materialAnisotropy:Float = MaterialNode.materialAnisotropy;
static var materialIOR:Float = MaterialNode.materialIOR;
static var materialTransmission:Float = MaterialNode.materialTransmission;
static var materialThickness:Float = MaterialNode.materialThickness;
static var materialAttenuationDistance:Float = MaterialNode.materialAttenuationDistance;
static var materialAttenuationColor:Float = MaterialNode.materialAttenuationColor;