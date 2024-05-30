import three.examples.jsm.nodes.core.NodeUpdateType;

class NodeFrame {

	public var time(default, null):Float;
	public var deltaTime(default, null):Float;

	public var frameId(default, null):Int;
	public var renderId(default, null):Int;

	public var startTime(default, null):Null<Float>;

	public var updateMap(default, null):haxe.ds.WeakMap<Dynamic, Dynamic>;
	public var updateBeforeMap(default, null):haxe.ds.WeakMap<Dynamic, Dynamic>;

	public var renderer(default, null):Null<Dynamic>;
	public var material(default, null):Null<Dynamic>;
	public var camera(default, null):Null<Dynamic>;
	public var object(default, null):Null<Dynamic>;
	public var scene(default, null):Null<Dynamic>;

	public function new() {

		this.time = 0;
		this.deltaTime = 0;

		this.frameId = 0;
		this.renderId = 0;

		this.startTime = null;

		this.updateMap = new haxe.ds.WeakMap();
		this.updateBeforeMap = new haxe.ds.WeakMap();

		this.renderer = null;
		this.material = null;
		this.camera = null;
		this.object = null;
		this.scene = null;

	}

	private function _getMaps( referenceMap:haxe.ds.WeakMap<Dynamic, Dynamic>, nodeRef:Dynamic ):Dynamic {

		var maps = referenceMap.get( nodeRef );

		if ( maps === null ) {

			maps = {
				renderMap: new haxe.ds.WeakMap(),
				frameMap: new haxe.ds.WeakMap()
			};

			referenceMap.set( nodeRef, maps );

		}

		return maps;

	}

	public function updateBeforeNode( node:Dynamic ) {

		var updateType = node.getUpdateBeforeType();
		var reference = node.updateReference( this );

		if ( updateType === NodeUpdateType.FRAME ) {

			var { frameMap } = this._getMaps( this.updateBeforeMap, reference );

			if ( frameMap.get( reference ) !== this.frameId ) {

				if ( node.updateBefore( this ) !== false ) {

					frameMap.set( reference, this.frameId );

				}

			}

		} else if ( updateType === NodeUpdateType.RENDER ) {

			var { renderMap } = this._getMaps( this.updateBeforeMap, reference );

			if ( renderMap.get( reference ) !== this.renderId ) {

				if ( node.updateBefore( this ) !== false ) {

					renderMap.set( reference, this.renderId );

				}

			}

		} else if ( updateType === NodeUpdateType.OBJECT ) {

			node.updateBefore( this );

		}

	}

	public function updateNode( node:Dynamic ) {

		var updateType = node.getUpdateType();
		var reference = node.updateReference( this );

		if ( updateType === NodeUpdateType.FRAME ) {

			var { frameMap } = this._getMaps( this.updateMap, reference );

			if ( frameMap.get( reference ) !== this.frameId ) {

				if ( node.update( this ) !== false ) {

					frameMap.set( reference, this.frameId );

				}

			}

		} else if ( updateType === NodeUpdateType.RENDER ) {

			var { renderMap } = this._getMaps( this.updateMap, reference );

			if ( renderMap.get( reference ) !== this.renderId ) {

				if ( node.update( this ) !== false ) {

					renderMap.set( reference, this.renderId );

				}

			}

		} else if ( updateType === NodeUpdateType.OBJECT ) {

			node.update( this );

		}

	}

	public function update() {

		this.frameId++;

		if ( this.lastTime === null ) this.lastTime = Date.now();

		this.deltaTime = ( Date.now() - this.lastTime ) / 1000;

		this.lastTime = Date.now();

		this.time += this.deltaTime;

	}

}