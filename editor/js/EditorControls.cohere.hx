import js.three.EventDispatcher;
import js.three.Matrix3;
import js.three.Sphere;
import js.three.Spherical;
import js.three.Vector2;
import js.three.Vector3;

class EditorControls extends EventDispatcher {
    public var enabled:Bool;
    public var center:Vector3;
    public var panSpeed:Float;
    public var zoomSpeed:Float;
    public var rotationSpeed:Float;

    private var scope:EditorControls;
    private var vector:Vector3;
    private var delta:Vector3;
    private var box:js.three.Box3;

    private static var STATE:Array<Int>;
    private var state:Int;

    private var normalMatrix:Matrix3;
    private var pointer:Vector2;
    private var pointerOld:Vector2;
    private var spherical:Spherical;
    private var sphere:Sphere;

    private var pointers:Array<Int>;
    private var pointerPositions:Map<Int, Vector2>;

    private var changeEvent:Dynamic;

    public function new(object:Dynamic, domElement:Dynamic) {
        super();

        scope = this;
        vector = new Vector3();
        delta = new Vector3();
        box = new js.three.Box3();

        STATE = [-1, 0, 1, 2];
        state = STATE[0];

        center = new Vector3();
        normalMatrix = new Matrix3();
        pointer = new Vector2();
        pointerOld = new Vector2();
        spherical = new Spherical();
        sphere = new Sphere();

        pointers = [];
        pointerPositions = new Map();

        changeEvent = { type: 'change' };

        this.focus = function(target:Dynamic) {
            var distance:Float;

            box.setFromObject(target);

            if (box.isEmpty()) {
                box.getCenter(center);
                distance = box.getBoundingSphere(sphere).radius;
            } else {
                center.setFromMatrixPosition(target.matrixWorld);
                distance = 0.1;
            }

            delta.set(0, 0, 1);
            delta.applyQuaternion(object.quaternion);
            delta.multiplyScalar(distance * 4);

            object.position.copy(center).add(delta);

            scope.dispatchEvent(changeEvent);
        };

        this.pan = function(delta:Vector3) {
            var distance = object.position.distanceTo(center);

            delta.multiplyScalar(distance * scope.panSpeed);
            delta.applyMatrix3(normalMatrix.getNormalMatrix(object.matrix));

            object.position.add(delta);
            center.add(delta);

            scope.dispatchEvent(changeEvent);
        };

        this.zoom = function(delta:Vector3) {
            var distance = object.position.distanceTo(center);

            delta.multiplyScalar(distance * scope.zoomSpeed);

            if (delta.length() > distance) {
                return;
            }

            delta.applyMatrix3(normalMatrix.getNormalMatrix(object.matrix));

            object.position.add(delta);

            scope.dispatchEvent(changeEvent);
        };

        this.rotate = function(delta:Vector3) {
            vector.copy(object.position).sub(center);

            spherical.setFromVector3(vector);

            spherical.theta += delta.x * scope.rotationSpeed;
            spherical.phi += delta.y * scope.rotationSpeed;

            spherical.makeSafe();

            vector.setFromSpherical(spherical);

            object.position.copy(center).add(vector);

            object.lookAt(center);

            scope.dispatchEvent(changeEvent);
        };

        function onPointerDown(event:Dynamic) {
            if (scope.enabled == false) {
                return;
            }

            if (pointers.length == 0) {
                domElement.setPointerCapture(event.pointerId);

                domElement.ownerDocument.addEventListener('pointermove', onPointerMove);
                domElement.ownerDocument.addEventListener('pointerup', onPointerUp);
            }

            if (isTrackingPointer(event)) {
                return;
            }

            addPointer(event);

            if (event.pointerType == 'touch') {
                onTouchStart(event);
            } else {
                onMouseDown(event);
            }
        }

        function onPointerMove(event:Dynamic) {
            if (scope.enabled == false) {
                return;
            }

            if (event.pointerType == 'touch') {
                onTouchMove(event);
            } else {
                onMouseMove(event);
            }
        }

        function onPointerUp(event:Dynamic) {
            removePointer(event);

            switch (pointers.length) {
                case 0:
                    domElement.releasePointerCapture(event.pointerId);

                    domElement.ownerDocument.removeEventListener('pointermove', onPointerMove);
                    domElement.ownerDocument.removeEventListener('pointerup', onPointerUp);
                    break;

                case 1:
                    var pointerId = pointers[0];
                    var position = pointerPositions.get(pointerId);

                    // minimal placeholder event - allows state correction on pointer-up
                    onTouchStart({ pointerId: pointerId, pageX: position.x, pageY: position.y });
                    break;
            }
        }

        // mouse

        function onMouseDown(event:Dynamic) {
            if (event.button == 0) {
                state = STATE[0];
            } else if (event.button == 1) {
                state = STATE[1];
            } else if (event.button == 2) {
                state = STATE[2];
            }

            pointerOld.set(event.clientX, event.clientY);
        }

        function onMouseMove(event:Dynamic) {
            pointer.set(event.clientX, event.clientY);

            var movementX = pointer.x - pointerOld.x;
            var movementY = pointer.y - pointerOld.y;

            if (state == STATE[0]) {
                scope.rotate(delta.set(-movementX, -movementY, 0));
            } else if (state == STATE[1]) {
                scope.zoom(delta.set(0, 0, movementY));
            } else if (state == STATE[2]) {
                scope.pan(delta.set(-movementX, movementY, 0));
            }

            pointerOld.set(event.clientX, event.clientY);
        }

        function onMouseUp() {
            state = STATE[3];
        }

        function onMouseWheel(event:Dynamic) {
            if (scope.enabled == false) {
                return;
            }

            event.preventDefault();

            // Normalize deltaY due to https://bugzilla.mozilla.org/show_bug.cgi?id=1392460
            scope.zoom(delta.set(0, 0, event.deltaY > 0 ? 1 : -1));
        }

        function contextmenu(event:Dynamic) {
            event.preventDefault();
        }

        this.dispose = function() {
            domElement.removeEventListener('contextmenu', contextmenu);
            domElement.removeEventListener('dblclick', onMouseUp);
            domElement.removeEventListener('wheel', onMouseWheel);

            domElement.removeEventListener('pointerdown', onPointerDown);
        };

        domElement.addEventListener('contextmenu', contextmenu);
        domElement.addEventListener('dblclick', onMouseUp);
        domElement.addEventListener('wheel', onMouseWheel, { passive: false });

        domElement.addEventListener('pointerdown', onPointerDown);

        // touch

        var touches = [new Vector3(), new Vector3(), new Vector3()];
        var prevTouches = [new Vector3(), new Vector3(), new Vector3()];

        var prevDistance:Float;

        function onTouchStart(event:Dynamic) {
            trackPointer(event);

            switch (pointers.length) {
                case 1:
                    touches[0].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
                    touches[1].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
                    break;

                case 2:
                    var position = getSecondPointerPosition(event);

                    touches[0].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
                    touches[1].set(position.x, position.y, 0).divideScalar(window.devicePixelRatio);
                    prevDistance = touches[0].distanceTo(touches[1]);
                    break;
            }

            prevTouches[0].copy(touches[0]);
            prevTouches[1].copy(touches[1]);
        }

        function onTouchMove(event:Dynamic) {
            trackPointer(event);

            function getClosest(touch:Vector3, touches:Array<Vector3>) {
                var closest = touches[0];

                for (touch2 in touches) {
                    if (closest.distanceTo(touch) > touch2.distanceTo(touch)) {
                        closest = touch2;
                    }
                }

                return closest;
            }

            switch (pointers.length) {
                case 1:
                    touches[0].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
                    touches[1].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
                    scope.rotate(touches[0].sub(getClosest(touches[0], prevTouches)).multiplyScalar(-1));
                    break;

                case 2:
                    var position = getSecondPointerPosition(event);

                    touches[0].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
                    touches[1].set(position.x, position.y, 0).divideScalar(window.devicePixelRatio);
                    var distance = touches[0].distanceTo(touches[1]);
                    scope.zoom(delta.set(0, 0, prevDistance - distance));
                    prevDistance = distance;

                    var offset0 = touches[0].clone().sub(getClosest(touches[0], prevTouches));
                    var offset1 = touches[1].clone().sub(getClosest(touches[1], prevTouches));
                    offset0.x = -offset0.x;
                    offset1.x = -offset1.x;

                    scope.pan(offset0.add(offset1));
                    break;
            }

            prevTouches[0].copy(touches[0]);
            prevTouches[1].copy(touches[1]);
        }

        function addPointer(event:Dynamic) {
            pointers.push(event.pointerId);
        }

        function removePointer(event:Dynamic) {
            pointerPositions.remove(event.pointerId);

            for (i in 0...pointers.length) {
                if (pointers[i] == event.pointerId) {
                    pointers.splice(i, 1);
                    return;
                }
            }
        }

        function isTrackingPointer(event:Dynamic) {
            for (i in 0...pointers.length) {
                if (pointers[i] == event.pointerId) {
                    return true;
                }
            }

            return false;
        }

        function trackPointer(event:Dynamic) {
            var position = pointerPositions.get(event.pointerId);

            if (position == null) {
                position = new Vector2();
                pointerPositions.set(event.pointerId, position);
            }

            position.set(event.pageX, event.pageY);
        }

        function getSecondPointerPosition(event:Dynamic) {
            var pointerId = (event.pointerId == pointers[0]) ? pointers[1] : pointers[0];

            return pointerPositions.get(pointerId);
        }
    }
}