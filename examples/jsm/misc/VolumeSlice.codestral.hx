import js.html.Canvas;
import js.html.CanvasRenderingContext2D;
import js.Three;

class VolumeSlice {
    public var volume:Volume;
    public var index:Int;
    public var axis:String;
    public var canvas:Canvas;
    public var canvasBuffer:Canvas;
    public var ctx:CanvasRenderingContext2D;
    public var ctxBuffer:CanvasRenderingContext2D;
    public var mesh:Three.Mesh;
    public var geometry:Three.PlaneGeometry;
    public var geometryNeedsUpdate:Bool;
    public var iLength:Int;
    public var jLength:Int;

    public function new(volume:Volume, index:Int = 0, axis:String = "z") {
        this.volume = volume;
        this.index = index;
        this.axis = axis;

        this.canvas = js.Browser.document.createElement("canvas").cast();
        this.canvasBuffer = js.Browser.document.createElement("canvas").cast();

        this.updateGeometry();

        var canvasMap = new Three.Texture(this.canvas);
        canvasMap.minFilter = Three.LinearFilter;
        canvasMap.wrapS = canvasMap.wrapT = Three.ClampToEdgeWrapping;
        canvasMap.colorSpace = Three.SRGBColorSpace;
        var material = new Three.MeshBasicMaterial({map: canvasMap, side: Three.DoubleSide, transparent: true});

        this.mesh = new Three.Mesh(this.geometry, material);
        this.mesh.matrixAutoUpdate = false;

        this.geometryNeedsUpdate = true;
        this.repaint();
    }

    public function repaint() {
        if (this.geometryNeedsUpdate) {
            this.updateGeometry();
        }

        // Implement repaint logic here.
    }

    public function updateGeometry() {
        var extracted = this.volume.extractPerpendicularPlane(this.axis, this.index);

        // Implement updateGeometry logic here.
    }
}