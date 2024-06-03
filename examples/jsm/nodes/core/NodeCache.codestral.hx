import haxe.ds.WeakMap;

var id: Int = 0;

class NodeCache {
    private var nodesData: WeakMap<Dynamic, Dynamic>;
    public var id: Int;

    public function new() {
        this.id = id++;
        this.nodesData = new WeakMap();
    }

    public function getNodeData(node: Dynamic): Dynamic {
        return this.nodesData.get(node);
    }

    public function setNodeData(node: Dynamic, data: Dynamic): Void {
        this.nodesData.set(node, data);
    }
}

export default NodeCache;