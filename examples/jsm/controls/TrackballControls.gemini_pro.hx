import three.core.EventDispatcher;
import three.math.MathUtils;
import three.math.Quaternion;
import three.math.Vector2;
import three.math.Vector3;
import three.constants.MOUSE;

class TrackballControls extends EventDispatcher {
	public var object:three.core.Object3D;
	public var domElement:html.Element;
	public var enabled:Bool = true;

	public var screen: { left:Float, top:Float, width:Float, height:Float } = { left:0, top:0, width:0, height:0 };

	public var rotateSpeed:Float = 1.0;
	public var zoomSpeed:Float = 1.2;
	public var panSpeed:Float = 0.3;

	public var noRotate:Bool = false;
	public var noZoom:Bool = false;
	public var noPan:Bool = false;

	public var staticMoving:Bool = false;
	public var dynamicDampingFactor:Float = 0.2;

	public var minDistance:Float = 0;
	public var maxDistance:Float = Infinity;

	public var minZoom:Float = 0;
	public var maxZoom:Float = Infinity;

	public var keys:Array<String> = ['KeyA', 'KeyS', 'KeyD'];

	public var mouseButtons: { LEFT:Int, MIDDLE:Int, RIGHT:Int } = { LEFT:MOUSE.ROTATE, MIDDLE:MOUSE.DOLLY, RIGHT:MOUSE.PAN };

	private var _state:Int = -1;
	private var _keyState:Int = -1;

	private var _touchZoomDistanceStart:Float = 0;
	private var _touchZoomDistanceEnd:Float = 0;

	private var _lastAngle:Float = 0;

	private var _eye:Vector3 = new Vector3();
	private var _movePrev:Vector2 = new Vector2();
	private var _moveCurr:Vector2 = new Vector2();
	private var _lastAxis:Vector3 = new Vector3();
	private var _zoomStart:Vector2 = new Vector2();
	private var _zoomEnd:Vector2 = new Vector2();
	private var _panStart:Vector2 = new Vector2();
	private var _panEnd:Vector2 = new Vector2();

	private var _pointers:Array<html.PointerEvent> = [];
	private var _pointerPositions:Map<Int, Vector2> = new Map();

	public var target:Vector3 = new Vector3();
	public var target0:Vector3 = new Vector3();
	public var position0:Vector3 = new Vector3();
	public var up0:Vector3 = new Vector3();
	public var zoom0:Float = 0;

	public function new(object:three.core.Object3D, domElement:html.Element) {
		super();
		this.object = object;
		this.domElement = domElement;
		domElement.style.touchAction = 'none';
		this.target0 = target.clone();
		this.position0 = object.position.clone();
		this.up0 = object.up.clone();
		this.zoom0 = object.zoom;

		domElement.addEventListener('contextmenu', contextmenu);
		domElement.addEventListener('pointerdown', onPointerDown);
		domElement.addEventListener('pointercancel', onPointerCancel);
		domElement.addEventListener('wheel', onMouseWheel, {passive: false});
		window.addEventListener('keydown', keydown);
		window.addEventListener('keyup', keyup);
		handleResize();
		update();
	}

	public function handleResize() {
		var box = domElement.getBoundingClientRect();
		var d = domElement.ownerDocument.documentElement;
		screen.left = box.left + window.pageXOffset - d.clientLeft;
		screen.top = box.top + window.pageYOffset - d.clientTop;
		screen.width = box.width;
		screen.height = box.height;
	}

	private function getMouseOnScreen(pageX:Float, pageY:Float):Vector2 {
		var vector = new Vector2();
		vector.set(
			( pageX - screen.left ) / screen.width,
			( pageY - screen.top ) / screen.height
		);
		return vector;
	}

	private function getMouseOnCircle(pageX:Float, pageY:Float):Vector2 {
		var vector = new Vector2();
		vector.set(
			( ( pageX - screen.width * 0.5 - screen.left ) / ( screen.width * 0.5 ) ),
			( ( screen.height + 2 * ( screen.top - pageY ) ) / screen.width ) // screen.width intentional
		);
		return vector;
	}

