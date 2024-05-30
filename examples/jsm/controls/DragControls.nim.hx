import EventDispatcher.EventDispatcher;
import Matrix4.Matrix4;
import Plane.Plane;
import Raycaster.Raycaster;
import Vector2.Vector2;
import Vector3.Vector3;

class DragControls extends EventDispatcher {

	public var _plane:Plane;
	public var _raycaster:Raycaster;
	public var _pointer:Vector2;
	public var _offset:Vector3;
	public var _diff:Vector2;
	public var _previousPointer:Vector2;
	public var _intersection:Vector3;
	public var _worldPosition:Vector3;
	public var _inverseMatrix:Matrix4;
	public var _up:Vector3;
	public var _right:Vector3;

	public var mode:String;
	public var rotateSpeed:Float;

	public var _selected:Dynamic;
	public var _hovered:Dynamic;
	public var _intersections:Array<Dynamic>;

	public function new( _objects:Array<Dynamic>, _camera:Dynamic, _domElement:Dynamic ) {

		super();

		_domElement.style.touchAction = 'none'; // disable touch scroll

		_selected = null;
		_hovered = null;

		_intersections = [];

		mode = 'translate';

		rotateSpeed = 1;

		_plane = new Plane();
		_raycaster = new Raycaster();
		_pointer = new Vector2();
		_offset = new Vector3();
		_diff = new Vector2();
		_previousPointer = new Vector2();
		_intersection = new Vector3();
		_worldPosition = new Vector3();
		_inverseMatrix = new Matrix4();
		_up = new Vector3();
		_right = new Vector3();

		var scope = this;

		function activate() {

			_domElement.addEventListener( 'pointermove', onPointerMove );
			_domElement.addEventListener( 'pointerdown', onPointerDown );
			_domElement.addEventListener( 'pointerup', onPointerCancel );
			_domElement.addEventListener( 'pointerleave', onPointerCancel );

		}

		function deactivate() {

			_domElement.removeEventListener( 'pointermove', onPointerMove );
			_domElement.removeEventListener( 'pointerdown', onPointerDown );
			_domElement.removeEventListener( 'pointerup', onPointerCancel );
			_domElement.removeEventListener( 'pointerleave', onPointerCancel );

			_domElement.style.cursor = '';

		}

		function dispose() {

			deactivate();

		}

		function getObjects() {

			return _objects;

		}

		function setObjects( objects ) {

			_objects = objects;

		}

		function getRaycaster() {

			return _raycaster;

		}

		function onPointerMove( event ) {

			if ( scope.enabled === false ) return;

			updatePointer( event );

			_raycaster.setFromCamera( _pointer, _camera );

			if ( _selected ) {

				if ( scope.mode === 'translate' ) {

					if ( _raycaster.ray.intersectPlane( _plane, _intersection ) ) {

						_selected.position.copy( _intersection.sub( _offset ).applyMatrix4( _inverseMatrix ) );

					}

				} else if ( scope.mode === 'rotate' ) {

					_diff.subVectors( _pointer, _previousPointer ).multiplyScalar( scope.rotateSpeed );
					_selected.rotateOnWorldAxis( _up, _diff.x );
					_selected.rotateOnWorldAxis( _right.normalize(), - _diff.y );

				}

				scope.dispatchEvent( { type: 'drag', object: _selected } );

				_previousPointer.copy( _pointer );

			} else {

				// hover support

				if ( event.pointerType === 'mouse' || event.pointerType === 'pen' ) {

					_intersections.length = 0;

					_raycaster.setFromCamera( _pointer, _camera );
					_raycaster.intersectObjects( _objects, scope.recursive, _intersections );

					if ( _intersections.length > 0 ) {

						var object = _intersections[ 0 ].object;

						_plane.setFromNormalAndCoplanarPoint( _camera.getWorldDirection( _plane.normal ), _worldPosition.setFromMatrixPosition( object.matrixWorld ) );

						if ( _hovered !== object && _hovered !== null ) {

							scope.dispatchEvent( { type: 'hoveroff', object: _hovered } );

							_domElement.style.cursor = 'auto';
							_hovered = null;

						}

						if ( _hovered !== object ) {

							scope.dispatchEvent( { type: 'hoveron', object: object } );

							_domElement.style.cursor = 'pointer';
							_hovered = object;

						}

					} else {

						if ( _hovered !== null ) {

							scope.dispatchEvent( { type: 'hoveroff', object: _hovered } );

							_domElement.style.cursor = 'auto';
							_hovered = null;

						}

					}

				}

			}

			_previousPointer.copy( _pointer );

		}

		function onPointerDown( event ) {

			if ( scope.enabled === false ) return;

			updatePointer( event );

			_intersections.length = 0;

			_raycaster.setFromCamera( _pointer, _camera );
			_raycaster.intersectObjects( _objects, scope.recursive, _intersections );

			if ( _intersections.length > 0 ) {

				if ( scope.transformGroup === true ) {

					// look for the outermost group in the object's upper hierarchy

					_selected = findGroup( _intersections[ 0 ].object );

				} else {

					_selected = _intersections[ 0 ].object;

				}

				_plane.setFromNormalAndCoplanarPoint( _camera.getWorldDirection( _plane.normal ), _worldPosition.setFromMatrixPosition( _selected.matrixWorld ) );

				if ( _raycaster.ray.intersectPlane( _plane, _intersection ) ) {

					if ( scope.mode === 'translate' ) {

						_inverseMatrix.copy( _selected.parent.matrixWorld ).invert();
						_offset.copy( _intersection ).sub( _worldPosition.setFromMatrixPosition( _selected.matrixWorld ) );

					} else if ( scope.mode === 'rotate' ) {

						// the controls only support Y+ up
						_up.set( 0, 1, 0 ).applyQuaternion( _camera.quaternion ).normalize();
						_right.set( 1, 0, 0 ).applyQuaternion( _camera.quaternion ).normalize();

					}

				}

				_domElement.style.cursor = 'move';

				scope.dispatchEvent( { type: 'dragstart', object: _selected } );

			}

			_previousPointer.copy( _pointer );

		}

		function onPointerCancel() {

			if ( scope.enabled === false ) return;

			if ( _selected ) {

				scope.dispatchEvent( { type: 'dragend', object: _selected } );

				_selected = null;

			}

			_domElement.style.cursor = _hovered ? 'pointer' : 'auto';

		}

		function updatePointer( event ) {

			var rect = _domElement.getBoundingClientRect();

			_pointer.x = ( event.clientX - rect.left ) / rect.width * 2 - 1;
			_pointer.y = - ( event.clientY - rect.top ) / rect.height * 2 + 1;

		}

		function findGroup( obj, group = null ) {

			if ( obj.isGroup ) group = obj;

			if ( obj.parent === null ) return group;

			return findGroup( obj.parent, group );

		}

		activate();

		// API

		this.enabled = true;
		this.recursive = true;
		this.transformGroup = false;

		this.activate = activate;
		this.deactivate = deactivate;
		this.dispose = dispose;
		this.getObjects = getObjects;
		this.getRaycaster = getRaycaster;
		this.setObjects = setObjects;

	}

}