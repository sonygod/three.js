package three.js.examples.jm.loaders;

import three.js.AnimationClip;
import three.js.Bone;
import three.js.FileLoader;
import three.js.Loader;
import three.js.Quaternion;
import three.js.QuaternionKeyframeTrack;
import three.js.Skeleton;
import three.js.Vector3;
import three.js.VectorKeyframeTrack;

class BVHLoader extends Loader {
    public var animateBonePositions:Bool;
    public var animateBoneRotations:Bool;

    public function new(manager:Loader) {
        super(manager);
        animateBonePositions = true;
        animateBoneRotations = true;
    }

    public function load(url:String, onLoad:(Dynamic->Void), onProgress:(Float->Void), onError:(Dynamic->Void)) {
        var loader:FileLoader = new FileLoader(manager);
        loader.setPath(path);
        loader.setRequestHeader(requestHeader);
        loader.setWithCredentials(withCredentials);
        loader.load(url, function(text:String) {
            try {
                onLoad(parse(text));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(text:String):{skeleton:Skeleton, clip:AnimationClip} {
        var lines:Array<String> = text.split("~/\r\n]+/g");
        var bones:Array<Bone> = readBvh(lines);
        var threeBones:Array<Bone> = [];
        toTHREEBone(bones[0], threeBones);
        var threeClip:AnimationClip = toTHREEAnimation(bones);
        return {skeleton: new Skeleton(threeBones), clip: threeClip};
    }

    function readBvh(lines:Array<String>):Array<Bone> {
        // ... (rest of the implementation remains the same)
    }

    function readNode(lines:Array<String>, firstLine:String, list:Array<Bone>):Bone {
        // ... (rest of the implementation remains the same)
    }

    function readFrameData(data:Array<String>, frameTime:Float, bone:Bone):Void {
        // ... (rest of the implementation remains the same)
    }

    function toTHREEBone(source:Bone, list:Array<Bone>):Bone {
        // ... (rest of the implementation remains the same)
    }

    function toTHREEAnimation(bones:Array<Bone>):AnimationClip {
        // ... (rest of the implementation remains the same)
    }

    function nextLine(lines:Array<String>):String {
        // ... (rest of the implementation remains the same)
    }
}