import Node, { addNodeClass } from '../core/Node.hx';
import { reference } from './ReferenceNode.hx';
import { materialReference } from './MaterialReferenceNode.hx';
import { normalView } from './NormalNode.hx';
import { nodeImmutable, float, vec2, mat2 } from '../shadernode/ShaderNode.hx';
import { uniform } from '../core/UniformNode.hx';
import { Vector2 } from 'three';

class MaterialNode extends Node {

	public var scope:String;

	public function new(scope:String) {
		super();
		this.scope = scope;
	}

	public function getCache(property:String, type:String):Node {
		var node = _propertyCache.get(property);
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
		var material = builder.context.material;
		var scope = this.scope;
		var node:Node = null;

		if (scope == MaterialNode.COLOR) {
			var colorNode = this.getColor(scope);
			if (material.map && material.map.isTexture == true) {
				node = colorNode.mul(this.getTexture('map'));
			} else {
				node = colorNode;
			}
		} else if (scope == MaterialNode.OPACITY) {
			var opacityNode = this.getFloat(scope);
			if (material.alphaMap && material.alphaMap.isTexture == true) {
				node = opacityNode.mul(this.getTexture('alpha'));
			} else {
				node = opacityNode;
			}
		} else if (scope == MaterialNode.SPECULAR_STRENGTH) {
			if (material.specularMap && material.specularMap.isTexture == true) {
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
			if (material.specularColorMap && material.specularColorMap.isTexture == true) {
				node = specularColorNode.mul(this.getTexture(scope).rgb);
			} else {
				node = specularColorNode;
			}
		} else if (scope == MaterialNode.ROUGHNESS) {
			var roughnessNode = this.getFloat(scope);
			if (material.roughnessMap && material.roughnessMap.isTexture == true) {
				node = roughnessNode.mul(this.getTexture(scope).g);
			} else {
				node = roughnessNode;
			}
		} else if (scope == MaterialNode.METALNESS) {
			var metalnessNode = this.getFloat(scope);
			if (material.metalnessMap && material.metalnessMap.isTexture == true) {
				node = metalnessNode.mul(this.getTexture(scope).b);
			} else {
				node = metalnessNode;
			}
		} else if (scope == MaterialNode.EMISSIVE) {
			var emissiveNode = this.getColor(scope);
			if (material.emissiveMap && material.emissiveMap.isTexture == true) {
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
				node = normalView;
			}
		} else if (scope == MaterialNode.CLEARCOAT) {
			var clearcoatNode = this.getFloat(scope);
			if (material.clearcoatMap && material.clearcoatMap.isTexture == true) {
				node = clearcoatNode.mul(this.getTexture(scope).r);
			} else {
				node = clearcoatNode;
			}
		} else if (scope == MaterialNode.CLEARCOAT_ROUGHNESS) {
			var clearcoatRoughnessNode = this.getFloat(scope);
			if (material.clearcoatRoughnessMap && material.clearcoatRoughnessMap.isTexture == true) {
				node = clearcoatRoughnessNode.mul(this.getTexture(scope).r);
			} else {
				node = clearcoatRoughnessNode;
			}
		} else if (scope == MaterialNode.CLEARCOAT_NORMAL) {
			if (material.clearcoatNormalMap) {
				node = this.getTexture(scope).normalMap(this.getCache(scope + 'Scale', 'vec2'));
			} else {
				node = normalView;
			}
		} else if (scope == MaterialNode.SHEEN) {
			var sheenNode = this.getColor('sheenColor').mul(this.getFloat('sheen'));
			if (material.sheenColorMap && material.sheenColorMap.isTexture == true) {
				node = sheenNode.mul(this.getTexture('sheenColor').rgb);
			} else {
				node = sheenNode;
			}
		} else if (scope == MaterialNode.SHEEN_ROUGHNESS) {
			var sheenRoughnessNode = this.getFloat(scope);
			if (material.sheenRoughnessMap && material.sheenRoughnessMap.isTexture == true) {
				node = sheenRoughnessNode.mul(this.getTexture(scope).a);
			} else {
				node = sheenRoughnessNode;
			}
			node = node.clamp(0.07, 1.0);
		} else if (scope == MaterialNode.ANISOTROPY) {
			if (material.anisotropyMap && material.anisotropyMap.isTexture == true) {
				var anisotropyPolar = this.getTexture(scope);
				var anisotropyMat = mat2(materialAnisotropyVector.x, materialAnisotropyVector.y, materialAnisotropyVector.y.negate(), materialAnisotropyVector.x);
				node = anisotropyMat.mul(anisotropyPolar.rg.mul(2.0).sub(vec2(1.0)).normalize().mul(anisotropyPolar.b));
			} else {
				node = materialAnisotropyVector;
			}
		} else if (scope == MaterialNode.IRIDESCENCE_THICKNESS) {
			var iridescenceThicknessMaximum = reference('1', 'float', material.iridescenceThicknessRange);
			if (material.iridescenceThicknessMap) {
				var iridescenceThicknessMinimum = reference('0', 'float', material.iridescenceThicknessRange);
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

addNodeClass('MaterialNode', MaterialNode);