import haxe.ui.Group;
import three.math.Vector3;

class WebXRController {

	private var _targetRay:Group = null;
	private var _grip:Group = null;
	private var _hand:Group = null;

	public function new() {
	}

	public function getHandSpace():Group {
		if (this._hand == null) {
			this._hand = new Group();
			this._hand.matrixAutoUpdate = false;
			this._hand.visible = false;
			this._hand.joints = new haxe.ds.StringMap<Group>();
			this._hand.inputState = {pinching: false};
		}
		return this._hand;
	}

	public function getTargetRaySpace():Group {
		if (this._targetRay == null) {
			this._targetRay = new Group();
			this._targetRay.matrixAutoUpdate = false;
			this._targetRay.visible = false;
			this._targetRay.hasLinearVelocity = false;
			this._targetRay.linearVelocity = new Vector3();
			this._targetRay.hasAngularVelocity = false;
			this._targetRay.angularVelocity = new Vector3();
		}
		return this._targetRay;
	}

	public function getGripSpace():Group {
		if (this._grip == null) {
			this._grip = new Group();
			this._grip.matrixAutoUpdate = false;
			this._grip.visible = false;
			this._grip.hasLinearVelocity = false;
			this._grip.linearVelocity = new Vector3();
			this._grip.hasAngularVelocity = false;
			this._grip.angularVelocity = new Vector3();
		}
		return this._grip;
	}

	public function dispatchEvent(event:Dynamic):WebXRController {
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

	public function connect(inputSource:Dynamic):WebXRController {
		if (inputSource != null && inputSource.hand != null) {
			var hand = this._hand;
			if (hand != null) {
				for (inputjoint in inputSource.hand.values()) {
					this._getHandJoint(hand, inputjoint);
				}
			}
		}
		this.dispatchEvent({type: 'connected', data: inputSource});
		return this;
	}

	public function disconnect(inputSource:Dynamic):WebXRController {
		this.dispatchEvent({type: 'disconnected', data: inputSource});
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

	public function update(inputSource:Dynamic, frame:Dynamic, referenceSpace:Dynamic):WebXRController {
		var inputPose:Dynamic = null;
		var gripPose:Dynamic = null;
		var handPose:Dynamic = null;
		var targetRay = this._targetRay;
		var grip = this._grip;
		var hand = this._hand;
		if (inputSource != null && frame.session.visibilityState != 'visible-blurred') {
			if (hand != null && inputSource.hand != null) {
				handPose = true;
				for (inputjoint in inputSource.hand.values()) {
					var jointPose = frame.getJointPose(inputjoint, referenceSpace);
					var joint = this._getHandJoint(hand, inputjoint);
					if (jointPose != null) {
						joint.matrix.fromArray(jointPose.transform.matrix);
						joint.matrix.decompose(joint.position, joint.rotation, joint.scale);
						joint.matrixWorldNeedsUpdate = true;
						joint.jointRadius = jointPose.radius;
					}
					joint.visible = jointPose != null;
				}
				var indexTip = hand.joints['index-finger-tip'];
				var thumbTip = hand.joints['thumb-tip'];
				var distance = indexTip.position.distanceTo(thumbTip.position);
				var distanceToPinch = 0.02;
				var threshold = 0.005;
				if (hand.inputState.pinching && distance > distanceToPinch + threshold) {
					hand.inputState.pinching = false;
					this.dispatchEvent({type: 'pinchend', handedness: inputSource.handedness, target: this});
				} else if (!hand.inputState.pinching && distance <= distanceToPinch - threshold) {
					hand.inputState.pinching = true;
					this.dispatchEvent({type: 'pinchstart', handedness: inputSource.handedness, target: this});
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
					this.dispatchEvent({type: 'move'});
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

	private function _getHandJoint(hand:Group, inputjoint:Dynamic):Group {
		if (hand.joints[inputjoint.jointName] == null) {
			var joint = new Group();
			joint.matrixAutoUpdate = false;
			joint.visible = false;
			hand.joints[inputjoint.jointName] = joint;
			hand.add(joint);
		}
		return hand.joints[inputjoint.jointName];
	}

}