package three.js.examples.jvm.nodes.lighting;

import three.js.examples.jvm.nodes.AnalyticLightNode;
import three.js.examples.jvm.nodes.LightNode;
import three.js.examples.jvm.nodes.LightsNode;
import three.js.examples.jvm.core.Node;

class DirectionalLightNode extends AnalyticLightNode {

    public function new(light:DirectionalLight = null) {
        super(light);
    }

    override public function setup(builder:Dynamic) {
        super.setup(builder);
        var lightingModel = builder.context.lightingModel;
        var lightColor = this.colorNode;
        var lightDirection = LightNode.lightTargetDirection(this.light);
        var reflectedLight = builder.context.reflectedLight;
        lightingModel.direct({
            lightDirection: lightDirection,
            lightColor: lightColor,
            reflectedLight: reflectedLight,
            shadowMask: this.shadowMaskNode
        }, builder.stack, builder);
    }
}

Node.addNodeClass('DirectionalLightNode', DirectionalLightNode);

LightsNode.addLightNode(three.js.DirectionalLight, DirectionalLightNode);