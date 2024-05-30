import three.geometries.CylinderGeometry;

class ConeGeometry extends CylinderGeometry {

    public var type:String;
    public var parameters:Dynamic;

    public function new(
        ?radius:Float = 1, 
        ?height:Float = 1, 
        ?radialSegments:Int = 32, 
        ?heightSegments:Int = 1, 
        ?openEnded:Bool = false, 
        ?thetaStart:Float = 0, 
        ?thetaLength:Float = Math.PI * 2
    ) {
        super(0, radius, height, radialSegments, heightSegments, openEnded, thetaStart, thetaLength);

        this.type = 'ConeGeometry';

        this.parameters = {
            radius: radius,
            height: height,
            radialSegments: radialSegments,
            heightSegments: heightSegments,
            openEnded: openEnded,
            thetaStart: thetaStart,
            thetaLength: thetaLength
        };
    }

    public static function fromJSON(data:Dynamic):ConeGeometry {
        return new ConeGeometry(
            data.radius,
            data.height,
            data.radialSegments,
            data.heightSegments,
            data.openEnded,
            data.thetaStart,
            data.thetaLength
        );
    }
}