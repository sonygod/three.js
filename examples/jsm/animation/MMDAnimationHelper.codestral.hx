import three.animation.AnimationMixer;
import three.core.Object3D;
import three.math.Quaternion;
import three.math.Vector3;
import three.animation.CCDIKSolver;
import three.animation.MMDPhysics;

class MMDAnimationHelper {
    private var meshes:Array<three.SkinnedMesh> = [];
    private var camera:three.Camera = null;
    private var cameraTarget:three.Object3D = new Object3D();
    private var audio:three.Audio = null;
    private var audioManager:AudioManager = null;
    private var objects:Map<Dynamic, Dynamic> = new Map();
    private var configuration:Dynamic = {
        sync: true,
        afterglow: 0.0,
        resetPhysicsOnLoop: true,
        pmxAnimation: false
    };
    private var enabled:Dynamic = {
        animation: true,
        ik: true,
        grant: true,
        physics: true,
        cameraAnimation: true
    };
    private var onBeforePhysics:Function = function(_:three.SkinnedMesh) {};
    private var sharedPhysics:Bool = false;
    private var masterPhysics:MMDPhysics = null;

    public function new(params:Dynamic = {}) {
        this.setDefaultValues(this.configuration, params);
        this.setDefaultValues(this.enabled, params);

        cameraTarget.name = 'target';
    }

    public function add(object:Dynamic, params:Dynamic = {}):MMDAnimationHelper {
        if (Std.is(object, three.SkinnedMesh)) {
            this._addMesh(object, params);
        } else if (Std.is(object, three.Camera)) {
            this._setupCamera(object, params);
        } else if (Std.is(object, three.Audio)) {
            this._setupAudio(object, params);
        } else {
            throw new Error('THREE.MMDAnimationHelper.add: accepts only THREE.SkinnedMesh or THREE.Camera or THREE.Audio instance.');
        }

        if (this.configuration.sync) this._syncDuration();

        return this;
    }

    public function remove(object:Dynamic):MMDAnimationHelper {
        if (Std.is(object, three.SkinnedMesh)) {
            this._removeMesh(object);
        } else if (Std.is(object, three.Camera)) {
            this._clearCamera(object);
        } else if (Std.is(object, three.Audio)) {
            this._clearAudio(object);
        } else {
            throw new Error('THREE.MMDAnimationHelper.remove: accepts only THREE.SkinnedMesh or THREE.Camera or THREE.Audio instance.');
        }

        if (this.configuration.sync) this._syncDuration();

        return this;
    }

    public function update(delta:Float):MMDAnimationHelper {
        if (this.audioManager !== null) this.audioManager.control(delta);

        for (i in 0...this.meshes.length) {
            this._animateMesh(this.meshes[i], delta);
        }

        if (this.sharedPhysics) this._updateSharedPhysics(delta);

        if (this.camera !== null) this._animateCamera(this.camera, delta);

        return this;
    }

    public function pose(mesh:three.SkinnedMesh, vpd:Dynamic, params:Dynamic = {}):MMDAnimationHelper {
        if (params.resetPose !== false) mesh.pose();

        var bones = mesh.skeleton.bones;
        var boneParams = vpd.bones;

        var boneNameDictionary:Map<String, Int> = new Map();

        for (i in 0...bones.length) {
            boneNameDictionary.set(bones[i].name, i);
        }

        var vector = new Vector3();
        var quaternion = new Quaternion();

        for (i in 0...boneParams.length) {
            var boneParam = boneParams[i];
            var boneIndex = boneNameDictionary.get(boneParam.name);

            if (boneIndex === null) continue;

            var bone = bones[boneIndex];
            bone.position.add(vector.fromArray(boneParam.translation));
            bone.quaternion.multiply(quaternion.fromArray(boneParam.quaternion));
        }

        mesh.updateMatrixWorld(true);

        if (this.configuration.pmxAnimation &&
            mesh.geometry.userData.MMD && mesh.geometry.userData.MMD.format === 'pmx') {

            var sortedBonesData = this._sortBoneDataArray(mesh.geometry.userData.MMD.bones.slice());
            var ikSolver = params.ik !== false ? this._createCCDIKSolver(mesh) : null;
            var grantSolver = params.grant !== false ? this.createGrantSolver(mesh) : null;
            this._animatePMXMesh(mesh, sortedBonesData, ikSolver, grantSolver);

        } else {

            if (params.ik !== false) {
                this._createCCDIKSolver(mesh).update();
            }

            if (params.grant !== false) {
                this.createGrantSolver(mesh).update();
            }

        }

        return this;
    }

