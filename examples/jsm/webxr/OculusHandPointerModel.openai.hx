package three.js.examples.webxr;

import three.js.*;

class OculusHandPointerModel extends Object3D {
    static inline var PINCH_MAX:Float = 0.05;
    static inline var PINCH_THRESHOLD:Float = 0.02;
    static inline var PINCH_MIN:Float = 0.01;
    static inline var POINTER_ADVANCE_MAX:Float = 0.02;
    static inline var POINTER_OPACITY_MAX:Float = 1;
    static inline var POINTER_OPACITY_MIN:Float = 0.4;
    static inline var POINTER_FRONT_RADIUS:Float = 0.002;
    static inline var POINTER_REAR_RADIUS:Float = 0.01;
    static inline var POINTER_REAR_RADIUS_MIN:Float = 0.003;
    static inline var POINTER_LENGTH:Float = 0.035;
    static inline var POINTER_SEGMENTS:Int = 16;
    static inline var POINTER_RINGS:Int = 12;
    static inline var POINTER_HEMISPHERE_ANGLE:Int = 110;
    static inline var CURSOR_RADIUS:Float = 0.02;
    static inline var CURSOR_MAX_DISTANCE:Float = 1.5;

    var hand:Object3D;
    var controller:Object3D;
    var motionController:Object3D;
    var envMap:Texture;
    var mesh:Mesh;
    var pointerGeometry:BufferGeometry;
    var pointerMesh:Mesh;
    var pointerObject:Object3D;
    var pinched:Bool;
    var attached:Bool;
    var cursorObject:Object3D;
    var raycaster:Raycaster;
    var _onConnected:Void->Void;
    var _onDisconnected:Void->Void;

    public function new(hand:Object3D, controller:Object3D) {
        super();
        this.hand = hand;
        this.controller = controller;

        motionController = null;
        envMap = null;
        mesh = null;

        pointerGeometry = null;
        pointerMesh = null;
        pointerObject = null;

        pinched = false;
        attached = false;

        cursorObject = null;

        raycaster = null;

        _onConnected = _onConnected.bind(this);
        _onDisconnected = _onDisconnected.bind(this);
        hand.addEventListener('connected', _onConnected);
        hand.addEventListener('disconnected', _onDisconnected);
    }

    function _onConnected(event:Event) {
        var xrInputSource:XrInputSource = event.data;
        if (xrInputSource.hand) {
            visible = true;
            xrInputSource = xrInputSource;
            createPointer();
        }
    }

    function _onDisconnected() {
        visible = false;
        xrInputSource = null;
        if (pointerGeometry != null) pointerGeometry.dispose();
        if (pointerMesh != null && pointerMesh.material != null) pointerMesh.material.dispose();
        clear();
    }

    function _drawVerticesRing(vertices:Array<Float>, baseVector:Vector3, ringIndex:Int) {
        var segmentVector:Vector3 = baseVector.clone();
        for (i in 0...POINTER_SEGMENTS) {
            segmentVector.applyAxisAngle(ZAXIS, Math.PI * 2 / POINTER_SEGMENTS);
            var vid:Int = ringIndex * POINTER_SEGMENTS + i;
            vertices[vid * 3] = segmentVector.x;
            vertices[vid * 3 + 1] = segmentVector.y;
            vertices[vid * 3 + 2] = segmentVector.z;
        }
    }

