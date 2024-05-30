import haxe.ds.WeakMap;

class NodeCache {
    static var id:Int = 0;

    var _id:Int;
    var nodesData:WeakMap<Dynamic, Dynamic>;

    public function new() {
        this._id = id++;
        this.nodesData = new WeakMap();
    }

    public function getNodeData(node:Dynamic):Dynamic {
        return this.nodesData.get(node);
    }

    public function setNodeData(node:Dynamic, data:Dynamic):Dynamic {
        return this.nodesData.set(node, data);
    }
}