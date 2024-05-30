package three.js.lights;

import three.js.Color;
import three.js.LightProbe;
import three.js.SphericalHarmonics3;
import three.js.Vector3;
import three.js.LinearSRGBColorSpace;
import three.js.SRGBColorSpace;
import three.js.NoColorSpace;
import three.js.HalfFloatType;
import three.js.DataUtils;

class LightProbeGenerator {

    static public function fromCubeTexture(cubeTexture:Dynamic) {
        var totalWeight:Float = 0;

        var coord:Vector3 = new Vector3();

        var dir:Vector3 = new Vector3();

        var color:Color = new Color();

        var shBasis:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0, 0];

        var sh:SphericalHarmonics3 = new SphericalHarmonics3();
        var shCoefficients:Array<Vector3> = sh.coefficients;

        for (faceIndex in 0...6) {
            var image:Dynamic = cubeTexture.image[faceIndex];

            var width:Int = image.width;
            var height:Int = image.height;

            var canvas:Dynamic = js.Browser.document.createElement("canvas");
            canvas.width = width;
            canvas.height = height;

            var context:Dynamic = canvas.getContext("2d");
            context.drawImage(image, 0, 0, width, height);

            var imageData:Dynamic = context.getImageData(0, 0, width, height);
            var data:Array<Int> = imageData.data;

            var imageWidth:Int = imageData.width; // assumed to be square

            var pixelSize:Float = 2 / imageWidth;

            for (i in 0...data.length step 4) {
                color.setRGB(data[i] / 255, data[i + 1] / 255, data[i + 2] / 255);

                convertColorToLinear(color, cubeTexture.colorSpace);

                var pixelIndex:Int = i / 4;
                var col:Float = -1 + (pixelIndex % imageWidth + 0.5) * pixelSize;
                var row:Float = 1 - (Math.floor(pixelIndex / imageWidth) + 0.5) * pixelSize;

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

                var lengthSq:Float = coord.lengthSq();
                var weight:Float = 4 / (Math.sqrt(lengthSq) * lengthSq);

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

        var norm:Float = (4 * Math.PI) / totalWeight;

        for (j in 0...9) {
            shCoefficients[j].x *= norm;
            shCoefficients[j].y *= norm;
            shCoefficients[j].z *= norm;
        }

        return new LightProbe(sh);
    }

    static public function fromCubeRenderTarget(renderer:Dynamic, cubeRenderTarget:Dynamic) {
        var totalWeight:Float = 0;

        var coord:Vector3 = new Vector3();

        var dir:Vector3 = new Vector3();

        var color:Color = new Color();

        var shBasis:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0, 0];

        var sh:SphericalHarmonics3 = new SphericalHarmonics3();
        var shCoefficients:Array<Vector3> = sh.coefficients;

        var dataType:String = cubeRenderTarget.texture.type;

        for (faceIndex in 0...6) {
            var imageWidth:Int = cubeRenderTarget.width; // assumed to be square

            var data:Dynamic;

            if (dataType == HalfFloatType) {
                data = new Uint16Array(imageWidth * imageWidth * 4);
            } else {
                data = new Uint8Array(imageWidth * imageWidth * 4);
            }

            renderer.readRenderTargetPixels(cubeRenderTarget, 0, 0, imageWidth, imageWidth, data, faceIndex);

            var pixelSize:Float = 2 / imageWidth;

            for (i in 0...data.length step 4) {
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

                var pixelIndex:Int = i / 4;
                var col:Float = -1 + (pixelIndex % imageWidth + 0.5) * pixelSize;
                var row:Float = 1 - (Math.floor(pixelIndex / imageWidth) + 0.5) * pixelSize;

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

                var lengthSq:Float = coord.lengthSq();
                var weight:Float = 4 / (Math.sqrt(lengthSq) * lengthSq);

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

        var norm:Float = (4 * Math.PI) / totalWeight;

        for (j in 0...9) {
            shCoefficients[j].x *= norm;
            shCoefficients[j].y *= norm;
            shCoefficients[j].z *= norm;
        }

        return new LightProbe(sh);
    }

    static public function convertColorToLinear(color:Color, colorSpace:String) {
        switch (colorSpace) {
            case SRGBColorSpace:
                color.convertSRGBToLinear();
                break;
            case LinearSRGBColorSpace:
            case NoColorSpace:
                break;
            default:
                js.Lib.warn("WARNING: LightProbeGenerator convertColorToLinear() encountered an unsupported color space.");
                break;
        }
        return color;
    }
}