	private function rotateCamera() {
		var axis = new Vector3();
		var quaternion = new Quaternion();
		var eyeDirection = new Vector3();
		var objectUpDirection = new Vector3();
		var objectSidewaysDirection = new Vector3();
		var moveDirection = new Vector3();
		moveDirection.set( _moveCurr.x - _movePrev.x, _moveCurr.y - _movePrev.y, 0 );
		var angle = moveDirection.length();
		if ( angle ) {
			_eye.copy( object.position ).sub( target );
			eyeDirection.copy( _eye ).normalize();
			objectUpDirection.copy( object.up ).normalize();
			objectSidewaysDirection.crossVectors( objectUpDirection, eyeDirection ).normalize();
			objectUpDirection.setLength( _moveCurr.y - _movePrev.y );
			objectSidewaysDirection.setLength( _moveCurr.x - _movePrev.x );
			moveDirection.copy( objectUpDirection.add( objectSidewaysDirection ) );
			axis.crossVectors( moveDirection, _eye ).normalize();
			angle *= rotateSpeed;
			quaternion.setFromAxisAngle( axis, angle );
			_eye.applyQuaternion( quaternion );
			object.up.applyQuaternion( quaternion );
			_lastAxis.copy( axis );
			_lastAngle = angle;
		} else if ( ! staticMoving && _lastAngle ) {
			_lastAngle *= Math.sqrt( 1.0 - dynamicDampingFactor );
			_eye.copy( object.position ).sub( target );
			quaternion.setFromAxisAngle( _lastAxis, _lastAngle );
			_eye.applyQuaternion( quaternion );
			object.up.applyQuaternion( quaternion );
		}
		_movePrev.copy( _moveCurr );
	}

	private function zoomCamera() {
		var factor:Float;
		if ( _state == 4 ) {
			factor = _touchZoomDistanceStart / _touchZoomDistanceEnd;
			_touchZoomDistanceStart = _touchZoomDistanceEnd;
			if ( object.isPerspectiveCamera ) {
				_eye.multiplyScalar( factor );
			} else if ( object.isOrthographicCamera ) {
				object.zoom = MathUtils.clamp( object.zoom / factor, minZoom, maxZoom );
				if ( object.zoom != zoom0 ) {
					object.updateProjectionMatrix();
				}
			} else {
				trace('THREE.TrackballControls: Unsupported camera type');
			}
		} else {
			factor = 1.0 + ( _zoomEnd.y - _zoomStart.y ) * zoomSpeed;
			if ( factor != 1.0 && factor > 0.0 ) {
				if ( object.isPerspectiveCamera ) {
					_eye.multiplyScalar( factor );
				} else if ( object.isOrthographicCamera ) {
					object.zoom = MathUtils.clamp( object.zoom / factor, minZoom, maxZoom );
					if ( object.zoom != zoom0 ) {
						object.updateProjectionMatrix();
					}
				} else {
					trace('THREE.TrackballControls: Unsupported camera type');
				}
			}
			if ( staticMoving ) {
				_zoomStart.copy( _zoomEnd );
			} else {
				_zoomStart.y += ( _zoomEnd.y - _zoomStart.y ) * dynamicDampingFactor;
			}
		}
	}

	private function panCamera() {
		var mouseChange = new Vector2();
		var objectUp = new Vector3();
		var pan = new Vector3();
		mouseChange.copy( _panEnd ).sub( _panStart );
		if ( mouseChange.lengthSq() ) {
			if ( object.isOrthographicCamera ) {
				var scale_x = ( object.right - object.left ) / object.zoom / domElement.clientWidth;
				var scale_y = ( object.top - object.bottom ) / object.zoom / domElement.clientWidth;
				mouseChange.x *= scale_x;
				mouseChange.y *= scale_y;
			}
			mouseChange.multiplyScalar( _eye.length() * panSpeed );
			pan.copy( _eye ).cross( object.up ).setLength( mouseChange.x );
			pan.add( objectUp.copy( object.up ).setLength( mouseChange.y ) );
			object.position.add( pan );
			target.add( pan );
			if ( staticMoving ) {
				_panStart.copy( _panEnd );
			} else {
				_panStart.add( mouseChange.subVectors( _panEnd, _panStart ).multiplyScalar( dynamicDampingFactor ) );
			}
		}
	}

	private function checkDistances() {
		if ( ! noZoom || ! noPan ) {
			if ( _eye.lengthSq() > maxDistance * maxDistance ) {
				object.position.addVectors( target, _eye.setLength( maxDistance ) );
				_zoomStart.copy( _zoomEnd );
			}
			if ( _eye.lengthSq() < minDistance * minDistance ) {
				object.position.addVectors( target, _eye.setLength( minDistance ) );
				_zoomStart.copy( _zoomEnd );
			}
		}
	}

