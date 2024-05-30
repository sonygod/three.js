import three.NodeMaterial;
import three.addNodeMaterial;
import three.VarNode.temp;
import three.VaryingNode.varying;
import three.PropertyNode.property;
import three.AttributeNode.attribute;
import three.CameraNode.cameraProjectionMatrix;
import three.MaterialNode.materialColor;
import three.ModelNode.modelViewMatrix;
import three.PositionNode.positionGeometry;
import three.MathNode.mix;
import three.ShaderNode.tslFn;
import three.UVNode.uv;
import three.ViewportNode.viewport;
import three.PropertyNode.dashSize;

import three.LineDashedMaterial;

class Line2NodeMaterial extends NodeMaterial {

    public function new(params:Dynamic = {}) {
        super();

        this.normals = false;
        this.lights = false;

        this.setDefaultValues(new LineDashedMaterial());

        this.useAlphaToCoverage = true;
        this.useColor = params.vertexColors;
        this.useDash = params.dashed;
        this.useWorldUnits = false;

        this.dashOffset = 0;
        this.lineWidth = 1;

        this.lineColorNode = null;

        this.offsetNode = null;
        this.dashScaleNode = null;
        this.dashSizeNode = null;
        this.gapSizeNode = null;

        this.setValues(params);
    }

    public function setup(builder:Dynamic) {
        this.setupShaders();
        super.setup(builder);
    }

    public function setupShaders() {
        // ... 这里是 setupShaders 函数的代码，需要根据 JavaScript 代码进行转换
    }

    // ... 其他函数和属性，需要根据 JavaScript 代码进行转换
}

addNodeMaterial('Line2NodeMaterial', Line2NodeMaterial);