class NodeCache {

    static var id:Int = 0;
    var nodesData:haxe.ds.WeakMap<Dynamic, Dynamic>;

    public function new() {

        id ++;
        nodesData = new haxe.ds.WeakMap();

    }

    public function getNodeData(node:Dynamic):Dynamic {

        return nodesData.get(node);

    }

    public function setNodeData(node:Dynamic, data:Dynamic):Void {

        nodesData.set(node, data);

    }

}