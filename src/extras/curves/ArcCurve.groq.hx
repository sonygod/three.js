package three.js.src.extras.curves;

import three.js.src.extras.curves.EllipseCurve;

class ArcCurve extends EllipseCurve {

    public var isArcCurve:Bool = true;
    public var type:String = 'ArcCurve';

    public function new(aX:Float, aY:Float, aRadius:Float, aStartAngle:Float, aEndAngle:Float, aClockwise:Bool) {
        super(aX, aY, aRadius, aRadius, aStartAngle, aEndAngle, aClockwise);
    }
}

// Export the class
extern class ArcCurve {}