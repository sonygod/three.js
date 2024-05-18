package three.js.examples.jsm.nodes.lighting;

import three.js.core.Node;
import three.js.examples.jsm.nodes.AnalyticLightNode;
import three.js.lights.AmbientLight;

class AmbientLightNode extends AnalyticLightNode {

    public function new(light:AmbientLight = null) {
        super(light);
    }

    public function setup(context:{irradiance:Dynamic}) {
        context.irradiance.addAssign(colorNode);
    }

}

Node.addNodeClass('AmbientLightNode', AmbientLightNode);

Node.addLightNode(AmbientLight, AmbientLightNode);