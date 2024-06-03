import three.math.Vector3;
import three.objects.Group;

class MoveEvent extends Event {
    public function new() { super("move"); }
}

class WebXRController {
    private var _targetRay:Group;
    private var _grip:Group;
    private var _hand:Group;
    private var _moveEvent:MoveEvent;

    public function new() {
        _targetRay = null;
        _grip = null;
        _hand = null;
        _moveEvent = new MoveEvent();
    }

    public function getHandSpace():Group {
        if (_hand == null) {
            _hand = new Group();
            _hand.matrixAutoUpdate = false;
            _hand.visible = false;
            _hand.joints = new haxe.ds.StringMap<Group>();
            _hand.inputState = { pinching: false };
        }
        return _hand;
    }

    public function getTargetRaySpace():Group {
        if (_targetRay == null) {
            _targetRay = new Group();
            _targetRay.matrixAutoUpdate = false;
            _targetRay.visible = false;
            _targetRay.hasLinearVelocity = false;
            _targetRay.linearVelocity = new Vector3();
            _targetRay.hasAngularVelocity = false;
            _targetRay.angularVelocity = new Vector3();
        }
        return _targetRay;
    }

    public function getGripSpace():Group {
        if (_grip == null) {
            _grip = new Group();
            _grip.matrixAutoUpdate = false;
            _grip.visible = false;
            _grip.hasLinearVelocity = false;
            _grip.linearVelocity = new Vector3();
            _grip.hasAngularVelocity = false;
            _grip.angularVelocity = new Vector3();
        }
        return _grip;
    }

    public function dispatchEvent(event:Event):WebXRController {
        if (_targetRay != null) {
            _targetRay.dispatchEvent(event);
        }
        if (_grip != null) {
            _grip.dispatchEvent(event);
        }
        if (_hand != null) {
            _hand.dispatchEvent(event);
        }
        return this;
    }

    public function connect(inputSource):WebXRController {
        if (inputSource != null && inputSource.hasOwnProperty("hand")) {
            var hand = _hand;
            if (hand != null) {
                for (inputJoint in Reflect.fields(inputSource.hand)) {
                    _getHandJoint(hand, Reflect.field(inputSource.hand, inputJoint));
                }
            }
        }
        dispatchEvent(new Event("connected", { data: inputSource }));
        return this;
    }

    public function disconnect(inputSource):WebXRController {
        dispatchEvent(new Event("disconnected", { data: inputSource }));
        if (_targetRay != null) {
            _targetRay.visible = false;
        }
        if (_grip != null) {
            _grip.visible = false;
        }
        if (_hand != null) {
            _hand.visible = false;
        }
        return this;
    }

    public function update(inputSource, frame, referenceSpace):WebXRController {
        var inputPose = null;
        var gripPose = null;
        var handPose = null;

        var targetRay = _targetRay;
        var grip = _grip;
        var hand = _hand;

        if (inputSource != null && frame.session.visibilityState != "visible-blurred") {
            if (hand != null && inputSource.hasOwnProperty("hand")) {
                handPose = true;
                for (inputJoint in Reflect.fields(inputSource.hand)) {
                    var jointPose = frame.getJointPose(Reflect.field(inputSource.hand, inputJoint), referenceSpace);
                    var joint = _getHandJoint(hand, Reflect.field(inputSource.hand, inputJoint));

                    if (jointPose != null) {
                        joint.matrix.fromArray(jointPose.transform.matrix);
                        joint.matrix.decompose(joint.position, joint.rotation, joint.scale);
                        joint.matrixWorldNeedsUpdate = true;
                        joint.jointRadius = jointPose.radius;
                    }

                    joint.visible = jointPose != null;
                }

                var indexTip = hand.joints.get("index-finger-tip");
                var thumbTip = hand.joints.get("thumb-tip");
                var distance = indexTip.position.distanceTo(thumbTip.position);

                var distanceToPinch = 0.02;
                var threshold = 0.005;

                if (hand.inputState.pinching && distance > distanceToPinch + threshold) {
                    hand.inputState.pinching = false;
                    dispatchEvent(new Event("pinchend", {
                        handedness: inputSource.handedness,
                        target: this
                    }));
                } else if (!hand.inputState.pinching && distance <= distanceToPinch - threshold) {
                    hand.inputState.pinching = true;
                    dispatchEvent(new Event("pinchstart", {
                        handedness: inputSource.handedness,
                        target: this
                    }));
                }
            } else {
                if (grip != null && inputSource.hasOwnProperty("gripSpace")) {
                    gripPose = frame.getPose(inputSource.gripSpace, referenceSpace);
                    if (gripPose != null) {
                        grip.matrix.fromArray(gripPose.transform.matrix);
                        grip.matrix.decompose(grip.position, grip.rotation, grip.scale);
                        grip.matrixWorldNeedsUpdate = true;

                        if (gripPose.hasOwnProperty("linearVelocity")) {
                            grip.hasLinearVelocity = true;
                            grip.linearVelocity.copy(gripPose.linearVelocity);
                        } else {
                            grip.hasLinearVelocity = false;
                        }

                        if (gripPose.hasOwnProperty("angularVelocity")) {
                            grip.hasAngularVelocity = true;
                            grip.angularVelocity.copy(gripPose.angularVelocity);
                        } else {
                            grip.hasAngularVelocity = false;
                        }
                    }
                }
            }

            if (targetRay != null) {
                inputPose = frame.getPose(inputSource.targetRaySpace, referenceSpace);

                if (inputPose == null && gripPose != null) {
                    inputPose = gripPose;
                }

                if (inputPose != null) {
                    targetRay.matrix.fromArray(inputPose.transform.matrix);
                    targetRay.matrix.decompose(targetRay.position, targetRay.rotation, targetRay.scale);
                    targetRay.matrixWorldNeedsUpdate = true;

                    if (inputPose.hasOwnProperty("linearVelocity")) {
                        targetRay.hasLinearVelocity = true;
                        targetRay.linearVelocity.copy(inputPose.linearVelocity);
                    } else {
                        targetRay.hasLinearVelocity = false;
                    }

                    if (inputPose.hasOwnProperty("angularVelocity")) {
                        targetRay.hasAngularVelocity = true;
                        targetRay.angularVelocity.copy(inputPose.angularVelocity);
                    } else {
                        targetRay.hasAngularVelocity = false;
                    }

                    dispatchEvent(_moveEvent);
                }
            }
        }

        if (targetRay != null) {
            targetRay.visible = inputPose != null;
        }

        if (grip != null) {
            grip.visible = gripPose != null;
        }

        if (hand != null) {
            hand.visible = handPose != null;
        }

        return this;
    }

    private function _getHandJoint(hand:Group, inputJoint):Group {
        if (hand.joints.exists(inputJoint.jointName) == false) {
            var joint = new Group();
            joint.matrixAutoUpdate = false;
            joint.visible = false;
            hand.joints.set(inputJoint.jointName, joint);
            hand.add(joint);
        }
        return hand.joints.get(inputJoint.jointName);
    }
}