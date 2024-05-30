class AnimationBuilder {
    function build(vmd:VMD, mesh:SkinnedMesh):AnimationClip {
        // combine skeletal and morph animations
        var tracks = this.buildSkeletalAnimation(vmd, mesh).tracks;
        var tracks2 = this.buildMorphAnimation(vmd, mesh).tracks;

        var i = 0;
        while (i < tracks2.length) {
            tracks.push(tracks2[i]);
            i++;
        }

        return new AnimationClip("", -1, tracks);
    }

    function buildSkeletalAnimation(vmd:VMD, mesh:SkinnedMesh):AnimationClip {
        function pushInterpolation(array:Array<Float>, interpolation:Array<Int>, index:Int) {
            array.push(interpolation[index + 0] / 127.0); // x1
            array.push(interpolation[index + 8] / 127.0); // x2
            array.push(interpolation[index + 4] / 127.0); // y1
            array.push(interpolation[index + 12] / 127.0); // y2
        }

        var tracks:Array<KeyframeTrack> = [];

        var motions = new Map<String, Array<Dynamic>>();
        var bones = mesh.skeleton.bones;
        var boneNameDictionary = new Map<String, Bool>();

        var i = 0;
        while (i < bones.length) {
            boneNameDictionary.set(bones[i].name, true);
            i++;
        }

        i = 0;
        while (i < vmd.metadata.motionCount) {
            var motion = vmd.motions[i];
            var boneName = motion.boneName;

            if (!boneNameDictionary.exists(boneName)) {
                i++;
                continue;
            }

            if (!motions.exists(boneName)) {
                motions.set(boneName, []);
            }

            motions.get(boneName).push(motion);
            i++;
        }

        for (motion in motions) {
            var array = motions.get(motion);

            array.sort(function (a:Dynamic, b:Dynamic) {
                return a.frameNum - b.frameNum;
            });

            var times = [];
            var positions = [];
            var rotations = [];
            var pInterpolations = [];
            var rInterpolations = [];

            var basePosition = mesh.skeleton.getBoneByName(motion).position.toArray();

            var i = 0;
            while (i < array.length) {
                var time = array[i].frameNum / 30;
                var position = array[i].position;
                var rotation = array[i].rotation;
                var interpolation = array[i].interpolation;

                times.push(time);

                var j = 0;
                while (j < 3) {
                    positions.push(basePosition[j] + position[j]);
                    j++;
                }

                var j = 0;
                while (j < 4) {
                    rotations.push(rotation[j]);
                    j++;
                }

                var j = 0;
                while (j < 3) {
                    pushInterpolation(pInterpolations, interpolation, j);
                    j++;
                }

                pushInterpolation(rInterpolations, interpolation, 3);

                i++;
            }

            var targetName = ".bones[" + motion + "]";

            tracks.push(this._createTrack(targetName + ".position", VectorKeyframeTrack, times, positions, pInterpolations));
            tracks.push(this._createTrack(targetName + ".quaternion", QuaternionKeyframeTrack, times, rotations, rInterpolations));
        }

        return new AnimationClip("", -1, tracks);
    }

    function buildMorphAnimation(vmd:VMD, mesh:SkinnedMesh):AnimationClip {
        var tracks:Array<KeyframeTrack> = [];

        var morphs = new Map<String, Array<Dynamic>>();
        var morphTargetDictionary = mesh.morphTargetDictionary;

        var i = 0;
        while (i < vmd.metadata.morphCount) {
            var morph = vmd.morphs[i];
            var morphName = morph.morphName;

            if (!morphTargetDictionary.exists(morphName)) {
                i++;
                continue;
            }

            if (!morphs.exists(morphName)) {
                morphs.set(morphName, []);
            }

            morphs.get(morphName).push(morph);
            i++;
        }

        for (morph in morphs) {
            var array = morphs.get(morph);

            array.sort(function (a:Dynamic, b:Dynamic) {
                return a.frameNum - b.frameNum;
            });

            var times = [];
            var values = [];

            var i = 0;
            while (i < array.length) {
                times.push(array[i].frameNum / 30);
                values.push(array[i].weight);
                i++;
            }

            tracks.push(new NumberKeyframeTrack(".morphTargetInfluences[" + morphTargetDictionary.get(morph) + "]", times, values));
        }

        return new AnimationClip("", -1, tracks);
    }

    function buildCameraAnimation(vmd:VMD):AnimationClip {
        function pushVector3(array:Array<Float>, vec:Vector3) {
            array.push(vec.x);
            array.push(vec.y);
            array.push(vec.z);
        }

        function pushQuaternion(array:Array<Float>, q:Quaternion) {
            array.push(q.x);
            array.push(q.y);
            array.push(q.z);
            array.push(q.w);
        }

        function pushInterpolation(array:Array<Float>, interpolation:Array<Int>, index:Int) {
            array.push(interpolation[index * 4 + 0] / 127.0); // x1
            array.push(interpolation[index * 4 + 1] / 127.0); // x2
            array.push(interpolation[index * 4 + 2] / 127.0); // y1
            array.push(interpolation[index * 4 + 3] / 127.0); // y2
        }

        var cameras = vmd.cameras != null ? vmd.cameras.slice() : [];

        cameras.sort(function (a:Dynamic, b:Dynamic) {
            return a.frameNum - b.frameNum;
        });

        var times = [];
        var centers = [];
        var quaternions = [];
        var positions = [];
        var fovs = [];

        var cInterpolations = [];
        var qInterpolations = [];
        var pInterpolations = [];
        var fInterpolations = [];

        var quaternion = new Quaternion();
        var euler = new Euler();
        var position = new Vector3();
        var center = new Vector3();

        var i = 0;
        while (i < cameras.length) {
            var motion = cameras[i];

            var time = motion.frameNum / 30;
            var pos = motion.position;
            var rot = motion.rotation;
            var distance = motion.distance;
            var fov = motion.fov;
            var interpolation = motion.interpolation;

            times.push(time);

            position.set(0, 0, -distance);
            center.set(pos[0], pos[1], pos[2]);

            euler.set(-rot[0], -rot[1], -rot[2]);
            quaternion.setFromEuler(euler);

            position.add(center);
            position.applyQuaternion(quaternion);

            pushVector3(centers, center);
            pushQuaternion(quaternions, quaternion);
            pushVector3(positions, position);

            fovs.push(fov);

            var j = 0;
            while (j < 3) {
                pushInterpolation(cInterpolations, interpolation, j);
                j++;
            }

            pushInterpolation(qInterpolations, interpolation, 3);

            // use the same parameter for x, y, z axis.
            var j = 0;
            while (j < 3) {
                pushInterpolation(pInterpolations, interpolation, 4);
                j++;
            }

            pushInterpolation(fInterpolations, interpolation, 5);

            i++;
        }

        var tracks:Array<KeyframeTrack> = [];

        // I expect an object whose name 'target' exists under THREE.Camera
        tracks.push(this._createTrack("target.position", VectorKeyframeTrack, times, centers, cInterpolations));

        tracks.push(this._createTrack(".quaternion", QuaternionKeyframeTrack, times, quaternions, qInterpolations));
        tracks.push(this._createTrack(".position", VectorKeyframeTrack, times, positions, pInterpolations));
        tracks.push(this._createTrack(".fov", NumberKeyframeTrack, times, fovs, fInterpolations));

        return new AnimationClip("", -1, tracks);
    }

    // private method
    function _createTrack(node:String, typedKeyframeTrack:KeyframeTrack, times:Array<Float>, values:Array<Float>, interpolations:Array<Float>):KeyframeTrack {
        /*
         * optimizes here not to let KeyframeTrackPrototype optimize
         * because KeyframeTrackPrototype optimizes times and values but
         * doesn't optimize interpolations.
         */
        if (times.length > 2) {
            times = times.slice();
            values = values.slice();
            interpolations = interpolations.slice();

            var stride = Std.int(values.length / times.length);
            var interpolateStride = Std.int(interpolations.length / times.length);

            var index = 1;

            var aheadIndex = 2;
            var endIndex = times.length;
            while (aheadIndex < endIndex) {
                var i = 0;
                while (i < stride) {
                    if (values[index * stride + i] != values[(index - 1) * stride + i] || values[index * stride + i] != values[aheadIndex * stride + i]) {
                        index++;
                        break;
                    }

                    i++;
                }

                if (aheadIndex > index) {
                    times[index] = times[aheadIndex];

                    var i = 0;
                    while (i < stride) {
                        values[index * stride + i] = values[aheadIndex * stride + i];
                        i++;
                    }

                    var i = 0;
                    while (i < interpolateStride) {
                        interpolations[index * interpolateStride + i] = interpolations[aheadIndex * interpolateStride + i];
                        i++;
                    }
                }

                aheadIndex++;
            }

            times.length = index + 1;
            values.length = (index + 1) * stride;
            interpolations.length = (index + 1) * interpolateStride;
        }

        var track = new typedKeyframeTrack(node, times, values);

        track.createInterpolant = function (result) {
            return new CubicBezierInterpolation(this.times, this.values, this.getValueSize(), result, new Float32Array(interpolations));
        };

        return track;
    }
}