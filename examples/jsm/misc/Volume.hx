package three.js.examples.jsm.misc;

import haxe.ds.Vector;
import haxe.io.Bytes;
import three.Matrix3;
import three.Matrix4;
import three.Vector3;

class Volume {
    public var xLength(default, null):Int;
    public var yLength(default, null):Int;
    public var zLength(default, null):Int;
    public var axisOrder(default, null):Array<String>;
    public var data(default, null):Bytes;
    public var spacing(default, null):Array<Float>;
    public var offset(default, null):Array<Float>;
    public var matrix(default, null):Matrix3;
    public var inverseMatrix(default, null):Matrix3;
    public var lowerThreshold(default, null):Float;
    public var upperThreshold(default, null):Float;
    public var sliceList(default, null):Array<VolumeSlice>;
    public var segmentation(default, null):Bool;
    public var RASDimensions(default, null):Vector3;

    public function new(xLength:Int, yLength:Int, zLength:Int, type:String, arrayBuffer:Bytes) {
        if (xLength != null) {
            this.xLength = xLength;
            this.yLength = yLength;
            this.zLength = zLength;
            this.axisOrder = ['x', 'y', 'z'];
            this.spacing = [1, 1, 1];
            this.offset = [0, 0, 0];
            this.matrix = new Matrix3();
            this.matrix.identity();
            this.inverseMatrix = new Matrix3();
            this.inverseMatrix.copy(this.matrix);
            this.inverseMatrix.invert();

            switch (type) {
                case 'Uint8':
                case 'uint8':
                case 'uchar':
                case 'unsigned char':
                case 'uint8_t':
                    data = new Bytes(arrayBuffer.length);
                    for (i in 0...arrayBuffer.length) {
                        data.set(i, arrayBuffer.get(i));
                    }
                    break;
                case 'Int8':
                case 'int8':
                case 'signed char':
                case 'int8_t':
                    data = new Bytes(arrayBuffer.length);
                    for (i in 0...arrayBuffer.length) {
                        data.set(i, arrayBuffer.get(i));
                    }
                    break;
                case 'Int16':
                case 'int16':
                case 'short':
                case 'short int':
                case 'signed short':
                case 'signed short int':
                case 'int16_t':
                    data = new Bytes(arrayBuffer.length);
                    for (i in 0...arrayBuffer.length) {
                        data.set(i, arrayBuffer.get(i));
                    }
                    break;
                case 'Uint16':
                case 'uint16':
                case 'ushort':
                case 'unsigned short':
                case 'unsigned short int':
                case 'uint16_t':
                    data = new Bytes(arrayBuffer.length);
                    for (i in 0...arrayBuffer.length) {
                        data.set(i, arrayBuffer.get(i));
                    }
                    break;
                case 'Int32':
                case 'int32':
                case 'int':
                case 'signed int':
                case 'int32_t':
                    data = new Bytes(arrayBuffer.length);
                    for (i in 0...arrayBuffer.length) {
                        data.set(i, arrayBuffer.get(i));
                    }
                    break;
                case 'Uint32':
                case 'uint32':
                case 'uint':
                case 'unsigned int':
                case 'uint32_t':
                    data = new Bytes(arrayBuffer.length);
                    for (i in 0...arrayBuffer.length) {
                        data.set(i, arrayBuffer.get(i));
                    }
                    break;
                case 'Float32':
                case 'float32':
                case 'float':
                    data = new Bytes(arrayBuffer.length);
                    for (i in 0...arrayBuffer.length) {
                        data.set(i, arrayBuffer.get(i));
                    }
                    break;
                case 'Float64':
                case 'float64':
                case 'double':
                    data = new Bytes(arrayBuffer.length);
                    for (i in 0...arrayBuffer.length) {
                        data.set(i, arrayBuffer.get(i));
                    }
                    break;
                default:
                    data = new Bytes(arrayBuffer.length);
                    for (i in 0...arrayBuffer.length) {
                        data.set(i, arrayBuffer.get(i));
                    }
            }

            if (data.length != xLength * yLength * zLength) {
                throw new Error('Error in Volume constructor, lengths are not matching arrayBuffer size');
            }

            this.lowerThreshold = -Math.POSITIVE_INFINITY;
            this.upperThreshold = Math.POSITIVE_INFINITY;
            this.sliceList = new Array<VolumeSlice>();

            Reflect.setProperty(this, 'lowerThreshold', {
                get: function() {
                    return lowerThreshold;
                },
                set: function(value) {
                    lowerThreshold = value;
                    for (slice in sliceList) {
                        slice.geometryNeedsUpdate = true;
                    }
                }
            });

            Reflect.setProperty(this, 'upperThreshold', {
                get: function() {
                    return upperThreshold;
                },
                set: function(value) {
                    upperThreshold = value;
                    for (slice in sliceList) {
                        slice.geometryNeedsUpdate = true;
                    }
                }
            });
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

    public function map(functionToMap:Float->Int->Bytes->Float, context:Dynamic = null):Volume {
        var length = data.length;
        context = context != null ? context : this;
        for (i in 0...length) {
            data.set(i, functionToMap(data.get(i), i, data));
        }
        return this;
    }

    public function extractPerpendicularPlane(axis:String, RASIndex:Int):Dynamic {
        var firstSpacing:Float, secondSpacing:Float, positionOffset:Float, IJKIndex:Vector3;

        switch (axis) {
            case 'x':
                // ...
                break;
            case 'y':
                // ...
                break;
            case 'z':
                // ...
                break;
        }

        // ...
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
            var value = data.get(i);
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

class VolumeSlice {
    public function new(volume:Volume, index:Int, axis:String) {}
    public function repaint() {}
}