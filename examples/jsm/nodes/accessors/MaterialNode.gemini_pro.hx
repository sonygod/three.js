import Node from '../core/Node';
import ReferenceNode from './ReferenceNode';
import MaterialReferenceNode from './MaterialReferenceNode';
import NormalNode from './NormalNode';
import ShaderNode, { nodeImmutable, float, vec2, mat2 } from '../shadernode/ShaderNode';
import UniformNode from '../core/UniformNode';
import { Vector2 } from 'three';

class MaterialNode extends Node {

    public static readonly ALPHA_TEST:String = "alphaTest";
    public static readonly COLOR:String = "color";
    public static readonly OPACITY:String = "opacity";
    public static readonly SHININESS:String = "shininess";
    public static readonly SPECULAR:String = "specular";
    public static readonly SPECULAR_STRENGTH:String = "specularStrength";
    public static readonly SPECULAR_INTENSITY:String = "specularIntensity";
    public static readonly SPECULAR_COLOR:String = "specularColor";
    public static readonly REFLECTIVITY:String = "reflectivity";
    public static readonly ROUGHNESS:String = "roughness";
    public static readonly METALNESS:String = "metalness";
    public static readonly NORMAL:String = "normal";
    public static readonly CLEARCOAT:String = "clearcoat";
    public static readonly CLEARCOAT_ROUGHNESS:String = "clearcoatRoughness";
    public static readonly CLEARCOAT_NORMAL:String = "clearcoatNormal";
    public static readonly EMISSIVE:String = "emissive";
    public static readonly ROTATION:String = "rotation";
    public static readonly SHEEN:String = "sheen";
    public static readonly SHEEN_ROUGHNESS:String = "sheenRoughness";
    public static readonly ANISOTROPY:String = "anisotropy";
    public static readonly IRIDESCENCE:String = "iridescence";
    public static readonly IRIDESCENCE_IOR:String = "iridescenceIOR";
    public static readonly IRIDESCENCE_THICKNESS:String = "iridescenceThickness";
    public static readonly IOR:String = "ior";
    public static readonly TRANSMISSION:String = "transmission";
    public static readonly THICKNESS:String = "thickness";
    public static readonly ATTENUATION_DISTANCE:String = "attenuationDistance";
    public static readonly ATTENUATION_COLOR:String = "attenuationColor";
    public static readonly LINE_SCALE:String = "scale";
    public static readonly LINE_DASH_SIZE:String = "dashSize";
    public static readonly LINE_GAP_SIZE:String = "gapSize";
    public static readonly LINE_WIDTH:String = "linewidth";
    public static readonly LINE_DASH_OFFSET:String = "dashOffset";
    public static readonly POINT_WIDTH:String = "pointWidth";

    private static _propertyCache:Map<String, Node> = new Map();

    public scope:String;

    public constructor(scope:String) {
        super();
        this.scope = scope;
    }

    private getCache(property:String, type:String):Node {
        var node = MaterialNode._propertyCache.get(property);
        if (node == null) {
            node = MaterialReferenceNode.create(property, type);
            MaterialNode._propertyCache.set(property, node);
        }
        return node;
    }

    public getFloat(property:String):Node {
        return this.getCache(property, 'float');
    }

    public getColor(property:String):Node {
        return this.getCache(property, 'color');
    }

    public getTexture(property:String):Node {
        return this.getCache((property == 'map') ? 'map' : property + 'Map', 'texture');
    }

