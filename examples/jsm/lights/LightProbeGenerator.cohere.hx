import js.three.Color;
import js.three.DataUtils;
import js.three.HalfFloatType;
import js.three.LightProbe;
import js.three.LinearSRGBColorSpace;
import js.three.NoColorSpace;
import js.three.SphericalHarmonics3;
import js.three.SRGBColorSpace;
import js.three.Vector3;

class LightProbeGenerator {
    public static function fromCubeTexture(cubeTexture:CubeTexture):LightProbe {
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
            var canvas = untyped __js__("document.createElement('canvas')");
            canvas.width = width;
            canvas.height = height;
            var context = untyped __js__("canvas.getContext('2d')");
            context.drawImage(image, 0, 0, width, height);
            var imageData = untyped __js__("context.getImageData(0, 0, width, height)");
            var data = imageData.data;
            var imageWidth = imageData.width;
            var pixelSize = 2 / imageWidth;

            for (i in 0...Std.int(data.length) by 4) {
                color.setRGB(data[i] / 255, data[i + 1] / 255, data[i + 2] / 255);
                convertColorToLinear(color, cubeTexture.colorSpace);

                var pixelIndex = i / 4;
                var col = -1 + (pixelIndex % imageWidth + 0.5) * pixelSize;
                var row = 1 - (Std.int(pixelIndex / imageWidth) + 0.5) * pixelSize;

                switch (faceIndex) {
                    case 0:
                        coord.set(-1, row, -col);
                        break;
                    case 1:
                        coord.set(1, row, col);
                        break;
                    case 2:
                        coord.set(-col, 1, -row);
                        break;
                    case 3:
                        coord.set(-col, -1, row);
                        break;
                    case 4:
                        coord.set(-col, row, 1);
                        break;
                    case 5:
                        coord.set(col, row, -1);
                        break;
                }

                var lengthSq = coord.lengthSq();
                var weight = 4 / (Math.sqrt(lengthSq) * lengthSq);
                totalWeight += weight;

                dir.copy(coord).normalize();
                SphericalHarmonics3.getBasisAt(dir, shBasis);

                for (j in 0...9) {
                    shCoefficients[j].x += shBasis[j] * color.r * weight;
                    shCoefficients[j].y += shBasis[j] * color.g * weight;
                    shCoefficients[j].z += shBasis[j] * color.b * weight;
                }
            }
        }

        var norm = (4 * Math.PI) / totalWeight;
        for (j in 0...9) {
            shCoefficients[j].x *= norm;
            shCoefficients[j].y *= norm;
            shCoefficients[j].z *= norm;
        }

        return new LightProbe(sh);
    }

    public static function fromCubeRenderTarget(renderer:WebGLRenderer, cubeRenderTarget:WebGLRenderTarget):LightProbe {
        var totalWeight = 0;
        var coord = new Vector3();
        var dir = new Vector3();
        var color = new Color();
        var shBasis = [0, 0, 0, 0, 0, 0, 0, 0, 0];
        var sh = new SphericalHarmonics3();
        var shCoefficients = sh.coefficients;
        var dataType = cubeRenderTarget.texture.type;

        for (faceIndex in 0...6) {
            var imageWidth = cubeRenderTarget.width;
            var data:Dynamic;

            if (dataType == HalfFloatType) {
                data = new Uint16Array(imageWidth * imageWidth * 4);
            } else {
                data = new Uint8Array(imageWidth * imageWidth * 4);
            }

            renderer.readRenderTargetPixels(cubeRenderTarget, 0, 0, imageWidth, imageWidth, data, faceIndex);
            var pixelSize = 2 / imageWidth;

            for (i in 0...Std.int(data.length) by 4) {
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

                color.setRGB(r, g, b);
                convertColorToLinear(color, cubeRenderTarget.texture.colorSpace);

                var pixelIndex = i / 4;
                var col = -1 + (pixelIndex % imageWidth + 0.5) * pixelSize;
                var row = 1 - (Std.int(pixelIndex / imageWidth) + 0.5) * pixelSize;

                switch (faceIndex) {
                    case 0:
                        coord.set(1, row, -col);
                        break;
                    case 1:
                        coord.set(-1, row, col);
                        break;
                    case 2:
                        coord.set(col, 1, -row);
                        break;
                    case 3:
                        coord.set(col, -1, row);
                        break;
                    case 4:
                        coord.set(col, row, 1);
                        break;
                    case 5:
                        coord.set(-col, row, -1);
                        break;
                }

                var lengthSq = coord.lengthSq();
                var weight = 4 / (Math.sqrt(lengthSq) * lengthSq);
                totalWeight += weight;

                dir.copy(coord).normalize();
                SphericalHarmonics3.getBasisAt(dir, shBasis);

                for (j in 0...9) {
                    shCoefficients[j].x += shBasis[j] * color.r * weight;
                    shCoefficients[j].y += shBasis[j] * color.g * weight;
                    shCoefficients[j].z += shBasis[j] * color.b * weight;
                }
            }
        }

        var norm = (4 * Math.PI) / totalWeight;
        for (j in 0...9) {
            shCoefficients[j].x *= norm;
            shCoefficients[j].y *= norm;
            shCoefficients[j].z *= norm;
        }

        return new LightProbe(sh);
    }
}

function convertColorToLinear(color:Color, colorSpace:Int) {
    switch (colorSpace) {
        case SRGBColorSpace:
            color.convertSRGBToLinear();
            break;
        case LinearSRGBColorSpace:
        case NoColorSpace:
            break;
        default:
            trace("WARNING: LightProbeGenerator convertColorToLinear() encountered an unsupported color space.");
            break;
    }

    return color;
}