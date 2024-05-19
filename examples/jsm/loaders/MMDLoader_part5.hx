package three.js.examples.jsm.loaders;

class AnimationBuilder {
    
    public function new() {}

    public function build(vmd:Object, mesh:SkinnedMesh):AnimationClip {
        // combine skeletal and morph animations

        var tracks:Array<Track> = buildSkeletalAnimation(vmd, mesh).tracks;
        var tracks2:Array<Track> = buildMorphAnimation(vmd, mesh).tracks;

        for (i in 0...tracks2.length) {
            tracks.push(tracks2[i]);
        }

        return new AnimationClip("", -1, tracks);
    }

    public function buildSkeletalAnimation(vmd:Object, mesh:SkinnedMesh):AnimationClip {
        function pushInterpolation(array:Array<Float>, interpolation:Array<Float>, index:Int) {
            array.push(interpolation[index + 0] / 127); // x1
            array.push(interpolation[index + 8] / 127); // x2
            array.push(interpolation[index + 4] / 127); // y1
            array.push(interpolation[index + 12] / 127); // y2
        }

        var tracks:Array<Track> = [];

        var motions:Object = {};
        var bones:Array<Bone> = mesh.skeleton.bones;
        var boneNameDictionary:Object = {};

        for (i in 0...bones.length) {
            boneNameDictionary[bones[i].name] = true;
        }

        for (i in 0...vmd.metadata.motionCount) {
            var motion:Object = vmd.motions[i];
            var boneName:String = motion.boneName;

            if (boneNameDictionary[boneName] == null) continue;

            if (motions[boneName] == null) motions[boneName] = [];
            motions[boneName].push(motion);
        }

        for (key in motions) {
            var array:Array<Motion> = motions[key];

            array.sort(function(a:Object, b:Object):Int {
                return a.frameNum - b.frameNum;
            });

            var times:Array<Float> = [];
            var positions:Array<Float> = [];
            var rotations:Array<Float> = [];
            var pInterpolations:Array<Float> = [];
            var rInterpolations:Array<Float> = [];

            var basePosition:Array<Float> = mesh.skeleton.getBoneByName(key).position.toArray();

            for (i in 0...array.length) {
                var time:Float = array[i].frameNum / 30;
                var position:Array<Float> = array[i].position;
                var rotation:Array<Float> = array[i].rotation;
                var interpolation:Array<Float> = array[i].interpolation;

                times.push(time);

                for (j in 0...3) {
                    positions.push(basePosition[j] + position[j]);
                }
                for (j in 0...4) {
                    rotations.push(rotation[j]);
                }
                for (j in 0...3) {
                    pushInterpolation(pInterpolations, interpolation, j);
                }
                pushInterpolation(rInterpolations, interpolation, 3);
            }

            var targetName:String = ".bones[" + key + "]";

            tracks.push(_createTrack(targetName + ".position", VectorKeyframeTrack, times, positions, pInterpolations));
            tracks.push(_createTrack(targetName + ".quaternion", QuaternionKeyframeTrack, times, rotations, rInterpolations));
        }

        return new AnimationClip("", -1, tracks);
    }

    public function buildMorphAnimation(vmd:Object, mesh:SkinnedMesh):AnimationClip {
        var tracks:Array<Track> = [];

        var morphs:Object = {};
        var morphTargetDictionary:Object = mesh.morphTargetDictionary;

        for (i in 0...vmd.metadata.morphCount) {
            var morph:Object = vmd.morphs[i];
            var morphName:String = morph.morphName;

            if (morphTargetDictionary[morphName] == null) continue;

            if (morphs[morphName] == null) morphs[morphName] = [];
            morphs[morphName].push(morph);
        }

        for (key in morphs) {
            var array:Array<Morph> = morphs[key];

            array.sort(function(a:Object, b:Object):Int {
                return a.frameNum - b.frameNum;
            });

            var times:Array<Float> = [];
            var values:Array<Float> = [];

            for (i in 0...array.length) {
                times.push(array[i].frameNum / 30);
                values.push(array[i].weight);
            }

            tracks.push(new NumberKeyframeTrack(".morphTargetInfluences[" + morphTargetDictionary[key] + "]", times, values));
        }

        return new AnimationClip("", -1, tracks);
    }

