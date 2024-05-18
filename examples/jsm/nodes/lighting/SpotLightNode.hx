Here is the converted Haxe code:
```
package three.js.examples.jsw.nodes.lighting;

import three.js.examples.jsw.nodes.AnalyticLightNode;
import three.js.examples.jsw.nodes.LightNode;
import three.js.examples.jsw.nodes.LightsNode;
import three.js.examples.jsw.utils.LightUtils;
import three.js.examples.jsw.core.UniformNode;
import three.js.examples.jsw.math.MathNode;
import three.js.examples.jsw.accessors.Object3DNode;
import three.js.examples.jsw.accessors.PositionNode;
import three.js.examples.jsw.core.Node;

import three.SpotLight;

class SpotLightNode extends AnalyticLightNode {
    public var coneCosNode:UniformNode;
    public var penumbraCosNode:UniformNode;
    public var cutoffDistanceNode:UniformNode;
    public var decayExponentNode:UniformNode;

    public function new(light:SpotLight = null) {
        super(light);

        coneCosNode = new UniformNode(0);
        penumbraCosNode = new UniformNode(0);

        cutoffDistanceNode = new UniformNode(0);
        decayExponentNode = new UniformNode(0);
    }

    override public function update(frame:Dynamic) {
        super.update(frame);

        var light:SpotLight = this.light;
        coneCosNode.value = Math.cos(light.angle);
        penumbraCosNode.value = Math.cos(light.angle * (1 - light.penumbra));

        cutoffDistanceNode.value = light.distance;
        decayExponentNode.value = light.decay;
    }

    public function getSpotAttenuation(angleCosine:Float):Float {
        return MathNode.smoothstep(coneCosNode.value, penumbraCosNode.value, angleCosine);
    }

    override public function setup(builder:Dynamic) {
        super.setup(builder);

        var lightingModel = builder.context.lightingModel;
        var colorNode = this.colorNode;
        var light:SpotLight = this.light;

        var lVector = Object3DNode.objectViewPosition(light).sub(PositionNode.positionView);
        var lightDirection = lVector.normalize();
        var angleCos = lightDirection.dot(LightNode.lightTargetDirection(light));
        var spotAttenuation = getSpotAttenuation(angleCos);

        var lightDistance = lVector.length;
        var lightAttenuation = LightUtils.getDistanceAttenuation({
            lightDistance: lightDistance,
            cutoffDistance: cutoffDistanceNode.value,
            decayExponent: decayExponentNode.value
        });

        var lightColor = colorNode.mul(spotAttenuation).mul(lightAttenuation);

        var reflectedLight = builder.context.reflectedLight;

        lightingModel.direct({
            lightDirection: lightDirection,
            lightColor: lightColor,
            reflectedLight: reflectedLight,
            shadowMask: this.shadowMaskNode
        }, builder.stack, builder);
    }
}

Node.addNodeClass("SpotLightNode", SpotLightNode);
LightsNode.addLightNode(SpotLight, SpotLightNode);
```
Note that I've kept the same namespace and package structure as the original JavaScript code. I've also used the same naming conventions and coding style to make the conversion as seamless as possible.