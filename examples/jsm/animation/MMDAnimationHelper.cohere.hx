package;

import js.three.AnimationMixer;
import js.three.Object3D;
import js.three.Quaternion;
import js.three.Vector3;
import js.ammo.MMDPhysics;
import js.three.CCDIKSolver;

class MMDAnimationHelper {
    var meshes:Array<Object>;
    var camera:Object3D;
    var cameraTarget:Object3D;
    var audio:Dynamic;
    var audioManager:Dynamic;
    var objects:Map<Object, Object>;
    var configuration:Dynamic;
    var enabled:Dynamic;
    var onBeforePhysics:Dynamic;
    var sharedPhysics:Bool;
    var masterPhysics:Dynamic;

    public function new(?params:Dynamic) {
        meshes = [];
        camera = null;
        cameraTarget = new Object3D();
        cameraTarget.name = 'target';
        audio = null;
        audioManager = null;
        objects = new Map();
        configuration = {
            sync: (params != null && 'sync' in params) ? params.sync : true,
            afterglow: (params != null && 'afterglow' in params) ? params.afterglow : 0.0,
            resetPhysicsOnLoop: (params != null && 'resetPhysicsOnLoop' in params) ? params.resetPhysicsOnLoop : true,
            pmxAnimation: (params != null && 'pmxAnimation' in params) ? params.pmxAnimation : false
        };
        enabled = {
            animation: true,
            ik: true,
            grant: true,
            physics: true,
            cameraAnimation: true
        };
        onBeforePhysics = function(_) {};
        sharedPhysics = false;
        masterPhysics = null;
    }

    public function add(object:Dynamic, ?params:Dynamic):MMDAnimationHelper {
        if (Std.is(object, SkinnedMesh)) {
            _addMesh(object, params);
        } else if (Std.is(object, Camera)) {
            _setupCamera(object, params);
        } else if (Std.is(object, Audio)) {
            _setupAudio(object, params);
        } else {
            throw new Error('THREE.MMDAnimationHelper.add: ' +
                'accepts only ' +
                'THREE.SkinnedMesh or ' +
                'THREE.Camera or ' +
                'THREE.Audio instance.');
        }
        if (configuration.sync) {
            _syncDuration();
        }
        return this;
    }

    public function remove(object:Dynamic):MMDAnimationHelper {
        if (Std.is(object, SkinnedMesh)) {
            _removeMesh(object);
        } else if (Std.is(object, Camera)) {
            _clearCamera(object);
        } else if (Std.is(object, Audio)) {
            _clearAudio(object);
        } else {
            throw new Error('THREE.MMDAnimationHelper.remove: ' +
                'accepts only ' +
                'THREE.SkinnedMesh or ' +
                'THREE.Camera or ' +
                'THREE.Audio instance.');
        }
        if (configuration.sync) {
            _syncDuration();
        }
        return this;
    }

    public function update(delta:Float):MMDAnimationHelper {
        if (audioManager != null) {
            audioManager.control(delta);
        }
        var i:Int;
        for (i = 0; i < meshes.length; i++) {
            _animateMesh(meshes[i], delta);
        }
        if (sharedPhysics) {
            _updateSharedPhysics(delta);
        }
        if (camera != null) {
            _animateCamera(camera, delta);
        }
        return this;
    }

