import AnimationUtils.AnimationUtils;
import KeyframeTrack.KeyframeTrack;
import KeyframeTrack.BooleanKeyframeTrack;
import KeyframeTrack.ColorKeyframeTrack;
import KeyframeTrack.NumberKeyframeTrack;
import KeyframeTrack.QuaternionKeyframeTrack;
import KeyframeTrack.StringKeyframeTrack;
import KeyframeTrack.VectorKeyframeTrack;
import MathUtils.MathUtils;
import NormalAnimationBlendMode.NormalAnimationBlendMode;

class AnimationClip {

	public var name:String;
	public var tracks:Array<KeyframeTrack>;
	public var duration:Float;
	public var blendMode:NormalAnimationBlendMode;
	public var uuid:String;

	public function new(name:String = "", duration:Float = -1, tracks:Array<KeyframeTrack> = [], blendMode:NormalAnimationBlendMode = NormalAnimationBlendMode.Normal) {

		this.name = name;
		this.tracks = tracks;
		this.duration = duration;
		this.blendMode = blendMode;

		this.uuid = MathUtils.generateUUID();

		// this means it should figure out its duration by scanning the tracks
		if (this.duration < 0) {

			this.resetDuration();

		}

	}

	static public function parse(json:Dynamic):AnimationClip {

		var tracks:Array<KeyframeTrack> = [];
		var jsonTracks:Array<Dynamic> = json.tracks;
		var frameTime:Float = 1.0 / (json.fps || 1.0);

		for (i in 0...jsonTracks.length) {

			tracks.push(parseKeyframeTrack(jsonTracks[i]).scale(frameTime));

		}

		var clip:AnimationClip = new AnimationClip(json.name, json.duration, tracks, json.blendMode);
		clip.uuid = json.uuid;

		return clip;

	}

	static public function toJSON(clip:AnimationClip):Dynamic {

		var tracks:Array<Dynamic> = [];
		var clipTracks:Array<KeyframeTrack> = clip.tracks;

		var json:Dynamic = {

			'name': clip.name,
			'duration': clip.duration,
			'tracks': tracks,
			'uuid': clip.uuid,
			'blendMode': clip.blendMode

		};

		for (i in 0...clipTracks.length) {

			tracks.push(KeyframeTrack.toJSON(clipTracks[i]));

		}

		return json;

	}

	static public function CreateFromMorphTargetSequence(name:String, morphTargetSequence:Array<Dynamic>, fps:Float, noLoop:Bool):AnimationClip {

		var numMorphTargets:Int = morphTargetSequence.length;
		var tracks:Array<KeyframeTrack> = [];

		for (i in 0...numMorphTargets) {

			var times:Array<Float> = [];
			var values:Array<Float> = [];

			times.push(
				(i + numMorphTargets - 1) % numMorphTargets,
				i,
				(i + 1) % numMorphTargets
			);

			values.push(0, 1, 0);

			var order:Array<Int> = AnimationUtils.getKeyframeOrder(times);
			times = AnimationUtils.sortedArray(times, 1, order);
			values = AnimationUtils.sortedArray(values, 1, order);

			// if there is a key at the first frame, duplicate it as the
			// last frame as well for perfect loop.
			if (!noLoop && times[0] === 0) {

				times.push(numMorphTargets);
				values.push(values[0]);

			}

			tracks.push(
				new NumberKeyframeTrack(
					'.morphTargetInfluences[' + morphTargetSequence[i].name + ']',
					times, values
				).scale(1.0 / fps)
			);

		}

		return new AnimationClip(name, -1, tracks);

	}

	static public function findByName(objectOrClipArray:Dynamic, name:String):AnimationClip {

		var clipArray:Array<AnimationClip> = cast objectOrClipArray;

		if (!Type.getClass(objectOrClipArray) == Array<AnimationClip>) {

			var o:Dynamic = objectOrClipArray;
			clipArray = o.geometry && o.geometry.animations || o.animations;

		}

		for (i in 0...clipArray.length) {

			if (clipArray[i].name == name) {

				return clipArray[i];

			}

		}

		return null;

	}

	static public function CreateClipsFromMorphTargetSequences(morphTargets:Array<Dynamic>, fps:Float, noLoop:Bool):Array<AnimationClip> {

		var animationToMorphTargets:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();

		// tested with https://regex101.com/ on trick sequences
		// such flamingo_flyA_003, flamingo_run1_003, crdeath0059
		var pattern:EReg = ~/^([\w-]*?)([\d]+)$/;

		// sort morph target names into animation groups based
		// patterns like Walk_001, Walk_002, Run_001, Run_002
		for (i in 0...morphTargets.length) {

			var morphTarget:Dynamic = morphTargets[i];
			var parts:Array<String> = morphTarget.name.match(pattern);

			if (parts && parts.length > 1) {

				var name:String = parts[1];

				var animationMorphTargets:Array<Dynamic> = animationToMorphTargets.get(name);

				if (!animationMorphTargets) {

					animationToMorphTargets.set(name, animationMorphTargets = []);

				}

				animationMorphTargets.push(morphTarget);

			}

		}

		var clips:Array<AnimationClip> = [];

		for (name in animationToMorphTargets.keys()) {

			clips.push(CreateFromMorphTargetSequence(name, animationToMorphTargets.get(name), fps, noLoop));

		}

		return clips;

	}

