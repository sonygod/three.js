package three.js.utils;

import three.AnimationClip;
import three AnimationMixer;
import three.Matrix4;
import three.Quaternion;
import three.QuaternionKeyframeTrack;
import three.SkeletonHelper;
import three.Vector3;
import three.VectorKeyframeTrack;

class SkeletonUtils {
    public static function retarget(target:three.Object3D, source:three.Object3D, options:{?preserveMatrix:Bool, ?preservePosition:Bool, ?preserveHipPosition:Bool, ?useTargetMatrix:Bool, ?hip:String, ?names:Dynamic}:Dynamic):Void {
        // ...
    }

    public static function retargetClip(target:three.Object3D, source:three.Object3D, clip:AnimationClip, options:{?useFirstFramePosition:Bool, ?fps:Int, ?names:Dynamic}:Dynamic):AnimationClip {
        // ...
    }

    public static function clone(source:three.Object3D):three.Object3D {
        // ...
    }

    private static function getBoneByName(name:String, skeleton:three.Skeleton):three.Bone {
        // ...
    }

    private static function getBones(skeleton:three.Skeleton):Array<three.Bone> {
        // ...
    }

    private static function getHelperFromSkeleton(skeleton:three.Skeleton):SkeletonHelper {
        // ...
    }

    private static function parallelTraverse(a:three.Object3D, b:three.Object3D, callback:(a:three.Object3D, b:three.Object3D)->Void):Void {
        // ...
    }
}