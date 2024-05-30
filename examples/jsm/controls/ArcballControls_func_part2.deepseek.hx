class Main {
    var _state:Int;
    var _timeCurrent:Float;
    var _wPrev:Float;
    var _wCurr:Float;
    var _animationId:Int;
    var _timeStart:Float;
    var _startCursorPosition:Vector3;
    var _currentCursorPosition:Vector3;
    var _startFingerRotation:Float;
    var _currentFingerRotation:Float;
    var _rotationAxis:Vector3;
    var _startFingerDistance:Float;
    var _currentFingerDistance:Float;
    var _v3_1:Vector3;
    var _v3_2:Vector3;
    var _m4_1:Matrix4;
    var _center:Vector2;
    var _touchCurrent:Array<Touch>;
    var _touchStart:Array<Touch>;
    var _devPxRatio:Float;
    var _fovState:Float;
    var _cameraMatrixState:Matrix4;
    var _gizmoMatrixState:Matrix4;
    var _offset:Vector3;
    var _changeEvent:Event;
    var _endEvent:Event;
    var _startEvent:Event;
    var _cursorPosPrev:Vector2;
    var _cursorPosCurr:Vector2;
    var _wMax:Float;
    var _gizmos:Gizmos;
    var _camera:Camera;
    var _domElement:HtmlElement;
    var _scene:Scene;
    var _enableRotate:Bool;
    var _enableAnimations:Bool;
    var _enablePan:Bool;
    var _enableZoom:Bool;
    var _enableGrid:Bool;
    var _scaleFactor:Float;
    var _minDistance:Float;
    var _maxDistance:Float;
    var _minFov:Float;
    var _maxFov:Float;

    function onSinglePanEnd() {
        if (_state == STATE.ROTATE) {
            if (!this.enableRotate) {
                return;
            }
            if (this.enableAnimations) {
                var deltaTime = (performance.now() - _timeCurrent);
                if (deltaTime < 120) {
                    var w = Math.abs((_wPrev + _wCurr) / 2);
                    var self = this;
                    _animationId = js.Browser.requestAnimationFrame(function(t) {
                        self.updateTbState(STATE.ANIMATION_ROTATE, true);
                        var rotationAxis = self.calculateRotationAxis(_cursorPosPrev, _cursorPosCurr);
                        self.onRotationAnim(t, rotationAxis, Math.min(w, _wMax));
                    });
                } else {
                    this.updateTbState(STATE.IDLE, false);
                    this.activateGizmos(false);
                    this.dispatchEvent(_changeEvent);
                }
            } else {
                this.updateTbState(STATE.IDLE, false);
                this.activateGizmos(false);
                this.dispatchEvent(_changeEvent);
            }
        } else if (_state == STATE.PAN || _state == STATE.IDLE) {
            this.updateTbState(STATE.IDLE, false);
            if (this.enableGrid) {
                this.disposeGrid();
            }
            this.activateGizmos(false);
            this.dispatchEvent(_changeEvent);
        }
        this.dispatchEvent(_endEvent);
    }

    // ... rest of your functions ...
}