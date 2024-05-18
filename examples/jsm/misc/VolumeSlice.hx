package three.js.examples.jsm.misc;

import three.ClampToEdgeWrapping;
import three.DoubleSide;
import three.LinearFilter;
import three.Mesh;
import three.MeshBasicMaterial;
import three.PlaneGeometry;
import three.SRGBColorSpace;
import three.Texture;

/**
 * This class has been made to hold a slice of a volume data
 * @class
 * @param   {Volume} volume    The associated volume
 * @param   {Int}       [index=0] The index of the slice
 * @param   {String}       [axis='z']      For now only 'x', 'y' or 'z' but later it will change to a normal vector
 * @see Volume
 */
class VolumeSlice {
    private var volume:Volume;
    private var index:Int;
    private var axis:String;
    private var canvas:js.html.CanvasElement;
    private var ctx:js.html.CanvasRenderingContext2D;
    private var canvasBuffer:js.html.CanvasElement;
    private var ctxBuffer:js.html.CanvasRenderingContext2D;
    private var mesh:Mesh;
    private var geometryNeedsUpdate:Bool;
    private var iLength:Int;
    private var jLength:Int;
    private var sliceAccess:_volume->Int->Int->Int;
    private var colorMap:Array<Int>;

    public function new(volume:Volume, index:Int = 0, axis:String = 'z') {
        this.volume = volume;
        this.index = index;
        this.axis = axis;
        this.canvas = js.Browser.document.createElement('canvas');
        this.ctx = this.canvas.getContext('2d');
        this.canvasBuffer = js.Browser.document.createElement('canvas');
        this.ctxBuffer = this.canvasBuffer.getContext('2d');
        this.updateGeometry();

        var canvasMap = new Texture(this.canvas);
        canvasMap.minFilter = LinearFilter;
        canvasMap.wrapS = canvasMap.wrapT = ClampToEdgeWrapping;
        canvasMap.colorSpace = SRGBColorSpace;
        var material = new MeshBasicMaterial({ map: canvasMap, side: DoubleSide, transparent: true });
        this.mesh = new Mesh(new PlaneGeometry(1, 1), material);
        this.mesh.matrixAutoUpdate = false;
        this.geometryNeedsUpdate = true;
        this.repaint();
    }

    public function repaint():Void {
        if (this.geometryNeedsUpdate) {
            this.updateGeometry();
        }

        var iLength:Int = this.iLength;
        var jLength:Int = this.jLength;
        var sliceAccess:_->Int->Int->Int = this.sliceAccess;
        var volume:Volume = this.volume;
        var canvas:js.html.CanvasElement = this.canvasBuffer;
        var ctx:js.html.CanvasRenderingContext2D = this.ctxBuffer;

        var imgData = ctx.getImageData(0, 0, iLength, jLength);
        var data:Array<Int> = imgData.data;
        var volumeData:Array<Int> = volume.data;
        var upperThreshold:Float = volume.upperThreshold;
        var lowerThreshold:Float = volume.lowerThreshold;
        var windowLow:Float = volume.windowLow;
        var windowHigh:Float = volume.windowHigh;

        var pixelCount:Int = 0;

        if (volume.dataType == 'label') {
            for (j in 0...jLength) {
                for (i in 0...iLength) {
                    var label:Int = volumeData[sliceAccess(i, j)];
                    label = label >= this.colorMap.length ? (label % this.colorMap.length) + 1 : label;
                    var color:Int = this.colorMap[label];
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
                    var value:Float = volumeData[sliceAccess(i, j)];
                    var alpha:Int = 0xff;
                    //apply threshold
                    alpha = upperThreshold >= value ? (lowerThreshold <= value ? alpha : 0) : 0;
                    //apply window level
                    value = Math.floor(255 * (value - windowLow) / (windowHigh - windowLow));
                    value = value > 255 ? 255 : (value < 0 ? 0 : Std.int(value));

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

    public function updateGeometry():Void {
        var extracted = this.volume.extractPerpendicularPlane(this.axis, this.index);
        this.sliceAccess = extracted.sliceAccess;
        this.jLength = extracted.jLength;
        this.iLength = extracted.iLength;
        this.matrix = extracted.matrix;

        this.canvas.width = extracted.planeWidth;
        this.canvas.height = extracted.planeHeight;
        this.canvasBuffer.width = this.iLength;
        this.canvasBuffer.height = this.jLength;
        this.ctx = this.canvas.getContext('2d');
        this.ctxBuffer = this.canvasBuffer.getContext('2d');

        if (this.geometry != null) this.geometry.dispose(); // dispose existing geometry

        this.geometry = new PlaneGeometry(extracted.planeWidth, extracted.planeHeight);

        if (this.mesh != null) {
            this.mesh.geometry = this.geometry;
            //reset mesh matrix
            this.mesh.matrix.identity();
            this.mesh.applyMatrix4(this.matrix);
        }

        this.geometryNeedsUpdate = false;
    }
}