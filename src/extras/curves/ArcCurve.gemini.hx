import three.extras.curves.EllipseCurve;

class ArcCurve extends EllipseCurve {

	public function new(aX:Float, aY:Float, aRadius:Float, aStartAngle:Float, aEndAngle:Float, aClockwise:Bool) {
		super(aX, aY, aRadius, aRadius, aStartAngle, aEndAngle, aClockwise);
		this.isArcCurve = true;
		this.type = "ArcCurve";
	}

	public var isArcCurve:Bool;
	public var type:String;

}