    public setup(builder:any):Node {
        var material = builder.context.material;
        var scope = this.scope;

        var node:Node = null;

        if (scope == MaterialNode.COLOR) {
            var colorNode = this.getColor(scope);
            if (material.map && material.map.isTexture) {
                node = colorNode.mul(this.getTexture('map'));
            } else {
                node = colorNode;
            }
        } else if (scope == MaterialNode.OPACITY) {
            var opacityNode = this.getFloat(scope);
            if (material.alphaMap && material.alphaMap.isTexture) {
                node = opacityNode.mul(this.getTexture('alpha'));
            } else {
                node = opacityNode;
            }
        } else if (scope == MaterialNode.SPECULAR_STRENGTH) {
            if (material.specularMap && material.specularMap.isTexture) {
                node = this.getTexture('specular').r;
            } else {
                node = float(1);
            }
        } else if (scope == MaterialNode.SPECULAR_INTENSITY) {
            var specularIntensity = this.getFloat(scope);
            if (material.specularMap) {
                node = specularIntensity.mul(this.getTexture(scope).a);
            } else {
                node = specularIntensity;
            }
        } else if (scope == MaterialNode.SPECULAR_COLOR) {
            var specularColorNode = this.getColor(scope);
            if (material.specularColorMap && material.specularColorMap.isTexture) {
                node = specularColorNode.mul(this.getTexture(scope).rgb);
            } else {
                node = specularColorNode;
            }
        } else if (scope == MaterialNode.ROUGHNESS) {
            var roughnessNode = this.getFloat(scope);
            if (material.roughnessMap && material.roughnessMap.isTexture) {
                node = roughnessNode.mul(this.getTexture(scope).g);
            } else {
                node = roughnessNode;
            }
        } else if (scope == MaterialNode.METALNESS) {
            var metalnessNode = this.getFloat(scope);
            if (material.metalnessMap && material.metalnessMap.isTexture) {
                node = metalnessNode.mul(this.getTexture(scope).b);
            } else {
                node = metalnessNode;
            }
        } else if (scope == MaterialNode.EMISSIVE) {
            var emissiveNode = this.getColor(scope);
            if (material.emissiveMap && material.emissiveMap.isTexture) {
                node = emissiveNode.mul(this.getTexture(scope));
            } else {
                node = emissiveNode;
            }
        } else if (scope == MaterialNode.NORMAL) {
            if (material.normalMap) {
                node = this.getTexture('normal').normalMap(this.getCache('normalScale', 'vec2'));
            } else if (material.bumpMap) {
                node = this.getTexture('bump').r.bumpMap(this.getFloat('bumpScale'));
            } else {
                node = NormalNode.normalView;
            }
        } else if (scope == MaterialNode.CLEARCOAT) {
            var clearcoatNode = this.getFloat(scope);
            if (material.clearcoatMap && material.clearcoatMap.isTexture) {
                node = clearcoatNode.mul(this.getTexture(scope).r);
            } else {
                node = clearcoatNode;
            }
        } else if (scope == MaterialNode.CLEARCOAT_ROUGHNESS) {
            var clearcoatRoughnessNode = this.getFloat(scope);
            if (material.clearcoatRoughnessMap && material.clearcoatRoughnessMap.isTexture) {
                node = clearcoatRoughnessNode.mul(this.getTexture(scope).r);
            } else {
                node = clearcoatRoughnessNode;
            }
        } else if (scope == MaterialNode.CLEARCOAT_NORMAL) {
            if (material.clearcoatNormalMap) {
                node = this.getTexture(scope).normalMap(this.getCache(scope + 'Scale', 'vec2'));
            } else {
                node = NormalNode.normalView;
            }
        } else if (scope == MaterialNode.SHEEN) {
            var sheenNode = this.getColor('sheenColor').mul(this.getFloat('sheen')); // Move this mul() to CPU
            if (material.sheenColorMap && material.sheenColorMap.isTexture) {
                node = sheenNode.mul(this.getTexture('sheenColor').rgb);
            } else {
                node = sheenNode;
            }
        } else if (scope == MaterialNode.SHEEN_ROUGHNESS) {
            var sheenRoughnessNode = this.getFloat(scope);
            if (material.sheenRoughnessMap && material.sheenRoughnessMap.isTexture) {
                node = sheenRoughnessNode.mul(this.getTexture(scope).a);
            } else {
                node = sheenRoughnessNode;
            }
            node = node.clamp(0.07, 1.0);
        } else if (scope == MaterialNode.ANISOTROPY) {
            if (material.anisotropyMap && material.anisotropyMap.isTexture) {
                var anisotropyPolar = this.getTexture(scope);
                var anisotropyMat = mat2(MaterialNode.materialAnisotropyVector.x, MaterialNode.materialAnisotropyVector.y, -MaterialNode.materialAnisotropyVector.y, MaterialNode.materialAnisotropyVector.x);
                node = anisotropyMat.mul(anisotropyPolar.rg.mul(2.0).sub(vec2(1.0)).normalize().mul(anisotropyPolar.b));
            } else {
                node = MaterialNode.materialAnisotropyVector;
            }
        } else if (scope == MaterialNode.IRIDESCENCE_THICKNESS) {
            var iridescenceThicknessMaximum = ReferenceNode.create('1', 'float', material.iridescenceThicknessRange);
            if (material.iridescenceThicknessMap) {
                var iridescenceThicknessMinimum = ReferenceNode.create('0', 'float', material.iridescenceThicknessRange);
                node = iridescenceThicknessMaximum.sub(iridescenceThicknessMinimum).mul(this.getTexture(scope).g).add(iridescenceThicknessMinimum);
            } else {
                node = iridescenceThicknessMaximum;
            }
        } else if (scope == MaterialNode.TRANSMISSION) {
            var transmissionNode = this.getFloat(scope);
            if (material.transmissionMap) {
                node = transmissionNode.mul(this.getTexture(scope).r);
            } else {
                node = transmissionNode;
            }
        } else if (scope == MaterialNode.THICKNESS) {
            var thicknessNode = this.getFloat(scope);
            if (material.thicknessMap) {
                node = thicknessNode.mul(this.getTexture(scope).g);
            } else {
                node = thicknessNode;
            }
        } else if (scope == MaterialNode.IOR) {
            node = this.getFloat(scope);
        } else {
            var outputType = this.getNodeType(builder);
            node = this.getCache(scope, outputType);
        }

        return node;
    }

}

