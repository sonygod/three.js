package three.js.examples.javascript.nodes.lighting;

import three.js.examples.javascript.nodes.AnalyticLightNode;
import three.js.examples.javascript.nodes.LightNode;
import three.js.examples.javascript.nodes.LightsNode;
import three.js.core.Node;

import three.DirectionalLight;

class DirectionalLightNode extends AnalyticLightNode {

    public function new(?light:DirectionalLight) {
        super(light);
    }

    override public function setup(builder:Dynamic) {
        super.setup(builder);

        var lightingModel = builder.context.lightingModel;
        var lightColor = colorNode;
        var lightDirection = LightNode.lightTargetDirection(light);
        var reflectedLight = builder.context.reflectedLight;

        lightingModel.direct({
            lightDirection: lightDirection,
            lightColor: lightColor,
            reflectedLight: reflectedLight,
            shadowMask: shadowMaskNode
        }, builder.stack, builder);
    }

}

// Add the node class to the registry
Node.addNodeClass('DirectionalLightNode', DirectionalLightNode);

// Register the light node
LightsNode.addLightNode(DirectionalLight, DirectionalLightNode);