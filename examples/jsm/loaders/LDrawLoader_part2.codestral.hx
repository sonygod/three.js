// LineSegments is an external class from three.js library
extern class LineSegments {
    public function new(geometry:Dynamic, material:Dynamic);
    public var isConditionalLine:Bool;
}

abstract ConditionalLineSegments(geometry:Dynamic, material:Dynamic) extends LineSegments {
    public function new(geometry:Dynamic, material:Dynamic) {
        super(geometry, material);
        this.isConditionalLine = true;
    }
}