import three.ClampToEdgeWrapping;
import three.DoubleSide;
import three.LinearFilter;
import three.Mesh;
import three.MeshBasicMaterial;
import three.PlaneGeometry;
import three.Texture;
import three.SRGBColorSpace;

class VolumeSlice {

	var volume:Volume;
	var index:Int;
	var axis:String;
	var canvas:js.html.CanvasElement;
	var canvasBuffer:js.html.CanvasElement;
	var ctx:js.html.CanvasRenderingContext2D;
	var ctxBuffer:js.html.CanvasRenderingContext2D;
	var mesh:Mesh;
	var geometryNeedsUpdate:Bool;
	var iLength:Int;
	var jLength:Int;
	var sliceAccess:Int->Int->Int;
	var matrix:three.Matrix4;

	public function new(volume:Volume, index:Int, axis:String) {
		this.volume = volume;
		this.index = index;
		this.axis = axis;
		this.canvas = js.Browser.document.createElement('canvas');
		this.canvasBuffer = js.Browser.document.createElement('canvas');
		this.ctx = this.canvas.getContext('2d');
		this.ctxBuffer = this.canvasBuffer.getContext('2d');
		this.updateGeometry();
		var canvasMap = new Texture(this.canvas);
		canvasMap.minFilter = LinearFilter;
		canvasMap.wrapS = canvasMap.wrapT = ClampToEdgeWrapping;
		canvasMap.colorSpace = SRGBColorSpace;
		var material = new MeshBasicMaterial({map: canvasMap, side: DoubleSide, transparent: true});
		this.mesh = new Mesh(this.geometry, material);
		this.mesh.matrixAutoUpdate = false;
		this.geometryNeedsUpdate = true;
		this.repaint();
	}

	public function repaint() {
		if (this.geometryNeedsUpdate) {
			this.updateGeometry();
		}
		var iLength = this.iLength;
		var jLength = this.jLength;
		var sliceAccess = this.sliceAccess;
		var volume = this.volume;
		var canvas = this.canvasBuffer;
		var ctx = this.ctxBuffer;
		var imgData = ctx.getImageData(0, 0, iLength, jLength);
		var data = imgData.data;
		var volumeData = volume.data;
		var upperThreshold = volume.upperThreshold;
		var lowerThreshold = volume.lowerThreshold;
		var windowLow = volume.windowLow;
		var windowHigh = volume.windowHigh;
		var pixelCount = 0;
		if (volume.dataType == 'label') {
			for (j in 0...jLength) {
				for (i in 0...iLength) {
					var label = volumeData[sliceAccess(i, j)];
					label = label >= this.colorMap.length ? (label % this.colorMap.length) + 1 : label;
					var color = this.colorMap[label];
					data[4 * pixelCount] = (color >> 24) & 0xff;
					data[4 * pixelCount + 1] = (color >> 16) & 0xff;
					data[4 * pixelCount + 2] = (color >> 8) & 0xff;
					data[4 * pixelCount + 3] = color & 0xff;
					pixelCount++;
				}
			}
		} else {
			for (j in 0...jLength) {
				for (i in 0...iLength) {
					var value = volumeData[sliceAccess(i, j)];
					var alpha = 0xff;
					alpha = upperThreshold >= value ? (lowerThreshold <= value ? alpha : 0) : 0;
					value = Math.floor(255 * (value - windowLow) / (windowHigh - windowLow));
					value = value > 255 ? 255 : (value < 0 ? 0 : value | 0);
					data[4 * pixelCount] = value;
					data[4 * pixelCount + 1] = value;
					data[4 * pixelCount + 2] = value;
					data[4 * pixelCount + 3] = alpha;
					pixelCount++;
				}
			}
		}
		ctx.putImageData(imgData, 0, 0);
		this.ctx.drawImage(canvas, 0, 0, iLength, jLength, 0, 0, this.canvas.width, this.canvas.height);
		this.mesh.material.map.needsUpdate = true;
	}

	public function updateGeometry() {
		var extracted = this.volume.extractPerpendicularPlane(this.axis, this.index);
		this.sliceAccess = extracted.sliceAccess;
		this.jLength = extracted.jLength;
		this.iLength = extracted.iLength;
		this.matrix = extracted.matrix;
		this.canvas.width = extracted.planeWidth;
		this.canvas.height = extracted.planeHeight;
		this.canvasBuffer.width = this.iLength;
		this.canvasBuffer.height = this.jLength;
		if (this.geometry != null) this.geometry.dispose();
		this.geometry = new PlaneGeometry(extracted.planeWidth, extracted.planeHeight);
		if (this.mesh != null) {
			this.mesh.geometry = this.geometry;
			this.mesh.matrix.identity();
			this.mesh.applyMatrix4(this.matrix);
		}
		this.geometryNeedsUpdate = false;
	}
}