    public function enable(key:String, enabled:Bool):MMDAnimationHelper {
        if (this.enabled[key] === null) {
            throw new Error('THREE.MMDAnimationHelper.enable: unknown key ' + key);
        }

        this.enabled[key] = enabled;

        if (key === 'physics') {
            for (i in 0...this.meshes.length) {
                this._optimizeIK(this.meshes[i], enabled);
            }
        }

        return this;
    }

    public function createGrantSolver(mesh:three.SkinnedMesh):GrantSolver {
        return new GrantSolver(mesh, mesh.geometry.userData.MMD.grants);
    }

    private function _addMesh(mesh:three.SkinnedMesh, params:Dynamic):MMDAnimationHelper {
        if (this.meshes.indexOf(mesh) >= 0) {
            throw new Error('THREE.MMDAnimationHelper._addMesh: SkinnedMesh \'' + mesh.name + '\' has already been added.');
        }

        this.meshes.push(mesh);
        this.objects.set(mesh, { looped: false });

        this._setupMeshAnimation(mesh, params.animation);

        if (params.physics !== false) {
            this._setupMeshPhysics(mesh, params);
        }

        return this;
    }

    private function _setupCamera(camera:three.Camera, params:Dynamic):MMDAnimationHelper {
        if (this.camera === camera) {
            throw new Error('THREE.MMDAnimationHelper._setupCamera: Camera \'' + camera.name + '\' has already been set.');
        }

        if (this.camera != null) this._clearCamera(this.camera);

        this.camera = camera;

        camera.add(this.cameraTarget);

        this.objects.set(camera, {});

        if (params.animation !== null) {
            this._setupCameraAnimation(camera, params.animation);
        }

        return this;
    }

    private function _setupAudio(audio:three.Audio, params:Dynamic):MMDAnimationHelper {
        if (this.audio === audio) {
            throw new Error('THREE.MMDAnimationHelper._setupAudio: Audio \'' + audio.name + '\' has already been set.');
        }

        if (this.audio != null) this._clearAudio(this.audio);

        this.audio = audio;
        this.audioManager = new AudioManager(audio, params);

        this.objects.set(this.audioManager, {
            duration: this.audioManager.duration
        });

        return this;
    }

    private function _removeMesh(mesh:three.SkinnedMesh):MMDAnimationHelper {
        var found = false;
        var writeIndex = 0;

        for (i in 0...this.meshes.length) {
            if (this.meshes[i] === mesh) {
                this.objects.delete(mesh);
                found = true;

                continue;
            }

            this.meshes[writeIndex++] = this.meshes[i];
        }

        if (!found) {
            throw new Error('THREE.MMDAnimationHelper._removeMesh: SkinnedMesh \'' + mesh.name + '\' has not been added yet.');
        }

        this.meshes.length = writeIndex;

        return this;
    }

    private function _clearCamera(camera:three.Camera):MMDAnimationHelper {
        if (camera !== this.camera) {
            throw new Error('THREE.MMDAnimationHelper._clearCamera: Camera \'' + camera.name + '\' has not been set yet.');
        }

        this.camera.remove(this.cameraTarget);

        this.objects.delete(this.camera);
        this.camera = null;

        return this;
    }

    private function _clearAudio(audio:three.Audio):MMDAnimationHelper {
        if (audio !== this.audio) {
            throw new Error('THREE.MMDAnimationHelper._clearAudio: Audio \'' + audio.name + '\' has not been set yet.');
        }

        this.objects.delete(this.audioManager);

        this.audio = null;
        this.audioManager = null;

        return this;
    }

    private function _setupMeshAnimation(mesh:three.SkinnedMesh, animation:Dynamic):MMDAnimationHelper {
        var objects = this.objects.get(mesh);

        if (animation !== null) {
            var animations = Array.isArray(animation) ? animation : [animation];

            objects.mixer = new AnimationMixer(mesh);

            for (i in 0...animations.length) {
                objects.mixer.clipAction(animations[i]).play();
            }

            objects.mixer.addEventListener('loop', function(event) {
                var tracks = event.action._clip.tracks;

                if (tracks.length > 0 && tracks[0].name.substring(0, 6) !== '.bones') return;

                objects.looped = true;
            });
        }

        objects.ikSolver = this._createCCDIKSolver(mesh);
        objects.grantSolver = this.createGrantSolver(mesh);

        return this;
    }

    private function _setupCameraAnimation(camera:three.Camera, animation:Dynamic):MMDAnimationHelper {
        var animations = Array.isArray(animation) ? animation : [animation];

        var objects = this.objects.get(camera);

        objects.mixer = new AnimationMixer(camera);

        for (i in 0...animations.length) {
            objects.mixer.clipAction(animations[i]).play();
        }
    }

