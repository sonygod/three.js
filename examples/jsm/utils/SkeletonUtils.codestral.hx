import three.AnimationClip;
import three.AnimationMixer;
import three.Matrix4;
import three.Quaternion;
import three.QuaternionKeyframeTrack;
import three.SkeletonHelper;
import three.Vector3;
import three.VectorKeyframeTrack;

class SkeletonUtils {

    static function retarget(target:Object, source:Object, options:Object = null):Void {
        var pos:Vector3 = new Vector3(),
            quat:Quaternion = new Quaternion(),
            scale:Vector3 = new Vector3(),
            bindBoneMatrix:Matrix4 = new Matrix4(),
            relativeMatrix:Matrix4 = new Matrix4(),
            globalMatrix:Matrix4 = new Matrix4();

        if(options == null) options = {};

        options.preserveMatrix = options.hasOwnProperty("preserveMatrix") ? options.preserveMatrix : true;
        options.preservePosition = options.hasOwnProperty("preservePosition") ? options.preservePosition : true;
        options.preserveHipPosition = options.hasOwnProperty("preserveHipPosition") ? options.preserveHipPosition : false;
        options.useTargetMatrix = options.hasOwnProperty("useTargetMatrix") ? options.useTargetMatrix : false;
        options.hip = options.hasOwnProperty("hip") ? options.hip : "hip";
        options.names = options.hasOwnProperty("names") ? options.names : {};

        var sourceBones = source.hasOwnProperty("isObject3D") ? source.skeleton.bones : getBones(source),
            bones = target.hasOwnProperty("isObject3D") ? target.skeleton.bones : getBones(target);

        var bindBones;
        var bone:Object, name:String, boneTo:Object, bonesPosition;

        if(target.hasOwnProperty("isObject3D")) {
            target.skeleton.pose();
        } else {
            options.useTargetMatrix = true;
            options.preserveMatrix = false;
        }

        if(options.preservePosition) {
            bonesPosition = [];
            for(bone in bones) {
                bonesPosition.push(bone.position.clone());
            }
        }

        if(options.preserveMatrix) {
            target.updateMatrixWorld();
            target.matrixWorld.identity();
            for(var i:Int = 0; i < target.children.length; ++i) {
                target.children[i].updateMatrixWorld(true);
            }
        }

        if(options.hasOwnProperty("offsets")) {
            bindBones = [];
            for(bone in bones) {
                name = options.names.hasOwnProperty(bone.name) ? options.names[bone.name] : bone.name;
                if(options.offsets.hasOwnProperty(name)) {
                    bone.matrix.multiply(options.offsets[name]);
                    bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);
                    bone.updateMatrixWorld();
                }
                bindBones.push(bone.matrixWorld.clone());
            }
        }

