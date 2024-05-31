import three.EventDispatcher;
import three.Quaternion;
import three.Vector3;
import js.Browser;

class FlyControls extends EventDispatcher {

    public var object(default, null) : three.Object3D;
    public var domElement(default, null) : js.html.Element;

    // API
    public var enabled(default, set) : Bool;

    public var movementSpeed(default, set) : Float;
    public var rollSpeed(default, set) : Float;

    public var dragToLook(default, set) : Bool;
    public var autoForward(default, set) : Bool;

    // internals
    var scope : FlyControls;
    var EPS : Float;
    var lastQuaternion : Quaternion;
    var lastPosition : Vector3;
    var tmpQuaternion : Quaternion;
    var status : Int;
    var moveState : { up:Int, down:Int, left:Int, right:Int, forward:Int, back:Int, pitchUp:Int, pitchDown:Int, yawLeft:Int, yawRight:Int, rollLeft:Int, rollRight:Int };
    var moveVector : Vector3;
    var rotationVector : Vector3;
    var movementSpeedMultiplier : Float;

    public function new(object : three.Object3D, domElement : js.html.Element) {

        super();

        this.object = object;
        this.domElement = domElement;

        // API

        // Set to false to disable this control
        this.enabled = true;

        this.movementSpeed = 1.0;
        this.rollSpeed = 0.005;

        this.dragToLook = false;
        this.autoForward = false;

        // disable default target object behavior

        // internals

        scope = this;

        EPS = 0.000001;

        lastQuaternion = new Quaternion();
        lastPosition = new Vector3();

        this.tmpQuaternion = new Quaternion();

        this.status = 0;
        this.movementSpeedMultiplier = 1.0;

        this.moveState = { up: 0, down: 0, left: 0, right: 0, forward: 0, back: 0, pitchUp: 0, pitchDown: 0, yawLeft: 0, yawRight: 0, rollLeft: 0, rollRight: 0 };
        this.moveVector = new Vector3( 0, 0, 0 );
        this.rotationVector = new Vector3( 0, 0, 0 );

        domElement.addEventListener("contextmenu", contextMenu);
        domElement.addEventListener("pointerdown", pointerdown);
        domElement.addEventListener("pointermove", pointermove);
        domElement.addEventListener("pointerup", pointerup);
        domElement.addEventListener("pointercancel", pointercancel);

        Browser.window.addEventListener("keydown", keydown);
        Browser.window.addEventListener("keyup", keyup);

        updateMovementVector();
        updateRotationVector();

    }

    public function update(delta:Float) : Void {

        if (!enabled) return;

        var moveMult = delta * movementSpeed * movementSpeedMultiplier;
        var rotMult = delta * rollSpeed;

        object.translateX( moveVector.x * moveMult );
        object.translateY( moveVector.y * moveMult );
        object.translateZ( moveVector.z * moveMult );

        tmpQuaternion.set( rotationVector.x * rotMult, rotationVector.y * rotMult, rotationVector.z * rotMult, 1 ).normalize();
        object.quaternion.multiply( tmpQuaternion );

        if (
            lastPosition.distanceToSquared( object.position ) > EPS ||
            8 * ( 1 - lastQuaternion.dot( object.quaternion ) ) > EPS
        ) {

            dispatchEvent( { type: 'change' } );
            lastQuaternion.copy( object.quaternion );
            lastPosition.copy( object.position );

        }

    }

    function updateMovementVector() : Void {

        var forward = ( moveState.forward == 1 || ( autoForward && moveState.back == 0 ) ) ? 1 : 0;

        moveVector.x = ( - moveState.left + moveState.right );
        moveVector.y = ( - moveState.down + moveState.up );
        moveVector.z = ( - forward + moveState.back );

        //console.log( 'move:', [ this.moveVector.x, this.moveVector.y, this.moveVector.z ] );

    }

    function updateRotationVector() : Void {

        rotationVector.x = ( - moveState.pitchDown + moveState.pitchUp );
        rotationVector.y = ( - moveState.yawRight + moveState.yawLeft );
        rotationVector.z = ( - moveState.rollRight + moveState.rollLeft );

        //console.log( 'rotate:', [ this.rotationVector.x, this.rotationVector.y, this.rotationVector.z ] );

    }

    function getContainerDimensions() : { size : Array<Int>, offset: Array<Int> } {

        if ( domElement != Browser.document.body ) {

            return {
                size: [ Std.int(domElement.offsetWidth), Std.int(domElement.offsetHeight) ],
                offset: [ Std.int(domElement.offsetLeft), Std.int(domElement.offsetTop) ]
            };

        } else {

            return {
                size: [ Browser.window.innerWidth, Browser.window.innerHeight ],
                offset: [ 0, 0 ]
            };

        }

    }

