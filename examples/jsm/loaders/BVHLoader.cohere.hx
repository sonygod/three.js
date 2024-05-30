package;

import js.three.AnimationClip;
import js.three.Bone;
import js.three.FileLoader;
import js.three.Loader;
import js.three.Quaternion;
import js.three.QuaternionKeyframeTrack;
import js.three.Skeleton;
import js.three.Vector3;
import js.three.VectorKeyframeTrack;

class BVHLoader extends Loader {
    public var animateBonePositions:Bool;
    public var animateBoneRotations:Bool;

    public function new(manager:Dynamic) {
        super(manager);
        this.animateBonePositions = true;
        this.animateBoneRotations = true;
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.path = scope.path;
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(text) {
            try {
                onLoad(scope.parse(text));
            } catch (e) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(text:String):Dynamic {
        function readBvh(lines:Array<String>):Dynamic {
            if (nextLine(lines) != 'HIERARCHY') {
                throw 'THREE.BVHLoader: HIERARCHY expected.';
            }

            var list = [];
            var root = readNode(lines, nextLine(lines), list);

            if (nextLine(lines) != 'MOTION') {
                throw 'THREE.BVHLoader: MOTION expected.';
            }

            var tokens = nextLine(lines).split(new RegExp('[\s]+'));
            var numFrames = Std.parseInt(tokens[1]);
            if (isNaN(numFrames)) {
                throw 'THREE.BVHLoader: Failed to read number of frames.';
            }

            tokens = nextLine(lines).split(new RegExp('[\s]+'));
            var frameTime = Std.parseFloat(tokens[2]);
            if (isNaN(frameTime)) {
                throw 'THREE.BVHLoader: Failed to read frame time.';
            }

            for (i in 0...numFrames) {
                tokens = nextLine(lines).split(new RegExp('[\s]+'));
                readFrameData(tokens, i * frameTime, root);
            }

            return list;
        }

        function readFrameData(data:Array<String>, frameTime:Float, bone:Dynamic):Void {
            if (bone.type == 'ENDSITE') {
                return;
            }

            var keyframe = {
                time: frameTime,
                position: new Vector3(),
                rotation: new Quaternion()
            };

            bone.frames.push(keyframe);
            var quat = new Quaternion();

            var vx = new Vector3(1, 0, 0);
            var vy = new Vector3(0, 1, 0);
            var vz = new Vector3(0, 0, 1);

            for (i in 0...bone.channels.length) {
                switch (bone.channels[i]) {
                    case 'Xposition':
                        keyframe.position.x = Std.parseFloat(data.shift().trim());
                        break;
                    case 'Yposition':
                        keyframe.position.y = Std.parseFloat(data.shift().trim());
                        break;
                    case 'Zposition':
                        keyframe.position.z = Std.parseFloat(data.shift().trim());
                        break;
                    case 'Xrotation':
                        quat.setFromAxisAngle(vx, Std.parseFloat(data.shift().trim()) * Math.PI / 180);
                        keyframe.rotation.multiply(quat);
                        break;
                    case 'Yrotation':
                        quat.setFromAxisAngle(vy, Std.parseFloat(data.shift().trim()) * Math.PI / 180);
                        keyframe.rotation.multiply(quat);
                        break;
                    case 'Zrotation':
                        quat.setFromAxisAngle(vz, Std.parseFloat(data.shift().trim()) * Math.PI / 180);
                        keyframe.rotation.multiply(quat);
                        break;
                    default:
                        throw 'THREE.BVHLoader: Invalid channel type.';
                }
            }

            for (i in 0...bone.children.length) {
                readFrameData(data, frameTime, bone.children[i]);
            }
        }

        function readNode(lines:Array<String>, firstline:String, list:Array<Dynamic>):Dynamic {
            var node = { name: '', type: '', frames: [] };
            list.push(node);

            var tokens = firstline.split(new RegExp('[\s]+'));
            if (tokens[0].toUpperCase() == 'END' && tokens[1].toUpperCase() == 'SITE') {
                node.type = 'ENDSITE';
                node.name = 'ENDSITE';
            } else {
                node.name = tokens[1];
                node.type = tokens[0].toUpperCase();
            }

            if (nextLine(lines) != '{') {
                throw 'THREE.BVHLoader: Expected opening { after type & name';
            }

            tokens = nextLine(lines).split(new RegExp('[\s]+'));
            if (tokens[0] != 'OFFSET') {
                throw 'THREE.BVHLoader: Expected OFFSET but got: ' + tokens[0];
            }

            if (tokens.length != 4) {
                throw 'THREE.BVHLoader: Invalid number of values for OFFSET.';
            }

            var offset = new Vector3(
                Std.parseFloat(tokens[1]),
                Std.parseFloat(tokens[2]),
                Std.parseFloat(tokens[3])
            );

            if (isNaN(offset.x) || isNaN(offset.y) || isNaN(offset.z)) {
                throw 'THREE.BVHLoader: Invalid values of OFFSET.';
            }

            node.offset = offset;

            if (node.type != 'ENDSITE') {
                tokens = nextLine(lines).split(new RegExp('[\s]+'));
                if (tokens[0] != 'CHANNELS') {
                    throw 'THREE.BVHLoader: Expected CHANNELS definition.';
                }

                var numChannels = Std.parseInt(tokens[1]);
                node.channels = tokens.splice(2, numChannels);
                node.children = [];
            }

            while (true) {
                var line = nextLine(lines);
                if (line == '}') {
                    return node;
                } else {
                    node.children.push(readNode(lines, line, list));
                }
            }
        }

        function toTHREEBone(source:Dynamic, list:Array<Dynamic>):Dynamic {
            var bone = new Bone();
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

        function toTHREEAnimation(bones:Array<Dynamic>):Dynamic {
            var tracks = [];

            for (i in 0...bones.length) {
                var bone = bones[i];
                if (bone.type == 'ENDSITE') {
                    continue;
                }

                var times = [];
                var positions = [];
                var rotations = [];

                for (j in 0...bone.frames.length) {
                    var frame = bone.frames[j];
                    times.push(frame.time);
                    positions.push(frame.position.x + bone.offset.x);
                    positions.push(frame.position.y + bone.offset.y);
                    positions.push(frame.position.z + bone.offset.z);
                    rotations.push(frame.rotation.x);
                    rotations.push(frame.rotation.y);
                    rotations.push(frame.rotation.z);
                    rotations.push(frame.rotation.w);
                }

                if (scope.animateBonePositions) {
                    tracks.push(new VectorKeyframeTrack(bone.name + '.position', times, positions));
                }

                if (scope.animateBoneRotations) {
                    tracks.push(new QuaternionKeyframeTrack(bone.name + '.quaternion', times, rotations));
                }
            }

            return new AnimationClip('animation', -1, tracks);
        }

        function nextLine(lines:Array<String>):String {
            var line;
            while (line = lines.shift().trim()).length == 0;
            return line;
        }

        var lines = text.split(new RegExp('[\r\n]+'));
        var bones = readBvh(lines);

        var threeBones = [];
        toTHREEBone(bones[0], threeBones);

        var threeClip = toTHREEAnimation(bones);

        return {
            skeleton: new Skeleton(threeBones),
            clip: threeClip
        };
    }
}