import three.AnimationClip;
import three.Bone;
import three.FileLoader;
import three.Loader;
import three.Quaternion;
import three.QuaternionKeyframeTrack;
import three.Skeleton;
import three.Vector3;
import three.VectorKeyframeTrack;

/**
 * Description: reads BVH files and outputs a single Skeleton and an AnimationClip
 *
 * Currently only supports bvh files containing a single root.
 *
 */

class BVHLoader extends Loader {

	public var animateBonePositions:Bool;
	public var animateBoneRotations:Bool;

	public function new(manager:Dynamic = null) {

		super(manager);

		this.animateBonePositions = true;
		this.animateBoneRotations = true;

	}

	override public function load(url:String, onLoad:Skeleton->AnimationClip->Void, ?onProgress:Int->Dynamic->Void, ?onError:Dynamic->Void):Void {

		final scope = this;

		final loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text:String) {

			try {

				onLoad(scope.parse(text).skeleton, scope.parse(text).clip);

			} catch (e:Dynamic) {

				if (onError != null) {

					onError(e);

				} else {

					trace(e);

				}

				scope.manager.itemError(url);

			}

		}, onProgress, onError);

	}

	public function parse(text:String):{skeleton:Skeleton, clip:AnimationClip} {

		/*
			reads a string array (lines) from a BVH file
			and outputs a skeleton structure including motion data

			returns the root node:
			{ name: '', channels: [], children: [] }
		*/
		function readBvh(lines:Array<String>):Array<Dynamic> {

			// read model structure

			if (nextLine(lines) != 'HIERARCHY') {

				throw "THREE.BVHLoader: HIERARCHY expected.";

			}

			final list:Array<Dynamic> = []; // collects flat array of all bones
			final root = readNode(lines, nextLine(lines), list);

			// read motion data

			if (nextLine(lines) != 'MOTION') {

				throw "THREE.BVHLoader: MOTION expected.";

			}

			// number of frames

			final tokens = nextLine(lines).split(~/[\s]+/);
			final numFrames:Int = Std.parseInt(tokens[1]);

			if (Math.isNaN(numFrames)) {

				throw "THREE.BVHLoader: Failed to read number of frames.";

			}

			// frame time

			final timeTokens = nextLine(lines).split(~/[\s]+/);
			final frameTime:Float = Std.parseFloat(timeTokens[2]);

			if (Math.isNaN(frameTime)) {

				throw "THREE.BVHLoader: Failed to read frame time.";

			}

			// read frame data line by line

			for (i in 0...numFrames) {

				final frameTokens = nextLine(lines).split(~/[\s]+/);
				readFrameData(frameTokens, i * frameTime, root);

			}

			return list;

		}

		/*
			Recursively reads data from a single frame into the bone hierarchy.
			The passed bone hierarchy has to be structured in the same order as the BVH file.
			keyframe data is stored in bone.frames.

			- data: splitted string array (frame values), values are shift()ed so
			this should be empty after parsing the whole hierarchy.
			- frameTime: playback time for this keyframe.
			- bone: the bone to read frame data from.
		*/
		function readFrameData(data:Array<String>, frameTime:Float, bone:Dynamic):Void {

			// end sites have no motion data

			if (bone.type == 'ENDSITE')
				return;

			// add keyframe

			final keyframe = {
				time: frameTime,
				position: new Vector3(),
				rotation: new Quaternion()
			};

			bone.frames.push(keyframe);

			final quat = new Quaternion();

			final vx = new Vector3(1, 0, 0);
			final vy = new Vector3(0, 1, 0);
			final vz = new Vector3(0, 0, 1);

			// parse values for each channel in node

			for (i in 0...bone.channels.length) {

				switch (bone.channels[i]) {

					case 'Xposition':
						keyframe.position.x = Std.parseFloat(data.shift());
						break;
					case 'Yposition':
						keyframe.position.y = Std.parseFloat(data.shift());
						break;
					case 'Zposition':
						keyframe.position.z = Std.parseFloat(data.shift());
						break;
					case 'Xrotation':
						quat.setFromAxisAngle(vx, Std.parseFloat(data.shift()) * Math.PI / 180);
						keyframe.rotation.multiply(quat);
						break;
					case 'Yrotation':
						quat.setFromAxisAngle(vy, Std.parseFloat(data.shift()) * Math.PI / 180);
						keyframe.rotation.multiply(quat);
						break;
					case 'Zrotation':
						quat.setFromAxisAngle(vz, Std.parseFloat(data.shift()) * Math.PI / 180);
						keyframe.rotation.multiply(quat);
						break;
					default:
						trace('THREE.BVHLoader: Invalid channel type.');

				}

			}

			// parse child nodes

			for (i in 0...bone.children.length) {

				readFrameData(data, frameTime, bone.children[i]);

			}

		}

		/*
		 Recursively parses the HIERACHY section of the BVH file

		 - lines: all lines of the file. lines are consumed as we go along.
		 - firstline: line containing the node type and name e.g. 'JOINT hip'
		 - list: collects a flat list of nodes

		 returns: a BVH node including children
		*/
		function readNode(lines:Array<String>, firstline:String, list:Array<Dynamic>):Dynamic {

			final node = {name: '', type: '', frames: []};
			list.push(node);

			// parse node type and name

			final tokens = firstline.split(~/[\s]+/);

			if (tokens[0].toUpperCase() == 'END' && tokens[1].toUpperCase() == 'SITE') {

				node.type = 'ENDSITE';
				node.name = 'ENDSITE'; // bvh end sites have no name

			} else {

				node.name = tokens[1];
				node.type = tokens[0].toUpperCase();

			}

			if (nextLine(lines) != '{') {

				throw "THREE.BVHLoader: Expected opening { after type & name";

			}

			// parse OFFSET

			final offsetTokens = nextLine(lines).split(~/[\s]+/);

			if (offsetTokens[0] != 'OFFSET') {

				throw 'THREE.BVHLoader: Expected OFFSET but got: ' + offsetTokens[0];

			}

			if (offsetTokens.length != 4) {

				throw "THREE.BVHLoader: Invalid number of values for OFFSET.";

			}

			final offset = new Vector3(
				Std.parseFloat(offsetTokens[1]),
				Std.parseFloat(offsetTokens[2]),
				Std.parseFloat(offsetTokens[3])
			);

			if (Math.isNaN(offset.x) || Math.isNaN(offset.y) || Math.isNaN(offset.z)) {

				throw "THREE.BVHLoader: Invalid values of OFFSET.";

			}

			node.offset = offset;

			// parse CHANNELS definitions

			if (node.type != 'ENDSITE') {

				final channelsTokens = nextLine(lines).split(~/[\s]+/);

				if (channelsTokens[0] != 'CHANNELS') {

					throw "THREE.BVHLoader: Expected CHANNELS definition.";

				}

				final numChannels = Std.parseInt(channelsTokens[1]);
				node.channels = channelsTokens.splice(2, numChannels);
				node.children = [];

			}

			// read children

			while (true) {

				final line = nextLine(lines);

				if (line == '}') {

					return node;

				} else {

					node.children.push(readNode(lines, line, list));

				}

			}

			return null;

		}

		/*
			recursively converts the internal bvh node structure to a Bone hierarchy

			source: the bvh root node
			list: pass an empty array, collects a flat list of all converted THREE.Bones

			returns the root Bone
		*/
		function toTHREEBone(source:Dynamic, list:Array<Bone>):Bone {

			final bone = new Bone();
			list.push(bone);

			bone.position.add(source.offset);
			bone.name = source.name;

			if (source.type != 'ENDSITE') {

				for (i in 0...source.children.length) {

					bone.add(toTHREEBone(source.children[i], list));

				}

			}

			return bone;

		}

		/*
			builds a AnimationClip from the keyframe data saved in each bone.

			bone: bvh root node

			returns: a AnimationClip containing position and quaternion tracks
		*/
		function toTHREEAnimation(bones:Array<Dynamic>):AnimationClip {

			final tracks:Array<Dynamic> = [];

			// create a position and quaternion animation track for each node

			for (i in 0...bones.length) {

				final bone = bones[i];

				if (bone.type == 'ENDSITE')
					continue;

				// track data

				final times:Array<Float> = [];
				final positions:Array<Float> = [];
				final rotations:Array<Float> = [];

				for (j in 0...bone.frames.length) {

					final frame = bone.frames[j];

					times.push(frame.time);

					// the animation system animates the position property,
					// so we have to add the joint offset to all values

					positions.push(frame.position.x + bone.offset.x);
					positions.push(frame.position.y + bone.offset.y);
					positions.push(frame.position.z + bone.offset.z);

					rotations.push(frame.rotation.x);
					rotations.push(frame.rotation.y);
					rotations.push(frame.rotation.z);
					rotations.push(frame.rotation.w);

				}

				if (animateBonePositions) {

					tracks.push(new VectorKeyframeTrack(bone.name + '.position', times, positions));

				}

				if (animateBoneRotations) {

					tracks.push(new QuaternionKeyframeTrack(bone.name + '.quaternion', times, rotations));

				}

			}

			return new AnimationClip('animation', -1, tracks);

		}

		/*
			returns the next non-empty line in lines
		*/
		function nextLine(lines:Array<String>):String {

			var line:String = "";
			// skip empty lines
			while ((line = lines.shift().trim()).length == 0) {
			}

			return line;

		}

		final lines = text.split(~/[\r\n]+/g);

		final bones = readBvh(lines);

		final threeBones:Array<Bone> = [];
		toTHREEBone(bones[0], threeBones);

		final threeClip = toTHREEAnimation(bones);

		return {skeleton: new Skeleton(threeBones), clip: threeClip};

	}

}

#if (!macro)
{
	// TODO: Remove these type exports, after Haxe compiler fix
	@:noCompletion @:keep private class __TypeExports {
		public static var AnimationClip(default, null) : Class<three.AnimationClip>;
		public static var Bone(default, null) : Class<three.Bone>;
		public static var FileLoader(default, null) : Class<three.FileLoader>;
		public static var Loader(default, null) : Class<three.Loader>;
		public static var Quaternion(default, null) : Class<three.Quaternion>;
		public static var QuaternionKeyframeTrack(default, null) : Class<three.QuaternionKeyframeTrack>;
		public static var Skeleton(default, null) : Class<three.Skeleton>;
		public static var Vector3(default, null) : Class<three.Vector3>;
		public static var VectorKeyframeTrack(default, null) : Class<three.VectorKeyframeTrack>;
	}
}
#end