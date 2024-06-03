import LightingNode from './LightingNode';
import { addNodeClass } from '../core/Node';

class AONode extends LightingNode {

    public var aoNode: dynamic;

    public function new(aoNode: dynamic = null) {
        super();
        this.aoNode = aoNode;
    }

    public function setup(builder: dynamic) {
        var aoIntensity: Float = 1.0;
        var aoNode: dynamic = this.aoNode.x.sub(1.0).mul(aoIntensity).add(1.0);

        builder.context.ambientOcclusion = builder.context.ambientOcclusion.mul(aoNode);
    }
}

addNodeClass('AONode', AONode);