	public function update() {
		_eye.subVectors( object.position, target );
		if ( ! noRotate ) {
			rotateCamera();
		}
		if ( ! noZoom ) {
			zoomCamera();
		}
		if ( ! noPan ) {
			panCamera();
		}
		object.position.addVectors( target, _eye );
		if ( object.isPerspectiveCamera ) {
			checkDistances();
			object.lookAt( target );
			if ( object.position.distanceToSquared( object.position ) > 0.000001 ) {
				dispatchEvent({type: 'change'});
				object.position.copy( object.position );
			}
		} else if ( object.isOrthographicCamera ) {
			object.lookAt( target );
			if ( object.position.distanceToSquared( object.position ) > 0.000001 || object.zoom != zoom0 ) {
				dispatchEvent({type: 'change'});
				object.position.copy( object.position );
				object.zoom = zoom0;
			}
		} else {
			trace('THREE.TrackballControls: Unsupported camera type');
		}
	}

	public function reset() {
		_state = -1;
		_keyState = -1;
		target.copy( target0 );
		object.position.copy( position0 );
		object.up.copy( up0 );
		object.zoom = zoom0;
		object.updateProjectionMatrix();
		_eye.subVectors( object.position, target );
		object.lookAt( target );
		dispatchEvent({type: 'change'});
		object.position.copy( object.position );
		object.zoom = zoom0;
	}

	private function onPointerDown(event:html.PointerEvent) {
		if ( ! enabled ) return;
		if ( _pointers.length == 0 ) {
			domElement.setPointerCapture(event.pointerId);
			domElement.addEventListener('pointermove', onPointerMove);
			domElement.addEventListener('pointerup', onPointerUp);
		}
		addPointer(event);
		if ( event.pointerType == 'touch' ) {
			onTouchStart(event);
		} else {
			onMouseDown(event);
		}
	}

	private function onPointerMove(event:html.PointerEvent) {
		if ( ! enabled ) return;
		if ( event.pointerType == 'touch' ) {
			onTouchMove(event);
		} else {
			onMouseMove(event);
		}
	}

	private function onPointerUp(event:html.PointerEvent) {
		if ( ! enabled ) return;
		if ( event.pointerType == 'touch' ) {
			onTouchEnd(event);
		} else {
			onMouseUp();
		}
		removePointer(event);
		if ( _pointers.length == 0 ) {
			domElement.releasePointerCapture(event.pointerId);
			domElement.removeEventListener('pointermove', onPointerMove);
			domElement.removeEventListener('pointerup', onPointerUp);
		}
	}

	private function onPointerCancel(event:html.PointerEvent) {
		removePointer(event);
	}

	private function keydown(event:html.KeyboardEvent) {
		if ( ! enabled ) return;
		window.removeEventListener('keydown', keydown);
		if ( _keyState != -1 ) {
			return;
		} else if ( event.code == keys[0] && ! noRotate ) {
			_keyState = 0;
		} else if ( event.code == keys[1] && ! noZoom ) {
			_keyState = 1;
		} else if ( event.code == keys[2] && ! noPan ) {
			_keyState = 2;
		}
	}

	private function keyup() {
		if ( ! enabled ) return;
		_keyState = -1;
		window.addEventListener('keydown', keydown);
	}

	private function onMouseDown(event:html.MouseEvent) {
		if ( _state == -1 ) {
			switch ( event.button ) {
				case 0:
					_state = 0;
					break;
				case 1:
					_state = 1;
					break;
				case 2:
					_state = 2;
					break;
			}
		}
		var state = ( _keyState != -1 ) ? _keyState : _state;
		if ( state == 0 && ! noRotate ) {
			_moveCurr.copy( getMouseOnCircle( event.pageX, event.pageY ) );
			_movePrev.copy( _moveCurr );
		} else if ( state == 1 && ! noZoom ) {
			_zoomStart.copy( getMouseOnScreen( event.pageX, event.pageY ) );
			_zoomEnd.copy( _zoomStart );
		} else if ( state == 2 && ! noPan ) {
			_panStart.copy( getMouseOnScreen( event.pageX, event.pageY ) );
			_panEnd.copy( _panStart );
		}
		dispatchEvent({type: 'start'});
	}

	private function onMouseMove(event:html.MouseEvent) {
		var state = ( _keyState != -1 ) ? _keyState : _state;
		if ( state == 0 && ! noRotate ) {
			_movePrev.copy( _moveCurr );
			_moveCurr.copy( getMouseOnCircle( event.pageX, event.pageY ) );
		} else if ( state == 1 && ! noZoom ) {
			_zoomEnd.copy( getMouseOnScreen( event.pageX, event.pageY ) );
		} else if ( state == 2 && ! noPan ) {
			_panEnd.copy( getMouseOnScreen( event.pageX, event.pageY ) );
		}
	}

