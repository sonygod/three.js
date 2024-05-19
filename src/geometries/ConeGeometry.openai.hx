import three.js.src.geometries.CylinderGeometry;

class ConeGeometry extends CylinderGeometry {
	
	public var radius(default, null):Float;
	public var height(default, null):Float;
	public var radialSegments(default, null):Int;
	public var heightSegments(default, null):Int;
	public var openEnded(default, null):Bool;
	public var thetaStart(default, null):Float;
	public var thetaLength(default, null):Float;
	
	public function new(radius:Float = 1, height:Float = 1, radialSegments:Int = 32, heightSegments:Int = 1, openEnded:Bool = false, thetaStart:Float = 0, thetaLength:Float = Math.PI * 2):Void {
		super(0, radius, height, radialSegments, heightSegments, openEnded, thetaStart, thetaLength);
		
		this.type = "ConeGeometry";
		
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
		return new ConeGeometry(data.radius, data.height, data.radialSegments, data.heightSegments, data.openEnded, data.thetaStart, data.thetaLength);
	}
}