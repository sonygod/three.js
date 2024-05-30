package three.js_examples.jm.nodes.lighting;

import three.js_examples.jm.nodes.AnalyticLightNode;
import three.js_examples.jm.nodes.LightNode;
import three.js_examples.jm.nodes.LightsNode;
import three.js_examples.jm.nodes.LightUtils;
import three.js_examples.core.UniformNode;
import three.js_examples.math.MathNode;
import three.js_examples.accessors.Object3DNode;
import three.js_examples.accessors.PositionNode;
import three.js_examples.core.Node;

class SpotLightNode extends AnalyticLightNode {
  private var coneCosNode:UniformNode;
  private var penumbraCosNode:UniformNode;
  private var cutoffDistanceNode:UniformNode;
  private var decayExponentNode:UniformNode;

  public function new(light:SpotLight = null) {
    super(light);
    coneCosNode = new UniformNode(0);
    penumbraCosNode = new UniformNode(0);
    cutoffDistanceNode = new UniformNode(0);
    decayExponentNode = new UniformNode(0);
  }

  override public function update(frame:Dynamic) {
    super.update(frame);
    var light:SpotLight = cast this.light;
    coneCosNode.value = Math.cos(light.angle);
    penumbraCosNode.value = Math.cos(light.angle * (1 - light.penumbra));
    cutoffDistanceNode.value = light.distance;
    decayExponentNode.value = light.decay;
  }

  private function getSpotAttenuation(angleCosine:Float):Float {
    return MathNode.smoothstep(coneCosNode.value, penumbraCosNode.value, angleCosine);
  }

  override public function setup(builder:Dynamic) {
    super.setup(builder);
    var lightingModel = builder.context.lightingModel;
    var colorNode = this.colorNode;
    var light:SpotLight = cast this.light;
    var lVector = Object3DNode.objectViewPosition(light).sub(PositionNode.positionView);
    var lightDirection = lVector.normalize();
    var angleCos = lightDirection.dot(LightNode.lightTargetDirection(light));
    var spotAttenuation = getSpotAttenuation(angleCos);
    var lightDistance = lVector.length;
    var lightAttenuation = LightUtils.getDistanceAttenuation({
      lightDistance: lightDistance,
      cutoffDistance: cutoffDistanceNode,
      decayExponent: decayExponentNode
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

Node.addClass("SpotLightNode", SpotLightNode);
LightsNode.addLightNode(SpotLight, SpotLightNode);