package three.js.examples.jm.nodes.lighting;

import three.js.examples.jm.nodes.AnalyticLightNode;
import three.js.examples.jm.nodes.LightsNode;
import three.js.examples.jm.utils.LightUtils;
import three.js.core.UniformNode;
import three.js.accessors.Object3DNode;
import three.js.accessors.PositionNode;
import three.js.core.Node;

import three.PointLight;

class PointLightNode extends AnalyticLightNode {

    public var cutoffDistanceNode:UniformNode;
    public var decayExponentNode:UniformNode;

    public function new(light:PointLight = null) {
        super(light);

        cutoffDistanceNode = new UniformNode(0);
        decayExponentNode = new UniformNode(0);
    }

    override public function update(frame:Dynamic) {
        var light:PointLight = this.light;

        super.update(frame);

        cutoffDistanceNode.value = light.distance;
        decayExponentNode.value = light.decay;
    }

    public function setup(builder:Dynamic) {
        var colorNode:Dynamic = this.colorNode;
        var cutoffDistanceNode:UniformNode = this.cutoffDistanceNode;
        var decayExponentNode:UniformNode = this.decayExponentNode;
        var light:PointLight = this.light;

        var lightingModel:Dynamic = builder.context.lightingModel;

        var lVector:Vector3 = Object3DNode.objectViewPosition(light).sub(PositionNode.positionView);
        var lightDirection:Vector3 = lVector.normalize();
        var lightDistance:Float = lVector.length;

        var lightAttenuation:Float = LightUtils.getDistanceAttenuation({
            lightDistance: lightDistance,
            cutoffDistance: cutoffDistanceNode,
            decayExponent: decayExponentNode
        });

        var lightColor:Vector3 = colorNode.mul(lightAttenuation);

        var reflectedLight:Dynamic = builder.context.reflectedLight;

        lightingModel.direct({
            lightDirection: lightDirection,
            lightColor: lightColor,
            reflectedLight: reflectedLight,
            shadowMask: this.shadowMaskNode
        }, builder.stack, builder);
    }

}

Node.addNodeClass('PointLightNode', PointLightNode);

LightsNode.addLightNode(PointLight, PointLightNode);