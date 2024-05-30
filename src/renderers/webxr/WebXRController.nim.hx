import Vector3.{Float32Array, Vector3Default};
import Group.{GroupDefault, Matrix4};

class WebXRController {
    private var _targetRay: GroupDefault;
    private var _grip: GroupDefault;
    private var _hand: GroupDefault;

    public function new() {
        this._targetRay = null;
        this._grip = null;
        this._hand = null;
    }

    public function getHandSpace(): GroupDefault {
        if (this._hand == null) {
            this._hand = new GroupDefault();
            this._hand.matrixAutoUpdate = false;
            this._hand.visible = false;

            this._hand.joints = new Map<String, GroupDefault>();
            this._hand.inputState = { pinching: false };
        }

        return this._hand;
    }

    public function getTargetRaySpace(): GroupDefault {
        if (this._targetRay == null) {
            this._targetRay = new GroupDefault();
            this._targetRay.matrixAutoUpdate = false;
            this._targetRay.visible = false;
            this._targetRay.hasLinearVelocity = false;
            this._targetRay.linearVelocity = new Vector3Default();
            this._targetRay.hasAngularVelocity = false;
            this._targetRay.angularVelocity = new Vector3Default();
        }

        return this._targetRay;
    }

    public function getGripSpace(): GroupDefault {
        if (this._grip == null) {
            this._grip = new GroupDefault();
            this._grip.matrixAutoUpdate = false;
            this._grip.visible = false;
            this._grip.hasLinearVelocity = false;
            this._grip.linearVelocity = new Vector3Default();
            this._grip.hasAngularVelocity = false;
            this._grip.angularVelocity = new Vector3Default();
        }

        return this._grip;
    }

    public function dispatchEvent(event: Dynamic): GroupDefault {
        if (this._targetRay != null) {
            this._targetRay.dispatchEvent(event);
        }

        if (this._grip != null) {
            this._grip.dispatchEvent(event);
        }

        if (this._hand != null) {
            this._hand.dispatchEvent(event);
        }

        return this;
    }

    public function connect(inputSource: Dynamic): GroupDefault {
        if (inputSource && inputSource.hand) {
            let hand = this._hand;

            if (hand != null) {
                for (inputjoint in inputSource.hand.values()) {
                    this._getHandJoint(hand, inputjoint);
                }
            }
        }

        this.dispatchEvent({ type: 'connected', data: inputSource });

        return this;
    }

    public function disconnect(inputSource: Dynamic): GroupDefault {
        this.dispatchEvent({ type: 'disconnected', data: inputSource });

        if (this._targetRay != null) {
            this._targetRay.visible = false;
        }

        if (this._grip != null) {
            this._grip.visible = false;
        }

        if (this._hand != null) {
            this._hand.visible = false;
        }

        return this;
    }

    public function update(inputSource: Dynamic, frame: Dynamic, referenceSpace: Dynamic): GroupDefault {
        let inputPose: Dynamic = null;
        let gripPose: Dynamic = null;
        let handPose: Dynamic = null;

        let targetRay = this._targetRay;
        let grip = this._grip;
        let hand = this._hand;

        if (inputSource && frame.session.visibilityState != 'visible-blurred') {
            if (hand != null && inputSource.hand) {
                handPose = true;

                for (inputjoint in inputSource.hand.values()) {
                    let jointPose = frame.getJointPose(inputjoint, referenceSpace);
                    let joint = this._getHandJoint(hand, inputjoint);

                    if (jointPose != null) {
                        joint.matrix.fromArray(jointPose.transform.matrix);
                        joint.matrix.decompose(joint.position, joint.rotation, joint.scale);
                        joint.matrixWorldNeedsUpdate = true;
                        joint.jointRadius = jointPose.radius;
                    }

                    joint.visible = jointPose != null;
                }

                // Custom events

                // Check pinchz
                let indexTip = hand.joints['index-finger-tip'];
                let thumbTip = hand.joints['thumb-tip'];
                let distance = indexTip.position.distanceTo(thumbTip.position);

                let distanceToPinch = 0.02;
                let threshold = 0.005;

                if (hand.inputState.pinching && distance > distanceToPinch + threshold) {
                    hand.inputState.pinching = false;
                    this.dispatchEvent({ type: 'pinchend', handedness: inputSource.handedness, target: this });
                } else if (!hand.inputState.pinching && distance <= distanceToPinch - threshold) {
                    hand.inputState.pinching = true;
                    this.dispatchEvent({ type: 'pinchstart', handedness: inputSource.handedness, target: this });
                }
            } else {
                if (grip != null && inputSource.gripSpace) {
                    gripPose = frame.getPose(inputSource.gripSpace, referenceSpace);

                    if (gripPose != null) {
                        grip.matrix.fromArray(gripPose.transform.matrix);
                        grip.matrix.decompose(grip.position, grip.rotation, grip.scale);
                        grip.matrixWorldNeedsUpdate = true;

                        if (gripPose.linearVelocity) {
                            grip.hasLinearVelocity = true;
                            grip.linearVelocity.copy(gripPose.linearVelocity);
                        } else {
                            grip.hasLinearVelocity = false;
                        }

                        if (gripPose.angularVelocity) {
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

                // Some runtimes (namely Vive Cosmos with Vive OpenXR Runtime) have only grip space and ray space is equal to it
                if (inputPose == null && gripPose != null) {
                    inputPose = gripPose;
                }

                if (inputPose != null) {
                    targetRay.matrix.fromArray(inputPose.transform.matrix);
                    targetRay.matrix.decompose(targetRay.position, targetRay.rotation, targetRay.scale);
                    targetRay.matrixWorldNeedsUpdate = true;

                    if (inputPose.linearVelocity) {
                        targetRay.hasLinearVelocity = true;
                        targetRay.linearVelocity.copy(inputPose.linearVelocity);
                    } else {
                        targetRay.hasLinearVelocity = false;
                    }

                    if (inputPose.angularVelocity) {
                        targetRay.hasAngularVelocity = true;
                        targetRay.angularVelocity.copy(inputPose.angularVelocity);
                    } else {
                        targetRay.hasAngularVelocity = false;
                    }

                    this.dispatchEvent(_moveEvent);
                }
            }
        }

        if (targetRay != null) {
            targetRay.visible = (inputPose != null);
        }

        if (grip != null) {
            grip.visible = (gripPose != null);
        }

        if (hand != null) {
            hand.visible = (handPose != null);
        }

        return this;
    }

    // private method
    private function _getHandJoint(hand: GroupDefault, inputjoint: Dynamic): GroupDefault {
        if (hand.joints[inputjoint.jointName] == null) {
            let joint = new GroupDefault();
            joint.matrixAutoUpdate = false;
            joint.visible = false;
            hand.joints[inputjoint.jointName] = joint;

            hand.add(joint);
        }

        return hand.joints[inputjoint.jointName];
    }
}