import js.html.Element;
import js.html.Event;
import js.html.MouseEvent;
import js.html.WheelEvent;
import js.html.TouchEvent;
import js.html.Document;
import js.Lib;

class OrbitControls {
    private var scope:Dynamic;
    private var pointers:Array<Int>;
    private var pointerPositions:Map<Int, Vector2>;
    private var state:Int;
    private var controlActive:Bool;
    private var _startEvent:Event;
    private var _endEvent:Event;

    public function new(scope:Dynamic) {
        this.scope = scope;
        this.pointers = [];
        this.pointerPositions = new Map<Int, Vector2>();
        this.state = STATE.NONE;
        this.controlActive = false;
        this._startEvent = js.Browser.createEvent("Event");
        this._startEvent.type = "start";
        this._endEvent = js.Browser.createEvent("Event");
        this._endEvent.type = "end";

        scope.domElement.addEventListener("contextmenu", onContextMenu);
        scope.domElement.addEventListener("pointerdown", onPointerDown);
        scope.domElement.addEventListener("pointercancel", onPointerUp);
        scope.domElement.addEventListener("wheel", onMouseWheel, { passive: false } );

        var document:Document = scope.domElement.ownerDocument;
        document.addEventListener("keydown", interceptControlDown, { passive: true, capture: true } );

        this.update();
    }

    private function onPointerDown(event:Event):Void {
        addPointer(event);
        if (event.pointerType == "touch") {
            onTouchStart(event);
        } else {
            onMouseDown(event);
        }
    }

    private function onPointerMove(event:Event):Void {
        if (!scope.enabled) return;
        if (event.pointerType == "touch") {
            onTouchMove(event);
        } else {
            onMouseMove(event);
        }
    }

    private function onPointerUp(event:Event):Void {
        removePointer(event);
        switch (pointers.length) {
            case 0:
                scope.domElement.releasePointerCapture(event.pointerId);
                scope.domElement.removeEventListener("pointermove", onPointerMove);
                scope.domElement.removeEventListener("pointerup", onPointerUp);
                scope.dispatchEvent(_endEvent);
                state = STATE.NONE;
                break;
            case 1:
                var pointerId:Int = pointers[0];
                var position:Vector2 = pointerPositions[pointerId];
                onTouchStart({ pointerId: pointerId, pageX: position.x, pageY: position.y });
                break;
        }
    }

    private function onMouseDown(event:MouseEvent):Void {
        var mouseAction:Int;
        switch (event.button) {
            case 0:
                mouseAction = scope.mouseButtons.LEFT;
                break;
            case 1:
                mouseAction = scope.mouseButtons.MIDDLE;
                break;
            case 2:
                mouseAction = scope.mouseButtons.RIGHT;
                break;
            default:
                mouseAction = -1;
        }
        switch (mouseAction) {
            case MOUSE.DOLLY:
                if (!scope.enableZoom) return;
                handleMouseDownDolly(event);
                state = STATE.DOLLY;
                break;
            case MOUSE.ROTATE:
                if (event.ctrlKey || event.metaKey || event.shiftKey) {
                    if (!scope.enablePan) return;
                    handleMouseDownPan(event);
                    state = STATE.PAN;
                } else {
                    if (!scope.enableRotate) return;
                    handleMouseDownRotate(event);
                    state = STATE.ROTATE;
                }
                break;
            case MOUSE.PAN:
                if (event.ctrlKey || event.metaKey || event.shiftKey) {
                    if (!scope.enableRotate) return;
                    handleMouseDownRotate(event);
                    state = STATE.ROTATE;
                } else {
                    if (!scope.enablePan) return;
                    handleMouseDownPan(event);
                    state = STATE.PAN;
                }
                break;
            default:
                state = STATE.NONE;
        }
        if (state != STATE.NONE) {
            scope.dispatchEvent(_startEvent);
        }
    }

    private function onMouseMove(event:MouseEvent):Void {
        switch (state) {
            case STATE.ROTATE:
                if (!scope.enableRotate) return;
                handleMouseMoveRotate(event);
                break;
            case STATE.DOLLY:
                if (!scope.enableZoom) return;
                handleMouseMoveDolly(event);
                break;
            case STATE.PAN:
                if (!scope.enablePan) return;
                handleMouseMovePan(event);
                break;
        }
    }

    private function onMouseWheel(event:WheelEvent):Void {
        if (!scope.enabled || !scope.enableZoom || state != STATE.NONE) return;
        event.preventDefault();
        scope.dispatchEvent(_startEvent);
        handleMouseWheel(customWheelEvent(event));
        scope.dispatchEvent(_endEvent);
    }

