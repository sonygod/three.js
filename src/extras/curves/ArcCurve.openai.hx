package three.js.src.extras.curves;

import three.js.src.extras.curves.EllipseCurve;

class ArcCurve extends EllipseCurve {

    public function new(aX:Float, aY:Float, aRadius:Float, aStartAngle:Float, aEndAngle:Float, aClockwise:Bool) {
        super(aX, aY, aRadius, aRadius, aStartAngle, aEndAngle, aClockwise);
        this.isArcCurve = true;
        this.type = 'ArcCurve';
    }

}