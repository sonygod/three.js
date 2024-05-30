import three.AnimationClip;
import three.AnimationMixer;
import three.Matrix4;
import three.Quaternion;
import three.QuaternionKeyframeTrack;
import three.SkeletonHelper;
import three.Vector3;
import three.VectorKeyframeTrack;

function retarget(target:Dynamic, source:Dynamic, options:Dynamic = null):Void {
    // ...
}

function retargetClip(target:Dynamic, source:Dynamic, clip:Dynamic, options:Dynamic = null):AnimationClip {
    // ...
}

function clone(source:Dynamic):Dynamic {
    // ...
}

function getBoneByName(name:String, skeleton:Dynamic):Dynamic {
    // ...
}

function getBones(skeleton:Dynamic):Array<Dynamic> {
    // ...
}

function getHelperFromSkeleton(skeleton:Dynamic):SkeletonHelper {
    // ...
}

function parallelTraverse(a:Dynamic, b:Dynamic, callback:Dynamic->Void):Void {
    // ...
}