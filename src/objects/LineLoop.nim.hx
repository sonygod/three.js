import three.js.src.objects.Line;

class LineLoop extends Line {

    public function new(geometry:Dynamic, material:Dynamic) {

        super(geometry, material);

        this.isLineLoop = true;

        this.type = 'LineLoop';

    }

}

export haxe.macro.Macro.export('three.js.src.objects.LineLoop', LineLoop);