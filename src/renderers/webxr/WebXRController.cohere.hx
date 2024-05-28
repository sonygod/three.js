import js.webxr.XRInputSource;
import js.webxr.XRFrame;
import js.webxr.XRReferenceSpace;
import js.webxr.XRInputJoint;
import js.webxr.XRJointPose;
import js.webxr.XRInputPose;
import js.webxr.XRHand;
import js.geom.Vector3;
import js.geom.Matrix4;
import js.html.Event;

class WebXRController {
	var _targetRay:Group;
	var _grip:Group;
	var _hand:Group;

	public function new() {
		_targetRay = null;
		_grip = null;
		_hand = null;
	}

	function getHandSpace():Group {
		if (_hand == null) {
			_hand = new Group();
			_hand.matrixAutoUpdate = false;
			_hand.visible = false;
			_hand.joints = new Map();
			_hand.inputState = { pinching: false };
		}
		return _hand;
	}

	function getTargetRaySpace():Group {
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

	function getGripSpace():Group {
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

	function dispatchEvent(event:Event):WebXRController {
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

	function connect(inputSource:XRInputSource):WebXRController {
		if (inputSource != null && inputSource.hand != null) {
			var hand = getHandSpace();
			if (hand != null) {
				for (inputjoint in inputSource.hand.values()) {
					_getHandJoint(hand, inputjoint);
				}
			}
		}
		dispatchEvent({ type: 'connected', data: inputSource });
		return this;
	}

	function disconnect(inputSource:XRInputSource):WebXRController {
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

	function update(inputSource:XRInputSource, frame:XRFrame, referenceSpace:XRReferenceSpace):WebXRController {
		var inputPose:XRInputPose, gripPose:XRInputPose, handPose:XRInputPose;
		var targetRay = getTargetRaySpace();
		var grip = getGripSpace();
		var hand = getHandSpace();

		if (inputSource != null && frame.session.visibilityState != 'visible-blurred') {
			if (hand != null && inputSource.hand != null) {
				handPose = true;
				for (inputjoint in inputSource.hand.values()) {
					var jointPose:XRJointPose = frame.getJointPose(inputjoint, referenceSpace);
					var joint = _getHandJoint(hand, inputjoint);
					if (jointPose != null) {
						joint.matrix.fromArray(jointPose.transform.matrix);
						joint.matrix.decompose(joint.position, joint.rotation, joint.scale);
						joint.matrixWorldNeedsUpdate = true;
						joint.jointRadius = jointPose.radius;
					}
					joint.visible = jointPose != null;
				}

				// Custom events
				var indexTip = hand.joints.get('index-finger-tip');
				var thumbTip = hand.joints.get('thumb-tip');
				var distance = indexTip.position.distanceTo(thumbTip.position);

				var distanceToPinch = 0.02;
				var threshold = 0.005;

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
				// Some runtimes (namely Vive Cosmos with Vive OpenXR Runtime) have only grip space and ray space is equal to it
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
			hand.visible = (handPose != null);
		}

		return this;
	}

	function _getHandJoint(hand:Group, inputjoint:XRInputJoint):Group {
		if (!hand.joints.exists(inputjoint.jointName)) {
			var joint = new Group();
			joint.matrixAutoUpdate = false;
			joint.visible = false;
			hand.joints.set(inputjoint.jointName, joint);
			hand.addChild(joint);
		}
		return hand.joints.get(inputjoint.jointName);
	}
}