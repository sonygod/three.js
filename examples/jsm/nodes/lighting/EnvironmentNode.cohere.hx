import LightingNode from './LightingNode.hx';
import { cache } from '../core/CacheNode.hx';
import { context } from '../core/ContextNode.hx';
import { roughness, clearcoatRoughness } from '../core/PropertyNode.hx';
import { cameraViewMatrix } from '../accessors/CameraNode.hx';
import { transformedClearcoatNormalView, transformedNormalView, transformedNormalWorld } from '../accessors/NormalNode.hx';
import { positionViewDirection } from '../accessors/PositionNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { float } from '../shadernode/ShaderNode.hx';
import { reference } from '../accessors/ReferenceNode.hx';
import { transformedBentNormalView } from '../accessors/AccessorsUtils.hx';
import { pmremTexture } from '../pmrem/PMREMNode.hx';

var envNodeCache = new WeakMap();

class EnvironmentNode extends LightingNode {
    public var envNode: { default: null } = { default: null };

    public function new(envNode: { default: null } = { default: null }) {
        super();
        this.envNode = envNode;
    }

    public function setup(builder: Builder) {
        var envNode = this.envNode;

        if (envNode.isTextureNode) {
            var cacheEnvNode = envNodeCache.get(envNode.value);

            if (cacheEnvNode == null) {
                cacheEnvNode = pmremTexture(envNode.value);
                envNodeCache.set(envNode.value, cacheEnvNode);
            }

            envNode = cacheEnvNode;
        }

        var material = builder.material;
        var envMap = material.envMap;
        var intensity = if (envMap != null) reference('envMapIntensity', 'float', builder.material) else reference('environmentIntensity', 'float', builder.scene);

        var useAnisotropy = material.useAnisotropy || material.anisotropy > 0;
        var radianceNormalView = if (useAnisotropy) transformedBentNormalView else transformedNormalView;

        var radiance = context(envNode, createRadianceContext(roughness, radianceNormalView)).mul(intensity);
        var irradiance = context(envNode, createIrradianceContext(transformedNormalWorld)).mul(Float.PI).mul(intensity);

        var isolateRadiance = cache(radiance);

        builder.context.radiance += isolateRadiance;
        builder.context.iblIrradiance += irradiance;

        var clearcoatRadiance = builder.context.lightingModel.clearcoatRadiance;
        if (clearcoatRadiance != null) {
            var clearcoatRadianceContext = context(envNode, createRadianceContext(clearcoatRoughness, transformedClearcoatNormalView)).mul(intensity);
            var isolateClearcoatRadiance = cache(clearcoatRadianceContext);

            clearcoatRadiance += isolateClearcoatRadiance;
        }
    }
}

function createRadianceContext(roughnessNode: RoughnessNode, normalViewNode: NormalViewNode) {
    var reflectVec: { default: null } = { default: null };

    return {
        getUV(): Vec3 {
            if (reflectVec == null) {
                reflectVec = positionViewDirection.negate().reflect(normalViewNode);
                reflectVec = roughnessNode.mul(roughnessNode).mix(reflectVec, normalViewNode).normalize();
                reflectVec = reflectVec.transformDirection(cameraViewMatrix);
            }

            return reflectVec;
        },

        getTextureLevel(): Float {
            return roughnessNode;
        }
    };
}

function createIrradianceContext(normalWorldNode: NormalWorldNode) {
    return {
        getUV(): Vec3 {
            return normalWorldNode;
        },

        getTextureLevel(): Float {
            return float(1.0);
        }
    };
}

@:enumField
class EnvironmentNodeFields {
    public static var envMapIntensity: String = 'envMapIntensity';
    public static var environmentIntensity: String = 'environmentIntensity';
}

addNodeClass('EnvironmentNode', EnvironmentNode);

export default EnvironmentNode;