    function _updatePointerVertices(rearRadius:Float) {
        var vertices:Array<Float> = pointerGeometry.attributes.position.array;
        var frontFaceBase:Vector3 = new Vector3(
            POINTER_FRONT_RADIUS,
            0,
            -1 * (POINTER_LENGTH - rearRadius)
        );
        _drawVerticesRing(vertices, frontFaceBase, 0);

        var rearBase:Vector3 = new Vector3(
            Math.sin(Math.PI * POINTER_HEMISPHERE_ANGLE / 180) * rearRadius,
            Math.cos(Math.PI * POINTER_HEMISPHERE_ANGLE / 180) * rearRadius,
            0
        );
        for (i in 0...POINTER_RINGS) {
            _drawVerticesRing(vertices, rearBase, i + 1);
            rearBase.applyAxisAngle(YAXIS, Math.PI * POINTER_HEMISPHERE_ANGLE / 180 / (POINTER_RINGS * -2));
        }

        var frontCenterIndex:Int = POINTER_SEGMENTS * (1 + POINTER_RINGS);
        var rearCenterIndex:Int = POINTER_SEGMENTS * (1 + POINTER_RINGS) + 1;
        var frontCenter:Vector3 = new Vector3(
            0,
            0,
            -1 * (POINTER_LENGTH - rearRadius)
        );
        vertices[frontCenterIndex * 3] = frontCenter.x;
        vertices[frontCenterIndex * 3 + 1] = frontCenter.y;
        vertices[frontCenterIndex * 3 + 2] = frontCenter.z;
        var rearCenter:Vector3 = new Vector3(0, 0, rearRadius);
        vertices[rearCenterIndex * 3] = rearCenter.x;
        vertices[rearCenterIndex * 3 + 1] = rearCenter.y;
        vertices[rearCenterIndex * 3 + 2] = rearCenter.z;

        pointerGeometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
    }

