import three.Matrix4;
import three.Vector3;
import three.Vector2;
import three.Quaternion;
import three.Sphere;
import three.Box3;
import three.Group;
import three.Raycaster;
import three.LineBasicMaterial;
import three.Line;
import three.BufferGeometry;
import three.EllipseCurve;
import three.GridHelper;
import three.MathUtils;
import three.cameras.Camera;
import three.scenes.Scene;
import js.Lib;
import three.events.EventDispatcher;

//trackball state
enum abstract STATE(Int) {

	var IDLE = 0;
	var ROTATE = 1;
	var PAN = 2;
	var SCALE = 3;
	var FOV = 4;
	var FOCUS = 5;
	var ZROTATE = 6;
	var TOUCH_MULTI = 7;
	var ANIMATION_FOCUS = 8;
	var ANIMATION_ROTATE = 9;

}

//input type
enum abstract INPUT(Int) {

	var NONE = 0;
	var ONE_FINGER = 1;
	var ONE_FINGER_SWITCHED = 2;
	var TWO_FINGER = 3;
	var MULT_FINGER = 4;
	var CURSOR = 5;

}

//cursor center coordinates
class _center {

	public static var x:Float = 0;
	public static var y:Float = 0;

}

//transformation matrices for gizmos and camera
class _transformation {

	public static var camera:Matrix4 = new Matrix4();
	public static var gizmos:Matrix4 = new Matrix4();

}

//events
class _changeEvent { 
	public static var type:String = 'change';
}

class _startEvent { 
	public static var type:String = 'start';
}

class _endEvent { 
	public static var type:String = 'end';
}

var _raycaster = new Raycaster();
var _offset = new Vector3();

var _gizmoMatrixStateTemp = new Matrix4();
var _cameraMatrixStateTemp = new Matrix4();
var _scalePointTemp = new Vector3();
/**
 *
 * @param {Camera} camera Virtual camera used in the scene
 * @param {HTMLElement} domElement Renderer's dom element
 * @param {Scene} scene The scene to be rendered
 */

class ArcballControls extends EventDispatcher {

	//camera state
	var _cameraMatrixState:Matrix4;
	var _cameraProjectionState:Matrix4;

	var _fovState:Float;
	var _upState:Vector3;
	var _zoomState:Float;
	var _nearPos:Float;
	var _farPos:Float;

	var _gizmoMatrixState:Matrix4;

	//initial values
	var _up0:Vector3;
	var _zoom0:Float;
	var _fov0:Float;
	var _initialNear:Float;
	var _nearPos0:Float;
	var _initialFar:Float;
	var _farPos0:Float;
	var _cameraMatrixState0:Matrix4;
	var _gizmoMatrixState0:Matrix4;

	//pointers array
	var _button:Int;
	var _touchStart:Array<Dynamic>;
	var _touchCurrent:Array<Dynamic>;
	var _input:Int;

	//two fingers touch interaction
	var _switchSensibility:Int;	//minimum movement to be performed to fire single pan start after the second finger has been released
	var _startFingerDistance:Float; //distance between two fingers
	var _currentFingerDistance:Float;
	var _startFingerRotation:Float; //amount of rotation performed with two fingers
	var _currentFingerRotation:Float;

	//double tap
	var _devPxRatio:Float;
	var _downValid:Bool;
	var _nclicks:Int;
	var _downEvents:Array<Dynamic>;
	var _downStart:Float;	//pointerDown time
	var _clickStart:Float;	//first click time
	var _maxDownTime:Int;
	var _maxInterval:Int;
	var _posThreshold:Int;
	var _movementThreshold:Int;

	//cursor positions
	var _currentCursorPosition:Vector3;
	var _startCursorPosition:Vector3;

	//grid
	var _grid:GridHelper; //grid to be visualized during pan operation
	var _gridPosition:Vector3;

	//gizmos
	var _gizmos:Group;
	var _curvePts:Int;

	//animations
	var _timeStart:Float; //initial time
	var _animationId:Int;

