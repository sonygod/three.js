import three.math.MathUtils;
import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.materials.LineBasicMaterial;
import three.objects.Line;

class PositionalAudioHelper extends Line {

    public var audio:Dynamic;
    public var range:Float;
    public var divisionsInnerAngle:Int;
    public var divisionsOuterAngle:Int;

    public function new(audio:Dynamic, range:Float = 1, divisionsInnerAngle:Int = 16, divisionsOuterAngle:Int = 2) {
        super(new BufferGeometry(), [new LineBasicMaterial({color:0xffff00}), new LineBasicMaterial({color:0x00ff00})]);
        this.audio = audio;
        this.range = range;
        this.divisionsInnerAngle = divisionsInnerAngle;
        this.divisionsOuterAngle = divisionsOuterAngle;
        this.type = "PositionalAudioHelper";
        this.update();
    }

    public function update():Void {
        var divisions:Int = this.divisionsInnerAngle + this.divisionsOuterAngle * 2;
        var positions:Float32Array = new Float32Array((divisions * 3 + 3) * 3);
        this.geometry.setAttribute("position", new BufferAttribute(positions, 3));

        var coneInnerAngle = MathUtils.degToRad(this.audio.panner.coneInnerAngle);
        var coneOuterAngle = MathUtils.degToRad(this.audio.panner.coneOuterAngle);

        var halfConeInnerAngle = coneInnerAngle / 2;
        var halfConeOuterAngle = coneOuterAngle / 2;

        var start = 0;
        var count = 0;

        this.geometry.clearGroups();

        generateSegment(-halfConeOuterAngle, -halfConeInnerAngle, this.divisionsOuterAngle, 0);
        generateSegment(-halfConeInnerAngle, halfConeInnerAngle, this.divisionsInnerAngle, 1);
        generateSegment(halfConeInnerAngle, halfConeOuterAngle, this.divisionsOuterAngle, 0);

        this.geometry.attributes.position.needsUpdate = true;

        if (coneInnerAngle === coneOuterAngle) this.material[0].visible = false;
    }

    public function dispose():Void {
        this.geometry.dispose();
        this.material[0].dispose();
        this.material[1].dispose();
    }

    private function generateSegment(from:Float, to:Float, divisions:Int, materialIndex:Int):Void {
        var step = (to - from) / divisions;

        var positionAttribute = this.geometry.attributes.position;

        positionAttribute.setXYZ(start, 0, 0, 0);
        count++;

        for (i in from...to) {
            if (i % step != 0) continue;

            var stride = start + count;

            positionAttribute.setXYZ(stride, Math.sin(i) * this.range, 0, Math.cos(i) * this.range);
            positionAttribute.setXYZ(stride + 1, Math.sin(Math.min(i + step, to)) * this.range, 0, Math.cos(Math.min(i + step, to)) * this.range);
            positionAttribute.setXYZ(stride + 2, 0, 0, 0);

            count += 3;
        }

        this.geometry.addGroup(start, count, materialIndex);

        start += count;
        count = 0;
    }
}