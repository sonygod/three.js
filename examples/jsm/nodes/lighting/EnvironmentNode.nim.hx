import LightingNode from './LightingNode.js';
import { cache } from '../core/CacheNode.js';
import { context } from '../core/ContextNode.js';
import { roughness, clearcoatRoughness } from '../core/PropertyNode.js';
import { cameraViewMatrix } from '../accessors/CameraNode.js';
import { transformedClearcoatNormalView, transformedNormalView, transformedNormalWorld } from '../accessors/NormalNode.js';
import { positionViewDirection } from '../accessors/PositionNode.js';
import { addNodeClass } from '../core/Node.js';
import { float } from '../shadernode/ShaderNode.js';
import { reference } from '../accessors/ReferenceNode.js';
import { transformedBentNormalView } from '../accessors/AccessorsUtils.js';
import { pmremTexture } from '../pmrem/PMREMNode.js';

typedef EnvNodeCache = haxe.ds.WeakMap<Dynamic, Dynamic>;

class EnvironmentNode extends LightingNode {

	public var envNode:Dynamic;

	public function new(envNode:Dynamic = null) {
		super();
		this.envNode = envNode;
	}

	public function setup(builder:Dynamic) {
		var envNode = this.envNode;

		if (Std.is(envNode, TextureNode)) {
			var cacheEnvNode = envNodeCache.get(envNode.value);

			if (cacheEnvNode == null) {
				cacheEnvNode = pmremTexture(envNode.value);
				envNodeCache.set(envNode.value, cacheEnvNode);
			}

			envNode = cacheEnvNode;
		}

		var material = builder.material;
		var envMap = material.envMap;
		var intensity = envMap ? reference('envMapIntensity', 'float', builder.material) : reference('environmentIntensity', 'float', builder.scene);

		var useAnisotropy = material.useAnisotropy == true || material.anisotropy > 0;
		var radianceNormalView = useAnisotropy ? transformedBentNormalView : transformedNormalView;

		var radiance = context(envNode, createRadianceContext(roughness, radianceNormalView)).mul(intensity);
		var irradiance = context(envNode, createIrradianceContext(transformedNormalWorld)).mul(Math.PI).mul(intensity);

		var isolateRadiance = cache(radiance);

		builder.context.radiance.addAssign(isolateRadiance);
		builder.context.iblIrradiance.addAssign(irradiance);

		var clearcoatRadiance = builder.context.lightingModel.clearcoatRadiance;

		if (clearcoatRadiance != null) {
			var clearcoatRadianceContext = context(envNode, createRadianceContext(clearcoatRoughness, transformedClearcoatNormalView)).mul(intensity);
			var isolateClearcoatRadiance = cache(clearcoatRadianceContext);

			clearcoatRadiance.addAssign(isolateClearcoatRadiance);
		}
	}

	static function createRadianceContext(roughnessNode:Dynamic, normalViewNode:Dynamic) {
		var reflectVec:Dynamic;

		return {
			getUV: function() {
				if (reflectVec == null) {
					reflectVec = positionViewDirection.negate().reflect(normalViewNode);
					reflectVec = roughnessNode.mul(roughnessNode).mix(reflectVec, normalViewNode).normalize();
					reflectVec = reflectVec.transformDirection(cameraViewMatrix);
				}

				return reflectVec;
			},
			getTextureLevel: function() {
				return roughnessNode;
			}
		};
	}

	static function createIrradianceContext(normalWorldNode:Dynamic) {
		return {
			getUV: function() {
				return normalWorldNode;
			},
			getTextureLevel: function() {
				return float(1.0);
			}
		};
	}

}

var envNodeCache:EnvNodeCache = new haxe.ds.WeakMap<Dynamic, Dynamic>();

export default EnvironmentNode;

addNodeClass('EnvironmentNode', EnvironmentNode);