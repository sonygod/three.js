import js.three.*;

class OculusHandPointerModel extends THREE.Object3D {
    public var hand:OculusHand;
    public var controller:OculusTouchController;
    public var motionController:OpenVRController;
    public var envMap:THREE.Texture;
    public var mesh:THREE.Mesh;
    public var pointerGeometry:THREE.BufferGeometry;
    public var pointerMesh:THREE.Mesh;
    public var pointerObject:THREE.Object3D;
    public var pinched:Bool;
    public var attached:Bool;
    public var cursorObject:THREE.Mesh;
    public var raycaster:THREE.Raycaster;
    public var xrInputSource:XRInputSource;

    static var PINCH_MAX:Float = 0.05;
    static var PINCH_THRESHOLD:Float = 0.02;
    static var PINCH_MIN:Float = 0.01;
    static var POINTER_ADVANCE_MAX:Float = 0.02;
    static var POINTER_OPACITY_MAX:Float = 1;
    static var POINTER_OPACITY_MIN:Float = 0.4;
    static var POINTER_FRONT_RADIUS:Float = 0.002;
    static var POINTER_REAR_RADIUS:Float = 0.01;
    static var POINTER_REAR_RADIUS_MIN:Float = 0.003;
    static var POINTER_LENGTH:Float = 0.035;
    static var POINTER_SEGMENTS:Int = 16;
    static var POINTER_RINGS:Int = 12;
    static var POINTER_HEMISPHERE_ANGLE:Float = 110;
    static inline var YAXIS:THREE.Vector3 = new THREE.Vector3(0, 1, 0);
    static inline var ZAXIS:THREE.Vector3 = new THREE.Vector3(0, 0, 1);
    static var CURSOR_RADIUS:Float = 0.02;
    static var CURSOR_MAX_DISTANCE:Float = 1.5;

    public function new(hand:OculusHand, controller:OculusTouchController) {
        super();
        this.hand = hand;
        this.controller = controller;
        this.motionController = null;
        this.envMap = null;
        this.mesh = null;
        this.pointerGeometry = null;
        this.pointerMesh = null;
        this.pointerObject = null;
        this.pinched = false;
        this.attached = false;
        this.cursorObject = null;
        this.raycaster = null;
        _onConnected = bind(_onConnected, this);
        _onDisconnected = bind(_onDisconnected, this);
        hand.addEventListener('connected', _onConnected);
        hand.addEventListener('disconnected', _onDisconnected);
    }

