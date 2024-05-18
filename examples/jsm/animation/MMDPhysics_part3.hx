package three.js.examples.jsm.animation;

import ammo.btSphereShape;
import ammo.btBoxShape;
import ammo.btCapsuleShape;
import ammo.btVector3;
import ammo.btRigidBodyConstructionInfo;
import ammo.btDefaultMotionState;
import ammo.btRigidBody;

class RigidBody {
    public var mesh:Dynamic;
    public var world:Dynamic;
    public var params:Dynamic;
    public var manager:Dynamic;

    public var body:btRigidBody;
    public var bone:Dynamic;
    public var boneOffsetForm:Dynamic;
    public var boneOffsetFormInverse:Dynamic;

    public function new(mesh:Dynamic, world:Dynamic, params:Dynamic, manager:Dynamic) {
        this.mesh = mesh;
        this.world = world;
        this.params = params;
        this.manager = manager;

        this.body = null;
        this.bone = null;
        this.boneOffsetForm = null;
        this.boneOffsetFormInverse = null;

        this._init();
    }

    /**
     * Resets rigid body transform to the current bone's.
     *
     * @return RigidBody
     */
    public function reset():RigidBody {
        this._setTransformFromBone();
        return this;
    }

    /**
     * Updates rigid body's transform from the current bone.
     *
     * @return RigidBody
     */
    public function updateFromBone():RigidBody {
        if (this.params.boneIndex !== -1 && this.params.type === 0) {
            this._setTransformFromBone();
        }
        return this;
    }

    /**
     * Updates bone from the current rigid body's transform.
     *
     * @return RigidBody
     */
    public function updateBone():RigidBody {
        if (this.params.type === 0 || this.params.boneIndex === -1) {
            return this;
        }

        this._updateBoneRotation();

        if (this.params.type === 1) {
            this._updateBonePosition();
        }

        this.bone.updateMatrixWorld(true);

        if (this.params.type === 2) {
            this._setPositionFromBone();
        }

        return this;
    }

    // private methods

    private function _init():Void {
        function generateShape(p:Dynamic):Dynamic {
            switch (p.shapeType) {
                case 0:
                    return new btSphereShape(p.width);
                case 1:
                    return new btBoxShape(new btVector3(p.width, p.height, p.depth));
                case 2:
                    return new btCapsuleShape(p.width, p.height);
                default:
                    throw new Error('unknown shape type ' + p.shapeType);
            }
        }

        var manager:Dynamic = this.manager;
        var params:Dynamic = this.params;
        var bones:Dynamic = this.mesh.skeleton.bones;
        var bone:Dynamic = (params.boneIndex === -1) ? new Bone() : bones[params.boneIndex];

        var shape:Dynamic = generateShape(params);
        var weight:Float = (params.type === 0) ? 0 : params.weight;
        var localInertia:Dynamic = manager.allocVector3();
        localInertia.setValue(0, 0, 0);

        if (weight !== 0) {
            shape.calculateLocalInertia(weight, localInertia);
        }

        var boneOffsetForm:Dynamic = manager.allocTransform();
        manager.setIdentity(boneOffsetForm);
        manager.setOriginFromArray3(boneOffsetForm, params.position);
        manager.setBasisFromArray3(boneOffsetForm, params.rotation);

        var vector:Dynamic = manager.allocThreeVector3();
        var boneForm:Dynamic = manager.allocTransform();
        manager.setIdentity(boneForm);
        manager.setOriginFromThreeVector3(boneForm, bone.getWorldPosition(vector));

        var form:Dynamic = manager.multiplyTransforms(boneForm, boneOffsetForm);
        var state:btDefaultMotionState = new btDefaultMotionState(form);

        var info:btRigidBodyConstructionInfo = new btRigidBodyConstructionInfo(weight, state, shape, localInertia);
        info.set_m_friction(params.friction);
        info.set_m_restitution(params.restitution);

        var body:btRigidBody = new btRigidBody(info);

        if (params.type === 0) {
            body.setCollisionFlags(body.getCollisionFlags() | 2);
            body.setActivationState(4);
        }

        body.setDamping(params.positionDamping, params.rotationDamping);
        body.setSleepingThresholds(0, 0);

        this.world.addRigidBody(body, 1 << params.groupIndex, params.groupTarget);

        this.body = body;
        this.bone = bone;
        this.boneOffsetForm = boneOffsetForm;
        this.boneOffsetFormInverse = manager.inverseTransform(boneOffsetForm);

        manager.freeVector3(localInertia);
        manager.freeTransform(form);
        manager.freeTransform(boneForm);
        manager.freeThreeVector3(vector);
    }

