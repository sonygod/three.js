import AnalyticLightNode from 'three.js.examples.jsm.nodes.lighting.AnalyticLightNode';
import { addLightNode } from 'three.js.examples.jsm.nodes.lighting.LightsNode';
import { addNodeClass } from 'three.js.examples.jsm.core.Node';
import { AmbientLight } from 'three';

class AmbientLightNode extends AnalyticLightNode {

    public function new(light:AmbientLight = null) {
        super(light);
    }

    public function setup(context:Dynamic) {
        context.irradiance.addAssign(this.colorNode);
    }

}

addNodeClass('AmbientLightNode', type(AmbientLightNode));
addLightNode(AmbientLight, type(AmbientLightNode));