    private function _setupMeshPhysics(mesh:three.SkinnedMesh, params:Dynamic):MMDAnimationHelper {
        var objects = this.objects.get(mesh);

        if (params.world === null && this.sharedPhysics) {
            var masterPhysics = this._getMasterPhysics();

            if (masterPhysics !== null) var world = masterPhysics.world;
        }

        objects.physics = this._createMMDPhysics(mesh, params);

        if (objects.mixer && params.animationWarmup !== false) {
            this._animateMesh(mesh, 0);
            objects.physics.reset();
        }

        objects.physics.warmup(params.warmup !== null ? params.warmup : 60);

        this._optimizeIK(mesh, true);
    }

    private function _animateMesh(mesh:three.SkinnedMesh, delta:Float):MMDAnimationHelper {
        var objects = this.objects.get(mesh);

        var mixer = objects.mixer;
        var ikSolver = objects.ikSolver;
        var grantSolver = objects.grantSolver;
        var physics = objects.physics;
        var looped = objects.looped;

        if (mixer && this.enabled.animation) {
            this._restoreBones(mesh);

            mixer.update(delta);

            this._saveBones(mesh);

            if (this.configuration.pmxAnimation &&
                mesh.geometry.userData.MMD && mesh.geometry.userData.MMD.format === 'pmx') {

                if (objects.sortedBonesData == null) objects.sortedBonesData = this._sortBoneDataArray(mesh.geometry.userData.MMD.bones.slice());

                this._animatePMXMesh(
                    mesh,
                    objects.sortedBonesData,
                    ikSolver && this.enabled.ik ? ikSolver : null,
                    grantSolver && this.enabled.grant ? grantSolver : null
                );

            } else {

                if (ikSolver && this.enabled.ik) {
                    mesh.updateMatrixWorld(true);
                    ikSolver.update();
                }

                if (grantSolver && this.enabled.grant) {
                    grantSolver.update();
                }

            }
        }

        if (looped && this.enabled.physics) {
            if (physics && this.configuration.resetPhysicsOnLoop) physics.reset();

            objects.looped = false;
        }

        if (physics && this.enabled.physics && !this.sharedPhysics) {
            this.onBeforePhysics(mesh);
            physics.update(delta);
        }

        return this;
    }

    private function _sortBoneDataArray(boneDataArray:Array<Dynamic>):Array<Dynamic> {
        return boneDataArray.sort(function(a, b) {
            if (a.transformationClass !== b.transformationClass) {
                return a.transformationClass - b.transformationClass;
            } else {
                return a.index - b.index;
            }
        });
    }

    private function _animatePMXMesh(mesh:three.SkinnedMesh, sortedBonesData:Array<Dynamic>, ikSolver:CCDIKSolver, grantSolver:GrantSolver):MMDAnimationHelper {
        var _quaternionIndex = 0;
        var _grantResultMap:Map<Int, Quaternion> = new Map();

        for (i in 0...sortedBonesData.length) {
            updateOne(mesh, sortedBonesData[i].index, ikSolver, grantSolver);
        }

        mesh.updateMatrixWorld(true);
        return this;
    }

    private function _animateCamera(camera:three.Camera, delta:Float):MMDAnimationHelper {
        var mixer = this.objects.get(camera).mixer;

        if (mixer && this.enabled.cameraAnimation) {
            mixer.update(delta);

            camera.updateProjectionMatrix();

            camera.up.set(0, 1, 0);
            camera.up.applyQuaternion(camera.quaternion);
            camera.lookAt(this.cameraTarget.position);
        }

        return this;
    }

    private function _optimizeIK(mesh:three.SkinnedMesh, physicsEnabled:Bool):MMDAnimationHelper {
        var iks = mesh.geometry.userData.MMD.iks;
        var bones = mesh.geometry.userData.MMD.bones;

        for (i in 0...iks.length) {
            var ik = iks[i];
            var links = ik.links;

            for (j in 0...links.length) {
                var link = links[j];

                if (physicsEnabled) {
                    link.enabled = bones[link.index].rigidBodyType > 0 ? false : true;
                } else {
                    link.enabled = true;
                }
            }
        }

        return this;
    }

    private function _createCCDIKSolver(mesh:three.SkinnedMesh):CCDIKSolver {
        if (CCDIKSolver == null) {
            throw new Error('THREE.MMDAnimationHelper: Import CCDIKSolver.');
        }

        return new CCDIKSolver(mesh, mesh.geometry.userData.MMD.iks);
    }

