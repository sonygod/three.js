package three.js.misc;

import three.Matrix3;
import three.Matrix4;
import three.Vector3;

class Volume {
    public var xLength:Int;
    public var yLength:Int;
    public var zLength:Int;
    public var axisOrder:Array<String>;
    public var data:Dynamic; // TypedArray
    public var spacing:Array<Float>;
    public var offset:Array<Float>;
    public var matrix:Matrix3;
    public var inverseMatrix:Matrix3;
    public var lowerThreshold:Float;
    public var upperThreshold:Float;
    public var sliceList:Array<VolumeSlice>;
    public var segmentation:Bool;
    public var RASDimensions:Array<Float>;

    public function new(xLength:Int, yLength:Int, zLength:Int, type:String, arrayBuffer:js.lib.Uint8Array) {
        if (xLength != null) {
            this.xLength = xLength;
            this.yLength = yLength;
            this.zLength = zLength;
            this.axisOrder = ['x', 'y', 'z'];
            switch (type) {
                case 'Uint8', 'uint8', 'uchar', 'unsigned char', 'uint8_t':
                    data = new js.lib.Uint8Array(arrayBuffer);
                case 'Int8', 'int8', 'signed char', 'int8_t':
                    data = new js.lib.Int8Array(arrayBuffer);
                case 'Int16', 'int16', 'short', 'short int', 'signed short', 'int16_t':
                    data = new js.lib.Int16Array(arrayBuffer);
                case 'Uint16', 'uint16', 'ushort', 'unsigned short', 'uint16_t':
                    data = new js.lib.Uint16Array(arrayBuffer);
                case 'Int32', 'int32', 'int', 'signed int', 'int32_t':
                    data = new js.lib.Int32Array(arrayBuffer);
                case 'Uint32', 'uint32', 'uint', 'unsigned int', 'uint32_t':
                    data = new js.lib.Uint32Array(arrayBuffer);
                case 'Float32', 'float32', 'float':
                    data = new js.lib.Float32Array(arrayBuffer);
                case 'Float64', 'float64', 'double':
                    data = new js.lib.Float64Array(arrayBuffer);
                default:
                    throw new js.Error('Error in Volume constructor, unsupported type: ' + type);
            }

            if (data.length != xLength * yLength * zLength) {
                throw new js.Error('Error in Volume constructor, lengths are not matching arrayBuffer size');
            }

            spacing = [1, 1, 1];
            offset = [0, 0, 0];
            matrix = new Matrix3();
            matrix.identity();
            inverseMatrix = matrix.clone().invert();
            lowerThreshold = -Math.POSITIVE_INFINITY;
            upperThreshold = Math.POSITIVE_INFINITY;
            sliceList = new Array<VolumeSlice>();
            segmentation = false;
            RASDimensions = [xLength, yLength, zLength];
        }
    }

    public function getData(i:Int, j:Int, k:Int):Float {
        return data[k * xLength * yLength + j * xLength + i];
    }

    public function access(i:Int, j:Int, k:Int):Int {
        return k * xLength * yLength + j * xLength + i;
    }

    public function reverseAccess(index:Int):Array<Int> {
        var z = Math.floor(index / (yLength * xLength));
        var y = Math.floor((index - z * yLength * xLength) / xLength);
        var x = index - z * yLength * xLength - y * xLength;
        return [x, y, z];
    }

    public function map(functionToMap:Dynamic->Int->js.lib.TypedArray->Void, context:Dynamic = null):Volume {
        var length = data.length;
        context = context == null ? this : context;
        for (i in 0...length) {
            data[i] = functionToMap(data[i], i, data);
        }
        return this;
    }

    public function extractPerpendicularPlane(axis:String, RASIndex:Int):Dynamic {
        // ... ( omitted )
    }

    public function extractSlice(axis:String, index:Int):VolumeSlice {
        var slice = new VolumeSlice(this, index, axis);
        sliceList.push(slice);
        return slice;
    }

    public function repaintAllSlices():Volume {
        for (slice in sliceList) {
            slice.repaint();
        }
        return this;
    }

    public function computeMinMax():Array<Float> {
        var min = Math.POSITIVE_INFINITY;
        var max = Math.NEGATIVE_INFINITY;
        for (i in 0...data.length) {
            var value = data[i];
            if (!Math.isNaN(value)) {
                min = Math.min(min, value);
                max = Math.max(max, value);
            }
        }
        this.min = min;
        this.max = max;
        return [min, max];
    }
}