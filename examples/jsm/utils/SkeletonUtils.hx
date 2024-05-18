package three.js.examples.jsm.utils;

import three.AnimationClip;
import three.AnimationMixer;
import three.Matrix4;
import three.Quaternion;
import three.QuaternionKeyframeTrack;
import three.SkeletonHelper;
import three.Vector3;
import three.VectorKeyframeTrack;

class SkeletonUtils {
    public static function retarget(target:Skeleton, source:Skeleton, ?options:SkeletonRetargetOptions):Void {
        var pos = new Vector3();
        var quat = new Quaternion();
        var scale = new Vector3();
        var bindBoneMatrix = new Matrix4();
        var relativeMatrix = new Matrix4();
        var globalMatrix = new Matrix4();

        options.preserveMatrix = options.preserveMatrix != null ? options.preserveMatrix : true;
        options.preservePosition = options.preservePosition != null ? options.preservePosition : true;
        options.preserveHipPosition = options.preserveHipPosition != null ? options.preserveHipPosition : false;
        options.useTargetMatrix = options.useTargetMatrix != null ? options.useTargetMatrix : false;
        options.hip = options.hip != null ? options.hip : 'hip';
        options.names = options.names != null ? options.names : {};

        var sourceBones:Array<Bone> = source.isObject3D ? source.skeleton.bones : getBones(source);
        var bones:Array<Bone> = target.isObject3D ? target.skeleton.bones : getBones(target);

        var bindBones:Array<Matrix4>;
        var bone:Bone;
        var name:String;
        var boneTo:Bone;
        var bonesPosition:Array<Vector3>;

        // reset bones

        if (target.isObject3D) {
            target.skeleton.pose();
        } else {
            options.useTargetMatrix = true;
            options.preserveMatrix = false;
        }

        if (options.preservePosition) {
            bonesPosition = [];

            for (i in 0...bones.length) {
                bonesPosition.push(bones[i].position.clone());
            }
        }

        if (options.preserveMatrix) {
            // reset matrix

            target.updateMatrixWorld();

            target.matrixWorld.identity();

            // reset children matrix

            for (i in 0...target.children.length) {
                target.children[i].updateMatrixWorld(true);
            }
        }

        if (options.offsets) {
            bindBones = [];

            for (i in 0...bones.length) {
                bone = bones[i];
                name = options.names[bone.name] != null ? options.names[bone.name] : bone.name;

                if (options.offsets[name] != null) {
                    bone.matrix.multiply(options.offsets[name]);

                    bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);

                    bone.updateMatrixWorld();
                }

                bindBones.push(bone.matrixWorld.clone());
            }
        }

        for (i in 0...bones.length) {
            bone = bones[i];
            name = options.names[bone.name] != null ? options.names[bone.name] : bone.name;

            boneTo = getBoneByName(name, sourceBones);

            globalMatrix.copy(bone.matrixWorld);

            if (boneTo != null) {
                boneTo.updateMatrixWorld();

                if (options.useTargetMatrix) {
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

                if (target.isObject3D) {
                    var boneIndex:Int = bones.indexOf(bone);
                    var wBindMatrix:Matrix4 = bindBones != null ? bindBones[boneIndex] : bindBoneMatrix.copy(target.skeleton.boneInverses[boneIndex]).invert();

                    globalMatrix.multiply(wBindMatrix);
                }

                globalMatrix.copyPosition(relativeMatrix);
            }

            if (bone.parent != null && bone.parent.isBone) {
                bone.matrix.copy(bone.parent.matrixWorld).invert();
                bone.matrix.multiply(globalMatrix);
            } else {
                bone.matrix.copy(globalMatrix);
            }

            if (options.preserveHipPosition && name == options.hip) {
                bone.matrix.setPosition(pos.set(0, bone.position.y, 0));
            }

            bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);

            bone.updateMatrixWorld();
        }

        if (options.preservePosition) {
            for (i in 0...bones.length) {
                bone = bones[i];
                name = options.names[bone.name] != null ? options.names[bone.name] : bone.name;

                if (name != options.hip) {
                    bone.position.copy(bonesPosition[i]);
                }
            }
        }

