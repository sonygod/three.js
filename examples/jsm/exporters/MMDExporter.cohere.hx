import js.three.Matrix4;
import js.three.Quaternion;
import js.three.Vector3;
import js.mmdparser.MMDParser;

class MMDExporter {
    public function parseVpd(skin:Skin, outputShiftJis:Bool, useOriginalBones:Bool):Null<Uint8Array> {
        if (!skin.isSkinnedMesh) {
            trace("MMDExporter: parseVpd() requires SkinnedMesh instance.");
            return null;
        }

        function toStringsFromNumber(num:Float):String {
            if (Math.abs(num) < 1e-6) {
                num = 0;
            }

            var a = num.toString();
            if (a.indexOf('.') == -1) {
                a += '.';
            }

            a += '000000';

            var index = a.indexOf('.');
            var d = a.substr(0, index);
            var p = a.substr(index + 1, 7);

            return d + '.' + p;
        }

        function toStringsFromArray(array:Array<Float>):String {
            var a = [];
            for (i in 0...array.length) {
                a.push(toStringsFromNumber(array[i]));
            }

            return a.join(',');
        }

        skin.updateMatrixWorld(true);

        var bones = skin.skeleton.bones;
        var bones2 = getBindBones(skin);

        var position = Vector3.create();
        var quaternion = Quaternion.create();
        var quaternion2 = Quaternion.create();
        var matrix = Matrix4.create();

        var array = [];
        array.push("Vocaloid Pose Data file");
        array.push("");
        array.push(if (skin.name != "") skin.name.replace(/\s/g, '_') else "skin") + ".osm;");
        array.push(bones.length + ";");
        array.push("");

        for (i in 0...bones.length) {
            var bone = bones[i];
            var bone2 = bones2[i];

            if (useOriginalBones && bone.userData.ik != null && bone.userData.ik.originalMatrix != null) {
                matrix.fromArray(bone.userData.ik.originalMatrix);
            } else {
                matrix.copy(bone.matrix);
            }

            position.setFromMatrixPosition(matrix);
            quaternion.setFromRotationMatrix(matrix);

            var pArray = position.sub(bone2.position).toArray();
            var qArray = quaternion2.copy(bone2.quaternion).conjugate().multiply(quaternion).toArray();

            // right to left
            pArray[2] = -pArray[2];
            qArray[0] = -qArray[0];
            qArray[1] = -qArray[1];

            array.push("Bone" + i + "{" + bone.name);
            array.push("  " + toStringsFromArray(pArray) + ";");
            array.push("  " + toStringsFromArray(qArray) + ";");
            array.push("}");
            array.push("");
        }

        array.push("");

        var lines = array.join("\n");

        if (outputShiftJis) {
            return unicodeToShiftjis(lines);
        } else {
            return lines;
        }
    }

    function unicodeToShiftjis(str:String):Uint8Array {
        if (u2sTable == null) {
            var encoder = new MMDParser.CharsetEncoder();
            var table = encoder.s2uTable;
            u2sTable = {};

            for (key in $iter(table)) {
                var value = table[key];
                key = Std.parseInt(key);

                u2sTable[value] = key;
            }
        }

        var array = [];

        for (i in 0...str.length) {
            var code = str.charCodeAt(i);
            var value = u2sTable[code];

            if (value == null) {
                throw "cannot convert charcode 0x" + code.toString(16);
            } else if (value > 0xff) {
                array.push((value >> 8) & 0xff);
                array.push(value & 0xff);
            } else {
                array.push(value & 0xff);
            }
        }

        return new Uint8Array(array);
    }

    function getBindBones(skin:Skin):Array<Bone> {
        var poseSkin = skin.clone();
        poseSkin.pose();
        return poseSkin.skeleton.bones;
    }
}