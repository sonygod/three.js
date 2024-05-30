import three.js.extras.core.LineSegments;

class ConditionalLineSegments extends LineSegments {

    public function new(geometry:Dynamic, material:Dynamic) {
        super(geometry, material);
        this.isConditionalLine = true;
    }

}