    private function _createMMDPhysics(mesh:three.SkinnedMesh, params:Dynamic):MMDPhysics {
        if (MMDPhysics == null) {
            throw new Error('THREE.MMDPhysics: Import MMDPhysics.');
        }

        return new MMDPhysics(
            mesh,
            mesh.geometry.userData.MMD.rigidBodies,
            mesh.geometry.userData.MMD.constraints,
            params
        );
    }

    private function _syncDuration():MMDAnimationHelper {
        var max = 0.0;

        var objects = this.objects;
        var meshes = this.meshes;
        var camera = this.camera;
        var audioManager = this.audioManager;

        for (i in 0...meshes.length) {
            var mixer = this.objects.get(meshes[i]).mixer;

            if (mixer == null) continue;

            for (j in 0...mixer._actions.length) {
                var clip = mixer._actions[j]._clip;

                if (!objects.has(clip)) {
                    objects.set(clip, {
                        duration: clip.duration
                    });
                }

                max = Math.max(max, objects.get(clip).duration);
            }
        }

        if (camera != null) {
            var mixer = this.objects.get(camera).mixer;

            if (mixer != null) {
                for (i in 0...mixer._actions.length) {
                    var clip = mixer._actions[i]._clip;

                    if (!objects.has(clip)) {
                        objects.set(clip, {
                            duration: clip.duration
                        });
                    }

                    max = Math.max(max, objects.get(clip).duration);
                }
            }
        }

        if (audioManager != null) {
            max = Math.max(max, objects.get(audioManager).duration);
        }

        max += this.configuration.afterglow;

        for (i in 0...this.meshes.length) {
            var mixer = this.objects.get(this.meshes[i]).mixer;

            if (mixer == null) continue;

            for (j in 0...mixer._actions.length) {
                mixer._actions[j]._clip.duration = max;
            }
        }

        if (camera != null) {
            var mixer = this.objects.get(camera).mixer;

            if (mixer != null) {
                for (i in 0...mixer._actions.length) {
                    mixer._actions[i]._clip.duration = max;
                }
            }
        }

        if (audioManager != null) {
            audioManager.duration = max;
        }

        return this;
    }

    private function _updatePropertyMixersBuffer(mesh:three.SkinnedMesh):MMDAnimationHelper {
        var mixer = this.objects.get(mesh).mixer;

        var propertyMixers = mixer._bindings;
        var accuIndex = mixer._accuIndex;

        for (i in 0...propertyMixers.length) {
            var propertyMixer = propertyMixers[i];
            var buffer = propertyMixer.buffer;
            var stride = propertyMixer.valueSize;
            var offset = (accuIndex + 1) * stride;

            propertyMixer.binding.getValue(buffer, offset);
        }

        return this;
    }

    private function _saveBones(mesh:three.SkinnedMesh):MMDAnimationHelper {
        var objects = this.objects.get(mesh);

        var bones = mesh.skeleton.bones;

        var backupBones = objects.backupBones;

        if (backupBones == null) {
            backupBones = new Float32Array(bones.length * 7);
            objects.backupBones = backupBones;
        }

        for (i in 0...bones.length) {
            var bone = bones[i];
            bone.position.toArray(backupBones, i * 7);
            bone.quaternion.toArray(backupBones, i * 7 + 3);
        }

        return this;
    }

    private function _restoreBones(mesh:three.SkinnedMesh):MMDAnimationHelper {
        var objects = this.objects.get(mesh);

        var backupBones = objects.backupBones;

        if (backupBones == null) return;

        var bones = mesh.skeleton.bones;

        for (i in 0...bones.length) {
            var bone = bones[i];
            bone.position.fromArray(backupBones, i * 7);
            bone.quaternion.fromArray(backupBones, i * 7 + 3);
        }

        return this;
    }

    private function _getMasterPhysics():MMDPhysics {
        if (this.masterPhysics !== null) return this.masterPhysics;

        for (i in 0...this.meshes.length) {
            var physics = this.meshes[i].physics;

            if (physics !== null && physics !== undefined) {
                this.masterPhysics = physics;
                return this.masterPhysics;
            }
        }

        return null;
    }

    private function _updateSharedPhysics(delta:Float):MMDAnimationHelper {
        if (this.meshes.length === 0 || !this.enabled.physics || !this.sharedPhysics) return;

        var physics = this._getMasterPhysics();

        if (physics === null) return;

        for (i in 0...this.meshes.length) {
            var p = this.meshes[i].physics;

            if (p !== null && p !== undefined) {
                p.updateRigidBodies();
            }
        }

        physics.stepSimulation(delta);

        for (i in 0...this.meshes.length) {
            var p = this.meshes[i].physics;

            if (p !== null && p !== undefined) {
                p.updateBones();
            }
        }

        return this;
    }