    function _onConnected(event:Event) {
        xrInputSource = cast event.data;
        if (xrInputSource.hand != null) {
            visible = true;
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

    function _drawVerticesRing(vertices:Array<Float>, baseVector:THREE.Vector3, ringIndex:Int) {
        var segmentVector = baseVector.clone();
        for (i in 0...POINTER_SEGMENTS) {
            segmentVector.applyAxisAngle(ZAXIS, (Math.PI * 2) / POINTER_SEGMENTS);
            var vid = ringIndex * POINTER_SEGMENTS + i;
            vertices[vid * 3] = segmentVector.x;
            vertices[vid * 3 + 1] = segmentVector.y;
            vertices[vid * 3 + 2] = segmentVector.z;
        }
    }

    function _updatePointerVertices(rearRadius:Float) {
        var vertices = pointerGeometry.attributes.position.array;
        // first ring for front face
        var frontFaceBase = new THREE.Vector3(
            POINTER_FRONT_RADIUS,
            0,
            -1 * (POINTER_LENGTH - rearRadius)
        );
        _drawVerticesRing(vertices, frontFaceBase, 0);

        // rings for rear hemisphere
        var rearBase = new THREE.Vector3(
            Math.sin((Math.PI * POINTER_HEMISPHERE_ANGLE) / 180) * rearRadius,
            Math.cos((Math.PI * POINTER_HEMISPHERE_ANGLE) / 180) * rearRadius,
            0
        );
        for (i in 0...POINTER_RINGS) {
            _drawVerticesRing(vertices, rearBase, i + 1);
            rearBase.applyAxisAngle(
                YAXIS,
                (Math.PI * POINTER_HEMISPHERE_ANGLE) / 180 / (POINTER_RINGS * -2)
            );
        }

        // front and rear face center vertices
        var frontCenterIndex = POINTER_SEGMENTS * (1 + POINTER_RINGS);
        var rearCenterIndex = POINTER_SEGMENTS * (1 + POINTER_RINGS) + 1;
        var frontCenter = new THREE.Vector3(
            0,
            0,
            -1 * (POINTER_LENGTH - rearRadius)
        );
        vertices[frontCenterIndex * 3] = frontCenter.x;
        vertices[frontCenterIndex * 3 + 1] = frontCenter.y;
        vertices[frontCenterIndex * 3 + 2] = frontCenter.z;
        var rearCenter = new THREE.Vector3(0, 0, rearRadius);
        vertices[rearCenterIndex * 3] = rearCenter.x;
        vertices[rearCenterIndex * 3 + 1] = rearCenter.y;
        vertices[rearCenterIndex * 3 + 2] = rearCenter.z;

        pointerGeometry.setAttribute(
            'position',
            new THREE.Float32BufferAttribute(vertices, 3)
        );
    }

    function createPointer() {
        var vertices = new Array<Float>();
        var indices = new Array<Int>();
        pointerGeometry = new THREE.BufferGeometry();
        pointerGeometry.setAttribute(
            'position',
            new THREE.Float32BufferAttribute(vertices, 3)
        );
        _updatePointerVertices(POINTER_REAR_RADIUS);

        // construct faces to connect rings
        for (i in 0...POINTER_RINGS) {
            for (j in 0...(POINTER_SEGMENTS - 1)) {
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

        // construct front and rear face
        var frontCenterIndex = POINTER_SEGMENTS * (1 + POINTER_RINGS);
        var rearCenterIndex = POINTER_SEGMENTS * (1 + POINTER_RINGS) + 1;
        for (i in 0...(POINTER_SEGMENTS - 1)) {
            indices.push(frontCenterIndex);
            indices.push(i + 1);
            indices.push(i);
            indices.push(rearCenterIndex);
            indices.push(i + POINTER_SEGMENTS * POINTER_RINGS);
            indices.push(i + POINTER_SEGMENTS * POINTER_RINGS + 1);
        }
        indices.push(frontCenterIndex);
        indices.push(0);
        indices.push(POINTER_SEGMENTS - 1);
        indices.push(rearCenterIndex);
        indices.push(POINTER_SEGMENTS * (POINTER_RINGS + 1) - 1);
        indices.push(POINTER_SEGMENTS * POINTER_RINGS);

        var material = new THREE.MeshBasicMaterial();
        material.transparent = true;
        material.opacity = POINTER_OPACITY_MIN;

        pointerGeometry.setIndex(indices);

        pointerMesh = new THREE.Mesh(pointerGeometry, material);
        pointerMesh.position.set(0, 0, -1 * POINTER_REAR_RADIUS);
        pointerObject = new THREE.Object3D();
        pointerObject.add(pointerMesh);

        raycaster = new THREE.Raycaster();

        // create cursor
        var cursorGeometry = new THREE.SphereGeometry(CURSOR_RADIUS, 10, 10);
        var cursorMaterial = new THREE.MeshBasicMaterial();
        cursorMaterial.transparent = true;
        cursorMaterial.opacity = POINTER_OPACITY_MIN;

        cursorObject = new THREE.Mesh(cursorGeometry, cursorMaterial);
        pointerObject.add(cursorObject);

        add(pointerObject);
    }

    function _updateRaycaster() {
        if (raycaster != null) {
            var pointerMatrix = pointerObject.matrixWorld;
            var tempMatrix = new THREE.Matrix4();
            tempMatrix.identity().extractRotation(pointerMatrix);
            raycaster.ray.origin.setFromMatrixPosition(pointerMatrix);
            raycaster.ray.direction.set(0, 0, -1).applyMatrix4(tempMatrix);
        }
    }

    function _updatePointer() {
        pointerObject.visible = controller.visible;
        var indexTip = hand.joints['index-finger-tip'];
        var thumbTip = hand.joints['thumb-tip'];
        var distance = indexTip.position.distanceTo(thumbTip.position);
        var position = indexTip.position.clone().add(thumbTip.position).multiplyScalar(0.5);
        pointerObject.position.copy(position);
        pointerObject.quaternion.copy(controller.quaternion);

        pinched = distance <= PINCH_THRESHOLD;

        var pinchScale = (distance - PINCH_MIN) / (PINCH_MAX - PINCH_MIN);
        var focusScale = (distance - PINCH_MIN) / (PINCH_THRESHOLD - PINCH_MIN);
        if (pinchScale > 1) {
            _updatePointerVertices(POINTER_REAR_RADIUS);
            pointerMesh.position.set(0, 0, -1 * POINTER_REAR_RADIUS);
            pointerMesh.material.opacity = POINTER_OPACITY_MIN;
        } else if (pinchScale > 0) {
            var rearRadius =
                (POINTER_REAR_RADIUS - POINTER_REAR_RADIUS_MIN) * pinchScale +
                POINTER_REAR_RADIUS_MIN;
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

    function intersectObject(object:THREE.Object3D, recursive:Bool = true):Array<THREE.Intersection> {
        if (raycaster != null) {
            return raycaster.intersectObject(object, recursive);
        }
        return [];
    }

    function intersectObjects(objects:Array<THREE.Object3D>, recursive:Bool = true):Array<THREE.Intersection> {
        if (raycaster != null) {
            return raycaster.intersectObjects(objects, recursive);
        }
        return [];
    }

    function checkIntersections(objects:Array<THREE.Object3D>, recursive:Bool = false) {
        if (raycaster != null && !attached) {
            var intersections = raycaster.intersectObjects(objects, recursive);
            var direction = new THREE.Vector3(0, 0, -1);
            if (intersections.length > 0) {
                var intersection = intersections[0];
                var distance = intersection.distance;
                cursorObject.position.copy(direction.multiplyScalar(distance));
            } else {
                cursorObject.position.copy(direction.multiplyScalar(CURSOR_MAX_DISTANCE));
            }
        }
    }

    function setCursor(distance:Float) {
        var direction = new THREE.Vector3(0, 0, -1);
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