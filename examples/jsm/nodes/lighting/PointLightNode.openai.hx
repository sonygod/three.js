package three.js.examples.jsm.nodes.lighting;

import three.js.examples.jsm.nodes.AnalyticLightNode;
import three.js.examples.jsm.nodes.LightsNode;
import three.js.examples.jsm.nodes.LightUtils;
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

    override public function update(frame:Any) {
        var light:PointLight = this.light;

        super.update(frame);

        cutoffDistanceNode.value = light.distance;
        decayExponentNode.value = light.decay;
    }

    public function setup(builder:Any) {
        var colorNode:Any = this.colorNode;
        var cutoffDistanceNode:Any = this.cutoffDistanceNode;
        var decayExponentNode:Any = this.decayExponentNode;
        var light:PointLight = this.light;

        var lightingModel:Any = builder.context.lightingModel;

        var lVector:Any = Object3DNode.objectViewPosition(light).sub(PositionNode.positionView);
        var lightDirection:Any = lVector.normalize();
        var lightDistance:Float = lVector.length;

        var lightAttenuation:Float = LightUtils.getDistanceAttenuation({
            lightDistance: lightDistance,
            cutoffDistance: cutoffDistanceNode,
            decayExponent: decayExponentNode
        });

        var lightColor:Any = colorNode.mul(lightAttenuation);

        var reflectedLight:Any = builder.context.reflectedLight;

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