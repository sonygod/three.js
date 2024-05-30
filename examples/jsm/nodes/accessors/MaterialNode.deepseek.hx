import three.Node;
import three.jsm.nodes.accessors.ReferenceNode.reference;
import three.jsm.nodes.accessors.MaterialReferenceNode.materialReference;
import three.jsm.nodes.accessors.NormalNode.normalView;
import three.jsm.nodes.shadernode.ShaderNode.*;
import three.jsm.nodes.core.UniformNode.uniform;
import three.Vector2;

class MaterialNode extends Node {

    private static var _propertyCache:Map<String, Node> = new Map();

    public function new(scope:String) {
        super();
        this.scope = scope;
    }

    public function getCache(property:String, type:String):Node {
        var node:Node = _propertyCache.get(property);
        if (node == null) {
            node = materialReference(property, type);
            _propertyCache.set(property, node);
        }
        return node;
    }

    public function getFloat(property:String):Node {
        return this.getCache(property, 'float');
    }

    public function getColor(property:String):Node {
        return this.getCache(property, 'color');
    }

    public function getTexture(property:String):Node {
        return this.getCache(property == 'map' ? 'map' : property + 'Map', 'texture');
    }

    public function setup(builder:Builder):Node {
        var material:Material = builder.context.material;
        var scope:String = this.scope;
        var node:Node = null;

        if (scope == MaterialNode.COLOR) {
            var colorNode:Node = this.getColor(scope);
            if (material.map != null && material.map.isTexture) {
                node = colorNode.mul(this.getTexture('map'));
            } else {
                node = colorNode;
            }
        } else if (scope == MaterialNode.OPACITY) {
            var opacityNode:Node = this.getFloat(scope);
            if (material.alphaMap != null && material.alphaMap.isTexture) {
                node = opacityNode.mul(this.getTexture('alpha'));
            } else {
                node = opacityNode;
            }
        } else if (scope == MaterialNode.SPECULAR_STRENGTH) {
            if (material.specularMap != null && material.specularMap.isTexture) {
                node = this.getTexture('specular').r;
            } else {
                node = float(1);
            }
        } else if (scope == MaterialNode.SPECULAR_INTENSITY) {
            var specularIntensity:Node = this.getFloat(scope);
            if (material.specularMap != null) {
                node = specularIntensity.mul(this.getTexture(scope).a);
            } else {
                node = specularIntensity;
            }
        } else if (scope == MaterialNode.SPECULAR_COLOR) {
            var specularColorNode:Node = this.getColor(scope);
            if (material.specularColorMap != null && material.specularColorMap.isTexture) {
                node = specularColorNode.mul(this.getTexture(scope).rgb);
            } else {
                node = specularColorNode;
            }
        } else if (scope == MaterialNode.ROUGHNESS) {
            var roughnessNode:Node = this.getFloat(scope);
            if (material.roughnessMap != null && material.roughnessMap.isTexture) {
                node = roughnessNode.mul(this.getTexture(scope).g);
            } else {
                node = roughnessNode;
            }
        } else if (scope == MaterialNode.METALNESS) {
            var metalnessNode:Node = this.getFloat(scope);
            if (material.metalnessMap != null && material.metalnessMap.isTexture) {
                node = metalnessNode.mul(this.getTexture(scope).b);
            } else {
                node = metalnessNode;
            }
        } else if (scope == MaterialNode.EMISSIVE) {
            var emissiveNode:Node = this.getColor(scope);
            if (material.emissiveMap != null && material.emissiveMap.isTexture) {
                node = emissiveNode.mul(this.getTexture(scope));
            } else {
                node = emissiveNode;
            }
        } else if (scope == MaterialNode.NORMAL) {
            if (material.normalMap != null) {
                node = this.getTexture('normal').normalMap(this.getCache('normalScale', 'vec2'));
            } else if (material.bumpMap != null) {
                node = this.getTexture('bump').r.bumpMap(this.getFloat('bumpScale'));
            } else {
                node = normalView;
            }
        } else if (scope == MaterialNode.CLEARCOAT) {
            var clearcoatNode:Node = this.getFloat(scope);
            if (material.clearcoatMap != null && material.clearcoatMap.isTexture) {
                node = clearcoatNode.mul(this.getTexture(scope).r);
            } else {
                node = clearcoatNode;
            }
        } else if (scope == MaterialNode.CLEARCOAT_ROUGHNESS) {
            var clearcoatRoughnessNode:Node = this.getFloat(scope);
            if (material.clearcoatRoughnessMap != null && material.clearcoatRoughnessMap.isTexture) {
                node = clearcoatRoughnessNode.mul(this.getTexture(scope).r);
            } else {
                node = clearcoatRoughnessNode;
            }
        } else if (scope == MaterialNode.CLEARCOAT_NORMAL) {
            if (material.clearcoatNormalMap != null) {
                node = this.getTexture(scope).normalMap(this.getCache(scope + 'Scale', 'vec2'));
            } else {
                node = normalView;
            }
        } else if (scope == MaterialNode.SHEEN) {
            var sheenNode:Node = this.getColor('sheenColor').mul(this.getFloat('sheen'));
            if (material.sheenColorMap != null && material.sheenColorMap.isTexture) {
                node = sheenNode.mul(this.getTexture('sheenColor').rgb);
            } else {
                node = sheenNode;
            }
        } else if (scope == MaterialNode.SHEEN_ROUGHNESS) {
            var sheenRoughnessNode:Node = this.getFloat(scope);
            if (material.sheenRoughnessMap != null && material.sheenRoughnessMap.isTexture) {
                node = sheenRoughnessNode.mul(this.getTexture(scope).a);
            } else {
                node = sheenRoughnessNode;
            }
            node = node.clamp(0.07, 1.0);
        } else if (scope == MaterialNode.ANISOTROPY) {
            if (material.anisotropyMap != null && material.anisotropyMap.isTexture) {
                var anisotropyPolar:Node = this.getTexture(scope);
                var anisotropyMat:Node = mat2(materialAnisotropyVector.x, materialAnisotropyVector.y, materialAnisotropyVector.y.negate(), materialAnisotropyVector.x);
                node = anisotropyMat.mul(anisotropyPolar.rg.mul(2.0).sub(vec2(1.0)).normalize().mul(anisotropyPolar.b));
            } else {
                node = materialAnisotropyVector;
            }
        } else if (scope == MaterialNode.IRIDESCENCE_THICKNESS) {
            var iridescenceThicknessMaximum:Node = reference('1', 'float', material.iridescenceThicknessRange);
            if (material.iridescenceThicknessMap != null) {
                var iridescenceThicknessMinimum:Node = reference('0', 'float', material.iridescenceThicknessRange);
                node = iridescenceThicknessMaximum.sub(iridescenceThicknessMinimum).mul(this.getTexture(scope).g).add(iridescenceThicknessMinimum);
            } else {
                node = iridescenceThicknessMaximum;
            }
        } else if (scope == MaterialNode.TRANSMISSION) {
            var transmissionNode:Node = this.getFloat(scope);
            if (material.transmissionMap != null) {
                node = transmissionNode.mul(this.getTexture(scope).r);
            } else {
                node = transmissionNode;
            }
        } else if (scope == MaterialNode.THICKNESS) {
            var thicknessNode:Node = this.getFloat(scope);
            if (material.thicknessMap != null) {
                node = thicknessNode.mul(this.getTexture(scope).g);
            } else {
                node = thicknessNode;
            }
        } else if (scope == MaterialNode.IOR) {
            node = this.getFloat(scope);
        } else {
            var outputType:String = this.getNodeType(builder);
            node = this.getCache(scope, outputType);
        }
        return node;
    }
}

