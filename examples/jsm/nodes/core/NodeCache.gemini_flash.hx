class NodeCache {

	static var _id:Int = 0;

	public var id:Int;
	public var nodesData:WeakMap<Dynamic,Dynamic>;

	public function new() {
		this.id = NodeCache._id++;
		this.nodesData = new WeakMap();
	}

	public function getNodeData(node:Dynamic):Dynamic {
		return this.nodesData.get(node);
	}

	public function setNodeData(node:Dynamic, data:Dynamic):Void {
		this.nodesData.set(node, data);
	}

}