import LightingNode.hx;
import Node.hx;

class AONode extends LightingNode {

    public var aoNode:Null<Dynamic>;

    public function new(aoNode:Null<Dynamic> = null) {
        super();
        this.aoNode = aoNode;
    }

    public function setup(builder:Dynamic) {
        var aoIntensity = 1;
        var aoNode = this.aoNode.x.sub(1.0).mul(aoIntensity).add(1.0);
        builder.context.ambientOcclusion.mulAssign(aoNode);
    }

    static function main() {
        addNodeClass('AONode', AONode);
    }
}