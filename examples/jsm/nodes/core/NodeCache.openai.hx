package three.js.examples.jmse.nodes.core;

class NodeCache {
    static var id:Int = 0;

    public var id:Int;
    public var nodesData:Map<Node, Dynamic>;

    public function new() {
        this.id = id++;
        nodesData = new Map();
    }

    public function getNodeData(node:Node):Dynamic {
        return nodesData.get(node);
    }

    public function setNodeData(node:Node, data:Dynamic) {
        nodesData.set(node, data);
    }
}