    private function _getBoneTransform():Dynamic {
        var manager:Dynamic = this.manager;
        var p:Dynamic = manager.allocThreeVector3();
        var q:Dynamic = manager.allocThreeQuaternion();
        var s:Dynamic = manager.allocThreeVector3();

        this.bone.matrixWorld.decompose(p, q, s);

        var tr:Dynamic = manager.allocTransform();
        manager.setOriginFromThreeVector3(tr, p);
        manager.setBasisFromThreeQuaternion(tr, q);

        var form:Dynamic = manager.multiplyTransforms(tr, this.boneOffsetForm);

        manager.freeTransform(tr);
        manager.freeThreeVector3(s);
        manager.freeThreeQuaternion(q);
        manager.freeThreeVector3(p);

        return form;
    }

    private function _getWorldTransformForBone():Dynamic {
        var manager:Dynamic = this.manager;
        var tr:Dynamic = this.body.getCenterOfMassTransform();
        return manager.multiplyTransforms(tr, this.boneOffsetFormInverse);
    }

    private function _setTransformFromBone():Void {
        var manager:Dynamic = this.manager;
        var form:Dynamic = this._getBoneTransform();

        // TODO: check the most appropriate way to set
        //this.body.setWorldTransform( form );
        this.body.setCenterOfMassTransform(form);
        this.body.getMotionState().setWorldTransform(form);

        manager.freeTransform(form);
    }

    private function _setPositionFromBone():Void {
        var manager:Dynamic = this.manager;
        var form:Dynamic = this._getBoneTransform();

        var tr:Dynamic = manager.allocTransform();
        this.body.getMotionState().getWorldTransform(tr);
        manager.copyOrigin(tr, form);

        // TODO: check the most appropriate way to set
        //this.body.setWorldTransform( tr );
        this.body.setCenterOfMassTransform(tr);
        this.body.getMotionState().setWorldTransform(tr);

        manager.freeTransform(tr);
        manager.freeTransform(form);
    }

    private function _updateBoneRotation():Void {
        var manager:Dynamic = this.manager;

        var tr:Dynamic = this._getWorldTransformForBone();
        var q:Dynamic = manager.getBasis(tr);

        var thQ:Dynamic = manager.allocThreeQuaternion();
        var thQ2:Dynamic = manager.allocThreeQuaternion();
        var thQ3:Dynamic = manager.allocThreeQuaternion();

        thQ.set(q.x(), q.y(), q.z(), q.w());
        thQ2.setFromRotationMatrix(this.bone.matrixWorld);
        thQ2.conjugate();
        thQ2.multiply(thQ);

        //this.bone.quaternion.multiply( thQ2 );

        thQ3.setFromRotationMatrix(this.bone.matrix);

        // Renormalizing quaternion here because repeatedly transforming
        // quaternion continuously accumulates floating point error and
        // can end up being overflow. See #15335
        this.bone.quaternion.copy(thQ2.multiply(thQ3).normalize());

        manager.freeThreeQuaternion(thQ);
        manager.freeThreeQuaternion(thQ2);
        manager.freeThreeQuaternion(thQ3);

        manager.freeQuaternion(q);
        manager.freeTransform(tr);
    }

    private function _updateBonePosition():Void {
        var manager:Dynamic = this.manager;

        var tr:Dynamic = this._getWorldTransformForBone();

        var thV:Dynamic = manager.allocThreeVector3();

        var o:Dynamic = manager.getOrigin(tr);
        thV.set(o.x(), o.y(), o.z());

        if (this.bone.parent) {
            this.bone.parent.worldToLocal(thV);
        }

        this.bone.position.copy(thV);

        manager.freeThreeVector3(thV);

        manager.freeTransform(tr);
    }
}