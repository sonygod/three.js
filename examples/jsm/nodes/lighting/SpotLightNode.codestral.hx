import three.SpotLight;

import js.html.compat.WebGLRenderer;
import js.html.compat.Object3D;
import js.html.compat.Vector3;

import three.nodes.core.Node;
import three.nodes.core.UniformNode;
import three.nodes.math.MathNode;
import three.nodes.accessors.PositionNode;
import three.nodes.accessors.Object3DNode;
import three.nodes.lighting.LightNode;
import three.nodes.lighting.LightUtils;
import three.nodes.lighting.AnalyticLightNode;
import three.nodes.lighting.LightsNode;

class SpotLightNode extends AnalyticLightNode {

    public var coneCosNode: UniformNode<Float>;
    public var penumbraCosNode: UniformNode<Float>;
    public var cutoffDistanceNode: UniformNode<Float>;
    public var decayExponentNode: UniformNode<Float>;

    public function new(light: SpotLight = null) {
        super(light);

        coneCosNode = new UniformNode(0.0);
        penumbraCosNode = new UniformNode(0.0);

        cutoffDistanceNode = new UniformNode(0.0);
        decayExponentNode = new UniformNode(0.0);
    }

    @override
    public function update(frame: Int) {
        super.update(frame);

        coneCosNode.value = Math.cos(light.angle);
        penumbraCosNode.value = Math.cos(light.angle * (1 - light.penumbra));

        cutoffDistanceNode.value = light.distance;
        decayExponentNode.value = light.decay;
    }

    public function getSpotAttenuation(angleCosine: Float): Float {
        return MathNode.smoothstep(coneCosNode.value, penumbraCosNode.value, angleCosine);
    }

    @override
    public function setup(builder: Node) {
        super.setup(builder);

        var lightingModel = builder.context.lightingModel;

        var lVector = Object3DNode.objectViewPosition(light).sub(PositionNode.positionView);

        var lightDirection = lVector.normalize();
        var angleCos = lightDirection.dot(LightNode.lightTargetDirection(light));
        var spotAttenuation = getSpotAttenuation(angleCos);

        var lightDistance = lVector.length();

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
            shadowMask: shadowMaskNode
        }, builder.stack, builder);
    }
}

Node.addNodeClass('SpotLightNode', SpotLightNode);
LightsNode.addLightNode(SpotLight, SpotLightNode);