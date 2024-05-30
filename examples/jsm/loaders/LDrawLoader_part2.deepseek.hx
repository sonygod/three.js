class ConditionalLineSegments extends LineSegments {

    public function new(geometry:Geometry, material:Material) {
        super(geometry, material);
        this.isConditionalLine = true;
    }

}