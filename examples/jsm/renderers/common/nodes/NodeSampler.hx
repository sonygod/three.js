package three.js.examples.jsm.renderers.common.nodes;

import three.js.examples.jsm.renderers.common.Sampler;

class NodeSampler extends Sampler {

    public var textureNode:Dynamic;

    public function new(name:String, textureNode:Dynamic) {
        super(name, textureNode != null ? textureNode.value : null);
        this.textureNode = textureNode;
    }

    public function update():Void {
        this.texture = this.textureNode.value;
    }

}