export default MaterialNode;

export var materialAlphaTest = nodeImmutable(MaterialNode, MaterialNode.ALPHA_TEST);
export var materialColor = nodeImmutable(MaterialNode, MaterialNode.COLOR);
export var materialShininess = nodeImmutable(MaterialNode, MaterialNode.SHININESS);
export var materialEmissive = nodeImmutable(MaterialNode, MaterialNode.EMISSIVE);
export var materialOpacity = nodeImmutable(MaterialNode, MaterialNode.OPACITY);
export var materialSpecular = nodeImmutable(MaterialNode, MaterialNode.SPECULAR);

export var materialSpecularIntensity = nodeImmutable(MaterialNode, MaterialNode.SPECULAR_INTENSITY);
export var materialSpecularColor = nodeImmutable(MaterialNode, MaterialNode.SPECULAR_COLOR);

export var materialSpecularStrength = nodeImmutable(MaterialNode, MaterialNode.SPECULAR_STRENGTH);
export var materialReflectivity = nodeImmutable(MaterialNode, MaterialNode.REFLECTIVITY);
export var materialRoughness = nodeImmutable(MaterialNode, MaterialNode.ROUGHNESS);
export var materialMetalness = nodeImmutable(MaterialNode, MaterialNode.METALNESS);
export var materialNormal = nodeImmutable(MaterialNode, MaterialNode.NORMAL);
export var materialClearcoat = nodeImmutable(MaterialNode, MaterialNode.CLEARCOAT);
export var materialClearcoatRoughness = nodeImmutable(MaterialNode, MaterialNode.CLEARCOAT_ROUGHNESS);
export var materialClearcoatNormal = nodeImmutable(MaterialNode, MaterialNode.CLEARCOAT_NORMAL);
export var materialRotation = nodeImmutable(MaterialNode, MaterialNode.ROTATION);
export var materialSheen = nodeImmutable(MaterialNode, MaterialNode.SHEEN);
export var materialSheenRoughness = nodeImmutable(MaterialNode, MaterialNode.SHEEN_ROUGHNESS);
export var materialAnisotropy = nodeImmutable(MaterialNode, MaterialNode.ANISOTROPY);
export var materialIridescence = nodeImmutable(MaterialNode, MaterialNode.IRIDESCENCE);
export var materialIridescenceIOR = nodeImmutable(MaterialNode, MaterialNode.IRIDESCENCE_IOR);
export var materialIridescenceThickness = nodeImmutable(MaterialNode, MaterialNode.IRIDESCENCE_THICKNESS);
export var materialTransmission = nodeImmutable(MaterialNode, MaterialNode.TRANSMISSION);
export var materialThickness = nodeImmutable(MaterialNode, MaterialNode.THICKNESS);
export var materialIOR = nodeImmutable(MaterialNode, MaterialNode.IOR);
export var materialAttenuationDistance = nodeImmutable(MaterialNode, MaterialNode.ATTENUATION_DISTANCE);
export var materialAttenuationColor = nodeImmutable(MaterialNode, MaterialNode.ATTENUATION_COLOR);
export var materialLineScale = nodeImmutable(MaterialNode, MaterialNode.LINE_SCALE);
export var materialLineDashSize = nodeImmutable(MaterialNode, MaterialNode.LINE_DASH_SIZE);
export var materialLineGapSize = nodeImmutable(MaterialNode, MaterialNode.LINE_GAP_SIZE);
export var materialLineWidth = nodeImmutable(MaterialNode, MaterialNode.LINE_WIDTH);
export var materialLineDashOffset = nodeImmutable(MaterialNode, MaterialNode.LINE_DASH_OFFSET);
export var materialPointWidth = nodeImmutable(MaterialNode, MaterialNode.POINT_WIDTH);
export var materialAnisotropyVector = UniformNode.create(new Vector2()).onReference(function(frame:any) {
    return frame.material;
}).onRenderUpdate(function(frame:any) {
    this.value.set(frame.material.anisotropy * Math.cos(frame.material.anisotropyRotation), frame.material.anisotropy * Math.sin(frame.material.anisotropyRotation));
});