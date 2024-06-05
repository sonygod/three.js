package three.js.examples.jsm.nodes.lighting;

import three.js.core.Node;
import three.js.core.UniformNode;
import three.js.math.MathNode;
import three.js.accessors.NormalNode;
import three.js.accessors.Object3DNode;
import three.js.lights.HemisphereLight;
import three.js.Color;

class HemisphereLightNode extends AnalyticLightNode {
    public var lightPositionNode:Object3DNode;
    public var lightDirectionNode:MathNode;
    public var groundColorNode:UniformNode;

    public function new(light:HemisphereLight = null) {
        super(light);

        lightPositionNode = Object3DNode.getObjectPosition(light);
        lightDirectionNode = lightPositionNode.normalize();

        groundColorNode = new UniformNode(new Color());
    }

    override public function update(frame:Int) {
        var light:HemisphereLight = this.light;

        super.update(frame);

        lightPositionNode.object3d = light;

        groundColorNode.value.copy(light.groundColor).multiplyScalar(light.intensity);
    }

    public function setup(builder:Node) {
        var colorNode:UniformNode = this.colorNode;
        var groundColorNode:UniformNode = this.groundColorNode;
        var lightDirectionNode:MathNode = this.lightDirectionNode;

        var dotNL:MathNode = NormalNode.normalView.dot(lightDirectionNode);
        var hemiDiffuseWeight:MathNode = dotNL.mul(0.5).add(0.5);

        var irradiance:MathNode = mix(groundColorNode, colorNode, hemiDiffuseWeight);

        builder.context.irradiance.addAssign(irradiance);
    }
}

// Register the node class
Node.addNodeClass('HemisphereLightNode', HemisphereLightNode);

// Register the light node
LightsNode.addLightNode(HemisphereLight, HemisphereLightNode);