MaterialNode.ALPHA_TEST = 'alphaTest';
MaterialNode.COLOR = 'color';
MaterialNode.OPACITY = 'opacity';
MaterialNode.SHININESS = 'shininess';
MaterialNode.SPECULAR = 'specular';
MaterialNode.SPECULAR_STRENGTH = 'specularStrength';
MaterialNode.SPECULAR_INTENSITY = 'specularIntensity';
MaterialNode.SPECULAR_COLOR = 'specularColor';
MaterialNode.REFLECTIVITY = 'reflectivity';
MaterialNode.ROUGHNESS = 'roughness';
MaterialNode.METALNESS = 'metalness';
MaterialNode.NORMAL = 'normal';
MaterialNode.CLEARCOAT = 'clearcoat';
MaterialNode.CLEARCOAT_ROUGHNESS = 'clearcoatRoughness';
MaterialNode.CLEARCOAT_NORMAL = 'clearcoatNormal';
MaterialNode.EMISSIVE = 'emissive';
MaterialNode.ROTATION = 'rotation';
MaterialNode.SHEEN = 'sheen';
MaterialNode.SHEEN_ROUGHNESS = 'sheenRoughness';
MaterialNode.ANISOTROPY = 'anisotropy';
MaterialNode.IRIDESCENCE = 'iridescence';
MaterialNode.IRIDESCENCE_IOR = 'iridescenceIOR';
MaterialNode.IRIDESCENCE_THICKNESS = 'iridescenceThickness';
MaterialNode.IOR = 'ior';
MaterialNode.TRANSMISSION = 'transmission';
MaterialNode.THICKNESS = 'thickness';
MaterialNode.ATTENUATION_DISTANCE = 'attenuationDistance';
MaterialNode.ATTENUATION_COLOR = 'attenuationColor';
MaterialNode.LINE_SCALE = 'scale';
MaterialNode.LINE_DASH_SIZE = 'dashSize';
MaterialNode.LINE_GAP_SIZE = 'gapSize';
MaterialNode.LINE_WIDTH = 'linewidth';
MaterialNode.LINE_DASH_OFFSET = 'dashOffset';
MaterialNode.POINT_WIDTH = 'pointWidth';