        for(bone in bones) {
            name = options.names.hasOwnProperty(bone.name) ? options.names[bone.name] : bone.name;
            boneTo = getBoneByName(name, sourceBones);
            globalMatrix.copy(bone.matrixWorld);

            if(boneTo != null) {
                boneTo.updateMatrixWorld();

                if(options.useTargetMatrix) {
                    relativeMatrix.copy(boneTo.matrixWorld);
                } else {
                    relativeMatrix.copy(target.matrixWorld).invert();
                    relativeMatrix.multiply(boneTo.matrixWorld);
                }

                scale.setFromMatrixScale(relativeMatrix);
                relativeMatrix.scale(scale.set(1 / scale.x, 1 / scale.y, 1 / scale.z));

                globalMatrix.makeRotationFromQuaternion(quat.setFromRotationMatrix(relativeMatrix));

                if(target.hasOwnProperty("isObject3D")) {
                    var boneIndex = bones.indexOf(bone);
                    var wBindMatrix = bindBones != null ? bindBones[boneIndex] : bindBoneMatrix.copy(target.skeleton.boneInverses[boneIndex]).invert();
                    globalMatrix.multiply(wBindMatrix);
                }

                globalMatrix.copyPosition(relativeMatrix);
            }

            if(bone.parent != null && bone.parent.hasOwnProperty("isBone")) {
                bone.matrix.copy(bone.parent.matrixWorld).invert();
                bone.matrix.multiply(globalMatrix);
            } else {
                bone.matrix.copy(globalMatrix);
            }

            if(options.preserveHipPosition && name == options.hip) {
                bone.matrix.setPosition(pos.set(0, bone.position.y, 0));
            }

            bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);
            bone.updateMatrixWorld();
        }

        if(options.preservePosition) {
            for(bone in bones) {
                name = options.names.hasOwnProperty(bone.name) ? options.names[bone.name] : bone.name;
                if(name != options.hip) {
                    bone.position.copy(bonesPosition[bones.indexOf(bone)]);
                }
            }
        }

        if(options.preserveMatrix) {
            target.updateMatrixWorld(true);
        }
    }

    static function retargetClip(target:Object, source:Object, clip:AnimationClip, options:Object = null):AnimationClip {
        if(options == null) options = {};

        options.useFirstFramePosition = options.hasOwnProperty("useFirstFramePosition") ? options.useFirstFramePosition : false;
        options.fps = options.hasOwnProperty("fps") ? options.fps : (Math.max(...clip.tracks.map(function(track):Int { return track.times.length; })) / clip.duration);
        options.names = options.hasOwnProperty("names") ? options.names : {};

        if(!source.hasOwnProperty("isObject3D")) {
            source = getHelperFromSkeleton(source);
        }

        var numFrames = Math.round(clip.duration * (options.fps / 1000) * 1000);
        var delta = clip.duration / (numFrames - 1);
        var convertedTracks = [];
        var mixer = new AnimationMixer(source);
        var bones = getBones(target.skeleton);
        var boneDatas = [];
        var positionOffset, bone, boneTo, boneData, name;

        mixer.clipAction(clip).play();
        mixer.update(0);
        source.updateMatrixWorld();

        for(var i:Int = 0; i < numFrames; ++i) {
            var time = i * delta;
            retarget(target, source, options);

            for(var j:Int = 0; j < bones.length; ++j) {
                name = options.names.hasOwnProperty(bones[j].name) ? options.names[bones[j].name] : bones[j].name;
                boneTo = getBoneByName(name, source.skeleton);

                if(boneTo != null) {
                    bone = bones[j];
                    boneData = boneDatas[j] = boneDatas[j] != null ? boneDatas[j] : {bone: bone};

                    if(options.hip == name) {
                        if(boneData.pos == null) {
                            boneData.pos = {
                                times: new Float32Array(numFrames),
                                values: new Float32Array(numFrames * 3)
                            };
                        }

                        if(options.useFirstFramePosition) {
                            if(i == 0) {
                                positionOffset = bone.position.clone();
                            }
                            bone.position.sub(positionOffset);
                        }

                        boneData.pos.times[i] = time;
                        bone.position.toArray(boneData.pos.values, i * 3);
                    }

                    if(boneData.quat == null) {
                        boneData.quat = {
                            times: new Float32Array(numFrames),
                            values: new Float32Array(numFrames * 4)
                        };
                    }

                    boneData.quat.times[i] = time;
                    bone.quaternion.toArray(boneData.quat.values, i * 4);
                }
            }

            if(i == numFrames - 2) {
                mixer.update(delta - 0.0000001);
            } else {
                mixer.update(delta);
            }

            source.updateMatrixWorld();
        }

        for(i = 0; i < boneDatas.length; ++i) {
            boneData = boneDatas[i];

            if(boneData != null) {
                if(boneData.pos != null) {
                    convertedTracks.push(new VectorKeyframeTrack(
                        '.bones[' + boneData.bone.name + '].position',
                        boneData.pos.times,
                        boneData.pos.values
                    ));
                }

                convertedTracks.push(new QuaternionKeyframeTrack(
                    '.bones[' + boneData.bone.name + '].quaternion',
                    boneData.quat.times,
                    boneData.quat.values
                ));
            }
        }

        mixer.uncacheAction(clip);

        return new AnimationClip(clip.name, -1, convertedTracks);
    }

    static function clone(source:Object):Object {
        var sourceLookup = new Map<Object, Object>();
        var cloneLookup = new Map<Object, Object>();

        var clone = source.clone();

        parallelTraverse(source, clone, function(sourceNode:Object, clonedNode:Object):Void {
            sourceLookup.set(clonedNode, sourceNode);
            cloneLookup.set(sourceNode, clonedNode);
        });

        clone.traverse(function(node:Object):Void {
            if(!node.hasOwnProperty("isSkinnedMesh")) return;

            var clonedMesh = node;
            var sourceMesh = sourceLookup.get(node);
            var sourceBones = sourceMesh.skeleton.bones;

            clonedMesh.skeleton = sourceMesh.skeleton.clone();
            clonedMesh.bindMatrix.copy(sourceMesh.bindMatrix);

            clonedMesh.skeleton.bones = sourceBones.map(function(bone:Object):Object {
                return cloneLookup.get(bone);
            });

            clonedMesh.bind(clonedMesh.skeleton, clonedMesh.bindMatrix);
        });

        return clone;
    }

    static function getBoneByName(name:String, skeleton:Object):Object {
        var bones = getBones(skeleton);
        for(var i:Int = 0; i < bones.length; i++) {
            if(name == bones[i].name)
                return bones[i];
        }
        return null;
    }

    static function getBones(skeleton:Object):Array<Object> {
        return Array.isArray(skeleton) ? skeleton : skeleton.bones;
    }

    static function getHelperFromSkeleton(skeleton:Object):SkeletonHelper {
        var source = new SkeletonHelper(skeleton.bones[0]);
        source.skeleton = skeleton;
        return source;
    }

    static function parallelTraverse(a:Object, b:Object, callback:(Object, Object) -> Void):Void {
        callback(a, b);
        for(var i:Int = 0; i < a.children.length; i++) {
            parallelTraverse(a.children[i], b.children[i], callback);
        }
    }
}