	// parse the animation.hierarchy format
	static public function parseAnimation(animation:Dynamic, bones:Array<Dynamic>):AnimationClip {

		if (!animation) {

			trace('THREE.AnimationClip: No animation in JSONLoader data.');
			return null;

		}

		var addNonemptyTrack = function(trackType:Class<KeyframeTrack>, trackName:String, animationKeys:Array<Dynamic>, propertyName:String, destTracks:Array<KeyframeTrack>) {

			// only return track if there are actually keys.
			if (animationKeys.length !== 0) {

				var times:Array<Float> = [];
				var values:Array<Float> = [];

				AnimationUtils.flattenJSON(animationKeys, times, values, propertyName);

				// empty keys are filtered out, so check again
				if (times.length !== 0) {

					destTracks.push(new trackType(trackName, times, values));

				}

			}

		};

		var tracks:Array<KeyframeTrack> = [];

		var clipName:String = animation.name || 'default';
		var fps:Float = animation.fps || 30;
		var blendMode:NormalAnimationBlendMode = animation.blendMode;

		// automatic length determination in AnimationClip.
		var duration:Float = animation.length || -1;

		var hierarchyTracks:Array<Dynamic> = animation.hierarchy || [];

		for (h in 0...hierarchyTracks.length) {

			var animationKeys:Array<Dynamic> = hierarchyTracks[h].keys;

			// skip empty tracks
			if (!animationKeys || animationKeys.length === 0) continue;

			// process morph targets
			if (animationKeys[0].morphTargets) {

				// figure out all morph targets used in this track
				var morphTargetNames:Map<String, Int> = new Map<String, Int>();

				var k:Int;

				for (k in 0...animationKeys.length) {

					if (animationKeys[k].morphTargets) {

						for (m in 0...animationKeys[k].morphTargets.length) {

							morphTargetNames.set(animationKeys[k].morphTargets[m], -1);

						}

					}

				}

				// create a track for each morph target with all zero
				// morphTargetInfluences except for the keys in which
				// the morphTarget is named.
				for (morphTargetName in morphTargetNames.keys()) {

					var times:Array<Float> = [];
					var values:Array<Float> = [];

					for (m in 0...animationKeys[k].morphTargets.length) {

						var animationKey:Dynamic = animationKeys[k];

						times.push(animationKey.time);
						values.push((animationKey.morphTarget == morphTargetName) ? 1 : 0);

					}

					tracks.push(new NumberKeyframeTrack('.morphTargetInfluence[' + morphTargetName + ']', times, values));

				}

				duration = morphTargetNames.length * fps;

			} else {

				// ...assume skeletal animation

				var boneName:String = '.bones[' + bones[h].name + ']';

				addNonemptyTrack(
					VectorKeyframeTrack, boneName + '.position',
					animationKeys, 'pos', tracks
				);

				addNonemptyTrack(
					QuaternionKeyframeTrack, boneName + '.quaternion',
					animationKeys, 'rot', tracks
				);

				addNonemptyTrack(
					VectorKeyframeTrack, boneName + '.scale',
					animationKeys, 'scl', tracks
				);

			}

		}

		if (tracks.length === 0) {

			return null;

		}

		var clip:AnimationClip = new AnimationClip(clipName, duration, tracks, blendMode);

		return clip;

	}

	public function resetDuration():AnimationClip {

		var tracks:Array<KeyframeTrack> = this.tracks;
		var duration:Float = 0;

		for (i in 0...tracks.length) {

			var track:KeyframeTrack = this.tracks[i];

			duration = Math.max(duration, track.times[track.times.length - 1]);

		}

		this.duration = duration;

		return this;

	}

	public function trim():AnimationClip {

		for (i in 0...this.tracks.length) {

			this.tracks[i].trim(0, this.duration);

		}

		return this;

	}

	public function validate():Bool {

		var valid:Bool = true;

		for (i in 0...this.tracks.length) {

			valid = valid && this.tracks[i].validate();

		}

		return valid;

	}

	public function optimize():AnimationClip {

		for (i in 0...this.tracks.length) {

			this.tracks[i].optimize();

		}

		return this;

	}

	public function clone():AnimationClip {

		var tracks:Array<KeyframeTrack> = [];

		for (i in 0...this.tracks.length) {

			tracks.push(this.tracks[i].clone());

		}

		return new AnimationClip(this.name, this.duration, tracks, this.blendMode);

	}

	public function toJSON():Dynamic {

		return AnimationClip.toJSON(this);

	}

}

function getTrackTypeForValueTypeName(typeName:String):Class<KeyframeTrack> {

	switch (typeName.toLowerCase()) {

		case 'scalar':
		case 'double':
		case 'float':
		case 'number':
		case 'integer':

			return NumberKeyframeTrack;

		case 'vector':
		case 'vector2':
		case 'vector3':
		case 'vector4':

			return VectorKeyframeTrack;

		case 'color':

			return ColorKeyframeTrack;

		case 'quaternion':

			return QuaternionKeyframeTrack;

		case 'bool':
		case 'boolean':

			return BooleanKeyframeTrack;

		case 'string':

			return StringKeyframeTrack;

	}

	throw new Error('THREE.KeyframeTrack: Unsupported typeName: ' + typeName);

}

function parseKeyframeTrack(json:Dynamic):KeyframeTrack {

	if (json.type === undefined) {

		throw new Error('THREE.KeyframeTrack: track type undefined, can not parse');

	}

	var trackType:Class<KeyframeTrack> = getTrackTypeForValueTypeName(json.type);

	if (json.times === undefined) {

		var times:Array<Float> = [];
		var values:Array<Float> = [];

		AnimationUtils.flattenJSON(json.keys, times, values, 'value');

		json.times = times;
		json.values = values;

	}

	// derived classes can define a static parse method
	if (trackType.parse !== undefined) {

		return trackType.parse(json);

	} else {

		// by default, we assume a constructor compatible with the base
		return new trackType(json.name, json.times, json.values, json.interpolation);

	}

}