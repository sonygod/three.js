package three.js.examples.jmw.nodes.lighting;

import three.js.core.CacheNode;
import three.js.core.ContextNode;
import three.js.core.LightingNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.accessors.AccessorsUtils;
import three.js.accessors.CameraNode;
import three.js.accessors.NormalNode;
import three.js.accessors.PositionNode;
import three.js.accessors.ReferenceNode;
import three.js.pmrem.PMREMNode;

class EnvironmentNode extends LightingNode {

    private var envNode:Dynamic;

    public function new(envNode:Dynamic = null) {
        super();
        this.envNode = envNode;
    }

    public function setup(builder:Dynamic) {
        var envNode = this.envNode;

        if (envNode.isTextureNode) {
            var cacheEnvNode = envNodeCache.get(envNode.value);
            if (cacheEnvNode == null) {
                cacheEnvNode = PMREMNode.pmremTexture(envNode.value);
                envNodeCache.set(envNode.value, cacheEnvNode);
            }
            envNode = cacheEnvNode;
        }

        var material:Dynamic = builder.material;
        var envMap:Dynamic = material.envMap;
        var intensity:Dynamic = envMap != null ? ReferenceNode.reference('envMapIntensity', 'float', builder.material) : ReferenceNode.reference('environmentIntensity', 'float', builder.scene);

        var useAnisotropy:Bool = material.useAnisotropy == true || material.anisotropy > 0;
        var radianceNormalView:Dynamic = useAnisotropy ? AccessorsUtils.transformedBentNormalView : NormalNode.transformedNormalView;

        var radiance:Dynamic = ContextNode.context(envNode, createRadianceContext(RoughnessNode.roughness, radianceNormalView)).mul(intensity);
        var irradiance:Dynamic = ContextNode.context(envNode, createIrradianceContext(NormalNode.transformedNormalWorld)).mul(Math.PI).mul(intensity);

        var isolateRadiance:Dynamic = CacheNode.cache(radiance);

        builder.context.radiance.addAssign(isolateRadiance);

        builder.context.iblIrradiance.addAssign(irradiance);

        var clearcoatRadiance:Dynamic = builder.context.lightingModel.clearcoatRadiance;

        if (clearcoatRadiance != null) {
            var clearcoatRadianceContext:Dynamic = ContextNode.context(envNode, createRadianceContext(ClearcoatRoughnessNode.clearcoatRoughness, NormalNode.transformedClearcoatNormalView)).mul(intensity);
            var isolateClearcoatRadiance:Dynamic = CacheNode.cache(clearcoatRadianceContext);

            clearcoatRadiance.addAssign(isolateClearcoatRadiance);
        }
    }

    static var envNodeCache:WeakMap<Dynamic, Dynamic> = new WeakMap();

    static function createRadianceContext(roughnessNode:Dynamic, normalViewNode:Dynamic) {
        var reflectVec:Dynamic = null;

        return {
            getUV: function() {
                if (reflectVec == null) {
                    reflectVec = PositionNode.positionViewDirection.negate().reflect(normalViewNode);

                    // Mixing the reflection with the normal is more accurate and keeps rough objects from gathering light from behind their tangent plane.
                    reflectVec = roughnessNode.mul(roughnessNode).mix(reflectVec, normalViewNode).normalize();

                    reflectVec = reflectVec.transformDirection(CameraNode.cameraViewMatrix);
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
                return ShaderNode.float(1.0);
            }
        };
    }
}

Node.addNodeClass('EnvironmentNode', EnvironmentNode);