    public function pose(mesh:SkinnedMesh, vpd:Dynamic, ?params:Dynamic):MMDAnimationHelper {
        if (params != null && 'resetPose' in params && !params.resetPose) {
            mesh.pose();
        }
        var bones = mesh.skeleton.bones;
        var boneParams = vpd.bones;
        var boneNameDictionary = new Map();
        var i:Int;
        for (i = 0; i < bones.length; i++) {
            boneNameDictionary[bones[i].name] = i;
        }
        var vector = new Vector3();
        var quaternion = new Quaternion();
        var i:Int;
        for (i = 0; i < boneParams.length; i++) {
            var boneParam = boneParams[i];
            var boneIndex = boneNameDictionary[boneParam.name];
            if (boneIndex == null) {
                continue;
            }
            var bone = bones[boneIndex];
            bone.position.add(vector.fromArray(boneParam.translation));
            bone.quaternion.multiply(quaternion.fromArray(boneParam.quaternion));
        }
        mesh.updateMatrixWorld(true);
        if (configuration.pmxAnimation &&
            mesh.geometry.userData.MMD != null && mesh.geometry.userData.MMD.format == 'pmx') {
            var sortedBonesData = _sortBoneDataArray(mesh.geometry.userData.MMD.bones.slice());
            var ikSolver = (params != null && 'ik' in params) ? _createCCDIKSolver(mesh) : null;
            var grantSolver = (params != null && 'grant' in params) ? createGrantSolver(mesh) : null;
            _animatePMXMesh(mesh, sortedBonesData, ikSolver, grantSolver);
        } else {
            if (params != null && 'ik' in params && params.ik) {
                _createCCDIKSolver(mesh).update();
            }
            if (params != null && 'grant' in params && params.grant) {
                createGrantSolver(mesh).update();
            }
        }
        return this;
    }

    public function enable(key:String, enabled:Bool):MMDAnimationHelper {
        if (!enabled.hasOwnProperty(key)) {
            throw new Error('THREE.MMDAnimationHelper.enable: ' +
                'unknown key ' + key);
        }
        enabled[key] = enabled;
        if (key == 'physics') {
            var i:Int;
            for (i = 0; i < meshes.length; i++) {
                _optimizeIK(meshes[i], enabled);
            }
        }
        return this;
    }

    public function createGrantSolver(mesh:SkinnedMesh):Dynamic {
        return new GrantSolver(mesh, mesh.geometry.userData.MMD.grants);
    }

    private function _addMesh(mesh:SkinnedMesh, params:Dynamic) {
        if (meshes.indexOf(mesh) >= 0) {
            throw new Error('THREE.MMDAnimationHelper._addMesh: ' +
                'SkinnedMesh \'' + mesh.name + '\' has already been added.');
        }
        meshes.push(mesh);
        objects.set(mesh, {looped: false});
        _setupMeshAnimation(mesh, params.animation);
        if (params.physics != false) {
            _setupMeshPhysics(mesh, params);
        }
    }

    private function _setupCamera(camera:Camera, params:Dynamic) {
        if (camera == this.camera) {
            throw new Error('THREE.MMDAnimationHelper._setupCamera: ' +
                'Camera \'' + camera.name + '\' has already been set.');
        }
        if (this.camera) {
            _clearCamera(this.camera);
        }
        this.camera = camera;
        camera.add(cameraTarget);
        objects.set(camera, {});
        if (params.animation != null) {
            _setupCameraAnimation(camera, params.animation);
        }
    }

    private function _setupAudio(audio:Audio, params:Dynamic) {
        if (audio == this.audio) {
            throw new Error('THREE.MMDAnimationHelper._setupAudio: ' +
                'Audio \'' + audio.name + '\' has already been set.');
        }
        if (this.audio) {
            _clearAudio(this.audio);
        }
        this.audio = audio;
        this.audioManager = new AudioManager(audio, params);
        objects.set(this.audioManager, {
            duration: this.audioManager.duration
        });
    }

    private function _removeMesh(mesh:SkinnedMesh) {
        var found = false;
        var writeIndex = 0;
        var i:Int;
        for (i = 0; i < meshes.length; i++) {
            if (meshes[i] == mesh) {
                objects.delete(mesh);
                found = true;
                continue;
            }
            meshes[writeIndex++] = meshes[i];
        }
        if (!found) {
            throw new Error('THREE.MMDAnimationHelper._removeMesh: ' +
                'SkinnedMesh \'' + mesh.name + '\' has not been added yet.');
        }
        meshes.length = writeIndex;
    }

    private function _clearCamera(camera:Camera) {
        if (camera != this.camera) {
            throw new Error('THREE.MMDAnimationHelper._clearCamera: ' +
                'Camera \'' + camera.name + '\' has not been set yet.');
        }
        this.camera.remove(cameraTarget);
        objects.delete(this.camera);
        this.camera = null;
    }

