package three.js.src.renderers.webxr;

import three.math.Vector3;
import three.objects.Group;

class WebXRController {
    
    private var _targetRay:Group;
    private var _grip:Group;
    private var _hand:Group;

    public function new() {
        _targetRay = null;
        _grip = null;
        _hand = null;
    }

    public function getHandSpace():Group {
        if (_hand == null) {
            _hand = new Group();
            _hand.matrixAutoUpdate = false;
            _hand.visible = false;
            _hand.joints = {};
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

    public function dispatchEvent(event:Dynamic):WebXRController {
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

    public function connect(inputSource:Dynamic):WebXRController {
        if (inputSource != null && inputSource.hand != null) {
            var hand:Group = _hand;
            if (hand != null) {
                for (inputJoint in inputSource.hand) {
                    _getHandJoint(hand, inputJoint);
                }
            }
        }
        dispatchEvent({ type: 'connected', data: inputSource });
        return this;
    }

    public function disconnect(inputSource:Dynamic):WebXRController {
        dispatchEvent({ type: 'disconnected', data: inputSource });
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

    public function update(inputSource:Dynamic, frame:Dynamic, referenceSpace:Dynamic):WebXRController {
        var inputPose:Dynamic = null;
        var gripPose:Dynamic = null;
        var handPose:Bool = false;

        var targetRay:Group = _targetRay;
        var grip:Group = _grip;
        var hand:Group = _hand;

        if (inputSource != null && frame.session.visibilityState != 'visible-blurred') {
            if (hand != null && inputSource.hand != null) {
                handPose = true;
                for (inputJoint in inputSource.hand) {
                    var jointPose:Dynamic = frame.getJointPose(inputJoint, referenceSpace);
                    var joint:Group = _getHandJoint(hand, inputJoint);
                    if (jointPose != null) {
                        joint.matrix.fromArray(jointPose.transform.matrix);
                        joint.matrix.decompose(joint.position, joint.rotation, joint.scale);
                        joint.matrixWorldNeedsUpdate = true;
                        joint.jointRadius = jointPose.radius;
                    }
                    joint.visible = jointPose != null;
                }

                // Custom events

                // Check pinch
                var indexTip:Group = hand.joints['index-finger-tip'];
                var thumbTip:Group = hand.joints['thumb-tip'];
                var distance:Float = indexTip.position.distanceTo(thumbTip.position);

                var distanceToPinch:Float = 0.02;
                var threshold:Float = 0.005;

                if (hand.inputState.pinching && distance > distanceToPinch + threshold) {
                    hand.inputState.pinching = false;
                    dispatchEvent({
                        type: 'pinchend',
                        handedness: inputSource.handedness,
                        target: this
                    });
                } else if (!hand.inputState.pinching && distance <= distanceToPinch - threshold) {
                    hand.inputState.pinching = true;
                    dispatchEvent({
                        type: 'pinchstart',
                        handedness: inputSource.handedness,
                        target: this
                    });
                }

            } else {
                if (grip != null && inputSource.gripSpace != null) {
                    gripPose = frame.getPose(inputSource.gripSpace, referenceSpace);
                    if (gripPose != null) {
                        grip.matrix.fromArray(gripPose.transform.matrix);
                        grip.matrix.decompose(grip.position, grip.rotation, grip.scale);
                        grip.matrixWorldNeedsUpdate = true;
                        if (gripPose.linearVelocity != null) {
                            grip.hasLinearVelocity = true;
                            grip.linearVelocity.copy(gripPose.linearVelocity);
                        } else {
                            grip.hasLinearVelocity = false;
                        }
                        if (gripPose.angularVelocity != null) {
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
                    if (inputPose.linearVelocity != null) {
                        targetRay.hasLinearVelocity = true;
                        targetRay.linearVelocity.copy(inputPose.linearVelocity);
                    } else {
                        targetRay.hasLinearVelocity = false;
                    }
                    if (inputPose.angularVelocity != null) {
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
            targetRay.visible = (inputPose != null);
        }
        if (grip != null) {
            grip.visible = (gripPose != null);
        }
        if (hand != null) {
            hand.visible = (handPose);
        }

        return this;
    }

    private function _getHandJoint(hand:Group, inputJoint:Dynamic):Group {
        if (hand.joints[inputJoint.jointName] == null) {
            var joint:Group = new Group();
            joint.matrixAutoUpdate = false;
            joint.visible = false;
            hand.joints[inputJoint.jointName] = joint;
            hand.add(joint);
        }
        return hand.joints[inputJoint.jointName];
    }
}