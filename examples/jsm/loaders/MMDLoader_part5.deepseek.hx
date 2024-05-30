class AnimationBuilder {

    public function build(vmd:Dynamic, mesh:SkinnedMesh):AnimationClip {

        var tracks = this.buildSkeletalAnimation(vmd, mesh).tracks;
        var tracks2 = this.buildMorphAnimation(vmd, mesh).tracks;

        for (i in tracks2) {
            tracks.push(tracks2[i]);
        }

        return new AnimationClip("", -1, tracks);
    }

    public function buildSkeletalAnimation(vmd:Dynamic, mesh:SkinnedMesh):AnimationClip {

        function pushInterpolation(array:Array<Float>, interpolation:Array<Int>, index:Int) {
            array.push(interpolation[index + 0] / 127); // x1
            array.push(interpolation[index + 8] / 127); // x2
            array.push(interpolation[index + 4] / 127); // y1
            array.push(interpolation[index + 12] / 127); // y2
        }

        var tracks = [];

        var motions = {};
        var bones = mesh.skeleton.bones;
        var boneNameDictionary = {};

        for (i in bones) {
            boneNameDictionary[bones[i].name] = true;
        }

        for (i in vmd.metadata.motionCount) {
            var motion = vmd.motions[i];
            var boneName = motion.boneName;

            if (boneNameDictionary[boneName] == null) continue;

            motions[boneName] = motions[boneName] || [];
            motions[boneName].push(motion);
        }

        for (key in motions) {
            var array = motions[key];

            array.sort(function(a, b) {
                return a.frameNum - b.frameNum;
            });

            var times = [];
            var positions = [];
            var rotations = [];
            var pInterpolations = [];
            var rInterpolations = [];

            var basePosition = mesh.skeleton.getBoneByName(key).position.toArray();

            for (i in array) {
                var time = array[i].frameNum / 30;
                var position = array[i].position;
                var rotation = array[i].rotation;
                var interpolation = array[i].interpolation;

                times.push(time);

                for (j in position) positions.push(basePosition[j] + position[j]);
                for (j in rotation) rotations.push(rotation[j]);
                for (j in interpolation) pushInterpolation(pInterpolations, interpolation, j);

                pushInterpolation(rInterpolations, interpolation, 3);
            }

            var targetName = '.bones[' + key + ']';

            tracks.push(this._createTrack(targetName + '.position', VectorKeyframeTrack, times, positions, pInterpolations));
            tracks.push(this._createTrack(targetName + '.quaternion', QuaternionKeyframeTrack, times, rotations, rInterpolations));
        }

        return new AnimationClip("", -1, tracks);
    }

    public function buildMorphAnimation(vmd:Dynamic, mesh:SkinnedMesh):AnimationClip {
        var tracks = [];

        var morphs = {};
        var morphTargetDictionary = mesh.morphTargetDictionary;

        for (i in vmd.metadata.morphCount) {
            var morph = vmd.morphs[i];
            var morphName = morph.morphName;

            if (morphTargetDictionary[morphName] == null) continue;

            morphs[morphName] = morphs[morphName] || [];
            morphs[morphName].push(morph);
        }

        for (key in morphs) {
            var array = morphs[key];

            array.sort(function(a, b) {
                return a.frameNum - b.frameNum;
            });

            var times = [];
            var values = [];

            for (i in array) {
                times.push(array[i].frameNum / 30);
                values.push(array[i].weight);
            }

            tracks.push(new NumberKeyframeTrack('.morphTargetInfluences[' + morphTargetDictionary[key] + ']', times, values));
        }

        return new AnimationClip("", -1, tracks);
    }

    public function buildCameraAnimation(vmd:Dynamic):AnimationClip {
        // ...
    }

    private function _createTrack(node:String, typedKeyframeTrack:Dynamic, times:Array<Float>, values:Array<Float>, interpolations:Array<Float>):Dynamic {
        // ...
    }
}