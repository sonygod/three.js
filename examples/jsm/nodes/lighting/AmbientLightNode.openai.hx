package three.js.nodes.lighting;

import three.js.nodes.AnalyticLightNode;
import three.js.nodes.LightsNode;
import three.js.core.Node;

class AmbientLightNode extends AnalyticLightNode {

    public function new(light:AmbientLight = null) {
        super(light);
    }

    public function setup(context) {
        context.irradiance.addAssign(colorNode);
    }

}

Node.addNodeClass('AmbientLightNode', AmbientLightNode);
LightsNode.addLightNode(three.AmbientLight, AmbientLightNode);