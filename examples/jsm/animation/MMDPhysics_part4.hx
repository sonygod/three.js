package three.js.examples.jm.animation;

import Ammo.btDiscreteDynamicsWorld;
import Ammo.btGeneric6DofSpringConstraint;
import ResourceManager;
import RigidBody;
import THREE.SkinnedMesh;

class Constraint {
	// fields
	var mesh:THREE.SkinnedMesh;
	var world:Ammo.btDiscreteDynamicsWorld;
	var bodyA:RigidBody;
	var bodyB:RigidBody;
	var params:Dynamic;
	var manager:ResourceManager;
	var constraint:Ammo.btGeneric6DofSpringConstraint;

	public function new(mesh:THREE.SkinnedMesh, world:Ammo.btDiscreteDynamicsWorld, bodyA:RigidBody, bodyB:RigidBody, params:Dynamic, manager:ResourceManager) {
		this.mesh = mesh;
		this.world = world;
		this.bodyA = bodyA;
		this.bodyB = bodyB;
		this.params = params;
		this.manager = manager;

		this.constraint = null;

		_init();
	}

	// private method
	function _init() {
		var manager = this.manager;
		var params = this.params;
		var bodyA = this.bodyA;
		var bodyB = this.bodyB;

		var form = manager.allocTransform();
		manager.setIdentity(form);
		manager.setOriginFromArray3(form, params.position);
		manager.setBasisFromArray3(form, params.rotation);

		var formA = manager.allocTransform();
		var formB = manager.allocTransform();

		bodyA.body.getMotionState().getWorldTransform(formA);
		bodyB.body.getMotionState().getWorldTransform(formB);

		var formInverseA = manager.inverseTransform(formA);
		var formInverseB = manager.inverseTransform(formB);

		var formA2 = manager.multiplyTransforms(formInverseA, form);
		var formB2 = manager.multiplyTransforms(formInverseB, form);

		constraint = new Ammo.btGeneric6DofSpringConstraint(bodyA.body, bodyB.body, formA2, formB2, true);

		var lll = manager.allocVector3();
		var lul = manager.allocVector3();
		var all = manager.allocVector3();
		var aul = manager.allocVector3();

		lll.setValue(params.translationLimitation1[0], params.translationLimitation1[1], params.translationLimitation1[2]);
		lul.setValue(params.translationLimitation2[0], params.translationLimitation2[1], params.translationLimitation2[2]);
		all.setValue(params.rotationLimitation1[0], params.rotationLimitation1[1], params.rotationLimitation1[2]);
		aul.setValue(params.rotationLimitation2[0], params.rotationLimitation2[1], params.rotationLimitation2[2]);

		constraint.setLinearLowerLimit(lll);
		constraint.setLinearUpperLimit(lul);
		constraint.setAngularLowerLimit(all);
		constraint.setAngularUpperLimit(aul);

		for (i in 0...3) {
			if (params.springPosition[i] != 0) {
				constraint.enableSpring(i, true);
				constraint.setStiffness(i, params.springPosition[i]);
			}
		}

		for (i in 0...3) {
			if (params.springRotation[i] != 0) {
				constraint.enableSpring(i + 3, true);
				constraint.setStiffness(i + 3, params.springRotation[i]);
			}
		}

		if (constraint.setParam != null) {
			for (i in 0...6) {
				constraint.setParam(2, 0.475, i);
			}
		}

		world.addConstraint(constraint, true);
		this.constraint = constraint;

		manager.freeTransform(form);
		manager.freeTransform(formA);
		manager.freeTransform(formB);
		manager.freeTransform(formInverseA);
		manager.freeTransform(formInverseB);
		manager.freeTransform(formA2);
		manager.freeTransform(formB2);
		manager.freeVector3(lll);
		manager.freeVector3(lul);
		manager.freeVector3(all);
		manager.freeVector3(aul);
	}
}