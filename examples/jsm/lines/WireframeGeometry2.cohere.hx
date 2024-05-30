import js.threes.WireframeGeometry;
import js.lines.LineSegmentsGeometry;

class WireframeGeometry2 extends LineSegmentsGeometry {
	public var isWireframeGeometry2:Bool = true;
	public var type:String = 'WireframeGeometry2';

	public function new(geometry:WireframeGeometry) {
		super();
		this.fromWireframeGeometry(geometry);
	}

	public function fromWireframeGeometry(geometry:WireframeGeometry):Void {
		// ...
	}
}

@:expose("WireframeGeometry2")
class WireframeGeometry2Extern { }