    private function _clearAudio(audio:Audio) {
        if (audio != this.audio) {
            throw new Error('THREE.MMDAnimationHelper._clearAudio: ' +
                'Audio \'' + audio.name + '\' has not been set yet.');
        }
        objects.delete(this.audioManager);
        this.audio = null;
        this.audioManager = null;
    }

    private function _setupMeshAnimation(mesh:SkinnedMesh, animation:Dynamic) {
        var objects = this.objects.get(mesh);
        if (animation != null) {
            var animations = (Type.enumParameter(animation, Array) ? animation : [animation]);
            objects.mixer = new AnimationMixer(mesh);
            var i:Int;
            for (i = 0; i < animations.length; i++) {
                objects.mixer.clipAction(animations[i]).play();
            }
            objects.mixer.addEventListener('loop', function(event) {
                var tracks = event.action._clip.tracks;
                if (tracks.length > 0 && tracks[0].name.slice(0, 6) != '.bones') {
                    return;
                }
                objects.looped = true;
            });
        }
        objects.ikSolver = _createCCDIKSolver(mesh);
        objects.grantSolver = createGrantSolver(mesh);
    }

    private function _setupCameraAnimation(camera:Camera, animation:Dynamic) {
        var animations = (Type.enumParameter(animation, Array) ? animation : [animation]);
        var objects = this.objects.get(camera);
        objects.mixer = new AnimationMixer(camera);
        var i:Int;
        for (i = 0; i < animations.length; i++) {
            objects.mixer.clipAction(animations[i]).play();
        }
    }

    private function _setupMeshPhysics(mesh:SkinnedMesh, params:Dynamic) {
        var objects = this.objects.get(mesh);
        if (params.world == null && sharedPhysics) {
            var masterPhysics = _getMasterPhysics();
            if (masterPhysics != null) {
                world = masterPhysics.world;
            }
        }
        objects.physics = _createMMDPhysics(mesh, params);
        if (objects.mixer && params.animationWarmup != false) {
            _animateMesh(mesh, 0);
            objects.physics.reset();
        }
        objects.physics.warmup((params.warmup != null) ? params.warmup : 60);
        _optimizeIK(mesh, true);
    }

    private function _animateMesh(mesh:SkinnedMesh, delta:Float) {
        var objects = this.objects.get(mesh);
        var mixer = objects.mixer;
        var ikSolver = objects.ikSolver;
        var grantSolver = objects.grantSolver;
        var physics = objects.physics;
        var looped = objects.looped;
        if (mixer && enabled.animation) {
            _restoreBones(mesh);
            mixer.update(delta);
            _saveBones(mesh);
            if (configuration.pmxAnimation &&
                mesh.geometry.userData.MMD != null && mesh.geometry.userData.MMD.format == 'pmx') {
                if (!objects.sortedBonesData) {
                    objects.sortedBonesData = _sortBoneDataArray(mesh.geometry.userData.MMD.bones.slice());
                }
                _animatePMXMesh(
                    mesh,
                    objects.sortedBonesData,
                    (ikSolver && enabled.ik) ? ikSolver : null,
                    (grantSolver && enabled.grant) ? grantSolver : null
                );
            } else {
                if (ikSolver && enabled.ik) {
                    mesh.updateMatrixWorld(true);
                    ikSolver.update();
                }
                if (grantSolver && enabled.grant) {
                    grantSolver.update();
                }
            }
        }
        if (looped && enabled.physics) {
            if (physics && configuration.resetPhysicsOnLoop) {
                physics.reset();
            }
            objects.looped = false;
        }
        if (physics && enabled.physics && !sharedPhysics) {
            onBeforePhysics(mesh);
            physics.update(delta);
        }
    }

    private function _sortBoneDataArray(boneDataArray:Array<Dynamic>):Array<Dynamic> {
        return boneDataArray.sort(function(a, b) {
            if (a.transformationClass != b.transformationClass) {
                return a.transformationClass - b.transformationClass;
            } else {
                return a.index - b.index;
            }
        });
    }

