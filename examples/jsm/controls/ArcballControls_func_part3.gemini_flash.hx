import three.Vector2;
import three.Vector3;
import three.Quaternion;
import three.Matrix4;
import three.Spherical;
import three.Box3;
import three.Sphere;
import three.MathUtils;
import three.EventDispatcher;
import three.MOUSE;
import three.PerspectiveCamera;
import three.OrthographicCamera;
import js.Browser;
import three.GridHelper;

class ControlsHelper extends EventDispatcher {

    // Public properties
    public domElement:js.html.Element;
    public camera:three.Camera;
    public target:Vector3;
    public scene:three.Scene;
    public enableDamping:Bool;
    public dampingFactor:Float;
    public enableZoom:Bool;
    public zoomSpeed:Float;
    public enableRotate:Bool;
    public rotateSpeed:Float;
    public enablePan:Bool;
    public panSpeed:Float;
    public screenSpacePanning:Bool;
    public keyPanSpeed:Float;
    public autoRotate:Bool;
    public autoRotateSpeed:Float;
    public adjustNearFar:Bool;
    public radiusFactor:Float;
    public minDistance:Float;
    public maxDistance:Float;
    public minZoom:Float;
    public maxZoom:Float;
    public minPolarAngle:Float;
    public maxPolarAngle:Float;
    public minAzimuthAngle:Float;
    public maxAzimuthAngle:Float;
    // Public methods
    public update():Void;
    public listenTo( element:js.html.Element ):Void;
    public dampen( state:Int, time:Float ):Void;
    public pan( deltaX:Float, deltaY:Float ):Void;
    public zoom( delta:Float ):Void;
    public rotate( deltaX:Float, deltaY:Float ):Void;
    public setMouseAction( operation:String, mouse:Int, ?key:String ):Bool;
    public unsetMouseAction( mouse:Int, ?key:String ):Bool;
    public getOpFromAction( mouse:Int, ?key:String ):String;
    public getOpStateFromAction( mouse:Int, ?key:String ):Int;
    public getAngle( p1:Dynamic, p2:Dynamic ):Float;
    public updateTouchEvent( event:Dynamic ):Void;
    public applyTransformMatrix( transformation:Dynamic ):Void;
    public calculateAngularSpeed( p0:Float, p1:Float, t0:Float, t1:Float ):Float;
    public calculatePointersDistance( p0:Dynamic, p1:Dynamic ):Float;
    public calculateRotationAxis( vec1:Vector3, vec2:Vector3 ):Vector3;
    public calculateTbRadius( camera:three.Camera ):Float;
    public focus( point:Vector3, size:Float, amount:Float = 1.0 ):Void;
    public drawGrid():Void;
    public dispose():Void;
    public disposeGrid():Void;
    public easeOutCubic( t:Float ):Float;
    public activateGizmos( isActive:Bool ):Void;
    public getCursorNDC( cursorX:Float, cursorY:Float, canvas:js.html.Element ):Vector2;
    public getCursorPosition( cursorX:Float, cursorY:Float, canvas:js.html.Element ):Vector2;
    public setCamera( camera:three.Camera ):Void;
    public setGizmosVisible( value:Bool ):Void;


    // Private members
    private _m4_1:Matrix4 = new Matrix4();
    private _vec3_1:Vector3 = new Vector3();
    private _v2_1:Vector2 = new Vector2();
    private _quat:Quaternion = new Quaternion();

    public function new( camera = null, target = null, scene:three.Scene = null ) {

        super();
        this.domElement = Browser.document.body;
        this.camera = camera;
        this.target = ( target !== null ) ? target : new Vector3();
        this.scene = scene;

    }
    
    // Public methods implementation

    public function setMouseAction( operation:String, mouse:Int, ?key:String ):Bool {

        const operationInput = [ 'PAN', 'ROTATE', 'ZOOM', 'FOV' ];
        const mouseInput = [ MOUSE.LEFT, MOUSE.MIDDLE, MOUSE.RIGHT, 'WHEEL' ];
        const keyInput = [ 'CTRL', 'SHIFT', null ];
        var state:Int;

        if ( !operationInput.indexOf(operation) != -1 || !mouseInput.indexOf(mouse) != -1 || !keyInput.indexOf(key) != -1 ) {

            //invalid parameters
            return false;

        }

        if ( mouse == 'WHEEL' ) {

            if ( operation != 'ZOOM' && operation != 'FOV' ) {

                //cannot associate 2D operation to 1D input
                return false;

            }

        }

        switch ( operation ) {

            case 'PAN':

                state = STATE.PAN;
            case 'ROTATE':

                state = STATE.ROTATE;
            case 'ZOOM':

                state = STATE.SCALE;
            case 'FOV':

                state = STATE.FOV;

        }

        var action = {

            operation: operation,
            mouse: mouse,
            key: key,
            state: state

        };

        for ( i in 0...this.mouseActions.length ) {

            if ( this.mouseActions[ i ].mouse == action.mouse && this.mouseActions[ i ].key == action.key ) {

                this.mouseActions.splice( i, 1, action );
                return true;

            }

        }

        this.mouseActions.push( action );
        return true;

    }

