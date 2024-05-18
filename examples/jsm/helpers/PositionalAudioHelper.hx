package three.js.examples.jsm.helpers;

import three.BufferGeometry;
import three.BufferAttribute;
import three.LineBasicMaterial;
import three.Line;
import three.MathUtils;

class PositionalAudioHelper extends Line {
    public var audio:Dynamic;
    public var range:Float;
    public var divisionsInnerAngle:Int;
    public var divisionsOuterAngle:Int;
    public var type:String;

    public function new(audio:Dynamic, range:Float = 1, divisionsInnerAngle:Int = 16, divisionsOuterAngle:Int = 2) {
        super(new BufferGeometry(), [new LineBasicMaterial({ color: 0x00ff00 }), new LineBasicMaterial({ color: 0xffff00 })]);

        this.audio = audio;
        this.range = range;
        this.divisionsInnerAngle = divisionsInnerAngle;
        this.divisionsOuterAngle = divisionsOuterAngle;
        this.type = 'PositionalAudioHelper';

        update();
    }

    public function update():Void {
        var audio:Dynamic = this.audio;
        var range:Float = this.range;
        var divisionsInnerAngle:Int = this.divisionsInnerAngle;
        var divisionsOuterAngle:Int = this.divisionsOuterAngle;

        var coneInnerAngle:Float = MathUtils.degToRad(audio.panner.coneInnerAngle);
        var coneOuterAngle:Float = MathUtils.degToRad(audio.panner.coneOuterAngle);

        var halfConeInnerAngle:Float = coneInnerAngle / 2;
        var halfConeOuterAngle:Float = coneOuterAngle / 2;

        var start:Int = 0;
        var count:Int = 0;
        var i:Int;
        var stride:Int;

        var geometry:BufferGeometry = this.geometry;
        var positionAttribute:BufferAttribute = geometry.getAttribute('position');

        geometry.clearGroups();

        function generateSegment(from:Float, to:Float, divisions:Int, materialIndex:Int):Void {
            var step:Float = (to - from) / divisions;

            positionAttribute.setXYZ(start, 0, 0, 0);
            count++;

            for (i in Std.int(from)..Std.int(to)) {
                stride = start + count;

                positionAttribute.setXYZ(stride, Math.sin(i) * range, 0, Math.cos(i) * range);
                positionAttribute.setXYZ(stride + 1, Math.sin(Math.min(i + step, to)) * range, 0, Math.cos(Math.min(i + step, to)) * range);
                positionAttribute.setXYZ(stride + 2, 0, 0, 0);

                count += 3;
            }

            geometry.addGroup(start, count, materialIndex);

            start += count;
            count = 0;
        }

        generateSegment(-halfConeOuterAngle, -halfConeInnerAngle, divisionsOuterAngle, 0);
        generateSegment(-halfConeInnerAngle, halfConeInnerAngle, divisionsInnerAngle, 1);
        generateSegment(halfConeInnerAngle, halfConeOuterAngle, divisionsOuterAngle, 0);

        positionAttribute.needsUpdate = true;

        if (coneInnerAngle == coneOuterAngle) material[0].visible = false;
    }

    public function dispose():Void {
        geometry.dispose();
        material[0].dispose();
        material[1].dispose();
    }
}