	//focus animation
	public var focusAnimationTime:Int; //duration of focus animation in ms

	//rotate animation
	var _timePrev:Float; //time at which previous rotate operation has been detected
	var _timeCurrent:Float; //time at which current rotate operation has been detected
	var _anglePrev:Float; //angle of previous rotation
	var _angleCurrent:Float; //angle of current rotation
	var _cursorPosPrev:Vector3;	//cursor position when previous rotate operation has been detected
	var _cursorPosCurr:Vector3;//cursor position when current rotate operation has been detected
	var _wPrev:Float; //angular velocity of the previous rotate operation
	var _wCurr:Float; //angular velocity of the current rotate operation

	public var camera:Camera;
	public var domElement:js.html.Element;
	public var scene:Scene;
	public var target:Vector3;

	var _currentTarget:Vector3;

	//parameters
	public var adjustNearFar:Bool;
	public var scaleFactor:Float;	//zoom/distance multiplier
	public var dampingFactor:Float;
	public var wMax:Float;	//maximum angular velocity allowed
	public var enableAnimations:Bool; //if animations should be performed
	public var enableGrid:Bool; //if grid should be showed during pan operation
	public var cursorZoom:Bool;	//if wheel zoom should be cursor centered
	public var minFov:Float;
	public var maxFov:Float;
	public var rotateSpeed:Float;
	
	public var radiusFactor:Float; 

	public var enabled:Bool;
	public var enablePan:Bool;
	public var enableRotate:Bool;
	public var enableZoom:Bool;
	public var enableGizmos:Bool;

	public var minDistance:Float;
	public var maxDistance:Float;
	public var minZoom:Float;
	public var maxZoom:Float;

	//trackball parameters
	var _tbRadius:Float;

	//FSA
	var _state:Int;

	public var mouseActions:Array<Dynamic>;
	var _mouseOp:Dynamic;

	//global vectors and matrices that are used in some operations to avoid creating new objects every time (e.g. every time cursor moves)
	var _v2_1:Vector2;
	var _v3_1:Vector3;
	var _v3_2:Vector3;

	var _m4_1:Matrix4;
	var _m4_2:Matrix4;

	var _quat:Quaternion;

	//transformation matrices
	var _translationMatrix:Matrix4; //matrix for translation operation
	var _rotationMatrix:Matrix4; //matrix for rotation operation
	var _scaleMatrix:Matrix4; //matrix for scaling operation

	var _rotationAxis:Vector3; //axis for rotate operation

