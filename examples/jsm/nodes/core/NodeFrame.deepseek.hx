import js.Browser.performance;

class NodeFrame {

	var time:Float;
	var deltaTime:Float;

	var frameId:Int;
	var renderId:Int;

	var startTime:Null<Float>;

	var updateMap:WeakMap<Dynamic->{frameMap:WeakMap<Dynamic, Int>, renderMap:WeakMap<Dynamic, Int>}>;
	var updateBeforeMap:WeakMap<Dynamic->{frameMap:WeakMap<Dynamic, Int>, renderMap:WeakMap<Dynamic, Int>}>;

	var renderer:Null<Dynamic>;
	var material:Null<Dynamic>;
	var camera:Null<Dynamic>;
	var object:Null<Dynamic>;
	var scene:Null<Dynamic>;

	public function new() {

		this.time = 0;
		this.deltaTime = 0;

		this.frameId = 0;
		this.renderId = 0;

		this.startTime = null;

		this.updateMap = new WeakMap();
		this.updateBeforeMap = new WeakMap();

		this.renderer = null;
		this.material = null;
		this.camera = null;
		this.object = null;
		this.scene = null;

	}

	private function _getMaps( referenceMap:WeakMap<Dynamic->{frameMap:WeakMap<Dynamic, Int>, renderMap:WeakMap<Dynamic, Int>}>, nodeRef:Dynamic ) {

		var maps = referenceMap.get( nodeRef );

		if ( maps === undefined ) {

			maps = {
				renderMap: new WeakMap(),
				frameMap: new WeakMap()
			};

			referenceMap.set( nodeRef, maps );

		}

		return maps;

	}

	public function updateBeforeNode( node:Dynamic ) {

		var updateType = node.getUpdateBeforeType();
		var reference = node.updateReference( this );

		if ( updateType == NodeUpdateType.FRAME ) {

			var { frameMap } = this._getMaps( this.updateBeforeMap, reference );

			if ( frameMap.get( reference ) !== this.frameId ) {

				if ( node.updateBefore( this ) !== false ) {

					frameMap.set( reference, this.frameId );

				}

			}

		} else if ( updateType == NodeUpdateType.RENDER ) {

			var { renderMap } = this._getMaps( this.updateBeforeMap, reference );

			if ( renderMap.get( reference ) !== this.renderId ) {

				if ( node.updateBefore( this ) !== false ) {

					renderMap.set( reference, this.renderId );

				}

			}

		} else if ( updateType == NodeUpdateType.OBJECT ) {

			node.updateBefore( this );

		}

	}

	public function updateNode( node:Dynamic ) {

		var updateType = node.getUpdateType();
		var reference = node.updateReference( this );

		if ( updateType == NodeUpdateType.FRAME ) {

			var { frameMap } = this._getMaps( this.updateMap, reference );

			if ( frameMap.get( reference ) !== this.frameId ) {

				if ( node.update( this ) !== false ) {

					frameMap.set( reference, this.frameId );

				}

			}

		} else if ( updateType == NodeUpdateType.RENDER ) {

			var { renderMap } = this._getMaps( this.updateMap, reference );

			if ( renderMap.get( reference ) !== this.renderId ) {

				if ( node.update( this ) !== false ) {

					renderMap.set( reference, this.renderId );

				}

			}

		} else if ( updateType == NodeUpdateType.OBJECT ) {

			node.update( this );

		}

	}

	public function update() {

		this.frameId ++;

		if ( this.lastTime === undefined ) this.lastTime = performance.now();

		this.deltaTime = ( performance.now() - this.lastTime ) / 1000;

		this.lastTime = performance.now();

		this.time += this.deltaTime;

	}

}