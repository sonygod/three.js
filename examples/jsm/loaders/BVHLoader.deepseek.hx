package three.jsm.loaders;

import three.AnimationClip;
import three.Bone;
import three.FileLoader;
import three.Loader;
import three.Quaternion;
import three.QuaternionKeyframeTrack;
import three.Skeleton;
import three.Vector3;
import three.VectorKeyframeTrack;

class BVHLoader extends Loader {

	var animateBonePositions:Bool;
	var animateBoneRotations:Bool;

	public function new(manager:Loader) {
		super(manager);
		animateBonePositions = true;
		animateBoneRotations = true;
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var loader = new FileLoader(manager);
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

	public function parse(text:String):Dynamic {
		var lines = text.split(/\r\n|\n/);
		var bones = readBvh(lines);
		var threeBones = [];
		toTHREEBone(bones[0], threeBones);
		var threeClip = toTHREEAnimation(bones);
		return {
			skeleton: new Skeleton(threeBones),
			clip: threeClip
		};
	}

	private function readBvh(lines:Array<String>):Array<Dynamic> {
		// ...
	}

	private function readFrameData(data:Array<String>, frameTime:Float, bone:Dynamic):Void {
		// ...
	}

	private function readNode(lines:Array<String>, firstline:String, list:Array<Dynamic>):Dynamic {
		// ...
	}

	private function toTHREEBone(source:Dynamic, list:Array<Dynamic>):Bone {
		// ...
	}

	private function toTHREEAnimation(bones:Array<Dynamic>):AnimationClip {
		// ...
	}

	private function nextLine(lines:Array<String>):String {
		// ...
	}
}