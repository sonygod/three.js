import three.SpotLight;
import three.AnalyticLightNode;
import three.LightNode;
import three.LightsNode;
import three.LightUtils;
import three.UniformNode;
import three.MathNode;
import three.Object3DNode;
import three.PositionNode;
import three.Node;

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

    public function update(frame:Dynamic) {
        super.update(frame);
        var light:SpotLight = this.light;
        coneCosNode.value = Math.cos(light.angle);
        penumbraCosNode.value = Math.cos(light.angle * (1 - light.penumbra));
        cutoffDistanceNode.value = light.distance;
        decayExponentNode.value = light.decay;
    }

    public function getSpotAttenuation(angleCosine:Float):Float {
        return MathNode.smoothstep(coneCosNode, penumbraCosNode, angleCosine);
    }

    public function setup(builder:Dynamic) {
        super.setup(builder);
        var lightingModel = builder.context.lightingModel;
        var colorNode = this.colorNode;
        var cutoffDistanceNode = this.cutoffDistanceNode;
        var decayExponentNode = this.decayExponentNode;
        var light:SpotLight = this.light;
        var lVector = Object3DNode.objectViewPosition(light).sub(PositionNode.positionView);
        var lightDirection = lVector.normalize();
        var angleCos = lightDirection.dot(LightNode.lightTargetDirection(light));
        var spotAttenuation = this.getSpotAttenuation(angleCos);
        var lightDistance = lVector.length();
        var lightAttenuation = LightUtils.getDistanceAttenuation({
            lightDistance:lightDistance,
            cutoffDistance:cutoffDistanceNode,
            decayExponent:decayExponentNode
        });
        var lightColor = colorNode.mul(spotAttenuation).mul(lightAttenuation);
        var reflectedLight = builder.context.reflectedLight;
        lightingModel.direct({
            lightDirection:lightDirection,
            lightColor:lightColor,
            reflectedLight:reflectedLight,
            shadowMask:this.shadowMaskNode
        }, builder.stack, builder);
    }
}

Node.addNodeClass('SpotLightNode', SpotLightNode);
LightsNode.addLightNode(SpotLight, SpotLightNode);