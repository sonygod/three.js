import three.Matrix4;
import three.Quaternion;
import three.Vector3;
import mmdparser.MMDParser;

class MMDExporter {

    public function new() {

    }

    public function parseVpd(skin:Dynamic, outputShiftJis:Bool, useOriginalBones:Bool):Dynamic {

        if (skin.isSkinnedMesh !== true) {

            trace('THREE.MMDExporter: parseVpd() requires SkinnedMesh instance.');
            return null;

        }

        function toStringsFromNumber(num:Float):String {

            if (Math.abs(num) < 1e-6) num = 0;

            var a = num.toString();

            if (a.indexOf('.') === - 1) {

                a += '.';

            }

            a += '000000';

            var index = a.indexOf('.');

            var d = a.slice(0, index);
            var p = a.slice(index + 1, index + 7);

            return d + '.' + p;

        }

        function toStringsFromArray(array:Array<Float>):String {

            var a = [];

            for (i in array) {

                a.push(toStringsFromNumber(array[Std.int(i)]));

            }

            return a.join(',');

        }

        skin.updateMatrixWorld(true);

        var bones = skin.skeleton.bones;
        var bones2 = getBindBones(skin);

        var position = new Vector3();
        var quaternion = new Quaternion();
        var quaternion2 = new Quaternion();
        var matrix = new Matrix4();

        var array = [];
        array.push('Vocaloid Pose Data file');
        array.push('');
        array.push((skin.name !== '' ? skin.name.replace(/\s/g, '_') : 'skin') + '.osm;');
        array.push(bones.length + ';');
        array.push('');

        for (i in bones) {

            var bone = bones[Std.int(i)];
            var bone2 = bones2[Std.int(i)];

            if (useOriginalBones === true &&
                bone.userData.ik !== undefined &&
                bone.userData.ik.originalMatrix !== undefined) {

                matrix.fromArray(bone.userData.ik.originalMatrix);

            } else {

                matrix.copy(bone.matrix);

            }

            position.setFromMatrixPosition(matrix);
            quaternion.setFromRotationMatrix(matrix);

            var pArray = position.sub(bone2.position).toArray();
            var qArray = quaternion2.copy(bone2.quaternion).conjugate().multiply(quaternion).toArray();

            pArray[2] = - pArray[2];
            qArray[0] = - qArray[0];
            qArray[1] = - qArray[1];

            array.push('Bone' + i + '{' + bone.name);
            array.push('  ' + toStringsFromArray(pArray) + ';');
            array.push('  ' + toStringsFromArray(qArray) + ';');
            array.push('}');
            array.push('');

        }

        array.push('');

        var lines = array.join('\n');

        return (outputShiftJis === true) ? unicodeToShiftjis(lines) : lines;

    }

}

static var u2sTable:Dynamic;

static function unicodeToShiftjis(str:String):UInt8Array {

    if (u2sTable === undefined) {

        var encoder = new MMDParser.CharsetEncoder();
        var table = encoder.s2uTable;
        u2sTable = {};

        var keys = Reflect.fields(table);

        for (i in keys) {

            var key = keys[Std.int(i)];

            var value = Reflect.field(table, key);
            key = Std.parseInt(key);

            u2sTable[value] = key;

        }

    }

    var array = [];

    for (i in str) {

        var code = str.charCodeAt(Std.int(i));

        var value = u2sTable[code];

        if (value === undefined) {

            throw 'cannot convert charcode 0x' + code.toString(16);

        } else if (value > 0xff) {

            array.push((value >> 8) & 0xff);
            array.push(value & 0xff);

        } else {

            array.push(value & 0xff);

        }

    }

    return new UInt8Array(array);

}

static function getBindBones(skin:Dynamic):Array<Dynamic> {

    var poseSkin = skin.clone();
    poseSkin.pose();
    return poseSkin.skeleton.bones;

}