	public function new( camera:Camera, domElement:js.html.Element, scene:Scene = null ) {

		super();
		this.camera = null;
		this.domElement = domElement;
		this.scene = scene;
		this.target = new Vector3();
		this._currentTarget = new Vector3();
		this.radiusFactor = 0.67;

		this.mouseActions = [];
		this._mouseOp = null;


		//global vectors and matrices that are used in some operations to avoid creating new objects every time (e.g. every time cursor moves)
		this._v2_1 = new Vector2();
		this._v3_1 = new Vector3();
		this._v3_2 = new Vector3();

		this._m4_1 = new Matrix4();
		this._m4_2 = new Matrix4();

		this._quat = new Quaternion();

		//transformation matrices
		this._translationMatrix = new Matrix4(); //matrix for translation operation
		this._rotationMatrix = new Matrix4(); //matrix for rotation operation
		this._scaleMatrix = new Matrix4(); //matrix for scaling operation

		this._rotationAxis = new Vector3(); //axis for rotate operation


		//camera state
		this._cameraMatrixState = new Matrix4();
		this._cameraProjectionState = new Matrix4();

		this._fovState = 1;
		this._upState = new Vector3();
		this._zoomState = 1;
		this._nearPos = 0;
		this._farPos = 0;

		this._gizmoMatrixState = new Matrix4();

		//initial values
		this._up0 = new Vector3();
		this._zoom0 = 1;
		this._fov0 = 0;
		this._initialNear = 0;
		this._nearPos0 = 0;
		this._initialFar = 0;
		this._farPos0 = 0;
		this._cameraMatrixState0 = new Matrix4();
		this._gizmoMatrixState0 = new Matrix4();

		//pointers array
		this._button = - 1;
		this._touchStart = [];
		this._touchCurrent = [];
		this._input = INPUT.NONE;

		//two fingers touch interaction
		this._switchSensibility = 32;	//minimum movement to be performed to fire single pan start after the second finger has been released
		this._startFingerDistance = 0; //distance between two fingers
		this._currentFingerDistance = 0;
		this._startFingerRotation = 0; //amount of rotation performed with two fingers
		this._currentFingerRotation = 0;

		//double tap
		this._devPxRatio = 0;
		this._downValid = true;
		this._nclicks = 0;
		this._downEvents = [];
		this._downStart = 0;	//pointerDown time
		this._clickStart = 0;	//first click time
		this._maxDownTime = 250;
		this._maxInterval = 300;
		this._posThreshold = 24;
		this._movementThreshold = 24;

		//cursor positions
		this._currentCursorPosition = new Vector3();
		this._startCursorPosition = new Vector3();

		//grid
		this._grid = null; //grid to be visualized during pan operation
		this._gridPosition = new Vector3();

		//gizmos
		this._gizmos = new Group();
		this._curvePts = 128;


		//animations
		this._timeStart = - 1; //initial time
		this._animationId = - 1;

		//focus animation
		this.focusAnimationTime = 500; //duration of focus animation in ms

		//rotate animation
		this._timePrev = 0; //time at which previous rotate operation has been detected
		this._timeCurrent = 0; //time at which current rotate operation has been detected
		this._anglePrev = 0; //angle of previous rotation
		this._angleCurrent = 0; //angle of current rotation
		this._cursorPosPrev = new Vector3();	//cursor position when previous rotate operation has been detected
		this._cursorPosCurr = new Vector3();//cursor position when current rotate operation has been detected
		this._wPrev = 0; //angular velocity of the previous rotate operation
		this._wCurr = 0; //angular velocity of the current rotate operation


		//parameters
		this.adjustNearFar = false;
		this.scaleFactor = 1.1;	//zoom/distance multiplier
		this.dampingFactor = 25;
		this.wMax = 20;	//maximum angular velocity allowed
		this.enableAnimations = true; //if animations should be performed
		this.enableGrid = false; //if grid should be showed during pan operation
		this.cursorZoom = false;	//if wheel zoom should be cursor centered
		this.minFov = 5;
		this.maxFov = 90;
		this.rotateSpeed = 1;

		this.enabled = true;
		this.enablePan = true;
		this.enableRotate = true;
		this.enableZoom = true;
		this.enableGizmos = true;

		this.minDistance = 0;
		this.maxDistance = Math.POSITIVE_INFINITY;
		this.minZoom = 0;
		this.maxZoom = Math.POSITIVE_INFINITY;

		//trackball parameters
		this._tbRadius = 1;

		//FSA
		this._state = STATE.IDLE;

		this.setCamera( camera );

		if ( this.scene != null ) {

			this.scene.add( this._gizmos );

		}

		this.domElement.style.touchAction = 'none';
		this._devPxRatio = Lib.window.devicePixelRatio;

		this.initializeMouseActions();

		this.domElement.addEventListener( 'contextmenu', this._onContextMenu );
		this.domElement.addEventListener( 'wheel', this._onWheel );
		this.domElement.addEventListener( 'pointerdown', this._onPointerDown );
		this.domElement.addEventListener( 'pointercancel', this._onPointerCancel );

		Lib.window.addEventListener( 'resize', this._onWindowResize );

	}
	