        if (options.preserveMatrix) {
            // restore matrix

            target.updateMatrixWorld(true);
        }
    }

    public static function retargetClip(target:Skeleton, source:Skeleton, clip:AnimationClip, ?options:SkeletonRetargetOptions):AnimationClip {
        options.useFirstFramePosition = options.useFirstFramePosition != null ? options.useFirstFramePosition : false;
        // Calculate the fps from the source clip based on the track with the most frames, unless fps is already provided.
        options.fps = options.fps != null ? options.fps : (Math.max(...clip.tracks.map(track -> track.times.length)) / clip.duration);
        options.names = options.names != null ? options.names : [];

        if (!source.isObject3D) {
            source = getHelperFromSkeleton(source);
        }

        var numFrames:Int = Math.round(clip.duration * (options.fps / 1000) * 1000);
        var delta:Float = clip.duration / (numFrames - 1);
        var convertedTracks:Array<KeyframeTrack> = [];
        var mixer:AnimationMixer = new AnimationMixer(source);
        var bones:Array<Bone> = getBones(target.skeleton);
        var boneDatas:Array<BoneData> = [];
        var positionOffset:Vector3;
        var bone:Bone;
        var boneTo:Bone;
        var boneData:BoneData;
        var name:String;

        mixer.clipAction(clip).play();
        mixer.update(0);

        source.updateMatrixWorld();

        for (i in 0...numFrames) {
            var time:Float = i * delta;

            retarget(target, source, options);

            for (j in 0...bones.length) {
                name = options.names[bones[j].name] != null ? options.names[bones[j].name] : bones[j].name;

                boneTo = getBoneByName(name, source.skeleton);

                if (boneTo != null) {
                    bone = bones[j];
                    boneData = boneDatas[j] = boneDatas[j] != null ? boneDatas[j] : { bone: bone };

                    if (options.hip == name) {
                        if (!boneData.pos) {
                            boneData.pos = {
                                times: new Float32Array(numFrames),
                                values: new Float32Array(numFrames * 3)
                            };
                        }

                        if (options.useFirstFramePosition) {
                            if (i == 0) {
                                positionOffset = bone.position.clone();
                            }

                            bone.position.sub(positionOffset);
                        }

                        boneData.pos.times[i] = time;

                        bone.position.toArray(boneData.pos.values, i * 3);
                    }

                    if (!boneData.quat) {
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

        for (i in 0...boneDatas.length) {
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

    public static function clone(source:Skeleton):Skeleton {
        var sourceLookup:Map<Skeleton, Skeleton> = new Map();
        var cloneLookup:Map<Skeleton, Skeleton> = new Map();

        var clone:Skeleton = source.clone();

        parallelTraverse(source, clone, function(sourceNode:Skeleton, clonedNode:Skeleton) {
            sourceLookup.set(clonedNode, sourceNode);
            cloneLookup.set(sourceNode, clonedNode);
        });

        clone.traverse(function(node:Skeleton) {
            if (!node.isSkinnedMesh) return;

            var clonedMesh:Skeleton = node;
            var sourceMesh:Skeleton = sourceLookup.get(node);
            var sourceBones:Array<Bone> = sourceMesh.skeleton.bones;

            clonedMesh.skeleton = sourceMesh.skeleton.clone();
            clonedMesh.bindMatrix.copy(sourceMesh.bindMatrix);

            clonedMesh.skeleton.bones = sourceBones.map(function(bone:Bone) {
                return cloneLookup.get(bone);
            });

            clonedMesh.bind(clonedMesh.skeleton, clonedMesh.bindMatrix);
        });

        return clone;
    }

    static function getBoneByName(name:String, skeleton:Skeleton):Bone {
        for (i in 0...(getBones(skeleton).length)) {
            if (name == getBones(skeleton)[i].name)
                return getBones(skeleton)[i];
        }

        return null;
    }

    static function getBones(skeleton:Skeleton):Array<Bone> {
        return Std.isOfType(skeleton, Array) ? skeleton : skeleton.bones;
    }

    static function getHelperFromSkeleton(skeleton:Skeleton):SkeletonHelper {
        var source:Skeleton = new SkeletonHelper(skeleton.bones[0]);
        source.skeleton = skeleton;

        return source;
    }

    static function parallelTraverse(a:Skeleton, b:Skeleton, callback:Skeleton->Skeleton->Void) {
        callback(a, b);

        for (i in 0...a.children.length) {
            parallelTraverse(a.children[i], b.children[i], callback);
        }
    }
}

typedef SkeletonRetargetOptions = {
    ?preserveMatrix:Bool,
    ?preservePosition:Bool,
    ?preserveHipPosition:Bool,
    ?useTargetMatrix:Bool,
    ?hip:String,
    ?names:Map<String, String>,
    ?offsets:Map<String, Matrix4>,
    ?useFirstFramePosition:Bool,
    ?fps:Float
}

typedef BoneData = {
    bone:Bone,
    ?pos:{
        times:Float32Array,
        values:Float32Array
    },
    ?quat:{
        times:Float32Array,
        values:Float32Array
    }
}