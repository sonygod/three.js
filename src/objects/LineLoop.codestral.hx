import Line from 'three.js.src.objects.Line';

class LineLoop extends Line {

    public function new(geometry:Geometry, material:Material) {
        super(geometry, material);
        this.isLineLoop = true;
        this.type = 'LineLoop';
    }

}