    function createPointer() {
        var vertices:Array<Float> = new Array((POINTER_RINGS + 1) * POINTER_SEGMENTS + 2 * 3).fill(0);
        var indices:Array<Int> = [];
        pointerGeometry = new BufferGeometry();

        pointerGeometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));

        _updatePointerVertices(POINTER_REAR_RADIUS);

        for (i in 0...POINTER_RINGS) {
            for (j in 0...POINTER_SEGMENTS - 1) {
                indices.push(i * POINTER_SEGMENTS + j);
                indices.push(i * POINTER_SEGMENTS + j + 1);
                indices.push((i + 1) * POINTER_SEGMENTS + j);
                indices.push(i * POINTER_SEGMENTS + j + 1);
                indices.push((i + 1) * POINTER_SEGMENTS + j + 1);
                indices.push((i + 1) * POINTER_SEGMENTS + j);
            }

            indices.push((i + 1) * POINTER_SEGMENTS - 1);
            indices.push(i * POINTER_SEGMENTS);
            indices.push((i + 2) * POINTER_SEGMENTS - 1);
            indices.push(i * POINTER_SEGMENTS);
            indices.push((i + 1) * POINTER_SEGMENTS);
            indices.push((i + 2) * POINTER_SEGMENTS - 1);
        }

        for (i in 0...POINTER_SEGMENTS - 1) {
            indices.push(frontCenterIndex, i + 1, i);
            indices.push(rearCenterIndex, i + POINTER_SEGMENTS * POINTER_RINGS, i + POINTER_SEGMENTS * POINTER_RINGS + 1);
        }

        indices.push(frontCenterIndex, 0, POINTER_SEGMENTS - 1);
        indices.push(rearCenterIndex, POINTER_SEGMENTS * (POINTER_RINGS + 1) - 1, POINTER_SEGMENTS * POINTER_RINGS);

        var material:MeshBasicMaterial = new MeshBasicMaterial();
        material.transparent = true;
        material.opacity = POINTER_OPACITY_MIN;

        pointerGeometry.setIndex(indices);

        pointerMesh = new Mesh(pointerGeometry, material);
        pointerObject = new Object3D();
        pointerObject.add(pointerMesh);

        raycaster = new Raycaster();

        var cursorGeometry:Geometry = new SphereGeometry(CURSOR_RADIUS, 10, 10);
        var cursorMaterial:MeshBasicMaterial = new MeshBasicMaterial();
        cursorMaterial.transparent = true;
        cursorMaterial.opacity = POINTER_OPACITY_MIN;
        cursorObject = new Mesh(cursorGeometry, cursorMaterial);
        pointerObject.add(cursorObject);

        add(pointerObject);
    }

    function _updateRaycaster() {
        if (raycaster != null) {
            var pointerMatrix:Matrix4 = pointerObject.matrixWorld;
            var tempMatrix:Matrix4 = new Matrix4();
            tempMatrix.identity().extractRotation(pointerMatrix);
            raycaster.ray.origin.setFromMatrixPosition(pointerMatrix);
            raycaster.ray.direction.set(0, 0, -1).applyMatrix4(tempMatrix);
        }
    }

    function _updatePointer() {
        pointerObject.visible = controller.visible;
        var indexTip:Vector3 = hand.joints.get('index-finger-tip').position;
        var thumbTip:Vector3 = hand.joints.get('thumb-tip').position;
        var distance:Float = indexTip.distanceTo(thumbTip);
        var position:Vector3 = indexTip.clone().add(thumbTip).multiplyScalar(0.5);
        pointerObject.position.copy(position);
        pointerObject.quaternion.copy(controller.quaternion);

        pinched = distance <= PINCH_THRESHOLD;

        var pinchScale:Float = (distance - PINCH_MIN) / (PINCH_MAX - PINCH_MIN);
        var focusScale:Float = (distance - PINCH_MIN) / (PINCH_THRESHOLD - PINCH_MIN);
        if (pinchScale > 1) {
            _updatePointerVertices(POINTER_REAR_RADIUS);
            pointerMesh.position.set(0, 0, -1 * POINTER_REAR_RADIUS);
            pointerMesh.material.opacity = POINTER_OPACITY_MIN;
        } else if (pinchScale > 0) {
            var rearRadius:Float = (POINTER_REAR_RADIUS - POINTER_REAR_RADIUS_MIN) * pinchScale + POINTER_REAR_RADIUS_MIN;
            _updatePointerVertices(rearRadius);
            if (focusScale < 1) {
                pointerMesh.position.set(
                    0,
                    0,
                    -1 * rearRadius - (1 - focusScale) * POINTER_ADVANCE_MAX
                );
                pointerMesh.material.opacity =
                    POINTER_OPACITY_MIN +
                    (1 - focusScale) * (POINTER_OPACITY_MAX - POINTER_OPACITY_MIN);
            } else {
                pointerMesh.position.set(0, 0, -1 * rearRadius);
                pointerMesh.material.opacity = POINTER_OPACITY_MIN;
            }
        } else {
            _updatePointerVertices(POINTER_REAR_RADIUS_MIN);
            pointerMesh.position.set(
                0,
                0,
                -1 * POINTER_REAR_RADIUS_MIN - POINTER_ADVANCE_MAX
            );
            pointerMesh.material.opacity = POINTER_OPACITY_MAX;
        }

        cursorObject.material.opacity = pointerMesh.material.opacity;
    }

    override function updateMatrixWorld(force:Bool) {
        super.updateMatrixWorld(force);
        if (pointerGeometry != null) {
            _updatePointer();
            _updateRaycaster();
        }
    }

    function isPinched():Bool {
        return pinched;
    }

    function setAttached(attached:Bool) {
        this.attached = attached;
    }

    function isAttached():Bool {
        return attached;
    }

    function intersectObject(object:Object3D, recursive:Bool = true):Array<RaycastResult> {
        if (raycaster != null) {
            return raycaster.intersectObject(object, recursive);
        }
        return [];
    }

    function intersectObjects(objects:Array<Object3D>, recursive:Bool = true):Array<RaycastResult> {
        if (raycaster != null) {
            return raycaster.intersectObjects(objects, recursive);
        }
        return [];
    }

    function checkIntersections(objects:Array<Object3D>, recursive:Bool = false) {
        if (raycaster != null && !attached) {
            var intersections:Array<RaycastResult> = raycaster.intersectObjects(objects, recursive);
            var direction:Vector3 = new Vector3(0, 0, -1);
            if (intersections.length > 0) {
                var intersection:RaycastResult = intersections[0];
                var distance:Float = intersection.distance;
                cursorObject.position.copy(direction.multiplyScalar(distance));
            } else {
                cursorObject.position.copy(direction.multiplyScalar(CURSOR_MAX_DISTANCE));
            }
        }
    }

    function setCursor(distance:Float) {
        var direction:Vector3 = new Vector3(0, 0, -1);
        if (raycaster != null && !attached) {
            cursorObject.position.copy(direction.multiplyScalar(distance));
        }
    }

    function dispose() {
        _onDisconnected();
        hand.removeEventListener('connected', _onConnected);
        hand.removeEventListener('disconnected', _onDisconnected);
    }
}