import js.three.AnimationClip;
import js.three.AnimationMixer;
import js.three.Matrix4;
import js.three.Quaternion;
import js.three.QuaternionKeyframeTrack;
import js.three.SkeletonHelper;
import js.three.Vector3;
import js.three.VectorKeyframeTrack;

function retarget(target:Dynamic, source:Dynamic, ?options:Map<Dynamic>) {
    var pos:Vector3 = new Vector3();
    var quat:Quaternion = new Quaternion();
    var scale:Vector3 = new Vector3();
    var bindBoneMatrix:Matrix4 = new Matrix4();
    var relativeMatrix:Matrix4 = new Matrix4();
    var globalMatrix:Matrix4 = new Matrix4();

    var preserveMatrix:Bool = options != null && options.exists('preserveMatrix') ? options.get('preserveMatrix') : true;
    var preservePosition:Bool = options != null && options.exists('preservePosition') ? options.get('preservePosition') : true;
    var preserveHipPosition:Bool = options != null && options.exists('preserveHipPosition') ? options.get('preserveHipPosition') : false;
    var useTargetMatrix:Bool = options != null && options.exists('useTargetMatrix') ? options.get('useTargetMatrix') : false;
    var hip:String = options != null && options.exists('hip') ? options.get('hip') : 'hip';
    var names:Map<String> = options != null && options.exists('names') ? options.get('names') : cast(Map<String>, cast(Map<Dynamic>, {}));

    var sourceBones:Array<Dynamic> = if (Reflect.hasField(source, 'isObject3D')) source.skeleton.bones : getBones(source);
    var bones:Array<Dynamic> = if (Reflect.hasField(target, 'isObject3D')) target.skeleton.bones : getBones(target);

    var bindBones:Array<Dynamic>;
    var bone:Dynamic, name:String, boneTo:Dynamic, bonesPosition:Array<Dynamic>;

    // reset bones

    if (Reflect.hasField(target, 'isObject3D')) {
        target.skeleton.pose();
    } else {
        useTargetMatrix = true;
        preserveMatrix = false;
    }

    if (preservePosition) {
        bonesPosition = [];
        var i:Int;
        for (i = 0; i < bones.length; i++) {
            bonesPosition.push(bones[i].position.clone());
        }
    }

    if (preserveMatrix) {
        // reset matrix
        target.updateMatrixWorld();
        target.matrixWorld.identity();

        // reset children matrix
        var j:Int;
        for (j = 0; j < target.children.length; ++j) {
            target.children[j].updateMatrixWorld(true);
        }
    }

    if (options != null && options.exists('offsets')) {
        bindBones = [];
        for (i = 0; i < bones.length; ++i) {
            bone = bones[i];
            name = names.get(bone.name) ?? bone.name;
            if (options.get('offsets').exists(name)) {
                bone.matrix.multiply(options.get('offsets').get(name));
                bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);
                bone.updateMatrixWorld();
            }
            bindBones.push(bone.matrixWorld.clone());
        }
    }

    for (i = 0; i < bones.length; ++i) {
        bone = bones[i];
        name = names.get(bone.name) ?? bone.name;
        boneTo = getBoneByName(name, sourceBones);
        globalMatrix.copy(bone.matrixWorld);
        if (boneTo != null) {
            boneTo.updateMatrixWorld();
            if (useTargetMatrix) {
                relativeMatrix.copy(boneTo.matrixWorld);
            } else {
                relativeMatrix.copy(target.matrixWorld).invert();
                relativeMatrix.multiply(boneTo.matrixWorld);
            }

            // ignore scale to extract rotation
            scale.setFromMatrixScale(relativeMatrix);
            relativeMatrix.scale(scale.set(1 / scale.x, 1 / scale.y, 1 / scale.z));

            // apply to global matrix
            globalMatrix.makeRotationFromQuaternion(quat.setFromRotationMatrix(relativeMatrix));

            if (Reflect.hasField(target, 'isObject3D')) {
                var boneIndex:Int = Array.indexOf(bones, bone);
                var wBindMatrix:Matrix4 = if (bindBones != null) bindBones[boneIndex] : bindBoneMatrix.copy(target.skeleton.boneInverses[boneIndex]).invert();
                globalMatrix.multiply(wBindMatrix);
            }

            globalMatrix.copyPosition(relativeMatrix);
        }

        if (bone.parent != null && Reflect.hasField(bone.parent, 'isBone')) {
            bone.matrix.copy(bone.parent.matrixWorld).invert();
            bone.matrix.multiply(globalMatrix);
        } else {
            bone.matrix.copy(globalMatrix);
        }

        if (preserveHipPosition && name == hip) {
            bone.matrix.setPosition(pos.set(0, bone.position.y, 0));
        }

        bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);
        bone.updateMatrixWorld();
    }

    if (preservePosition) {
        for (i = 0; i < bones.length; ++i) {
            bone = bones[i];
            name = names.get(bone.name) ?? bone.name;
            if (name != hip) {
                bone.position.copy(bonesPosition[i]);
            }
        }
    }

    if (preserveMatrix) {
        // restore matrix
        target.updateMatrixWorld(true);
    }
}

