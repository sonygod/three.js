package three.js.examples.javascript.nodes.core;

class NodeCache {
    private static var id:Int = 0;

    public var id:Int;
    public var nodesData:Map<Node, Dynamic>;

    public function new() {
        id = id++;
        nodesData = new Map<Node, Dynamic>();
    }

    public function getNodeData(node:Node):Dynamic {
        return nodesData.get(node);
    }

    public function setNodeData(node:Node, data:Dynamic):Void {
        nodesData.set(node, data);
    }
}