	private function onMouseUp() {
		_state = -1;
		dispatchEvent({type: 'end'});
	}

	private function onMouseWheel(event:html.WheelEvent) {
		if ( ! enabled ) return;
		if ( noZoom ) return;
		event.preventDefault();
		switch ( event.deltaMode ) {
			case 2:
				_zoomStart.y -= event.deltaY * 0.025;
				break;
			case 1:
				_zoomStart.y -= event.deltaY * 0.01;
				break;
			default:
				_zoomStart.y -= event.deltaY * 0.00025;
				break;
		}
		dispatchEvent({type: 'start'});
		dispatchEvent({type: 'end'});
	}

	private function onTouchStart(event:html.PointerEvent) {
		trackPointer(event);
		switch ( _pointers.length ) {
			case 1:
				_state = 3;
				_moveCurr.copy( getMouseOnCircle( _pointers[0].pageX, _pointers[0].pageY ) );
				_movePrev.copy( _moveCurr );
				break;
			default:
				_state = 4;
				var dx = _pointers[0].pageX - _pointers[1].pageX;
				var dy = _pointers[0].pageY - _pointers[1].pageY;
				_touchZoomDistanceEnd = _touchZoomDistanceStart = Math.sqrt( dx * dx + dy * dy );
				var x = ( _pointers[0].pageX + _pointers[1].pageX ) / 2;
				var y = ( _pointers[0].pageY + _pointers[1].pageY ) / 2;
				_panStart.copy( getMouseOnScreen( x, y ) );
				_panEnd.copy( _panStart );
				break;
		}
		dispatchEvent({type: 'start'});
	}

	private function onTouchMove(event:html.PointerEvent) {
		trackPointer(event);
		switch ( _pointers.length ) {
			case 1:
				_movePrev.copy( _moveCurr );
				_moveCurr.copy( getMouseOnCircle( event.pageX, event.pageY ) );
				break;
			default:
				var position = getSecondPointerPosition(event);
				var dx = event.pageX - position.x;
				var dy = event.pageY - position.y;
				_touchZoomDistanceEnd = Math.sqrt( dx * dx + dy * dy );
				var x = ( event.pageX + position.x ) / 2;
				var y = ( event.pageY + position.y ) / 2;
				_panEnd.copy( getMouseOnScreen( x, y ) );
				break;
		}
	}

	private function onTouchEnd(event:html.PointerEvent) {
		switch ( _pointers.length ) {
			case 0:
				_state = -1;
				break;
			case 1:
				_state = 3;
				_moveCurr.copy( getMouseOnCircle( event.pageX, event.pageY ) );
				_movePrev.copy( _moveCurr );
				break;
			case 2:
				_state = 4;
				for ( i in 0..._pointers.length ) {
					if ( _pointers[i].pointerId != event.pointerId ) {
						var position = _pointerPositions.get(_pointers[i].pointerId);
						_moveCurr.copy( getMouseOnCircle( position.x, position.y ) );
						_movePrev.copy( _moveCurr );
						break;
					}
				}
				break;
		}
		dispatchEvent({type: 'end'});
	}

	private function contextmenu(event:html.MouseEvent) {
		if ( ! enabled ) return;
		event.preventDefault();
	}

	private function addPointer(event:html.PointerEvent) {
		_pointers.push(event);
	}

	private function removePointer(event:html.PointerEvent) {
		_pointerPositions.remove(event.pointerId);
		for ( i in 0..._pointers.length ) {
			if ( _pointers[i].pointerId == event.pointerId ) {
				_pointers.splice(i, 1);
				return;
			}
		}
	}

	private function trackPointer(event:html.PointerEvent) {
		var position = _pointerPositions.get(event.pointerId);
		if ( position == null ) {
			position = new Vector2();
			_pointerPositions.set(event.pointerId, position);
		}
		position.set(event.pageX, event.pageY);
	}

	private function getSecondPointerPosition(event:html.PointerEvent):Vector2 {
		var pointer = ( event.pointerId == _pointers[0].pointerId ) ? _pointers[1] : _pointers[0];
		return _pointerPositions.get(pointer.pointerId);
	}

	public function dispose() {
		domElement.removeEventListener('contextmenu', contextmenu);
		domElement.removeEventListener('pointerdown', onPointerDown);
		domElement.removeEventListener('pointercancel', onPointerCancel);
		domElement.removeEventListener('wheel', onMouseWheel);
		domElement.removeEventListener('pointermove', onPointerMove);
		domElement.removeEventListener('pointerup', onPointerUp);
		window.removeEventListener('keydown', keydown);
		window.removeEventListener('keyup', keyup);
	}
}