function retargetClip(target:Dynamic, source:Dynamic, clip:Dynamic, ?options:Map<Dynamic>) {
    var useFirstFramePosition:Bool = options != null && options.exists('useFirstFramePosition') ? options.get('useFirstFramePosition') : false;
    // Calculate the fps from the source clip based on the track with the most frames, unless fps is already provided.
    var fps:Float = options != null && options.exists('fps') ? options.get('fps') : (cast(Float, clip.duration) / 1000) * 1000 / Math.max(Array.map(clip.tracks, function(track:Dynamic) {
        return track.times.length;
    }));
    var names:Map<String> = options != null && options.exists('names') ? options.get('names') : cast(Map<String>, []);

    if (!Reflect.hasField(source, 'isObject3D')) {
        source = getHelperFromSkeleton(source);
    }

    var numFrames:Int = cast(Int, Math.round(clip.duration * (fps / 1000) * 1000));
    var delta:Float = clip.duration / (numFrames - 1);
    var convertedTracks:Array<Dynamic> = [];
    var mixer:AnimationMixer = new AnimationMixer(source);
    var bones:Array<Dynamic> = getBones(target.skeleton);
    var boneDatas:Array<Dynamic> = [];
    var positionOffset:Dynamic, bone:Dynamic, boneTo:Dynamic, boneData:Dynamic, name:String;

    mixer.clipAction(clip).play();
    mixer.update(0);

    source.updateMatrixWorld();

    var i:Int, j:Int;
    for (i = 0; i < numFrames; ++i) {
        var time:Float = i * delta;
        retarget(target, source, options);
        for (j = 0; j < bones.length; ++j) {
            name = names.get(bones[j].name) ?? bones[j].name;
            boneTo = getBoneByName(name, source.skeleton);
            if (boneTo != null) {
                bone = bones[j];
                boneData = boneDatas[j] = boneDatas[j] ?? {bone: bone};
                if (hip == name) {
                    if (boneData.pos == null) {
                        boneData.pos = {
                            times: new Float32Array(numFrames),
                            values: new Float32Array(numFrames * 3)
                        };
                    }
                    if (useFirstFramePosition) {
                        if (i == 0) {
                            positionOffset = bone.position.clone();
                        }
                        bone.position.sub(positionOffset);
                    }
                    boneData.pos.times[i] = time;
                    bone.position.toArray(boneData.pos.values, i * 3);
                }
                if (boneData.quat == null) {
                    boneData.quat = {
                        times: new Float32Array(numFrames),
                        values: new Float32Array(numFrames * 4)
                    };
                }
                boneData.quat.times[i] = time;
                bone.quaternion.toArray(boneData.quat.values, i * 4);
            }
        }
        if (i == numFrames - 2) {
            // last mixer update before final loop iteration
            // make sure we do not go over or equal to clip duration
            mixer.update(delta - 0.0000001);
        } else {
            mixer.update(delta);
        }
        source.updateMatrixWorld();
    }

    for (i = 0; i < boneDatas.length; ++i) {
        boneData = boneDatas[i];
        if (boneData != null) {
            if (boneData.pos != null) {
                convertedTracks.push(new VectorKeyframeTrack('.bones[' + boneData.bone.name + '].position', boneData.pos.times, boneData.pos.values));
            }
            convertedTracks.push(new QuaternionKeyframeTrack('.bones[' + boneData.bone.name + '].quaternion', boneData.quat.times, boneData.quat.values));
        }
    }

    mixer.uncacheAction(clip);

    return new AnimationClip(clip.name, -1, convertedTracks);
}

function clone(source:Dynamic) {
    var sourceLookup:Map<Dynamic> = new Map();
    var cloneLookup:Map<Dynamic> = new Map();

    var clone:Dynamic = source.clone();

    parallelTraverse(source, clone, function(sourceNode:Dynamic, clonedNode:Dynamic) {
        sourceLookup.set(clonedNode, sourceNode);
        cloneLookup.set(sourceNode, clonedNode);
    });

    clone.traverse(function(node:Dynamic) {
        if (!Reflect.hasField(node, 'isSkinnedMesh')) return;
        var clonedMesh:Dynamic = node;
        var sourceMesh:Dynamic = sourceLookup.get(node);
        var sourceBones:Array<Dynamic> = sourceMesh.skeleton.bones;

        clonedMesh.skeleton = sourceMesh.skeleton.clone();
        clonedMesh.bindMatrix.copy(sourceMesh.bindMatrix);

        clonedMesh.skeleton.bones = sourceBones.map(function(bone:Dynamic) {
            return cloneLookup.get(bone);
        });

        clonedMesh.bind(clonedMesh.skeleton, clonedMesh.bindMatrix);
    });

    return clone;
}

// internal helper

function getBoneByName(name:String, skeleton:Dynamic) {
    var bones:Array<Dynamic> = getBones(skeleton);
    var i:Int;
    for (i = 0; i < bones.length; i++) {
        if (name == bones[i].name) {
            return bones[i];
        }
    }
}

function getBones(skeleton:Dynamic) {
    if (Reflect.isArray(skeleton)) {
        return skeleton;
    } else {
        return skeleton.bones;
    }
}

function getHelperFromSkeleton(skeleton:Dynamic) {
    var source:SkeletonHelper = new SkeletonHelper(skeleton.bones[0]);
    source.skeleton = skeleton;
    return source;
}

function parallelTraverse(a:Dynamic, b:Dynamic, callback:Function) {
    callback(a, b);
    var i:Int;
    for (i = 0; i < a.children.length; i++) {
        parallelTraverse(a.children[i], b.children[i], callback);
    }
}

class Exports {
    static var retarget:Dynamic = retarget;
    static var retargetClip:Dynamic = retargetClip;
    static var clone:Dynamic = clone;
}