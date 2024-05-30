class NodeCache {
    var id: Int;
    var nodesData: WeakMap<Dynamic, Dynamic>;

    public function new() {
        id = 0;
        nodesData = WeakMap<Dynamic, Dynamic>();
    }

    public function getNodeData(node: Dynamic): Dynamic {
        return nodesData.get(node);
    }

    public function setNodeData(node: Dynamic, data: Dynamic): Void {
        nodesData.set(node, data);
    }
}