    private function _animatePMXMesh(mesh:SkinnedMesh, sortedBonesData:Array<Dynamic>, ikSolver:Dynamic, grantSolver:Dynamic) {
        _quaternionIndex = 0;
        _grantResultMap.clear();
        var i:Int;
        for (i = 0; i < sortedBonesData.length; i++) {
            updateOne(mesh, sortedBonesData[i].index, ikSolver, grantSolver);
        }
        mesh.updateMatrixWorld(true);
        return this;
    }

    private function _animateCamera(camera:Camera, delta:Float) {
        var mixer = this.objects.get(camera).mixer;
        if (mixer && enabled.cameraAnimation) {
            mixer.update(delta);
            camera.updateProjectionMatrix();
            camera.up.set(0, 1, 0);
            camera.up.applyQuaternion(camera.quaternion);
            camera.lookAt(this.cameraTarget.position);
        }
    }

    private function _optimizeIK(mesh:SkinnedMesh, physicsEnabled:Bool) {
        var iks = mesh.geometry.userData.MMD.iks;
        var bones = mesh.geometry.userData.MMD.bones;
        var i:Int;
        for (i = 0; i < iks.length; i++) {
            var ik = iks[i];
            var links = ik.links;
            var j:Int;
            for (j = 0; j < links.length; j++) {
                var link = links[j];
                if (physicsEnabled) {
                    link.enabled = bones[link.index].rigidBodyType > 0 ? false : true;
                } else {
                    link.enabled = true;
                }
            }
        }
    }

    private function _createCCDIKSolver(mesh:SkinnedMesh):Dynamic {
        if (CCDIKSolver == null) {
            throw new Error('THREE.MMDAnimationHelper: Import CCDIKSolver.');
        }
        return new CCDIKSolver(mesh, mesh.geometry.userData.MMD.iks);
    }