	function onSinglePanStart( event:js.html.MouseEvent, operation:String ) {

		if ( this.enabled ) {

			this.dispatchEvent( { type: 'start'} );

			this.setCenter( event.clientX, event.clientY );

			switch ( operation ) {

				case 'PAN':

					if ( ! this.enablePan ) {

						return;

					}

					if ( this._animationId != - 1 ) {

						Lib.window.cancelAnimationFrame( this._animationId );
						this._animationId = - 1;
						this._timeStart = - 1;

						this.activateGizmos( false );
						this.dispatchEvent( { type: 'change'} );

					}

					this.updateTbState( STATE.PAN, true );
					this._startCursorPosition.copy( this.unprojectOnTbPlane( this.camera, _center.x, _center.y, this.domElement ) );
					if ( this.enableGrid ) {

						this.drawGrid();
						this.dispatchEvent( { type: 'change'} );

					}

					break;

				case 'ROTATE':

					if ( ! this.enableRotate ) {

						return;

					}

					if ( this._animationId != - 1 ) {

						Lib.window.cancelAnimationFrame( this._animationId );
						this._animationId = - 1;
						this._timeStart = - 1;

					}

					this.updateTbState( STATE.ROTATE, true );
					this._startCursorPosition.copy( this.unprojectOnTbSurface( this.camera, _center.x, _center.y, this.domElement, this._tbRadius ) );
					this.activateGizmos( true );
					if ( this.enableAnimations ) {

						this._timePrev = this._timeCurrent = Lib.window.performance.now();
						this._angleCurrent = this._anglePrev = 0;
						this._cursorPosPrev.copy( this._startCursorPosition );
						this._cursorPosCurr.copy( this._cursorPosPrev );
						this._wCurr = 0;
						this._wPrev = this._wCurr;

					}

					this.dispatchEvent( { type: 'change'} );
					break;

				case 'FOV':

					if ( ! this.camera.isPerspectiveCamera || ! this.enableZoom ) {

						return;

					}

					if ( this._animationId != - 1 ) {

						Lib.window.cancelAnimationFrame( this._animationId );
						this._animationId = - 1;
						this._timeStart = - 1;

						this.activateGizmos( false );
						this.dispatchEvent( { type: 'change'} );

					}

					this.updateTbState( STATE.FOV, true );
					this._startCursorPosition.setY( this.getCursorNDC( _center.x, _center.y, this.domElement ).y * 0.5 );
					this._currentCursorPosition.copy( this._startCursorPosition );
					break;

				case 'ZOOM':

					if ( ! this.enableZoom ) {

						return;

					}

					if ( this._animationId != - 1 ) {

						Lib.window.cancelAnimationFrame( this._animationId );
						this._animationId = - 1;
						this._timeStart = - 1;

						this.activateGizmos( false );
						this.dispatchEvent( { type: 'change'} );

					}

					this.updateTbState( STATE.SCALE, true );
					this._startCursorPosition.setY( this.getCursorNDC( _center.x, _center.y, this.domElement ).y * 0.5 );
					this._currentCursorPosition.copy( this._startCursorPosition );
					break;

			}

		}

	}
	
