package three.animation;

import three.animation.AnimationAction;
import three.core.EventDispatcher;
import three.math.interpolants.LinearInterpolant;
import three.animation.PropertyBinding;
import three.animation.PropertyMixer;
import three.animation.AnimationClip;
import three.constants.NormalAnimationBlendMode;
import js.lib.Float32Array;

class AnimationMixer extends EventDispatcher {
    private var _controlInterpolantsResultBuffer = new Float32Array(1);

    public var _root;
    public var _accuIndex = 0;
    public var time = 0;
    public var timeScale = 1.0;

    // Other functions go here, methods are translated similarly.
}

// More classes can go here

class Main {
    public static function main() {
        // Application entry point
    }
}