    private function setDefaultValues(target:Dynamic, source:Dynamic):Dynamic {
        for (key in Reflect.fields(target)) {
            if (source[key] !== null) {
                target[key] = source[key];
            }
        }

        return target;
    }
}

class AudioManager {
    private var audio:three.Audio;
    private var elapsedTime:Float;
    private var currentTime:Float;
    private var delayTime:Float;
    private var audioDuration:Float;
    public var duration:Float;

    public function new(audio:three.Audio, params:Dynamic = {}) {
        this.audio = audio;

        this.elapsedTime = 0.0;
        this.currentTime = 0.0;
        this.delayTime = params.delayTime !== null ? params.delayTime : 0.0;

        this.audioDuration = this.audio.buffer.duration;
        this.duration = this.audioDuration + this.delayTime;
    }

    public function control(delta:Float):AudioManager {
        this.elapsedTime += delta;
        this.currentTime += delta;

        if (this._shouldStopAudio()) this.audio.stop();
        if (this._shouldStartAudio()) this.audio.play();

        return this;
    }

    private function _shouldStartAudio():Bool {
        if (this.audio.isPlaying) return false;

        while (this.currentTime >= this.duration) {
            this.currentTime -= this.duration;
        }

        if (this.currentTime < this.delayTime) return false;

        if ((this.currentTime - this.delayTime) > this.audioDuration) return false;

        return true;
    }

    private function _shouldStopAudio():Bool {
        return this.audio.isPlaying && this.currentTime >= this.duration;
    }
}

class GrantSolver {
    private var mesh:three.SkinnedMesh;
    private var grants:Array<Dynamic>;

    public function new(mesh:three.SkinnedMesh, grants:Array<Dynamic> = []) {
        this.mesh = mesh;
        this.grants = grants;
    }

    public function update():GrantSolver {
        var grants = this.grants;

        for (i in 0...grants.length) {
            this.updateOne(grants[i]);
        }

        return this;
    }

    public function updateOne(grant:Dynamic):GrantSolver {
        var bones = this.mesh.skeleton.bones;
        var bone = bones[grant.index];
        var parentBone = bones[grant.parentIndex];

        if (grant.isLocal) {
            if (grant.affectPosition) {
                // TODO: implement
            }

            if (grant.affectRotation) {
                // TODO: implement
            }
        } else {
            if (grant.affectPosition) {
                // TODO: implement
            }

            if (grant.affectRotation) {
                this.addGrantRotation(bone, parentBone.quaternion, grant.ratio);
            }
        }

        return this;
    }

    public function addGrantRotation(bone:three.Bone, q:Quaternion, ratio:Float):GrantSolver {
        var _q = new Quaternion();
        _q.set(0, 0, 0, 1);
        _q.slerp(q, ratio);
        bone.quaternion.multiply(_q);

        return this;
    }
}

var _q:Quaternion = new Quaternion();

function updateOne(mesh:three.SkinnedMesh, boneIndex:Int, ikSolver:CCDIKSolver, grantSolver:GrantSolver):Void {
    var bones = mesh.skeleton.bones;
    var bonesData = mesh.geometry.userData.MMD.bones;
    var boneData = bonesData[boneIndex];
    var bone = bones[boneIndex];

    if (_grantResultMap.exists(boneIndex)) return;

    var quaternion = _quaternions[_quaternionIndex++];

    _grantResultMap.set(boneIndex, quaternion.copy(bone.quaternion));

    if (grantSolver !== null && boneData.grant && !boneData.grant.isLocal && boneData.grant.affectRotation) {
        var parentIndex = boneData.grant.parentIndex;
        var ratio = boneData.grant.ratio;

        if (!_grantResultMap.exists(parentIndex)) {
            updateOne(mesh, parentIndex, ikSolver, grantSolver);
        }

        grantSolver.addGrantRotation(bone, _grantResultMap.get(parentIndex), ratio);
    }

    if (ikSolver !== null && boneData.ik) {
        mesh.updateMatrixWorld(true);
        ikSolver.updateOne(boneData.ik);

        var links = boneData.ik.links;

        for (i in 0...links.length) {
            var link = links[i];

            if (link.enabled === false) continue;

            var linkIndex = link.index;

            if (_grantResultMap.exists(linkIndex)) {
                _grantResultMap.set(linkIndex, _grantResultMap.get(linkIndex).copy(bones[linkIndex].quaternion));
            }
        }
    }

    quaternion.copy(bone.quaternion);
}