class ArcCurve extends EllipseCurve {
    public var isArcCurve:Bool;
    public var type:String;

    public function new(aX:Float, aY:Float, aRadius:Float, aStartAngle:Float, aEndAngle:Float, aClockwise:Bool) {
        super(aX, aY, aRadius, aRadius, aStartAngle, aEndAngle, aClockwise);
        isArcCurve = true;
        type = "ArcCurve";
    }
}