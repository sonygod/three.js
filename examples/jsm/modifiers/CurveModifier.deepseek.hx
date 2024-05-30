import three.DataTexture;
import three.DataUtils;
import three.RGBAFormat;
import three.HalfFloatType;
import three.RepeatWrapping;
import three.Mesh;
import three.InstancedMesh;
import three.LinearFilter;
import three.DynamicDrawUsage;
import three.Matrix4;

class CurveModifier {

    static var CHANNELS = 4;
    static var TEXTURE_WIDTH = 1024;
    static var TEXTURE_HEIGHT = 4;

    static function initSplineTexture(numberOfCurves:Int = 1):DataTexture {

        var dataArray = new Uint16Array(TEXTURE_WIDTH * TEXTURE_HEIGHT * numberOfCurves * CHANNELS);
        var dataTexture = new DataTexture(
            dataArray,
            TEXTURE_WIDTH,
            TEXTURE_HEIGHT * numberOfCurves,
            RGBAFormat,
            HalfFloatType
        );

        dataTexture.wrapS = RepeatWrapping;
        dataTexture.wrapY = RepeatWrapping;
        dataTexture.magFilter = LinearFilter;
        dataTexture.minFilter = LinearFilter;
        dataTexture.needsUpdate = true;

        return dataTexture;

    }

    static function updateSplineTexture(texture:DataTexture, splineCurve:Curve, offset:Int = 0) {

        var numberOfPoints = Math.floor(TEXTURE_WIDTH * (TEXTURE_HEIGHT / 4));
        splineCurve.arcLengthDivisions = numberOfPoints / 2;
        splineCurve.updateArcLengths();
        var points = splineCurve.getSpacedPoints(numberOfPoints);
        var frenetFrames = splineCurve.computeFrenetFrames(numberOfPoints, true);

        for (i in 0...numberOfPoints) {

            var rowOffset = Math.floor(i / TEXTURE_WIDTH);
            var rowIndex = i % TEXTURE_WIDTH;

            var pt = points[i];
            setTextureValue(texture, rowIndex, pt.x, pt.y, pt.z, 0 + rowOffset + (TEXTURE_HEIGHT * offset));
            pt = frenetFrames.tangents[i];
            setTextureValue(texture, rowIndex, pt.x, pt.y, pt.z, 1 + rowOffset + (TEXTURE_HEIGHT * offset));
            pt = frenetFrames.normals[i];
            setTextureValue(texture, rowIndex, pt.x, pt.y, pt.z, 2 + rowOffset + (TEXTURE_HEIGHT * offset));
            pt = frenetFrames.binormals[i];
            setTextureValue(texture, rowIndex, pt.x, pt.y, pt.z, 3 + rowOffset + (TEXTURE_HEIGHT * offset));

        }

        texture.needsUpdate = true;

    }

    static function setTextureValue(texture:DataTexture, index:Int, x:Float, y:Float, z:Float, o:Int) {

        var image = texture.image;
        var data = image.data;
        var i = CHANNELS * TEXTURE_WIDTH * o; // Row Offset
        data[index * CHANNELS + i + 0] = DataUtils.toHalfFloat(x);
        data[index * CHANNELS + i + 1] = DataUtils.toHalfFloat(y);
        data[index * CHANNELS + i + 2] = DataUtils.toHalfFloat(z);
        data[index * CHANNELS + i + 3] = DataUtils.toHalfFloat(1);

    }

    static function getUniforms(splineTexture:DataTexture) {

        var uniforms = {
            spineTexture: {value: splineTexture},
            pathOffset: {type: 'f', value: 0}, // time of path curve
            pathSegment: {type: 'f', value: 1}, // fractional length of path
            spineOffset: {type: 'f', value: 161},
            spineLength: {type: 'f', value: 400},
            flow: {type: 'i', value: 1},
        };
        return uniforms;

    }

    // ... 其他函数和类 ...

}