import three.js.examples.jsm.effects.OutlineEffect;
import three.js.examples.jsm.effects.OutlineEffectParameters;
import three.js.examples.jsm.effects.OutlineEffectRenderer;
import three.js.examples.jsm.effects.OutlineEffectScene;
import three.js.examples.jsm.effects.OutlineEffectCamera;
import three.js.examples.jsm.effects.OutlineEffectMaterial;
import three.js.examples.jsm.effects.OutlineEffectObject;

class Main {
    static function main() {
        var renderer = new OutlineEffectRenderer();
        var parameters = new OutlineEffectParameters();
        var effect = new OutlineEffect(renderer, parameters);
        var scene = new OutlineEffectScene();
        var camera = new OutlineEffectCamera();
        var material = new OutlineEffectMaterial();
        var object = new OutlineEffectObject();

        // Set default outline parameters
        parameters.defaultThickness = 0.01;
        parameters.defaultColor = [0, 0, 0];
        parameters.defaultAlpha = 0.8;
        parameters.defaultKeepAlive = true;

        // Set outline parameters for each material
        material.userData.outlineParameters = {
            thickness: 0.01,
            color: [0, 0, 0],
            alpha: 0.8,
            visible: true,
            keepAlive: true
        };

        // Traditional usage
        effect.render(scene, camera);

        // VR compatible usage
        scene.onAfterRender = function() {
            if (renderingOutline) return;
            renderingOutline = true;
            effect.renderOutline(scene, camera);
            renderingOutline = false;
        };

        function render() {
            renderer.render(scene, camera);
        }
    }
}