    function dispose() : Void {

        domElement.removeEventListener("contextmenu", contextMenu);
        domElement.removeEventListener( 'pointerdown', pointerdown );
        domElement.removeEventListener( 'pointermove', pointermove );
        domElement.removeEventListener( 'pointerup', pointerup );
        domElement.removeEventListener( 'pointercancel', pointercancel );

        Browser.window.removeEventListener( 'keydown', keydown );
        Browser.window.removeEventListener( 'keyup', keyup );

    }

    function contextMenu(event:js.jquery.Event) : Void {

        if ( !enabled ) return;

        event.preventDefault();

    }

    function pointerdown(event:js.jquery.Event) : Void {

        if ( !enabled ) return;

        if ( dragToLook ) {

            status ++;

        } else {
            switch ( event.button ) {

                case 0: moveState.forward = 1; break;
                case 2: moveState.back = 1; break;

            }

            updateMovementVector();

        }

    }

    function pointermove(event:js.jquery.Event) : Void {

        if ( !enabled ) return;

        if ( ! dragToLook || status > 0 ) {

            var container = getContainerDimensions();
            var halfWidth = container.size[ 0 ] / 2;
            var halfHeight = container.size[ 1 ] / 2;

            moveState.yawLeft = - ( ( event.pageX - container.offset[ 0 ] ) - halfWidth ) / halfWidth;
            moveState.pitchDown = ( ( event.pageY - container.offset[ 1 ] ) - halfHeight ) / halfHeight;

            updateRotationVector();

        }

    }

    function pointerup(event:js.jquery.Event) : Void {

        if ( !enabled ) return;

        if ( dragToLook ) {

            status --;

            moveState.yawLeft = moveState.pitchDown = 0;

        } else {

            switch ( event.button ) {

                case 0: moveState.forward = 0; break;
                case 2: moveState.back = 0; break;

            }

            updateMovementVector();

        }

        updateRotationVector();

    }

    function pointercancel(event:js.jquery.Event) : Void {

        if ( !enabled ) return;

        if ( dragToLook ) {

            status = 0;

            moveState.yawLeft = moveState.pitchDown = 0;

        } else {

            moveState.forward = 0;
            moveState.back = 0;

            updateMovementVector();

        }

        updateRotationVector();

    }

    function keydown(event:js.jquery.Event) : Void {

        if ( event.altKey || !enabled ) {

            return;

        }

        switch ( event.code ) {

            case 'ShiftLeft':
            case 'ShiftRight': movementSpeedMultiplier = .1; break;

            case 'KeyW': moveState.forward = 1; break;
            case 'KeyS': moveState.back = 1; break;

            case 'KeyA': moveState.left = 1; break;
            case 'KeyD': moveState.right = 1; break;

            case 'KeyR': moveState.up = 1; break;
            case 'KeyF': moveState.down = 1; break;

            case 'ArrowUp': moveState.pitchUp = 1; break;
            case 'ArrowDown': moveState.pitchDown = 1; break;

            case 'ArrowLeft': moveState.yawLeft = 1; break;
            case 'ArrowRight': moveState.yawRight = 1; break;

            case 'KeyQ': moveState.rollLeft = 1; break;
            case 'KeyE': moveState.rollRight = 1; break;

        }

        updateMovementVector();
        updateRotationVector();

    }

    function keyup(event:js.jquery.Event) : Void {

        if ( !enabled ) return;

        switch ( event.code ) {

            case 'ShiftLeft':
            case 'ShiftRight': movementSpeedMultiplier = 1; break;

            case 'KeyW': moveState.forward = 0; break;
            case 'KeyS': moveState.back = 0; break;

            case 'KeyA': moveState.left = 0; break;
            case 'KeyD': moveState.right = 0; break;

            case 'KeyR': moveState.up = 0; break;
            case 'KeyF': moveState.down = 0; break;

            case 'ArrowUp': moveState.pitchUp = 0; break;
            case 'ArrowDown': moveState.pitchDown = 0; break;

            case 'ArrowLeft': moveState.yawLeft = 0; break;
            case 'ArrowRight': moveState.yawRight = 0; break;

            case 'KeyQ': moveState.rollLeft = 0; break;
            case 'KeyE': moveState.rollRight = 0; break;

        }

        updateMovementVector();
        updateRotationVector();

    }

    function set_enabled(value:Bool):Bool {
        enabled = value;
        return value;
    }

    function set_movementSpeed(value:Float):Float {
        movementSpeed = value;
        return value;
    }

    function set_rollSpeed(value:Float):Float {
        rollSpeed = value;
        return value;
    }

    function set_dragToLook(value:Bool):Bool {
        dragToLook = value;
        return value;
    }

    function set_autoForward(value:Bool):Bool {
        autoForward = value;
        return value;
    }

}