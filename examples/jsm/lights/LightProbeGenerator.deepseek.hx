import three.Color;
import three.LightProbe;
import three.LinearSRGBColorSpace;
import three.SphericalHarmonics3;
import three.Vector3;
import three.SRGBColorSpace;
import three.NoColorSpace;
import three.HalfFloatType;
import three.DataUtils;

class LightProbeGenerator {

    public static function fromCubeTexture(cubeTexture:Dynamic):LightProbe {

        var totalWeight = 0;

        var coord = new Vector3();

        var dir = new Vector3();

        var color = new Color();

        var shBasis = [0, 0, 0, 0, 0, 0, 0, 0, 0];

        var sh = new SphericalHarmonics3();
        var shCoefficients = sh.coefficients;

        for (faceIndex in 0...6) {

            var image = cubeTexture.image[faceIndex];

            var width = image.width;
            var height = image.height;

            var canvas = js.Browser.document.createElement('canvas');

            canvas.width = width;
            canvas.height = height;

            var context = canvas.getContext('2d');

            context.drawImage(image, 0, 0, width, height);

            var imageData = context.getImageData(0, 0, width, height);

            var data = imageData.data;

            var imageWidth = imageData.width; // assumed to be square

            var pixelSize = 2 / imageWidth;

            for (i in 0...data.length) { // RGBA assumed

                // pixel color
                color.setRGB(data[i] / 255, data[i + 1] / 255, data[i + 2] / 255);

                // convert to linear color space
                convertColorToLinear(color, cubeTexture.colorSpace);

                // pixel coordinate on unit cube

                var pixelIndex = i / 4;

                var col = -1 + (pixelIndex % imageWidth + 0.5) * pixelSize;

                var row = 1 - (Math.floor(pixelIndex / imageWidth) + 0.5) * pixelSize;

                switch (faceIndex) {

                    case 0: coord.set(-1, row, -col); break;

                    case 1: coord.set(1, row, col); break;

                    case 2: coord.set(-col, 1, -row); break;

                    case 3: coord.set(-col, -1, row); break;

                    case 4: coord.set(-col, row, 1); break;

                    case 5: coord.set(col, row, -1); break;

                }

                // weight assigned to this pixel

                var lengthSq = coord.lengthSq();

                var weight = 4 / (Math.sqrt(lengthSq) * lengthSq);

                totalWeight += weight;

                // direction vector to this pixel
                dir.copy(coord).normalize();

                // evaluate SH basis functions in direction dir
                SphericalHarmonics3.getBasisAt(dir, shBasis);

                // accummuulate
                for (j in 0...9) {

                    shCoefficients[j].x += shBasis[j] * color.r * weight;
                    shCoefficients[j].y += shBasis[j] * color.g * weight;
                    shCoefficients[j].z += shBasis[j] * color.b * weight;

                }

            }

        }

        // normalize
        var norm = (4 * Math.PI) / totalWeight;

        for (j in 0...9) {

            shCoefficients[j].x *= norm;
            shCoefficients[j].y *= norm;
            shCoefficients[j].z *= norm;

        }

        return new LightProbe(sh);

    }

    public static function fromCubeRenderTarget(renderer:Dynamic, cubeRenderTarget:Dynamic):LightProbe {

        // The renderTarget must be set to RGBA in order to make readRenderTargetPixels works
        var totalWeight = 0;

        var coord = new Vector3();

        var dir = new Vector3();

        var color = new Color();

        var shBasis = [0, 0, 0, 0, 0, 0, 0, 0, 0];

        var sh = new SphericalHarmonics3();
        var shCoefficients = sh.coefficients;

        var dataType = cubeRenderTarget.texture.type;

        for (faceIndex in 0...6) {

            var imageWidth = cubeRenderTarget.width; // assumed to be square

            var data:Array<Int>;

            if (dataType == HalfFloatType) {

                data = new Uint16Array(imageWidth * imageWidth * 4);

            } else {

                // assuming UnsignedByteType

                data = new Uint8Array(imageWidth * imageWidth * 4);

            }

            renderer.readRenderTargetPixels(cubeRenderTarget, 0, 0, imageWidth, imageWidth, data, faceIndex);

            var pixelSize = 2 / imageWidth;

            for (i in 0...data.length) { // RGBA assumed

                var r:Float, g:Float, b:Float;

                if (dataType == HalfFloatType) {

                    r = DataUtils.fromHalfFloat(data[i]);
                    g = DataUtils.fromHalfFloat(data[i + 1]);
                    b = DataUtils.fromHalfFloat(data[i + 2]);

                } else {

                    r = data[i] / 255;
                    g = data[i + 1] / 255;
                    b = data[i + 2] / 255;

                }

                // pixel color
                color.setRGB(r, g, b);

                // convert to linear color space
                convertColorToLinear(color, cubeRenderTarget.texture.colorSpace);

                // pixel coordinate on unit cube

                var pixelIndex = i / 4;

                var col = -1 + (pixelIndex % imageWidth + 0.5) * pixelSize;

                var row = 1 - (Math.floor(pixelIndex / imageWidth) + 0.5) * pixelSize;

                switch (faceIndex) {

                    case 0: coord.set(1, row, -col); break;

                    case 1: coord.set(-1, row, col); break;

                    case 2: coord.set(col, 1, -row); break;

                    case 3: coord.set(col, -1, row); break;

                    case 4: coord.set(col, row, 1); break;

                    case 5: coord.set(-col, row, -1); break;

                }

                // weight assigned to this pixel

                var lengthSq = coord.lengthSq();

                var weight = 4 / (Math.sqrt(lengthSq) * lengthSq);

                totalWeight += weight;

                // direction vector to this pixel
                dir.copy(coord).normalize();

                // evaluate SH basis functions in direction dir
                SphericalHarmonics3.getBasisAt(dir, shBasis);

                // accummuulate
                for (j in 0...9) {

                    shCoefficients[j].x += shBasis[j] * color.r * weight;
                    shCoefficients[j].y += shBasis[j] * color.g * weight;
                    shCoefficients[j].z += shBasis[j] * color.b * weight;

                }

            }

        }

        // normalize
        var norm = (4 * Math.PI) / totalWeight;

        for (j in 0...9) {

            shCoefficients[j].x *= norm;
            shCoefficients[j].y *= norm;
            shCoefficients[j].z *= norm;

        }

        return new LightProbe(sh);

    }

}

function convertColorToLinear(color:Color, colorSpace:String):Color {

    switch (colorSpace) {

        case SRGBColorSpace:

            color.convertSRGBToLinear();
            break;

        case LinearSRGBColorSpace:
        case NoColorSpace:

            break;

        default:

            js.Browser.console.warn('WARNING: LightProbeGenerator convertColorToLinear() encountered an unsupported color space.');
            break;

    }

    return color;

}