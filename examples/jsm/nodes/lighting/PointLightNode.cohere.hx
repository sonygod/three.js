import AnalyticLightNode from './AnalyticLightNode.hx';
import { addLightNode } from './LightsNode.hx';
import { getDistanceAttenuation } from './LightUtils.hx';
import { Uniform } from '../core/UniformNode.hx';
import { objectViewPosition } from '../accessors/Object3DNode.hx';
import { positionView } from '../accessors/PositionNode.hx';
import { addNodeClass } from '../core/Node.hx';

import { PointLight } from 'three';

class PointLightNode extends AnalyticLightNode {
    public var cutoffDistanceNode:Uniform;
    public var decayExponentNode:Uniform;

    public function new(light:PointLight = null) {
        super(light);
        cutoffDistanceNode = Uniform(0);
        decayExponentNode = Uniform(0);
    }

    public function update(frame:Int) {
        super.update(frame);
        cutoffDistanceNode.value = light.distance;
        decayExponentNode.value = light.decay;
    }

    public function setup(builder:Dynamic) {
        var colorNode = this.colorNode;
        var cutoffDistanceNode = this.cutoffDistanceNode;
        var decayExponentNode = this.decayExponentNode;
        var light = this.light;

        var lightingModel = builder.context.lightingModel;

        var lVector = objectViewPosition(light).sub(positionView);
        var lightDirection = lVector.normalize();
        var lightDistance = lVector.length();

        var lightAttenuation = getDistanceAttenuation({
            lightDistance: lightDistance,
            cutoffDistance: cutoffDistanceNode,
            decayExponent: decayExponentNode
        });

        var lightColor = colorNode.mul(lightAttenuation);

        var reflectedLight = builder.context.reflectedLight;

        lightingModel.direct({
            lightDirection: lightDirection,
            lightColor: lightColor,
            reflectedLight: reflectedLight,
            shadowMask: this.shadowMaskNode
        }, builder.stack, builder);
    }
}

addNodeClass('PointLightNode', PointLightNode);
addLightNode(PointLight, PointLightNode);

export { PointLightNode };