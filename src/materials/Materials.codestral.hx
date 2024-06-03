import three.js.src.materials.Material;
import three.js.src.materials.ShadowMaterial;
import three.js.src.materials.SpriteMaterial;
import three.js.src.materials.RawShaderMaterial;
import three.js.src.materials.ShaderMaterial;
import three.js.src.materials.PointsMaterial;
import three.js.src.materials.MeshPhysicalMaterial;
import three.js.src.materials.MeshStandardMaterial;
import three.js.src.materials.MeshPhongMaterial;
import three.js.src.materials.MeshToonMaterial;
import three.js.src.materials.MeshNormalMaterial;
import three.js.src.materials.MeshLambertMaterial;
import three.js.src.materials.MeshDepthMaterial;
import three.js.src.materials.MeshDistanceMaterial;
import three.js.src.materials.MeshBasicMaterial;
import three.js.src.materials.MeshMatcapMaterial;
import three.js.src.materials.LineDashedMaterial;
import three.js.src.materials.LineBasicMaterial;

class Materials {

    public static function getShadowMaterial(): ShadowMaterial {
        return new ShadowMaterial();
    }

    public static function getSpriteMaterial(): SpriteMaterial {
        return new SpriteMaterial();
    }

    public static function getRawShaderMaterial(): RawShaderMaterial {
        return new RawShaderMaterial();
    }

    public static function getShaderMaterial(): ShaderMaterial {
        return new ShaderMaterial();
    }

    public static function getPointsMaterial(): PointsMaterial {
        return new PointsMaterial();
    }

    public static function getMeshPhysicalMaterial(): MeshPhysicalMaterial {
        return new MeshPhysicalMaterial();
    }

    public static function getMeshStandardMaterial(): MeshStandardMaterial {
        return new MeshStandardMaterial();
    }

    public static function getMeshPhongMaterial(): MeshPhongMaterial {
        return new MeshPhongMaterial();
    }

    public static function getMeshToonMaterial(): MeshToonMaterial {
        return new MeshToonMaterial();
    }

    public static function getMeshNormalMaterial(): MeshNormalMaterial {
        return new MeshNormalMaterial();
    }

    public static function getMeshLambertMaterial(): MeshLambertMaterial {
        return new MeshLambertMaterial();
    }

    public static function getMeshDepthMaterial(): MeshDepthMaterial {
        return new MeshDepthMaterial();
    }

    public static function getMeshDistanceMaterial(): MeshDistanceMaterial {
        return new MeshDistanceMaterial();
    }

    public static function getMeshBasicMaterial(): MeshBasicMaterial {
        return new MeshBasicMaterial();
    }

    public static function getMeshMatcapMaterial(): MeshMatcapMaterial {
        return new MeshMatcapMaterial();
    }

    public static function getLineDashedMaterial(): LineDashedMaterial {
        return new LineDashedMaterial();
    }

    public static function getLineBasicMaterial(): LineBasicMaterial {
        return new LineBasicMaterial();
    }

    public static function getMaterial(): Material {
        return new Material();
    }
}


This code creates a `Materials` class that provides static methods to create new instances of the different material classes. You can call these methods like this:


var material: Material = Materials.getMaterial();
var standardMaterial: MeshStandardMaterial = Materials.getMeshStandardMaterial();
// ... and so on