var materialAlphaTest:Node = nodeImmutable(MaterialNode, MaterialNode.ALPHA_TEST);
var materialColor:Node = nodeImmutable(MaterialNode, MaterialNode.COLOR);
var materialShininess:Node = nodeImmutable(MaterialNode, MaterialNode.SHININESS);
var materialEmissive:Node = nodeImmutable(MaterialNode, MaterialNode.EMISSIVE);
var materialOpacity:Node = nodeImmutable(MaterialNode, MaterialNode.OPACITY);
var materialSpecular:Node = nodeImmutable(MaterialNode, MaterialNode.SPECULAR);
var materialSpecularIntensity:Node = nodeImmutable(MaterialNode, MaterialNode.SPECULAR_INTENSITY);
var materialSpecularColor:Node = nodeImmutable(MaterialNode, MaterialNode.SPECULAR_COLOR);
var materialSpecularStrength:Node = nodeImmutable(MaterialNode, MaterialNode.SPECULAR_STRENGTH);
var materialReflectivity:Node = nodeImmutable(MaterialNode, MaterialNode.REFLECTIVITY);
var materialRoughness:Node = nodeImmutable(MaterialNode, MaterialNode.ROUGHNESS);
var materialMetalness:Node = nodeImmutable(MaterialNode, MaterialNode.METALNESS);
var materialNormal:Node = nodeImmutable(MaterialNode, MaterialNode.NORMAL);
var materialClearcoat:Node = nodeImmutable(MaterialNode, MaterialNode.CLEARCOAT);
var materialClearcoatRoughness:Node = nodeImmutable(MaterialNode, MaterialNode.CLEARCOAT_ROUGHNESS);
var materialClearcoatNormal:Node = nodeImmutable(MaterialNode, MaterialNode.CLEARCOAT_NORMAL);
var materialRotation:Node = nodeImmutable(MaterialNode, MaterialNode.ROTATION);
var materialSheen:Node = nodeImmutable(MaterialNode, MaterialNode.SHEEN);
var materialSheenRoughness:Node = nodeImmutable(MaterialNode, MaterialNode.SHEEN_ROUGHNESS);
var materialAnisotropy:Node = nodeImmutable(MaterialNode, MaterialNode.ANISOTROPY);
var materialIridescence:Node = nodeImmutable(MaterialNode, MaterialNode.IRIDESCENCE);
var materialIridescenceIOR:Node = nodeImmutable(MaterialNode, MaterialNode.IRIDESCENCE_IOR);
var materialIridescenceThickness:Node = nodeImmutable(MaterialNode, MaterialNode.IRIDESCENCE_THICKNESS);
var materialTransmission:Node = nodeImmutable(MaterialNode, MaterialNode.TRANSMISSION);
var materialThickness:Node = nodeImmutable(MaterialNode, MaterialNode.THICKNESS);
var materialIOR:Node = nodeImmutable(MaterialNode, MaterialNode.IOR);
var materialAttenuationDistance:Node = nodeImmutable(MaterialNode, MaterialNode.ATTENUATION_DISTANCE);
var materialAttenuationColor:Node = nodeImmutable(MaterialNode, MaterialNode.ATTENUATION_COLOR);
var materialLineScale:Node = nodeImmutable(MaterialNode, MaterialNode.LINE_SCALE);
var materialLineDashSize:Node = nodeImmutable(MaterialNode, MaterialNode.LINE_DASH_SIZE);
var materialLineGapSize:Node = nodeImmutable(MaterialNode, MaterialNode.LINE_GAP_SIZE);
var materialLineWidth:Node = nodeImmutable(MaterialNode, MaterialNode.LINE_WIDTH);
var materialLineDashOffset:Node = nodeImmutable(MaterialNode, MaterialNode.LINE_DASH_OFFSET);
var materialPointWidth:Node = nodeImmutable(MaterialNode, MaterialNode.POINT_WIDTH);
var materialAnisotropyVector:Node = uniform(new Vector2()).onReference(function (frame) {
    return frame.material;
}).onRenderUpdate(function ({material}) {
    this.value.set(material.anisotropy * Math.cos(material.anisotropyRotation), material.anisotropy * Math.sin(material.anisotropyRotation));
});

addNodeClass('MaterialNode', MaterialNode);