    private function _createMMDPhysics(mesh:SkinnedMesh, params:Dynamic):Dynamic {
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

    private function _syncDuration() {
        var max = 0.0;
        var objects = this.objects;
        var meshes = this.meshes;
        var camera = this.camera;
        var audioManager = this.audioManager;
        var i:Int;
        // get the longest duration
        for (i = 0; i < meshes.length; i++) {
            var mixer = this.objects.get(meshes[i]).mixer;
            if (mixer == null) {
                continue;
            }
            var j:Int;
            for (j = 0; j < mixer._actions.length; j++) {
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
                var i:Int;
                for (i = 0; i < mixer._actions.length; i++) {
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
        max += configuration.afterglow;
        // update the duration
        var i:Int;
        for (i = 0; i < meshes.length; i++) {
            var mixer = this.objects.get(meshes[i]).mixer;
            if (mixer == null)
            continue;
        }
        var j:Int;
        for (j = 0; j < mixer._actions.length; j++) {
            mixer._actions[j]._clip.duration = max;
        }
    }
    if (camera != null) {
        var mixer = this.objects.get(camera).mixer;
        if (mixer != null) {
            var i:Int;
            for (i = 0; i < mixer._actions.length; i++) {
                mixer._actions[i]._clip.duration = max;
            }
        }
    }
    if (audioManager != null) {
        audioManager.duration = max;
    }
}

// workaround

private function _updatePropertyMixersBuffer(mesh:SkinnedMesh) {
    var mixer = this.objects.get(mesh).mixer;
    var propertyMixers = mixer._bindings;
    var accuIndex = mixer._accuIndex;
    var i:Int;
    for (i = 0; i < propertyMixers.length; i++) {
        var propertyMixer = propertyMixers[i];
        var buffer = propertyMixer.buffer;
        var stride = propertyMixer.valueSize;
        var offset = (accuIndex + 1) * stride;
        propertyMixer.binding.getValue(buffer, offset);
    }
}

// Avoiding these two issues by restore/save bones before/after mixer animation.
// 1. PropertyMixer used by AnimationMixer holds cache value in .buffer.
// Calculating IK, Grant, and Physics after mixer animation can break
// the cache coherency.
// 2. Applying Grant two or more times without reset the posing breaks model.
private function _saveBones(mesh:SkinnedMesh) {
    var objects = this.objects.get(mesh);
    var bones = mesh.skeleton.bones;
    var backupBones = objects.backupBones;
    if (backupBones == null) {
        backupBones = new Float32Array(bones.length * 7);
        objects.backupBones = backupBones;
    }
    var i:Int;
    for (i = 0; i < bones.length; i++) {
        var bone = bones[i];
        bone.position.toArray(backupBones, i * 7);
        bone.quaternion.toArray(backupBones, i * 7 + 3);
    }
}

private function _restoreBones(mesh:SkinnedMesh) {
    var objects = this.objects.get(mesh);
    var backupBones = objects.backupBones;
    if (backupBones == null) {
        return;
    }
    var bones = mesh.skeleton.bones;
    var i:Int;
    for (i = 0; i < bones.length; i++) {
        var bone = bones[i];
        bone.position.fromArray(backupBones, i * 7);
        bone.quaternion.fromArray(backupBones, i * 7 + 3);
    }
}

// experimental

private function _getMasterPhysics():Dynamic {
    if (masterPhysics != null) {
        return masterPhysics;
    }
    var i:Int;
    for (i = 0; i < meshes.length; i++) {
        var physics = meshes[i].physics;
        if (physics != null) {
            masterPhysics = physics;
            return masterPhysics;
        }
    }
    return null;
}

private function _updateSharedPhysics(delta:Float) {
    if (meshes.length == 0 || !enabled.physics || !sharedPhysics) {
        return;
    }
    var physics = _getMasterPhysics();
    if (physics == null) {
        return;
    }
    var i:Int;
    for (i = 0; i < meshes.length; i++) {
        var p = meshes[i].physics;
        if (p != null) {
            p.updateRigidBodies();
        }
    }
    physics.stepSimulation(delta);
    var i:Int;
    for (i = 0; i < meshes.length; i++) {
        var p = meshes[i].physics;
        if (p != null) {
            p.updateBones();
        }
    }
}

class AudioManager {
    var audio:Audio;
    var elapsedTime:Float;
    var currentTime:Float;
    var delayTime:Float;
    var audioDuration:Float;
    var duration:Float;

    public function new(audio:Audio, ?params:Dynamic) {
        this.audio = audio;
        elapsedTime = 0.0;
        currentTime = 0.0;
        delayTime = (params != null && 'delayTime' in params) ? params.delayTime : 0.0;
        audioDuration = this.audio.buffer.duration;
        duration = audioDuration + delayTime;
    }

    public function control(delta:Float):AudioManager {
        elapsed += delta;
        currentTime += delta;
        if (_shouldStopAudio()) {
            audio.stop();
        }
        if (_shouldStartAudio()) {
            audio.play();
        }
        return this;
    }

    private function _shouldStartAudio():Bool {
        if (audio.isPlaying) {
            return false;
        }
        while (currentTime >= duration) {
            currentTime -= duration;
        }
        if (currentTime < delayTime) {
            return false;
        }
        if ((currentTime - delayTime) > audioDuration) {
            return false;
        }
        return true;
    }

    private function _shouldStopAudio():Bool {
        return audio.isPlaying && currentTime >= duration;
    }
}

var _q = new Quaternion();

class GrantSolver {
    var mesh:SkinnedMesh;
    var grants:Array<Dynamic>;

    public function new(mesh:SkinnedMesh, ?grants:Array<Dynamic>) {
        this.mesh = mesh;
        this.grants = grants != null ? grants : [];
    }

    public function update():GrantSolver {
        var grants = this.grants;
        var i:Int;
        for (i = 0; i < grants.length; i++) {
            updateOne(grants[i]);
        }
        return this;
    }

    public function updateOne(grant:Dynamic):GrantSolver {
        var bones = mesh.skeleton.bones;
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
                addGrantRotation(bone, parentBone.quaternion, grant.ratio);
            }
        }
        return this;
    }

    public function addGrantRotation(bone:Dynamic, q:Quaternion, ratio:Float):GrantSolver {
        _q.set(0, 0, 0, 1);
        _q.slerp(q, ratio);
        bone.quaternion.multiply(_q);
        return this;
    }
}

export {MMDAnimationHelper};