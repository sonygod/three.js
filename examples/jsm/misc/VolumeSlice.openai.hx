package three.js.examples.jsm.misc;

import three.js.Three;
import three.js.geometries.PlaneGeometry;
import three.js.materials.MeshBasicMaterial;
import three.js.textures.Texture;
import three.js.math.Vector2;

class VolumeSlice {
    public var volume:Volume;
    public var index(default, set):Int;
    public var axis:String;
    public var canvas:js.html.CanvasElement;
    public var ctx:js.html.CanvasRenderingContext2D;
    public var canvasBuffer:js.html.CanvasElement;
    public var ctxBuffer:js.html.CanvasRenderingContext2D;
    public var mesh:Three.Mesh;
    public var geometryNeedsUpdate:Bool;
    public var iLength:Float;
    public var jLength:Float;
    public var sliceAccess:Array<Int>->Int;

    public function new(volume:Volume, index:Int = 0, axis:String = 'z') {
        this.volume = volume;
        this.index = index;
        this.axis = axis;

        canvas = js.Browser.document.createCanvasElement();
        ctx = canvas.getContext('2d');
        canvasBuffer = js.Browser.document.createCanvasElement();
        ctxBuffer = canvasBuffer.getContext('2d');

        updateGeometry();

        var canvasMap = new three.Texture(canvas);
        canvasMap.minFilter = three.LinearFilter;
        canvasMap.wrapS = canvasMap.wrapT = three.ClampToEdgeWrapping;
        canvasMap.colorSpace = three.SRGBColorSpace;
        var material = new three.MeshBasicMaterial({ map: canvasMap, side: three.DoubleSide, transparent: true });
        mesh = new three.Mesh(new three.PlaneGeometry(1, 1), material);
        mesh.matrixAutoUpdate = false;
        geometryNeedsUpdate = true;
        repaint();
    }

    private function set_index(value:Int):Int {
        index = value;
        geometryNeedsUpdate = true;
        return index;
    }

    public function repaint() {
        if (geometryNeedsUpdate) {
            updateGeometry();
        }

        var iLength = this.iLength;
        var jLength = this.jLength;
        var sliceAccess = this.sliceAccess;
        var volume = this.volume;
        var canvas = this.canvasBuffer;
        var ctx = this.ctxBuffer;

        // get the imageData and pixel array from the canvas
        var imgData = ctx.getImageData(0, 0, iLength, jLength);
        var data = imgData.data;
        var volumeData = volume.data;
        var upperThreshold = volume.upperThreshold;
        var lowerThreshold = volume.lowerThreshold;
        var windowLow = volume.windowLow;
        var windowHigh = volume.windowHigh;

        // manipulate some pixel elements
        var pixelCount = 0;

        if (volume.dataType == 'label') {
            // this part is currently useless but will be used when colortables will be handled
            for (j in 0...jLength) {
                for (i in 0...iLength) {
                    var label = volumeData[sliceAccess(i, j)];
                    label = label >= colorMap.length ? (label % colorMap.length) + 1 : label;
                    var color = colorMap[label];
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
                    // apply threshold
                    alpha = upperThreshold >= value ? (lowerThreshold <= value ? alpha : 0) : 0;
                    // apply window level
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
        ctx.drawImage(canvas, 0, 0, iLength, jLength, 0, 0, canvas.width, canvas.height);

        mesh.material.map.needsUpdate = true;
    }

    public function updateGeometry() {
        var extracted = volume.extractPerpendicularPlane(axis, index);
        sliceAccess = extracted.sliceAccess;
        jLength = extracted.jLength;
        iLength = extracted.iLength;
        matrix = extracted.matrix;

        canvas.width = extracted.planeWidth;
        canvas.height = extracted.planeHeight;
        canvasBuffer.width = iLength;
        canvasBuffer.height = jLength;
        ctx = canvasBuffer.getContext('2d');
        ctxBuffer = canvasBuffer.getContext('2d');

        if (geometry != null) geometry.dispose(); // dispose existing geometry

        geometry = new PlaneGeometry(extracted.planeWidth, extracted.planeHeight);

        if (mesh != null) {
            mesh.geometry = geometry;
            // reset mesh matrix
            mesh.matrix.identity();
            mesh.applyMatrix4(matrix);
        }

        geometryNeedsUpdate = false;
    }
}