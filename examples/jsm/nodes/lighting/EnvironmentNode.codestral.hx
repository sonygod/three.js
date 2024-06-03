import three.js.nodes.lighting.LightingNode;
import three.js.nodes.core.CacheNode.cache;
import three.js.nodes.core.ContextNode.context;
import three.js.nodes.core.PropertyNode.roughness;
import three.js.nodes.core.PropertyNode.clearcoatRoughness;
import three.js.nodes.accessors.CameraNode.cameraViewMatrix;
import three.js.nodes.accessors.NormalNode.transformedClearcoatNormalView;
import three.js.nodes.accessors.NormalNode.transformedNormalView;
import three.js.nodes.accessors.NormalNode.transformedNormalWorld;
import three.js.nodes.accessors.PositionNode.positionViewDirection;
import three.js.nodes.core.Node.addNodeClass;
import three.js.nodes.shadernode.ShaderNode.floatNode;
import three.js.nodes.accessors.ReferenceNode.reference;
import three.js.nodes.accessors.AccessorsUtils.transformedBentNormalView;
import three.js.nodes.pmrem.PMREMNode.pmremTexture;

class EnvironmentNode extends LightingNode {

    public var envNode:Dynamic;

    public function new(envNode:Dynamic = null) {
        super();
        this.envNode = envNode;
    }

    public function setup(builder:Dynamic) {
        var envNode:Dynamic = this.envNode;

        if (Std.is(envNode, Dynamic).envNode.isTextureNode) {
            var cacheEnvNode:Dynamic = envNodeCache.get(envNode.value);

            if (cacheEnvNode == null) {
                cacheEnvNode = pmremTexture(envNode.value);
                envNodeCache.set(envNode.value, cacheEnvNode);
            }

            envNode = cacheEnvNode;
        }

        var { material } = builder;

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
}

function createRadianceContext(roughnessNode:Dynamic, normalViewNode:Dynamic):Dynamic {
    var reflectVec:Dynamic = null;

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

function createIrradianceContext(normalWorldNode:Dynamic):Dynamic {
    return {
        getUV: function() {
            return normalWorldNode;
        },
        getTextureLevel: function() {
            return floatNode(1.0);
        }
    };
}

var envNodeCache = new haxe.ds.WeakMap();

addNodeClass('EnvironmentNode', EnvironmentNode);