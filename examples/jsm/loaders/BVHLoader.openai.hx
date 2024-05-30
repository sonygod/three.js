package three.js.loaders;

import three.js.loaders.Loader;
import three.js.loaders.FileLoader;
import three.js.math.Quaternion;
import three.js.math.Vector3;
import three.js.animation.AnimationClip;
import three.js.animation.VectorKeyframeTrack;
import three.js.animation.QuaternionKeyframeTrack;
import three.js.objects.Bone;
import three.js.objects.Skeleton;

class BVHLoader extends Loader {
    public var animateBonePositions:Bool = true;
    public var animateBoneRotations:Bool = true;

    public function new(manager:Loader) {
        super(manager);
    }

    public function load(url:String, onLoad:(result:Dynamic)->Void, onProgress:(progress:Int)->Void, onError:(error:Error)->Void) {
        var scope:this = this;
        var loader:FileLoader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(text:String) {
            try {
                onLoad(scope.parse(text));
            } catch (e:Error) {
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
        var lines:Array<String> = text.split~/[\r\n]+/g;

        function readBvh(lines:Array<String>):Array<Bone> {
            // read model structure
            if (nextLine(lines) != 'HIERARCHY') {
                trace('THREE.BVHLoader: HIERARCHY expected.');
            }

            var list:Array<Bone> = [];
            var root:Bone = readNode(lines, nextLine(lines), list);

            // read motion data
            if (nextLine(lines) != 'MOTION') {
                trace('THREE.BVHLoader: MOTION expected.');
            }

            // number of frames
            var tokens:Array<String> = nextLine(lines).split~/[\s]+/;
            var numFrames:Int = Std.parseInt(tokens[1]);

            if (Math.isNaN(numFrames)) {
                trace('THREE.BVHLoader: Failed to read number of frames.');
            }

            // frame time
            tokens = nextLine(lines).split~/[\s]+/;
            var frameTime:Float = Std.parseFloat(tokens[2]);

            if (Math.isNaN(frameTime)) {
                trace('THREE.BVHLoader: Failed to read frame time.');
            }

            // read frame data line by line
            for (i in 0...numFrames) {
                tokens = nextLine(lines).split~/[\s]+/;
                readFrameData(tokens, i * frameTime, root);
            }

            return list;
        }

        function readFrameData(data:Array<String>, frameTime:Float, bone:Bone) {
            // end sites have no motion data
            if (bone.type == 'ENDSITE') return;

            // add keyframe
            var keyframe:{
                time:Float,
                position:Vector3,
                rotation:Quaternion
            } = {
                time: frameTime,
                position: new Vector3(),
                rotation: new Quaternion()
            };

            bone.frames.push(keyframe);

            var quat:Quaternion = new Quaternion();

            var vx:Vector3 = new Vector3(1, 0, 0);
            var vy:Vector3 = new Vector3(0, 1, 0);
            var vz:Vector3 = new Vector3(0, 0, 1);

            // parse values for each channel in node
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
                        trace('THREE.BVHLoader: Invalid channel type.');
                }
            }

            // parse child nodes
            for (i in 0...bone.children.length) {
                readFrameData(data, frameTime, bone.children[i]);
            }
        }

        function readNode(lines:Array<String>, firstline:String, list:Array<Bone>):Bone {
            var node:Bone = {
                name: '',
                type: '',
                frames: [],
                children: []
            };
            list.push(node);

            // parse node type and name
            var tokens:Array<String> = firstline.split~/[\s]+/;
            if (tokens[0].toUpperCase() == 'END' && tokens[1].toUpperCase() == 'SITE') {
                node.type = 'ENDSITE';
                node.name = 'ENDSITE'; // bvh end sites have no name
            } else {
                node.name = tokens[1];
                node.type = tokens[0].toUpperCase();
            }

            if (nextLine(lines) != '{') {
                trace('THREE.BVHLoader: Expected opening { after type & name');
            }

            // parse OFFSET
            tokens = nextLine(lines).split~/[\s]+/;
            if (tokens[0] != 'OFFSET') {
                trace('THREE.BVHLoader: Expected OFFSET but got: ' + tokens[0]);
            }

            if (tokens.length != 4) {
                trace('THREE.BVHLoader: Invalid number of values for OFFSET.');
            }

            var offset:Vector3 = new Vector3(
                Std.parseFloat(tokens[1]),
                Std.parseFloat(tokens[2]),
                Std.parseFloat(tokens[3])
            );

            if (Math.isNaN(offset.x) || Math.isNaN(offset.y) || Math.isNaN(offset.z)) {
                trace('THREE.BVHLoader: Invalid values of OFFSET.');
            }

            node.offset = offset;

            // parse CHANNELS definitions
            if (node.type != 'ENDSITE') {
                tokens = nextLine(lines).split~/[\s]+/;
                if (tokens[0] != 'CHANNELS') {
                    trace('THREE.BVHLoader: Expected CHANNELS definition.');
                }

                var numChannels:Int = Std.parseInt(tokens[1]);
                node.channels = tokens.splice(2, numChannels);
                node.children = [];
            }

            // read children
            while (true) {
                var line:String = nextLine(lines);
                if (line == '}') {
                    return node;
                } else {
                    node.children.push(readNode(lines, line, list));
                }
            }

            return node;
        }

        function toTHREEBone(source:Bone, list:Array<Bone>) {
            var bone:Bone = new Bone();
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

        function toTHREEAnimation(bones:Array<Bone>):AnimationClip {
            var tracks:Array<VectorKeyframeTrack> = [];

            for (i in 0...bones.length) {
                var bone:Bone = bones[i];

                if (bone.type == 'ENDSITE') continue;

                var times:Array<Float> = [];
                var positions:Array<Float> = [];
                var rotations:Array<Float> = [];

                for (j in 0...bone.frames.length) {
                    var frame:{
                        time:Float,
                        position:Vector3,
                        rotation:Quaternion
                    } = bone.frames[j];

                    times.push(frame.time);

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

        function nextLine(lines:Array<String>):String {
            var line:String;
            while ((line = lines.shift().trim()).length == 0) {}
            return line;
        }

        var scope:this = this;
        var lines:Array<String> = text.split~/[\r\n]+/g;
        var bones:Array<Bone> = readBvh(lines);

        var threeBones:Array<Bone> = [];
        toTHREEBone(bones[0], threeBones);

        var threeClip:AnimationClip = toTHREEAnimation(bones);

        return {
            skeleton: new Skeleton(threeBones),
            clip: threeClip
        };
    }
}