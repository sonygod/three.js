import js.three.BufferGeometry;
import js.three.BufferAttribute;
import js.three.LineBasicMaterial;
import js.three.Line;
import js.three.MathUtils;

class PositionalAudioHelper extends Line {
    public var audio:Dynamic;
    public var range:Float = 1.0;
    public var divisionsInnerAngle:Int = 16;
    public var divisionsOuterAngle:Int = 2;

    public function new(audio:Dynamic, ?range:Float, ?divisionsInnerAngle:Int, ?divisionsOuterAngle:Int) {
        super();

        var geometry = new BufferGeometry();
        var divisions = divisionsInnerAngle + (divisionsOuterAngle * 2);
        var positions = new Float32Array((divisions * 3 + 3) * 3);
        geometry.setAttribute('position', new BufferAttribute(positions, 3));

        var materialInnerAngle = new LineBasicMaterial({ color: 0x00ff00 });
        var materialOuterAngle = new LineBasicMaterial({ color: 0xffff00 });

        super(geometry, [materialOuterAngle, materialInnerAngle]);

        this.audio = audio;
        this.range = range ?? 1.0;
        this.divisionsInnerAngle = divisionsInnerAngle ?? 16;
        this.divisionsOuterAngle = divisionsOuterAngle ?? 2;
        this.type = 'PositionalAudioHelper';

        this.update();
    }

    public function update() {
        var audio = this.audio;
        var range = this.range;
        var divisionsInnerAngle = this.divisionsInnerAngle;
        var divisionsOuterAngle = this.divisionsOuterAngle;

        var coneInnerAngle = MathUtils.degToRad(audio.panner.coneInnerAngle);
        var coneOuterAngle = MathUtils.degToRad(audio.panner.coneOuterAngle);

        var halfConeInnerAngle = coneInnerAngle / 2.0;
        var halfConeOuterAngle = coneOuterAngle / 2.0;

        var start = 0;
        var count = 0;
        var i:Float;
        var stride:Int;

        var geometry = this.geometry;
        var positionAttribute = geometry.attributes.position;

        geometry.clearGroups();

        function generateSegment(from:Float, to:Float, divisions:Int, materialIndex:Int) {
            var step = (to - from) / divisions;

            positionAttribute.setXYZ(start, 0.0, 0.0, 0.0);
            count++;

            for (i = from; i < to; i += step) {
                stride = start + count;

                positionAttribute.setXYZ(stride, Math.sin(i) * range, 0.0, Math.cos(i) * range);
                positionAttribute.setXYZ(stride + 1, Math.sin(Math.min(i + step, to)) * range, 0.0, Math.cos(Math.min(i + step, to)) * range);
                positionAttribute.setXYZ(stride + 2, 0.0, 0.0, 0.0);

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

        if (coneInnerAngle == coneOuterAngle) {
            this.material[0].visible = false;
        }
    }

    public function dispose() {
        this.geometry.dispose();
        this.material[0].dispose();
        this.material[1].dispose();
    }
}

class Export {
    public static function PositionalAudioHelper() -> PositionalAudioHelper {
        return PositionalAudioHelper;
    }
}