	function onSinglePanMove( event:js.html.MouseEvent, opState:Int ) {

		if ( this.enabled ) {

			var restart = opState != this._state;
			this.setCenter( event.clientX, event.clientY );

			switch ( opState ) {

				case STATE.PAN:

					if ( this.enablePan ) {

						if ( restart ) {

							//switch to pan operation

							this.dispatchEvent( { type: 'end' } );
							this.dispatchEvent( { type: 'start' } );

							this.updateTbState( opState, true );
							this._startCursorPosition.copy( this.unprojectOnTbPlane( this.camera, _center.x, _center.y, this.domElement ) );
							if ( this.enableGrid ) {

								this.drawGrid();

							}

							this.activateGizmos( false );

						} else {

							//continue with pan operation
							this._currentCursorPosition.copy( this.unprojectOnTbPlane( this.camera, _center.x, _center.y, this.domElement ) );
							this.applyTransformMatrix( this.pan( this._startCursorPosition, this._currentCursorPosition ) );

						}

					}

					break;

				case STATE.ROTATE:

					if ( this.enableRotate ) {

						if ( restart ) {

							//switch to rotate operation

							this.dispatchEvent( { type: 'end' } );
							this.dispatchEvent( { type: 'start' } );

							this.updateTbState( opState, true );
							this._startCursorPosition.copy( this.unprojectOnTbSurface( this.camera, _center.x, _center.y, this.domElement, this._tbRadius ) );

							if ( this.enableGrid ) {

								this.disposeGrid();

							}

							this.activateGizmos( true );

						} else {

							//continue with rotate operation
							this._currentCursorPosition.copy( this.unprojectOnTbSurface( this.camera, _center.x, _center.y, this.domElement, this._tbRadius ) );

							var distance = this._startCursorPosition.distanceTo( this._currentCursorPosition );
							var angle = this._startCursorPosition.angleTo( this._currentCursorPosition );
							var amount = Math.max( distance / this._tbRadius, angle ) * this.rotateSpeed; //effective rotation angle

							this.applyTransformMatrix( this.rotate( this.calculateRotationAxis( this._startCursorPosition, this._currentCursorPosition ), amount ) );

							if ( this.enableAnimations ) {

								this._timePrev = this._timeCurrent;
								this._timeCurrent = Lib.window.performance.now();
								this._anglePrev = this._angleCurrent;
								this._angleCurrent = amount;
								this._cursorPosPrev.copy( this._cursorPosCurr );
								this._cursorPosCurr.copy( this._currentCursorPosition );
								this._wPrev = this._wCurr;
								this._wCurr = this.calculateAngularSpeed( this._anglePrev, this._angleCurrent, this._timePrev, this._timeCurrent );

							}

						}

					}

					break;

				case STATE.SCALE:

					if ( this.enableZoom ) {

						if ( restart ) {

							//switch to zoom operation

							this.dispatchEvent( { type: 'end' } );
							this.dispatchEvent( { type: 'start' } );

							this.updateTbState( opState, true );
							this._startCursorPosition.setY( this.getCursorNDC( _center.x, _center.y, this.domElement ).y * 0.5 );
							this._currentCursorPosition.copy( this._startCursorPosition );

							if ( this.enableGrid ) {

								this.disposeGrid();

							}

							this.activateGizmos( false );

						} else {

							//continue with zoom operation
							var screenNotches:Float = 8;	//how many wheel notches corresponds to a full screen pan
							this._currentCursorPosition.setY( this.getCursorNDC( _center.x, _center.y, this.domElement ).y * 0.5 );

							var movement = this._currentCursorPosition.y - this._startCursorPosition.y;

							var size = 1.0;

							if ( movement < 0 ) {

								size = 1 / ( Math.pow( this.scaleFactor, - movement * screenNotches ) );

							} else if ( movement > 0 ) {

								size = Math.pow( this.scaleFactor, movement * screenNotches );

							}

							this._v3_1.setFromMatrixPosition( this._gizmoMatrixState );

							this.applyTransformMatrix( this.scale( size, this._v3_1 ) );

						}

					}

					break;

				case STATE.FOV:

					if ( this.enableZoom && this.camera.isPerspectiveCamera ) {

						if ( restart ) {

							//switch to fov operation

							this.dispatchEvent( { type: 'end' } );
							this.dispatchEvent( { type: 'start' } );

							this.updateTbState( opState, true );
							this._startCursorPosition.setY( this.getCursorNDC( _center.x, _center.y, this.domElement ).y * 0.5 );
							this._currentCursorPosition.copy( this._startCursorPosition );

							if ( this.enableGrid ) {

								this.disposeGrid();

							}

							this.activateGizmos( false );

						} else {

							//continue with fov operation
							var screenNotches:Float = 8;	//how many wheel notches corresponds to a full screen pan
							this._currentCursorPosition.setY( this.getCursorNDC( _center.x, _center.y, this.domElement ).y * 0.5 );

							var movement = this._currentCursorPosition.y - this._startCursorPosition.y;

							var size = 1.0;

							if ( movement < 0 ) {

								size = 1 / ( Math.pow( this.scaleFactor, - movement * screenNotches ) );

							} else if ( movement > 0 ) {

								size = Math.pow( this.scaleFactor, movement * screenNotches );

							}

							this._v3_1.setFromMatrixPosition( this._cameraMatrixState );
							var x = this._v3_1.distanceTo( this._gizmos.position );
							var xNew = x / size; //distance between camera and gizmos if scale(size, scalepoint) would be performed

							//check min and max distance
							xNew = MathUtils.clamp( xNew, this.minDistance, this.maxDistance );

							var y = x * Math.tan( MathUtils.DEG2RAD * this._fovState * 0.5 );

							//calculate new fov
							var newFov = MathUtils.RAD2DEG * ( Math.atan( y / xNew ) * 2 );

							//check min and max fov
							newFov = MathUtils.clamp( newFov, this.minFov, this.maxFov );

							var newDistance = y / Math.tan( MathUtils.DEG2RAD * ( newFov / 2 ) );
							size = x / newDistance;
							this._v3_2.setFromMatrixPosition( this._gizmoMatrixState );

							this.setFov( newFov );
							this.applyTransformMatrix( this.scale( size, this._v3_2, false ) );

							//adjusting distance
							_offset.copy( this._gizmos.position ).sub( this.camera.position ).normalize().multiplyScalar( newDistance / x );
							this._m4_1.makeTranslation( _offset.x, _offset.y, _offset.z );

						}

					}

					break;

			}

			this.dispatchEvent( { type: 'change' } );

		}

	}
	