    private function customWheelEvent(event:WheelEvent):WheelEvent {
        var mode:Int = event.deltaMode;
        var newEvent:WheelEvent = {
            clientX: event.clientX,
            clientY: event.clientY,
            deltaY: event.deltaY
        };
        switch (mode) {
            case 1: // LINE_MODE
                newEvent.deltaY *= 16;
                break;
            case 2: // PAGE_MODE
                newEvent.deltaY *= 100;
                break;
        }
        if (event.ctrlKey && !controlActive) {
            newEvent.deltaY *= 10;
        }
        return newEvent;
    }

    private function interceptControlDown(event:KeyboardEvent):Void {
        if (event.key == "Control") {
            controlActive = true;
            var document:Document = scope.domElement.ownerDocument;
            document.addEventListener("keyup", interceptControlUp, { passive: true, capture: true } );
        }
    }

    private function interceptControlUp(event:KeyboardEvent):Void {
        if (event.key == "Control") {
            controlActive = false;
            var document:Document = scope.domElement.ownerDocument;
            document.removeEventListener("keyup", interceptControlUp, { passive: true, capture: true } );
        }
    }

    private function onKeyDown(event:KeyboardEvent):Void {
        if (!scope.enabled || !scope.enablePan) return;
        handleKeyDown(event);
    }

    private function onTouchStart(event:TouchEvent):Void {
        trackPointer(event);
        switch (pointers.length) {
            case 1:
                switch (scope.touches.ONE) {
                    case TOUCH.ROTATE:
                        if (!scope.enableRotate) return;
                        handleTouchStartRotate(event);
                        state = STATE.TOUCH_ROTATE;
                        break;
                    case TOUCH.PAN:
                        if (!scope.enablePan) return;
                        handleTouchStartPan(event);
                        state = STATE.TOUCH_PAN;
                        break;
                    default:
                        state = STATE.NONE;
                }
                break;
            case 2:
                switch (scope.touches.TWO) {
                    case TOUCH.DOLLY_PAN:
                        if (!scope.enableZoom && !scope.enablePan) return;
                        handleTouchStartDollyPan(event);
                        state = STATE.TOUCH_DOLLY_PAN;
                        break;
                    case TOUCH.DOLLY_ROTATE:
                        if (!scope.enableZoom && !scope.enableRotate) return;
                        handleTouchStartDollyRotate(event);
                        state = STATE.TOUCH_DOLLY_ROTATE;
                        break;
                    default:
                        state = STATE.NONE;
                }
                break;
            default:
                state = STATE.NONE;
        }
        if (state != STATE.NONE) {
            scope.dispatchEvent(_startEvent);
        }
    }

    private function onTouchMove(event:TouchEvent):Void {
        trackPointer(event);
        switch (state) {
            case STATE.TOUCH_ROTATE:
                if (!scope.enableRotate) return;
                handleTouchMoveRotate(event);
                scope.update();
                break;
            case STATE.TOUCH_PAN:
                if (!scope.enablePan) return;
                handleTouchMovePan(event);
                scope.update();
                break;
            case STATE.TOUCH_DOLLY_PAN:
                if (!scope.enableZoom && !scope.enablePan) return;
                handleTouchMoveDollyPan(event);
                scope.update();
                break;
            case STATE.TOUCH_DOLLY_ROTATE:
                if (!scope.enableZoom && !scope.enableRotate) return;
                handleTouchMoveDollyRotate(event);
                scope.update();
                break;
            default:
                state = STATE.NONE;
        }
    }

    private function onContextMenu(event:Event):Void {
        if (!scope.enabled) return;
        event.preventDefault();
    }

    private function addPointer(event:Event):Void {
        pointers.push(event.pointerId);
    }

    private function removePointer(event:Event):Void {
        delete pointerPositions[event.pointerId];
        for (i in 0...pointers.length) {
            if (pointers[i] == event.pointerId) {
                pointers.splice(i, 1);
                return;
            }
        }
    }

    private function isTrackingPointer(event:Event):Bool {
        for (i in 0...pointers.length) {
            if (pointers[i] == event.pointerId) return true;
        }
        return false;
    }

    private function trackPointer(event:Event):Void {
        var position:Vector2 = pointerPositions[event.pointerId];
        if (position == null) {
            position = new Vector2();
            pointerPositions[event.pointerId] = position;
        }
        position.set(event.pageX, event.pageY);
    }

    private function getSecondPointerPosition(event:Event):Vector2 {
        var pointerId:Int = (event.pointerId == pointers[0]) ? pointers[1] : pointers[0];
        return pointerPositions[pointerId];
    }
}