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
    public var animateBonePositions:Bool = true;
    public var animateBoneRotations:Bool = true;

    public function new(manager:Loader.LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(text:String) {
            try {
                onLoad(this.parse(text));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                this.manager.itemError(url);
            }
        }.bind(this), onProgress, onError);
    }

    public function parse(text:String):Dynamic {
        var lines:Array<String> = text.split(/\r\n|\r|\n/g);
        var bones:Array<Dynamic> = readBvh(lines);
        var threeBones:Array<Bone> = [];
        toTHREEBone(bones[0], threeBones);
        var threeClip:AnimationClip = toTHREEAnimation(bones);
        return {
            skeleton: new Skeleton(threeBones),
            clip: threeClip
        };
    }

    private function readBvh(lines:Array<String>):Array<Dynamic> {
        if (nextLine(lines) != "HIERARCHY") {
            trace("THREE.BVHLoader: HIERARCHY expected.");
        }
        var list:Array<Dynamic> = [];
        var root:Dynamic = readNode(lines, nextLine(lines), list);
        if (nextLine(lines) != "MOTION") {
            trace("THREE.BVHLoader: MOTION expected.");
        }
        var tokens:Array<String> = nextLine(lines).split(/\s+/);
        var numFrames:Int = Std.parseInt(tokens[1]);
        if (Std.isNaN(numFrames)) {
            trace("THREE.BVHLoader: Failed to read number of frames.");
        }
        tokens = nextLine(lines).split(/\s+/);
        var frameTime:Float = Std.parseFloat(tokens[2]);
        if (Std.isNaN(frameTime)) {
            trace("THREE.BVHLoader: Failed to read frame time.");
        }
        for (var i:Int = 0; i < numFrames; i++) {
            tokens = nextLine(lines).split(/\s+/);
            readFrameData(tokens, i * frameTime, root);
        }
        return list;
    }

    private function readFrameData(data:Array<String>, frameTime:Float, bone:Dynamic):Void {
        if (bone.type == "ENDSITE") return;
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
        for (var i:Int = 0; i < bone.channels.length; i++) {
            switch (bone.channels[i]) {
                case "Xposition":
                    keyframe.position.x = Std.parseFloat(data.shift());
                    break;
                case "Yposition":
                    keyframe.position.y = Std.parseFloat(data.shift());
                    break;
                case "Zposition":
                    keyframe.position.z = Std.parseFloat(data.shift());
                    break;
                case "Xrotation":
                    quat.setFromAxisAngle(vx, Std.parseFloat(data.shift()) * Math.PI / 180);
                    keyframe.rotation.multiply(quat);
                    break;
                case "Yrotation":
                    quat.setFromAxisAngle(vy, Std.parseFloat(data.shift()) * Math.PI / 180);
                    keyframe.rotation.multiply(quat);
                    break;
                case "Zrotation":
                    quat.setFromAxisAngle(vz, Std.parseFloat(data.shift()) * Math.PI / 180);
                    keyframe.rotation.multiply(quat);
                    break;
                default:
                    trace("THREE.BVHLoader: Invalid channel type.");
            }
        }
        for (i = 0; i < bone.children.length; i++) {
            readFrameData(data, frameTime, bone.children[i]);
        }
    }

    private function readNode(lines:Array<String>, firstline:String, list:Array<Dynamic>):Dynamic {
        var node = { name: "", type: "", frames: [] };
        list.push(node);
        var tokens:Array<String> = firstline.split(/\s+/);
        if (tokens[0].toUpperCase() == "END" && tokens[1].toUpperCase() == "SITE") {
            node.type = "ENDSITE";
            node.name = "ENDSITE";
        } else {
            node.name = tokens[1];
            node.type = tokens[0].toUpperCase();
        }
        if (nextLine(lines) != "{") {
            trace("THREE.BVHLoader: Expected opening { after type & name");
        }
        tokens = nextLine(lines).split(/\s+/);
        if (tokens[0] != "OFFSET") {
            trace("THREE.BVHLoader: Expected OFFSET but got: " + tokens[0]);
        }
        if (tokens.length != 4) {
            trace("THREE.BVHLoader: Invalid number of values for OFFSET.");
        }
        var offset = new Vector3(
            Std.parseFloat(tokens[1]),
            Std.parseFloat(tokens[2]),
            Std.parseFloat(tokens[3])
        );
        if (Std.isNaN(offset.x) || Std.isNaN(offset.y) || Std.isNaN(offset.z)) {
            trace("THREE.BVHLoader: Invalid values of OFFSET.");
        }
        node.offset = offset;
        if (node.type != "ENDSITE") {
            tokens = nextLine(lines).split(/\s+/);
            if (tokens[0] != "CHANNELS") {
                trace("THREE.BVHLoader: Expected CHANNELS definition.");
            }
            var numChannels:Int = Std.parseInt(tokens[1]);
            node.channels = tokens.slice(2, 2 + numChannels);
            node.children = [];
        }
        while (true) {
            var line:String = nextLine(lines);
            if (line == "}") {
                return node;
            } else {
                node.children.push(readNode(lines, line, list));
            }
        }
    }

    private function toTHREEBone(source:Dynamic, list:Array<Bone>):Bone {
        var bone = new Bone();
        list.push(bone);
        bone.position.add(source.offset);
        bone.name = source.name;
        if (source.type != "ENDSITE") {
            for (var i:Int = 0; i < source.children.length; i++) {
                bone.add(toTHREEBone(source.children[i], list));
            }
        }
        return bone;
    }

    private function toTHREEAnimation(bones:Array<Dynamic>):AnimationClip {
        var tracks:Array<Dynamic> = [];
        for (var i:Int = 0; i < bones.length; i++) {
            var bone:Dynamic = bones[i];
            if (bone.type == "ENDSITE") continue;
            var times:Array<Float> = [];
            var positions:Array<Float> = [];
            var rotations:Array<Float> = [];
            for (var j:Int = 0; j < bone.frames.length; j++) {
                var frame:Dynamic = bone.frames[j];
                times.push(frame.time);
                positions.push(frame.position.x + bone.offset.x);
                positions.push(frame.position.y + bone.offset.y);
                positions.push(frame.position.z + bone.offset.z);
                rotations.push(frame.rotation.x);
                rotations.push(frame.rotation.y);
                rotations.push(frame.rotation.z);
                rotations.push(frame.rotation.w);
            }
            if (this.animateBonePositions) {
                tracks.push(new VectorKeyframeTrack(bone.name + ".position", times, positions));
            }
            if (this.animateBoneRotations) {
                tracks.push(new QuaternionKeyframeTrack(bone.name + ".quaternion", times, rotations));
            }
        }
        return new AnimationClip("animation", -1, tracks);
    }

    private function nextLine(lines:Array<String>):String {
        var line:String;
        while ((line = lines.shift()).trim() == "") {}
        return line;
    }
}