    public function unsetMouseAction( mouse:Int, ?key:String ):Bool {

        for ( i in 0...this.mouseActions.length ) {

            if ( this.mouseActions[ i ].mouse == mouse && this.mouseActions[ i ].key == key ) {

                this.mouseActions.splice( i, 1 );
                return true;

            }

        }

        return false;

    }

    public function getOpFromAction( mouse:Int, ?key:String ):String {

        var action:Dynamic;

        for ( i in 0...this.mouseActions.length ) {

            action = this.mouseActions[ i ];
            if ( action.mouse == mouse && action.key == key ) {

                return action.operation;

            }

        }

        if ( key != null ) {

            for ( i in 0...this.mouseActions.length ) {

                action = this.mouseActions[ i ];
                if ( action.mouse == mouse && action.key == null ) {

                    return action.operation;

                }

            }

        }

        return null;

    }

    public function getOpStateFromAction( mouse:Int, ?key:String ):Int {

        var action:Dynamic;

        for ( i in 0...this.mouseActions.length ) {

            action = this.mouseActions[ i ];
            if ( action.mouse == mouse && action.key == key ) {

                return action.state;

            }

        }

        if ( key != null ) {

            for ( i in 0...this.mouseActions.length ) {

                action = this.mouseActions[ i ];
                if ( action.mouse == mouse && action.key == null ) {

                    return action.state;

                }

            }

        }

        return null;

    }

    public function getAngle( p1:Dynamic, p2:Dynamic ):Float {

        return Math.atan2( p2.clientY - p1.clientY, p2.clientX - p1.clientX ) * 180 / Math.PI;

    }

    public function updateTouchEvent( event:Dynamic ):Void {

        for ( i in 0...this._touchCurrent.length ) {

            if ( this._touchCurrent[ i ].pointerId == event.pointerId ) {

                this._touchCurrent.splice( i, 1, event );
                break;

            }

        }

    }

    public function applyTransformMatrix( transformation:Dynamic ):Void {

        if ( transformation.camera != null ) {

            this._m4_1.copy( this._cameraMatrixState ).multiply(transformation.camera);
            this._m4_1.decompose( this.camera.position, this.camera.quaternion, this.camera.scale );
            this.camera.updateMatrix();

            //update camera up vector
            if ( this._state == STATE.ROTATE || this._state == STATE.ZROTATE || this._state == STATE.ANIMATION_ROTATE ) {

                this.camera.up.copy( this._upState ).applyQuaternion( this.camera.quaternion );

            }

        }

        if ( transformation.gizmos != null ) {

            this._m4_1.copy( this._gizmoMatrixState ).multiply(transformation.gizmos);
            this._m4_1.decompose( this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale );
            this._gizmos.updateMatrix();

        }

        if ( this._state == STATE.SCALE || this._state == STATE.FOCUS || this._state == STATE.ANIMATION_FOCUS ) {

            this._tbRadius = this.calculateTbRadius( this.camera );

            if ( this.adjustNearFar ) {

                var cameraDistance = this.camera.position.distanceTo( this._gizmos.position );

                var bb = new Box3();
                bb.setFromObject( this._gizmos );
                var sphere = new Sphere();
                bb.getBoundingSphere( sphere );

                var adjustedNearPosition = Math.max( this._nearPos0, sphere.radius + sphere.center.length() );
                var regularNearPosition = cameraDistance - this._initialNear;

                var minNearPos = Math.min( adjustedNearPosition, regularNearPosition );
                this.camera.near = cameraDistance - minNearPos;


                var adjustedFarPosition = Math.min( this._farPos0, - sphere.radius + sphere.center.length() );
                var regularFarPosition = cameraDistance - this._initialFar;

                var minFarPos = Math.min( adjustedFarPosition, regularFarPosition );
                this.camera.far = cameraDistance - minFarPos;

                this.camera.updateProjectionMatrix();

            } else {

                var update = false;

                if ( this.camera.near != this._initialNear ) {

                    this.camera.near = this._initialNear;
                    update = true;

                }

                if ( this.camera.far != this._initialFar ) {

                    this.camera.far = this._initialFar;
                    update = true;

                }

                if ( update ) {

                    this.camera.updateProjectionMatrix();

                }

            }

        }

    }