    public function buildCameraAnimation(vmd:Object):AnimationClip {
        function pushVector3(array:Array<Float>, vec:Array<Float>) {
            array.push(vec[0]);
            array.push(vec[1]);
            array.push(vec[2]);
        }

        function pushQuaternion(array:Array<Float>, q:Array<Float>) {
            array.push(q[0]);
            array.push(q[1]);
            array.push(q[2]);
            array.push(q[3]);
        }

        function pushInterpolation(array:Array<Float>, interpolation:Array<Float>, index:Int) {
            array.push(interpolation[index * 4 + 0] / 127); // x1
            array.push(interpolation[index * 4 + 1] / 127); // x2
            array.push(interpolation[index * 4 + 2] / 127); // y1
            array.push(interpolation[index * 4 + 3] / 127); // y2
        }

        var cameras:Array<Object> = vmd.cameras == null ? [] : vmd.cameras.slice();

        cameras.sort(function(a:Object, b:Object):Int {
            return a.frameNum - b.frameNum;
        });

        var times:Array<Float> = [];
        var centers:Array<Float> = [];
        var quaternions:Array<Float> = [];
        var positions:Array<Float> = [];
        var fovs:Array<Float> = [];

        var cInterpolations:Array<Float> = [];
        var qInterpolations:Array<Float> = [];
        var pInterpolations:Array<Float> = [];
        var fInterpolations:Array<Float> = [];

        var quaternion:Array<Float> = new Quaternion();
        var euler:Array<Float> = new Euler();
        var position:Array<Float> = new Vector3();
        var center:Array<Float> = new Vector3();

        for (i in 0...cameras.length) {
            var motion:Object = cameras[i];

            var time:Float = motion.frameNum / 30;
            var pos:Array<Float> = motion.position;
            var rot:Array<Float> = motion.rotation;
            var distance:Float = motion.distance;
            var fov:Float = motion.fov;
            var interpolation:Array<Float> = motion.interpolation;

            times.push(time);

            position.set(0, 0, -distance);
            center.set(pos[0], pos[1], pos[2]);

            euler.set(-rot[0], -rot[1], -rot[2]);
            quaternion.setFromEuler(euler);

            position.add(center);
            position.applyQuaternion(quaternion);

            pushVector3(centers, center);
            pushQuaternion(quaternions, quaternion.toArray());
            pushVector3(positions, position.toArray());

            fovs.push(fov);

            for (j in 0...3) {
                pushInterpolation(cInterpolations, interpolation, j);
            }

            pushInterpolation(qInterpolations, interpolation, 3);

            for (j in 0...3) {
                pushInterpolation(pInterpolations, interpolation, 4);
            }

            pushInterpolation(fInterpolations, interpolation, 5);
        }

        var tracks:Array<Track> = [];

        tracks.push(_createTrack("target.position", VectorKeyframeTrack, times, centers, cInterpolations));
        tracks.push(_createTrack(".quaternion", QuaternionKeyframeTrack, times, quaternions, qInterpolations));
        tracks.push(_createTrack(".position", VectorKeyframeTrack, times, positions, pInterpolations));
        tracks.push(_createTrack(".fov", NumberKeyframeTrack, times, fovs, fInterpolations));

        return new AnimationClip("", -1, tracks);
    }

    private function _createTrack(node:String, typedKeyframeTrack:Class<Track>, times:Array<Float>, values:Array<Float>, interpolations:Array<Float>):Track {
        if (times.length > 2) {
            times = times.slice();
            values = values.slice();
            interpolations = interpolations.slice();

            var stride:Int = values.length ~/ times.length;
            var interpolateStride:Int = interpolations.length ~/ times.length;

            var index:Int = 1;

            for (aheadIndex in 2...times.length) {
                for (i in 0...stride) {
                    if (values[index * stride + i] != values[(index - 1) * stride + i] ||
                            values[index * stride + i] != values[aheadIndex * stride + i]) {
                        index++;
                        break;
                    }
                }

                if (aheadIndex > index) {
                    times[index] = times[aheadIndex];

                    for (i in 0...stride) {
                        values[index * stride + i] = values[aheadIndex * stride + i];
                    }

                    for (i in 0...interpolateStride) {
                        interpolations[index * interpolateStride + i] = interpolations[aheadIndex * interpolateStride + i];
                    }
                }
            }

            times.length = index + 1;
            values.length = (index + 1) * stride;
            interpolations.length = (index + 1) * interpolateStride;
        }

        var track:Track = new typedKeyframeTrack(node, times, values);

        track.createInterpolant = function(result:Array<Float>) {
            return new CubicBezierInterpolation(times, values, values.length ~/ times.length, result, new Float32Array(interpolations));
        };

        return track;
    }
}