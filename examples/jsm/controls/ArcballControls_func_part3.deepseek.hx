class ArcballControls {
    // ...

    public function setMouseAction(operation:String, mouse:Dynamic, key:Dynamic = null):Bool {
        // ...
    }

    public function unsetMouseAction(mouse:Dynamic, key:Dynamic = null):Bool {
        // ...
    }

    public function getOpFromAction(mouse:Dynamic, key:Dynamic):Dynamic {
        // ...
    }

    public function getOpStateFromAction(mouse:Dynamic, key:Dynamic):Dynamic {
        // ...
    }

    public function getAngle(p1:Dynamic, p2:Dynamic):Float {
        // ...
    }

    public function updateTouchEvent(event:Dynamic):Void {
        // ...
    }

    public function applyTransformMatrix(transformation:Dynamic):Void {
        // ...
    }

    public function calculateAngularSpeed(p0:Float, p1:Float, t0:Float, t1:Float):Float {
        // ...
    }

    public function calculatePointersDistance(p0:Dynamic, p1:Dynamic):Float {
        // ...
    }

    public function calculateRotationAxis(vec1:Dynamic, vec2:Dynamic):Dynamic {
        // ...
    }

    public function calculateTbRadius(camera:Dynamic):Float {
        // ...
    }

    public function focus(point:Dynamic, size:Float, amount:Float = 1):Void {
        // ...
    }

    public function drawGrid():Void {
        // ...
    }

    public function dispose():Void {
        // ...
    }

    public function disposeGrid():Void {
        // ...
    }

    public function easeOutCubic(t:Float):Float {
        // ...
    }

    public function activateGizmos(isActive:Bool):Void {
        // ...
    }

    public function getCursorNDC(cursorX:Float, cursorY:Float, canvas:Dynamic):Dynamic {
        // ...
    }

    public function getCursorPosition(cursorX:Float, cursorY:Float, canvas:Dynamic):Dynamic {
        // ...
    }

    public function setCamera(camera:Dynamic):Void {
        // ...
    }

    public function setGizmosVisible(value:Bool):Void {
        // ...
    }
}