class ConeGeometry extends CylinderGeometry {
    public var type:String = 'ConeGeometry';
    public var parameters:Dynamic;

    public function new(radius:Float = 1., height:Float = 1., radialSegments:Int = 32, heightSegments:Int = 1, openEnded:Bool = false, thetaStart:Float = 0., thetaLength:Float = Std.Math.PI * 2.) {
        super(0., radius, height, radialSegments, heightSegments, openEnded, thetaStart, thetaLength);
        parameters = {
            radius: radius,
            height: height,
            radialSegments: radialSegments,
            heightSegments: heightSegments,
            openEnded: openEnded,
            thetaStart: thetaStart,
            thetaLength: thetaLength
        };
    }

    public static function fromJSON(data:Dynamic) : ConeGeometry {
        return new ConeGeometry(data.radius, data.height, data.radialSegments, data.heightSegments, data.openEnded, data.thetaStart, data.thetaLength);
    }
}