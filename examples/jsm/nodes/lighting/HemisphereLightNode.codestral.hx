import AnalyticLightNode from './AnalyticLightNode';
import { addLightNode } from './LightsNode';
import { uniform } from '../core/UniformNode';
import { mix } from '../math/MathNode';
import { normalView } from '../accessors/NormalNode';
import { objectPosition } from '../accessors/Object3DNode';
import { addNodeClass } from '../core/Node';
import three.Color;
import three.HemisphereLight;

class HemisphereLightNode extends AnalyticLightNode {

    public var lightPositionNode: Node;
    public var lightDirectionNode: Node;
    public var groundColorNode: Node;

    public function new(light: three.HemisphereLight = null) {
        super(light);

        this.lightPositionNode = objectPosition(light);
        this.lightDirectionNode = this.lightPositionNode.normalize();

        this.groundColorNode = uniform(new Color());
    }

    public function update(frame: Frame) {
        const light = this.light;

        super.update(frame);

        this.lightPositionNode.object3d = light;

        this.groundColorNode.value.copy(light.groundColor).multiplyScalar(light.intensity);
    }

    public function setup(builder: Builder) {
        const dotNL = normalView.dot(this.lightDirectionNode);
        const hemiDiffuseWeight = dotNL.mul(0.5).add(0.5);

        const irradiance = mix(this.groundColorNode, this.colorNode, hemiDiffuseWeight);

        builder.context.irradiance.addAssign(irradiance);
    }
}

addNodeClass('HemisphereLightNode', HemisphereLightNode);

addLightNode(HemisphereLight, HemisphereLightNode);