class AnimationParser {

    public function parse():Array<AnimationClip> {

        var animationClips:Array<AnimationClip> = [];

        var rawClips = this.parseClips();

        if (rawClips != null) {

            for (key in rawClips) {

                var rawClip = rawClips[key];

                var clip = this.addClip(rawClip);

                animationClips.push(clip);

            }

        }

        return animationClips;

    }

    // ... rest of the code ...

    public function addClip(rawClip:Dynamic):AnimationClip {

        var tracks:Array<KeyframeTrack> = [];

        for (rawTracks in rawClip.layer) {

            tracks = tracks.concat(this.generateTracks(rawTracks));

        }

        return new AnimationClip(rawClip.name, -1, tracks);

    }

    // ... rest of the code ...

}