    public function calculateAngularSpeed( p0:Float, p1:Float, t0:Float, t1:Float ):Float {

        var s = p1 - p0;
        var t = ( t1 - t0 ) / 1000;
        if ( t == 0 ) {

            return 0;

        }

        return s / t;

    }

    public function calculatePointersDistance( p0:Dynamic, p1:Dynamic ):Float {

        return Math.sqrt( Math.pow( p1.clientX - p0.clientX, 2 ) + Math.pow( p1.clientY - p0.clientY, 2 ) );

    }

    public function calculateRotationAxis( vec1:Vector3, vec2:Vector3 ):Vector3 {

        this._rotationMatrix.extractRotation( this._cameraMatrixState );
        this._quat.setFromRotationMatrix( this._rotationMatrix );

        this._rotationAxis.crossVectors( vec1, vec2 ).applyQuaternion( this._quat );
        return this._rotationAxis.normalize();

    }

    public function calculateTbRadius( camera:three.Camera ):Float {

        var distance = camera.position.distanceTo( this._gizmos.position );
        if ( Std.isOfType(camera, PerspectiveCamera) ) {

            var halfFovV = MathUtils.DEG2RAD * camera.fov * 0.5; //vertical fov/2 in radians
            var halfFovH = Math.atan( ( camera.aspect ) * Math.tan( halfFovV ) ); //horizontal fov/2 in radians
            return Math.tan( Math.min( halfFovV, halfFovH ) ) * distance * this.radiusFactor;

        } else if ( Std.isOfType(camera, OrthographicCamera) ) {

            return Math.min( camera.top, camera.right ) * this.radiusFactor;

        }
        return 0.0;

    }

    public function focus( point:Vector3, size:Float, amount:Float = 1.0 ):Void {

        //move center of camera (along with gizmos) towards point of interest
        this._vec3_1.copy( point ).sub( this._gizmos.position ).multiplyScalar( amount );
        this._translationMatrix.makeTranslation( this._vec3_1.x, this._vec3_1.y, this._vec3_1.z );

        this._gizmoMatrixStateTemp.copy( this._gizmoMatrixState );
        this._gizmoMatrixState.multiply(this._translationMatrix);
        this._gizmoMatrixState.decompose( this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale );

        this._cameraMatrixStateTemp.copy( this._cameraMatrixState );
        this._cameraMatrixState.multiply(this._translationMatrix);
        this._cameraMatrixState.decompose( this.camera.position, this.camera.quaternion, this.camera.scale );

        //apply zoom
        if ( this.enableZoom ) {

            this.applyTransformMatrix( this.scale( size, this._gizmos.position ) );

        }

        this._gizmoMatrixState.copy( this._gizmoMatrixStateTemp );
        this._cameraMatrixState.copy( this._cameraMatrixStateTemp );

    }

    public function drawGrid():Void {

        if ( this.scene != null ) {

            var color = 0x888888;
            var multiplier = 3;
            var size:Float, divisions:Float, maxLength:Float, tick:Float;

            if ( Std.isOfType(this.camera, OrthographicCamera) ) {

                var width = this.camera.right - this.camera.left;
                var height = this.camera.bottom - this.camera.top;

                maxLength = Math.max( width, height );
                tick = maxLength / 20;

                size = maxLength / this.camera.zoom * multiplier;
                divisions = size / tick * this.camera.zoom;

            } else if ( Std.isOfType(this.camera, PerspectiveCamera) ) {

                var distance = this.camera.position.distanceTo( this._gizmos.position );
                var halfFovV = MathUtils.DEG2RAD * this.camera.fov * 0.5;
                var halfFovH = Math.atan( ( this.camera.aspect ) * Math.tan( halfFovV ) );

                maxLength = Math.tan( Math.max( halfFovV, halfFovH ) ) * distance * 2;
                tick = maxLength / 20;

                size = maxLength * multiplier;
                divisions = size / tick;

            }

            if ( this._grid == null ) {

                this._grid = new GridHelper( size, Std.int(divisions), color, color );
                this._grid.position.copy( this._gizmos.position );
                this._gridPosition.copy( this._grid.position );
                this._grid.quaternion.copy( this.camera.quaternion );
                this._grid.rotateX( Math.PI * 0.5 );

                this.scene.add( this._grid );

            }

        }

    }

