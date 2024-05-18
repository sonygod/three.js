Here is the converted Haxe code:
```
package three.js.examples.jsm.nodes.lighting;

import three.js.examples.jsm.nodes.core.CacheNode;
import three.js.examples.jsm.nodes.core.ContextNode;
import three.js.examples.jsm.nodes.core.PropertyNode;
import three.js.examples.jsm.accessors.CameraNode;
import three.js.examples.jsm.accessors.NormalNode;
import three.js.examples.jsm.accessors.PositionNode;
import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.shadernode.ShaderNode;
import three.js.examples.jsm.accessors.ReferenceNode;
import three.js.examples.jsm.accessors.AccessorsUtils;
import three.js.examples.jsm.pmrem.PMREMNode;

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
                cacheEnvNode = pmremTexture(envNode.value);
                envNodeCache.set(envNode.value, cacheEnvNode);
            }
            envNode = cacheEnvNode;
        }

        var material = builder.material;
        var envMap = material.envMap;
        var intensity = envMap != null ? reference('envMapIntensity', 'float', builder.material) : reference('environmentIntensity', 'float', builder.scene);

        var useAnisotropy = material.useAnisotropy || material.anisotropy > 0;
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

var envNodeCache:WeakMap<Dynamic, Dynamic> = new WeakMap<Dynamic, Dynamic>();

Node.addNodeClass('EnvironmentNode', EnvironmentNode);
```
Note that I've kept the same naming conventions and organization as the original JavaScript code. I've also used Haxe's `Dynamic` type to represent the `any` type in JavaScript, since Haxe is a statically-typed language.