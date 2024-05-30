import AnalyticLightNode from './AnalyticLightNode.hx';
import { lightTargetDirection } from './LightNode.hx';
import { addLightNode } from './LightsNode.hx';
import { getDistanceAttenuation } from './LightUtils.hx';
import { uniform } from '../core/UniformNode.hx';
import { smoothstep } from '../math/MathNode.hx';
import { objectViewPosition } from '../accessors/Object3DNode.hx';
import { positionView } from '../accessors/PositionNode.hx';
import { addNodeClass } from '../core/Node.hx';

import { SpotLight } from 'three';

class SpotLightNode extends AnalyticLightNode {
    public coneCosNode:Dynamic;
    public penumbraCosNode:Dynamic;
    public cutoffDistanceNode:Dynamic;
    public decayExponentNode:Dynamic;

    public function new(light:SpotLight = null) {
        super(light);
        this.coneCosNode = uniform(0);
        this.penumbraCosNode = uniform(0);
        this.cutoffDistanceNode = uniform(0);
        this.decayExponentNode = uniform(0);
    }

    public function update(frame:Int) {
        super.update(frame);
        var light = this.light as SpotLight;
        this.coneCosNode.value = Math.cos(light.angle);
        this.penumbraCosNode.value = Math.cos(light.angle * (1 - light.penumbra));
        this.cutoffDistanceNode.value = light.distance;
        this.decayExponentNode.value = light.decay;
    }

    public function getSpotAttenuation(angleCosine:Float):Float {
        return smoothstep(this.coneCosNode, this.penumbraCosNode, angleCosine);
    }

    public function setup(builder:Dynamic) {
        super.setup(builder);
        var lightingModel = builder.context.lightingModel;
        var lVector = objectViewPosition(this.light).sub(positionView);
        var lightDirection = lVector.normalize();
        var angleCos = lightDirection.dot(lightTargetDirection(this.light));
        var spotAttenuation = this.getSpotAttenuation(angleCos);
        var lightDistance = lVector.length();
        var lightAttenuation = getDistanceAttenuation({
            lightDistance: lightDistance,
            cutoffDistance: this.cutoffDistanceNode,
            decayExponent: this.decayExponentNode
        });
        var lightColor = this.colorNode.mul(spotAttenuation).mul(lightAttenuation);
        var reflectedLight = builder.context.reflectedLight;
        lightingModel.direct({
            lightDirection: lightDirection,
            lightColor: lightColor,
            reflectedLight: reflectedLight,
            shadowMask: this.shadowMaskNode
        }, builder.stack, builder);
    }
}

addNodeClass('SpotLightNode', SpotLightNode);
addLightNode(SpotLight, SpotLightNode);

export default SpotLightNode;