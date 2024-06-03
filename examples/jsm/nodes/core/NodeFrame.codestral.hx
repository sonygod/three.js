import Node;
import NodeUpdateType;

class NodeFrame {

	public var time:Float = 0;
	public var deltaTime:Float = 0;

	public var frameId:Int = 0;
	public var renderId:Int = 0;

	public var startTime:Float = null;

	public var updateMap:haxe.ds.WeakMap<Node, Dynamic> = new haxe.ds.WeakMap<Node, Dynamic>();
	public var updateBeforeMap:haxe.ds.WeakMap<Node, Dynamic> = new haxe.ds.WeakMap<Node, Dynamic>();

	public var renderer:Dynamic = null;
	public var material:Dynamic = null;
	public var camera:Dynamic = null;
	public var object:Dynamic = null;
	public var scene:Dynamic = null;

	public var lastTime:Float;

	public function _getMaps(referenceMap:haxe.ds.WeakMap<Node, Dynamic>, nodeRef:Node):Dynamic {

		var maps:Dynamic = referenceMap.get(nodeRef);

		if (maps == null) {

			maps = {
				renderMap: new haxe.ds.WeakMap<Node, Int>(),
				frameMap: new haxe.ds.WeakMap<Node, Int>()
			};

			referenceMap.set(nodeRef, maps);

		}

		return maps;

	}

	public function updateBeforeNode(node:Node) {

		var updateType:NodeUpdateType = node.getUpdateBeforeType();
		var reference:Node = node.updateReference(this);

		if (updateType == NodeUpdateType.FRAME) {

			var maps:Dynamic = this._getMaps(this.updateBeforeMap, reference);
			var frameMap:haxe.ds.WeakMap<Node, Int> = cast maps.frameMap;

			if (frameMap.get(reference) != this.frameId) {

				if (node.updateBefore(this) != false) {

					frameMap.set(reference, this.frameId);

				}

			}

		} else if (updateType == NodeUpdateType.RENDER) {

			var maps:Dynamic = this._getMaps(this.updateBeforeMap, reference);
			var renderMap:haxe.ds.WeakMap<Node, Int> = cast maps.renderMap;

			if (renderMap.get(reference) != this.renderId) {

				if (node.updateBefore(this) != false) {

					renderMap.set(reference, this.renderId);

				}

			}

		} else if (updateType == NodeUpdateType.OBJECT) {

			node.updateBefore(this);

		}

	}

	public function updateNode(node:Node) {

		var updateType:NodeUpdateType = node.getUpdateType();
		var reference:Node = node.updateReference(this);

		if (updateType == NodeUpdateType.FRAME) {

			var maps:Dynamic = this._getMaps(this.updateMap, reference);
			var frameMap:haxe.ds.WeakMap<Node, Int> = cast maps.frameMap;

			if (frameMap.get(reference) != this.frameId) {

				if (node.update(this) != false) {

					frameMap.set(reference, this.frameId);

				}

			}

		} else if (updateType == NodeUpdateType.RENDER) {

			var maps:Dynamic = this._getMaps(this.updateMap, reference);
			var renderMap:haxe.ds.WeakMap<Node, Int> = cast maps.renderMap;

			if (renderMap.get(reference) != this.renderId) {

				if (node.update(this) != false) {

					renderMap.set(reference, this.renderId);

				}

			}

		} else if (updateType == NodeUpdateType.OBJECT) {

			node.update(this);

		}

	}

	public function update() {

		this.frameId++;

		if (this.lastTime == null) this.lastTime = js.Date.now();

		this.deltaTime = (js.Date.now() - this.lastTime) / 1000;

		this.lastTime = js.Date.now();

		this.time += this.deltaTime;

	}

}