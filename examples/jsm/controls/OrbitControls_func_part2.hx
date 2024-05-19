package three.js.examples.jsm.controls;

import three.Vector3;
import three.Matrix4;
import three.PerspectiveCamera;
import three.OrthographicCamera;
import three.EventDispatcher;

class OrbitControlsFuncPart2 {
    var scope:Dynamic;
    var panOffset:Vector3;
    var panLeft:Vector3->Float->Void;
    var panUp:Vector3->Float->Void;
    var pan:Float->Float->Void;
    var dollyOut:Float->Void;
    var dollyIn:Float->Void;
    var updateZoomParameters:Float->Float->Void;
    var clampDistance:Float->Float;
    var handleMouseDownRotate:Event->Void;
    var handleMouseDownDolly:Event->Void;
    var handleMouseDownPan:Event->Void;
    var handleMouseMoveRotate:Event->Void;
    var handleMouseMoveDolly:Event->Void;
    var handleMouseMovePan:Event->Void;
    var handleMouseWheel:Event->Void;
    var handleKeyDown:Event->Void;
    var handleTouchStartRotate:Event->Void;
    var handleTouchStartPan:Event->Void;
    var handleTouchStartDolly:Event->Void;
    var handleTouchStartDollyPan:Event->Void;
    var handleTouchStartDollyRotate:Event->Void;
    var handleTouchMoveRotate:Event->Void;
    var handleTouchMovePan:Event->Void;
    var handleTouchMoveDolly:Event->Void;
    var handleTouchMoveDollyPan:Event->Void;
    var handleTouchMoveDollyRotate:Event->Void;

    public function new(scope:Dynamic) {
        this.scope = scope;
        this.panOffset = new Vector3();
        this.panLeft = panLeftFunc();
        this.panUp = panUpFunc();
        this.pan = panFunc();
        this.dollyOut = dollyOutFunc();
        this.dollyIn = dollyInFunc();
        this.updateZoomParameters = updateZoomParametersFunc();
        this.clampDistance = clampDistanceFunc();
    }

    function panLeftFunc():Vector3->Float->Void {
        var v = new Vector3();
        return function panLeft(distance:Float, objectMatrix:Matrix4):Void {
            v.setFromMatrixColumn(objectMatrix, 0); // get X column of objectMatrix
            v.multiplyScalar(-distance);
            panOffset.add(v);
        };
    }

    function panUpFunc():Vector3->Float->Void {
        var v = new Vector3();
        return function panUp(distance:Float, objectMatrix:Matrix4):Void {
            if (scope.screenSpacePanning) {
                v.setFromMatrixColumn(objectMatrix, 1);
            } else {
                v.setFromMatrixColumn(objectMatrix, 0);
                v.crossVectors(scope.object.up, v);
            }
            v.multiplyScalar(distance);
            panOffset.add(v);
        };
    }

    function panFunc():Float->Float->Void {
        var offset = new Vector3();
        return function pan(deltaX:Float, deltaY:Float):Void {
            var element = scope.domElement;
            if (scope.object.isPerspectiveCamera) {
                // perspective
                var position = scope.object.position;
                offset.copy(position).sub(scope.target);
                var targetDistance = offset.length();
                targetDistance *= Math.tan((scope.object.fov / 2) * Math.PI / 180.0);
                panLeft(2 * deltaX * targetDistance / element.clientHeight, scope.object.matrix);
                panUp(2 * deltaY * targetDistance / element.clientHeight, scope.object.matrix);
            } else if (scope.object.isOrthographicCamera) {
                // orthographic
                panLeft(deltaX * (scope.object.right - scope.object.left) / scope.object.zoom / element.clientWidth, scope.object.matrix);
                panUp(deltaY * (scope.object.top - scope.object.bottom) / scope.object.zoom / element.clientHeight, scope.object.matrix);
            } else {
                // camera neither orthographic nor perspective
                console.warn('WARNING: OrbitControls.js encountered an unknown camera type - pan disabled.');
                scope.enablePan = false;
            }
        };
    }

    function dollyOutFunc():Float->Void {
        return function dollyOut(dollyScale:Float):Void {
            if (scope.object.isPerspectiveCamera || scope.object.isOrthographicCamera) {
                scale /= dollyScale;
            } else {
                console.warn('WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.');
                scope.enableZoom = false;
            }
        };
    }

    function dollyInFunc():Float->Void {
        return function dollyIn(dollyScale:Float):Void {
            if (scope.object.isPerspectiveCamera || scope.object.isOrthographicCamera) {
                scale *= dollyScale;
            } else {
                console.warn('WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.');
                scope.enableZoom = false;
            }
        };
    }

    function updateZoomParametersFunc():Float->Float->Void {
        return function updateZoomParameters(x:Float, y:Float):Void {
            if (!scope.zoomToCursor) return;
            performCursorZoom = true;
            var rect = scope.domElement.getBoundingClientRect();
            var dx = x - rect.left;
            var dy = y - rect.top;
            var w = rect.width;
            var h = rect.height;
            mouse.x = (dx / w) * 2 - 1;
            mouse.y = -(dy / h) * 2 + 1;
            dollyDirection.set(mouse.x, mouse.y, 1).unproject(scope.object).sub(scope.object.position).normalize();
        };
    }

    function clampDistanceFunc():Float->Float {
        return function clampDistance(dist:Float):Float {
            return Math.max(scope.minDistance, Math.min(scope.maxDistance, dist));
        };
    }

    // ... (rest of the code remains the same)
}