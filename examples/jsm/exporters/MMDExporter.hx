package three.js.examples.jm.exporters;

import three.Matrix4;
import three.Quaternion;
import three.Vector3;
import mmdparser.MMDParser;

class MMDExporter {
  // mesh -> pmd
  public function parsePmd(object:Dynamic):Void {
    // TODO: implement
  }

  // mesh -> pmx
  public function parsePmx(object:Dynamic):Void {
    // TODO: implement
  }

  // animation + skeleton -> vmd
  public function parseVmd(object:Dynamic):Void {
    // TODO: implement
  }

  /**
   * skeleton -> vpd
   * Returns Shift_JIS encoded ByteArray. Otherwise return strings.
   */
  public function parseVpd(skin:Dynamic, outputShiftJis:Bool, useOriginalBones:Bool):Dynamic {
    if (!skin.isSkinnedMesh) {
      trace('THREE.MMDExporter: parseVpd() requires SkinnedMesh instance.');
      return null;
    }

    function toStringsFromNumber(num:Float):String {
      if (Math.abs(num) < 1e-6) num = 0;
      var a:String = num.toString();
      if (a.indexOf('.') == -1) a += '.';
      a += '000000';
      var index:Int = a.indexOf('.');
      var d:String = a.substring(0, index);
      var p:String = a.substring(index + 1, index + 7);
      return d + '.' + p;
    }

    function toStringsFromArray(array:Array<Float>):String {
      var a:Array<String> = [];
      for (i in 0...array.length) {
        a.push(toStringsFromNumber(array[i]));
      }
      return a.join(',');
    }

    skin.updateMatrixWorld(true);

    var bones:Array<Dynamic> = skin.skeleton.bones;
    var bones2:Array<Dynamic> = getBindBones(skin);

    var position:Vector3 = new Vector3();
    var quaternion:Quaternion = new Quaternion();
    var quaternion2:Quaternion = new Quaternion();
    var matrix:Matrix4 = new Matrix4();

    var array:Array<String> = [];
    array.push('Vocaloid Pose Data file');
    array.push('');
    array.push((skin.name != '' ? skin.name.replace(/\s/g, '_') : 'skin') + '.osm;');
    array.push(bones.length + ';');
    array.push('');

    for (i in 0...bones.length) {
      var bone:Dynamic = bones[i];
      var bone2:Dynamic = bones2[i];

      if (useOriginalBones && bone.userData.ik != null && bone.userData.ik.originalMatrix != null) {
        matrix.fromArray(bone.userData.ik.originalMatrix);
      } else {
        matrix.copy(bone.matrix);
      }

      position.setFromMatrixPosition(matrix);
      quaternion.setFromRotationMatrix(matrix);

      var pArray:Array<Float> = position.sub(bone2.position).toArray();
      var qArray:Array<Float> = quaternion2.copy(bone2.quaternion).conjugate().multiply(quaternion).toArray();

      // right to left
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

    var lines:String = array.join('\n');

    return outputShiftJis ? unicodeToShiftjis(lines) : lines;
  }

  static function unicodeToShiftjis(str:String):ByteArray {
    if (u2sTable == null) {
      var encoder:MMDParser CharsetEncoder = new MMDParser CharsetEncoder();
      var table:Hash<Int> = encoder.s2uTable;
      u2sTable = new Hash<Int>();

      for (key in table.keys()) {
        var value:Int = table[key];
        key = Std.parseInt(key);
        u2sTable[value] = key;
      }
    }

    var array:Array<Int> = [];

    for (i in 0...str.length) {
      var code:Int = str.charCodeAt(i);

      var value:Int = u2sTable[code];

      if (value == null) {
        throw new Error('cannot convert charcode 0x' + code.toHexString());
      } else if (value > 0xff) {
        array.push((value >> 8) & 0xff);
        array.push(value & 0xff);
      } else {
        array.push(value & 0xff);
      }
    }

    return ByteArray.fromArray(array);
  }

  static function getBindBones(skin:Dynamic):Array<Dynamic> {
    var poseSkin:Dynamic = skin.clone();
    poseSkin.pose();
    return poseSkin.skeleton.bones;
  }
}

// Unicode to Shift_JIS table
static var u2sTable:Hash<Int> = null;