	//event handlers
	function _onContextMenu( event:js.html.MouseEvent ):Void {

		event.preventDefault();

	}
	
	function _onWheel( event:js.html.WheelEvent ):Void {
		
		//TODO

	}
	
	function _onPointerDown( event:js.html.PointerEvent ):Void {
		
		//TODO
		
	}
	
	function _onPointerCancel( event:js.html.PointerEvent ):Void {
		
		//TODO
		
	}
	
	function _onWindowResize( event:js.html.Event ):Void {
		
		//TODO
		
	}

	//to be implemented
	function setCamera( camera:Camera ):Void {

		//TODO

	}
	
	function setCenter( clientX:Float, clientY:Float ):Void {
		
		//TODO
		
	}
	
	function updateTbState( newState:Int, updateMatrices:Bool = false ):Void {
		
		//TODO
		
	}
	
	function unprojectOnTbPlane( camera:Camera, clientX:Float, clientY:Float, domElement:js.html.Element ):Vector3 {
		
		//TODO
		
		return null;
		
	}
	
	function drawGrid():Void {
		
		//TODO
		
	}
	
	function activateGizmos( isActive:Bool ):Void {
		
		//TODO
		
	}
	
	function unprojectOnTbSurface( camera:Camera, clientX:Float, clientY:Float, domElement:js.html.Element, tbRadius:Float ):Vector3 {
		
		//TODO
		
		return null;
		
	}
	
	function getCursorNDC( clientX:Float, clientY:Float, domElement:js.html.Element ):Vector2 {
		
		//TODO
		
		return null;
		
	}
	
	function disposeGrid():Void {
		
		//TODO
		
	}
	
	function applyTransformMatrix( matrix:Matrix4 ):Void {
		
		//TODO
		
	}
	
	function pan( p0:Vector3, p1:Vector3 ):Matrix4 {
		
		//TODO
		
		return null;
		
	}
	
	function rotate( axis:Vector3, angle:Float ):Matrix4 {
		
		//TODO
		
		return null;
		
	}
	
	function calculateRotationAxis( p0:Vector3, p1:Vector3 ):Vector3 {
		
		//TODO
		
		return null;
		
	}
	
	function calculateAngularSpeed( p0:Float, p1:Float, t0:Float, t1:Float ):Float {
		
		//TODO
		
		return 0;
		
	}
	
	function scale( size:Float, point:Vector3, scaleDistance:Bool = true ):Matrix4 {
		
		//TODO
		
		return null;
		
	}
	
	function setFov( value:Float ):Void {
		
		//TODO
		
	}

}