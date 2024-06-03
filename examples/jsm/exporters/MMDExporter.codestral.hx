import three.Matrix4;
import three.Quaternion;
import three.Vector3;
import mmdparser.MMDParser;

class MMDExporter {

    // TODO: implement
    // mesh -> pmd
    public function parsePmd(object:Object):Void {
        // Implementation needed
    }

    // TODO: implement
    // mesh -> pmx
    public function parsePmx(object:Object):Void {
        // Implementation needed
    }

    // TODO: implement
    // animation + skeleton -> vmd
    public function parseVmd(object:Object):Void {
        // Implementation needed
    }

    /*
     * skeleton -> vpd
     * Returns Shift_JIS encoded Uint8Array. Otherwise return strings.
     */
    public function parseVpd(skin:SkinnedMesh, outputShiftJis:Bool, useOriginalBones:Bool):Dynamic {
        if (Std.is(skin, SkinnedMesh) == false) {
            trace('THREE.MMDExporter: parseVpd() requires SkinnedMesh instance.');
            return null;
        }

        function toStringsFromNumber(num:Float):String {
            if (Math.abs(num) < 1e-6) num = 0;
            var a = num.toString();
            if (a.indexOf('.') == -1) {
                a += '.';
            }
            a += '000000';
            var index = a.indexOf('.');
            var d = a.substring(0, index);
            var p = a.substring(index + 1, index + 7);
            return d + '.' + p;
        }

        function toStringsFromArray(array:Array<Float>):String {
            var a = new Array<String>();
            for (i in 0...array.length) {
                a.push(toStringsFromNumber(array[i]));
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

        var array = new Array<String>();
        array.push('Vocaloid Pose Data file');
        array.push('');
        array.push((skin.name != '' ? skin.name.replace(new EReg("\\s", "g"), '_') : 'skin') + '.osm;');
        array.push(bones.length + ';');
        array.push('');

        for (i in 0...bones.length) {
            var bone = bones[i];
            var bone2 = bones2[i];

            if (useOriginalBones == true && bone.userData.ik != null && bone.userData.ik.originalMatrix != null) {
                matrix.fromArray(bone.userData.ik.originalMatrix);
            } else {
                matrix.copy(bone.matrix);
            }

            position.setFromMatrixPosition(matrix);
            quaternion.setFromRotationMatrix(matrix);

            var pArray = position.sub(bone2.position).toArray();
            var qArray = quaternion2.copy(bone2.quaternion).conjugate().multiply(quaternion).toArray();

            pArray[2] = -pArray[2];
            qArray[0] = -qArray[0];
            qArray[1] = -qArray[1];

            array.push('Bone' + i + '{' + bone.name);
            array.push('  ' + toStringsFromArray(pArray) + ';');
            array.push('  ' + toStringsFromArray(qArray) + ';');
            array.push('}');
            array.push('');
        }

        array.push('');

        var lines = array.join('\n');

        return (outputShiftJis == true) ? unicodeToShiftjis(lines) : lines;
    }
}

var u2sTable:haxe.ds.StringMap<Int>;

function unicodeToShiftjis(str:String):Uint8Array {
    if (u2sTable == null) {
        var encoder = new MMDParser.CharsetEncoder();
        var table = encoder.s2uTable;
        u2sTable = new haxe.ds.StringMap<Int>();

        for (key in table.keys()) {
            var value = table.get(key);
            key = Std.parseInt(key);

            u2sTable.set(String.fromCodePoint(value), key);
        }
    }

    var array = new Array<Int>();

    for (i in 0...str.length) {
        var code = str.codePointAt(i);

        var value = u2sTable.get(String.fromCodePoint(code));

        if (value == null) {
            throw new Error('cannot convert charcode 0x' + code.toString(16));
        } else if (value > 0xff) {
            array.push((value >> 8) & 0xff);
            array.push(value & 0xff);
        } else {
            array.push(value & 0xff);
        }
    }

    return new Uint8Array(array);
}

function getBindBones(skin:SkinnedMesh):Array<Bone> {
    var poseSkin = skin.clone();
    poseSkin.pose();
    return poseSkin.skeleton.bones;
}

export MMDExporter;