import Node from '../core/Node';
import { addNodeClass } from '../core/Node';
import { reference } from './ReferenceNode';
import { materialReference } from './MaterialReferenceNode';
import { normalView } from './NormalNode';
import { nodeImmutable, float, vec2, mat2 } from '../shadernode/ShaderNode';
import { uniform } from '../core/UniformNode';
import { Vector2 } from 'three';

class MaterialNode extends Node {

  public scope: String;

  public constructor(scope: String) {
    super();
    this.scope = scope;
  }

  private static _propertyCache: Map<String, Node> = new Map();

  private getCache(property: String, type: String): Node {
    let node = MaterialNode._propertyCache.get(property);
    if (node == null) {
      node = materialReference(property, type);
      MaterialNode._propertyCache.set(property, node);
    }
    return node;
  }

  public getFloat(property: String): Node {
    return this.getCache(property, 'float');
  }

  public getColor(property: String): Node {
    return this.getCache(property, 'color');
  }

  public getTexture(property: String): Node {
    return this.getCache(property == 'map' ? 'map' : property + 'Map', 'texture');
  }

  public setup(builder: { context: { material: dynamic } }): Node {
    let material = builder.context.material;
    let scope = this.scope;
    let node: Node = null;

    if (scope == MaterialNode.COLOR) {
      let colorNode = this.getColor(scope);
      if (material.map != null && material.map.isTexture == true) {
        node = colorNode.mul(this.getTexture('map'));
      } else {
        node = colorNode;
      }
    } else if (scope == MaterialNode.OPACITY) {
      let opacityNode = this.getFloat(scope);
      if (material.alphaMap != null && material.alphaMap.isTexture == true) {
        node = opacityNode.mul(this.getTexture('alpha'));
      } else {
        node = opacityNode;
      }
    } else if (scope == MaterialNode.SPECULAR_STRENGTH) {
      if (material.specularMap != null && material.specularMap.isTexture == true) {
        node = this.getTexture('specular').r;
      } else {
        node = float(1);
      }
    } else if (scope == MaterialNode.SPECULAR_INTENSITY) {
      let specularIntensity = this.getFloat(scope);
      if (material.specularMap != null) {
        node = specularIntensity.mul(this.getTexture(scope).a);
      } else {
        node = specularIntensity;
      }
    } else if (scope == MaterialNode.SPECULAR_COLOR) {
      let specularColorNode = this.getColor(scope);
      if (material.specularColorMap != null && material.specularColorMap.isTexture == true) {
        node = specularColorNode.mul(this.getTexture(scope).rgb);
      } else {
        node = specularColorNode;
      }
    } else if (scope == MaterialNode.ROUGHNESS) {
      let roughnessNode = this.getFloat(scope);
      if (material.roughnessMap != null && material.roughnessMap.isTexture == true) {
        node = roughnessNode.mul(this.getTexture(scope).g);
      } else {
        node = roughnessNode;
      }
    } else if (scope == MaterialNode.METALNESS) {
      let metalnessNode = this.getFloat(scope);
      if (material.metalnessMap != null && material.metalnessMap.isTexture == true) {
        node = metalnessNode.mul(this.getTexture(scope).b);
      } else {
        node = metalnessNode;
      }
    } else if (scope == MaterialNode.EMISSIVE) {
      let emissiveNode = this.getColor(scope);
      if (material.emissiveMap != null && material.emissiveMap.isTexture == true) {
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
      let clearcoatNode = this.getFloat(scope);
      if (material.clearcoatMap != null && material.clearcoatMap.isTexture == true) {
        node = clearcoatNode.mul(this.getTexture(scope).r);
      } else {
        node = clearcoatNode;
      }
    } else if (scope == MaterialNode.CLEARCOAT_ROUGHNESS) {
      let clearcoatRoughnessNode = this.getFloat(scope);
      if (material.clearcoatRoughnessMap != null && material.clearcoatRoughnessMap.isTexture == true) {
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
      let sheenNode = this.getColor('sheenColor').mul(this.getFloat('sheen'));
      if (material.sheenColorMap != null && material.sheenColorMap.isTexture == true) {
        node = sheenNode.mul(this.getTexture('sheenColor').rgb);
      } else {
        node = sheenNode;
      }
    } else if (scope == MaterialNode.SHEEN_ROUGHNESS) {
      let sheenRoughnessNode = this.getFloat(scope);
      if (material.sheenRoughnessMap != null && material.sheenRoughnessMap.isTexture == true) {
        node = sheenRoughnessNode.mul(this.getTexture(scope).a);
      } else {
        node = sheenRoughnessNode;
      }
      node = node.clamp(0.07, 1.0);
    } else if (scope == MaterialNode.ANISOTROPY) {
      if (material.anisotropyMap != null && material.anisotropyMap.isTexture == true) {
        let anisotropyPolar = this.getTexture(scope);
        let anisotropyMat = mat2(materialAnisotropyVector.x, materialAnisotropyVector.y, -materialAnisotropyVector.y, materialAnisotropyVector.x);
        node = anisotropyMat.mul(anisotropyPolar.rg.mul(2.0).sub(vec2(1.0)).normalize().mul(anisotropyPolar.b));
      } else {
        node = materialAnisotropyVector;
      }
    } else if (scope == MaterialNode.IRIDESCENCE_THICKNESS) {
      let iridescenceThicknessMaximum = reference('1', 'float', material.iridescenceThicknessRange);
      if (material.iridescenceThicknessMap != null) {
        let iridescenceThicknessMinimum = reference('0', 'float', material.iridescenceThicknessRange);
        node = iridescenceThicknessMaximum.sub(iridescenceThicknessMinimum).mul(this.getTexture(scope).g).add(iridescenceThicknessMinimum);
      } else {
        node = iridescenceThicknessMaximum;
      }
    } else if (scope == MaterialNode.TRANSMISSION) {
      let transmissionNode = this.getFloat(scope);
      if (material.transmissionMap != null) {
        node = transmissionNode.mul(this.getTexture(scope).r);
      } else {
        node = transmissionNode;
      }
    } else if (scope == MaterialNode.THICKNESS) {
      let thicknessNode = this.getFloat(scope);
      if (material.thicknessMap != null) {
        node = thicknessNode.mul(this.getTexture(scope).g);
      } else {
        node = thicknessNode;
      }
    } else if (scope == MaterialNode.IOR) {
      node = this.getFloat(scope);
    } else {
      let outputType = this.getNodeType(builder);
      node = this.getCache(scope, outputType);
    }
    return node;
  }

  public static ALPHA_TEST: String = 'alphaTest';
  public static COLOR: String = 'color';
  public static OPACITY: String = 'opacity';
  public static SHININESS: String = 'shininess';
  public static SPECULAR: String = 'specular';
  public static SPECULAR_STRENGTH: String = 'specularStrength';
  public static SPECULAR_INTENSITY: String = 'specularIntensity';
  public static SPECULAR_COLOR: String = 'specularColor';
  public static REFLECTIVITY: String = 'reflectivity';
  public static ROUGHNESS: String = 'roughness';
  public static METALNESS: String = 'metalness';
  public static NORMAL: String = 'normal';
  public static CLEARCOAT: String = 'clearcoat';
  public static CLEARCOAT_ROUGHNESS: String = 'clearcoatRoughness';
  public static CLEARCOAT_NORMAL: String = 'clearcoatNormal';
  public static EMISSIVE: String = 'emissive';
  public static ROTATION: String = 'rotation';
  public static SHEEN: String = 'sheen';
  public static SHEEN_ROUGHNESS: String = 'sheenRoughness';
  public static ANISOTROPY: String = 'anisotropy';
  public static IRIDESCENCE: String = 'iridescence';
  public static IRIDESCENCE_IOR: String = 'iridescenceIOR';
  public static IRIDESCENCE_THICKNESS: String = 'iridescenceThickness';
  public static IOR: String = 'ior';
  public static TRANSMISSION: String = 'transmission';
  public static THICKNESS: String = 'thickness';
  public static ATTENUATION_DISTANCE: String = 'attenuationDistance';
  public static ATTENUATION_COLOR: String = 'attenuationColor';
  public static LINE_SCALE: String = 'scale';
  public static LINE_DASH_SIZE: String = 'dashSize';
  public static LINE_GAP_SIZE: String = 'gapSize';
  public static LINE_WIDTH: String = 'linewidth';
  public static LINE_DASH_OFFSET: String = 'dashOffset';
  public static POINT_WIDTH: String = 'pointWidth';
}

export var materialAlphaTest: Node = nodeImmutable(MaterialNode, MaterialNode.ALPHA_TEST);
export var materialColor: Node = nodeImmutable(MaterialNode, MaterialNode.COLOR);
export var materialShininess: Node = nodeImmutable(MaterialNode, MaterialNode.SHININESS);
export var materialEmissive: Node = nodeImmutable(MaterialNode, MaterialNode.EMISSIVE);
export var materialOpacity: Node = nodeImmutable(MaterialNode, MaterialNode.OPACITY);
export var materialSpecular: Node = nodeImmutable(MaterialNode, MaterialNode.SPECULAR);

export var materialSpecularIntensity: Node = nodeImmutable(MaterialNode, MaterialNode.SPECULAR_INTENSITY);
export var materialSpecularColor: Node = nodeImmutable(MaterialNode, MaterialNode.SPECULAR_COLOR);

export var materialSpecularStrength: Node = nodeImmutable(MaterialNode, MaterialNode.SPECULAR_STRENGTH);
export var materialReflectivity: Node = nodeImmutable(MaterialNode, MaterialNode.REFLECTIVITY);
export var materialRoughness: Node = nodeImmutable(MaterialNode, MaterialNode.ROUGHNESS);
export var materialMetalness: Node = nodeImmutable(MaterialNode, MaterialNode.METALNESS);
export var materialNormal: Node = nodeImmutable(MaterialNode, MaterialNode.NORMAL);
export var materialClearcoat: Node = nodeImmutable(MaterialNode, MaterialNode.CLEARCOAT);
export var materialClearcoatRoughness: Node = nodeImmutable(MaterialNode, MaterialNode.CLEARCOAT_ROUGHNESS);
export var materialClearcoatNormal: Node = nodeImmutable(MaterialNode, MaterialNode.CLEARCOAT_NORMAL);
export var materialRotation: Node = nodeImmutable(MaterialNode, MaterialNode.ROTATION);
export var materialSheen: Node = nodeImmutable(MaterialNode, MaterialNode.SHEEN);
export var materialSheenRoughness: Node = nodeImmutable(MaterialNode, MaterialNode.SHEEN_ROUGHNESS);
export var materialAnisotropy: Node = nodeImmutable(MaterialNode, MaterialNode.ANISOTROPY);
export var materialIridescence: Node = nodeImmutable(MaterialNode, MaterialNode.IRIDESCENCE);
export var materialIridescenceIOR: Node = nodeImmutable(MaterialNode, MaterialNode.IRIDESCENCE_IOR);
export var materialIridescenceThickness: Node = nodeImmutable(MaterialNode, MaterialNode.IRIDESCENCE_THICKNESS);
export var materialTransmission: Node = nodeImmutable(MaterialNode, MaterialNode.TRANSMISSION);
export var materialThickness: Node = nodeImmutable(MaterialNode, MaterialNode.THICKNESS);
export var materialIOR: Node = nodeImmutable(MaterialNode, MaterialNode.IOR);
export var materialAttenuationDistance: Node = nodeImmutable(MaterialNode, MaterialNode.ATTENUATION_DISTANCE);
export var materialAttenuationColor: Node = nodeImmutable(MaterialNode, MaterialNode.ATTENUATION_COLOR);
export var materialLineScale: Node = nodeImmutable(MaterialNode, MaterialNode.LINE_SCALE);
export var materialLineDashSize: Node = nodeImmutable(MaterialNode, MaterialNode.LINE_DASH_SIZE);
export var materialLineGapSize: Node = nodeImmutable(MaterialNode, MaterialNode.LINE_GAP_SIZE);
export var materialLineWidth: Node = nodeImmutable(MaterialNode, MaterialNode.LINE_WIDTH);
export var materialLineDashOffset: Node = nodeImmutable(MaterialNode, MaterialNode.LINE_DASH_OFFSET);
export var materialPointWidth: Node = nodeImmutable(MaterialNode, MaterialNode.POINT_WIDTH);

export var materialAnisotropyVector: Node = uniform(new Vector2()).onReference(function(frame) {
  return frame.material;
}).onRenderUpdate(function({ material }) {
  this.value.set(material.anisotropy * Math.cos(material.anisotropyRotation), material.anisotropy * Math.sin(material.anisotropyRotation));
});

addNodeClass('MaterialNode', MaterialNode);

export default MaterialNode;