    public function dispose():Void {

        if ( this._animationId != - 1 ) {

            Browser.window.cancelAnimationFrame( this._animationId );

        }

        this.domElement.removeEventListener( 'pointerdown', this._onPointerDown );
        this.domElement.removeEventListener( 'pointercancel', this._onPointerCancel );
        this.domElement.removeEventListener( 'wheel', this._onWheel );
        this.domElement.removeEventListener( 'contextmenu', this._onContextMenu );

        Browser.window.removeEventListener( 'pointermove', this._onPointerMove );
        Browser.window.removeEventListener( 'pointerup', this._onPointerUp );

        Browser.window.removeEventListener( 'resize', this._onWindowResize );

        if ( this.scene !== null ) this.scene.remove( this._gizmos );
        this.disposeGrid();

    }

    public function disposeGrid():Void {

        if ( this._grid != null && this.scene != null ) {

            this.scene.remove( this._grid );
            this._grid = null;

        }

    }

    public function easeOutCubic( t:Float ):Float {

        return 1 - Math.pow( 1 - t, 3 );

    }

    public function activateGizmos( isActive:Bool ):Void {

        var gizmoX = this._gizmos.children[ 0 ];
        var gizmoY = this._gizmos.children[ 1 ];
        var gizmoZ = this._gizmos.children[ 2 ];

        if ( isActive ) {

            // @ts-ignore
            gizmoX.material.setValues( { opacity: 1 } );
            // @ts-ignore
            gizmoY.material.setValues( { opacity: 1 } );
            // @ts-ignore
            gizmoZ.material.setValues( { opacity: 1 } );

        } else {

            // @ts-ignore
            gizmoX.material.setValues( { opacity: 0.6 } );
            // @ts-ignore
            gizmoY.material.setValues( { opacity: 0.6 } );
            // @ts-ignore
            gizmoZ.material.setValues( { opacity: 0.6 } );

        }

    }

    public function getCursorNDC( cursorX:Float, cursorY:Float, canvas:js.html.Element ):Vector2 {

        var canvasRect = canvas.getBoundingClientRect();
        this._v2_1.setX( ( ( cursorX - canvasRect.left ) / canvasRect.width ) * 2 - 1 );
        this._v2_1.setY( ( ( canvasRect.bottom - cursorY ) / canvasRect.height ) * 2 - 1 );
        return this._v2_1.clone();

    }

    public function getCursorPosition( cursorX:Float, cursorY:Float, canvas:js.html.Element ):Vector2 {

        this._v2_1.copy( this.getCursorNDC( cursorX, cursorY, canvas ) );
        this._v2_1.x *= ( this.camera.right - this.camera.left ) * 0.5;
        this._v2_1.y *= ( this.camera.top - this.camera.bottom ) * 0.5;
        return this._v2_1.clone();

    }

    public function setCamera( camera:three.Camera ):Void {

        camera.lookAt( this.target );
        camera.updateMatrix();

        //setting state
        if ( Std.isOfType(camera, PerspectiveCamera) ) {

            this._fov0 = camera.fov;
            this._fovState = camera.fov;

        }

        this._cameraMatrixState0.copy( camera.matrix );
        this._cameraMatrixState.copy( this._cameraMatrixState0 );
        this._cameraProjectionState.copy( camera.projectionMatrix );
        this._zoom0 = camera.zoom;
        this._zoomState = this._zoom0;

        this._initialNear = camera.near;
        this._nearPos0 = camera.position.distanceTo( this.target ) - camera.near;
        this._nearPos = this._initialNear;

        this._initialFar = camera.far;
        this._farPos0 = camera.position.distanceTo( this.target ) - camera.far;
        this._farPos = this._initialFar;

        this._up0.copy( camera.up );
        this._upState.copy( camera.up );

        this.camera = camera;
        this.camera.updateProjectionMatrix();

        //making gizmos
        this._tbRadius = this.calculateTbRadius( camera );
        this.makeGizmos( this.target, this._tbRadius );

    }

    public function setGizmosVisible( value:Bool ):Void {

        this._gizmos.visible = value;
        this.dispatchEvent( _changeEvent );

    }

    // Private methods
    
}