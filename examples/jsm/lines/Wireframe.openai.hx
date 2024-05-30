package three.js.examples.jsm.lines;

import three.js.Lib;
import three.jsInstancedInterleavedBuffer;
import three.jsInterleavedBufferAttribute;
import three.jsMesh;
import three.jsVector3;
import three.jsVector4;
import three.js.lines.LineSegmentsGeometry;
import three.js.lines.LineMaterial;

class Wireframe extends Mesh {
    public var isWireframe:Bool;
    public var type:String;

    public function new(?geometry:LineSegmentsGeometry, ?material:LineMaterial) {
        if (geometry == null) geometry = new LineSegmentsGeometry();
        if (material == null) material = new LineMaterial({ color: Math.random() * 0xFFFFFF });
        super(geometry, material);
        isWireframe = true;
        type = 'Wireframe';
    }

    public function computeLineDistances():Wireframe {
        var geometry:LineSegmentsGeometry = cast geometry;
        var instanceStart = geometry.attributes.get("instanceStart");
        var instanceEnd = geometry.attributes.get("instanceEnd");
        var lineDistances = new Float32Array(2 * instanceStart.count);

        for (i in 0...instanceStart.count) {
            _start.fromBufferAttribute(instanceStart, i);
            _end.fromBufferAttribute(instanceEnd, i);
            lineDistances[i * 2] = (i == 0) ? 0 : lineDistances[i * 2 - 1];
            lineDistances[i * 2 + 1] = lineDistances[i * 2] + _start.distanceTo(_end);
        }

        var instanceDistanceBuffer = new InstancedInterleavedBuffer(lineDistances, 2, 1);
        geometry.setAttribute("instanceDistanceStart", new InterleavedBufferAttribute(instanceDistanceBuffer, 1, 0));
        geometry.setAttribute("instanceDistanceEnd", new InterleavedBufferAttribute(instanceDistanceBuffer, 1, 1));
        return this;
    }

    public function onBeforeRender(renderer:Dynamic):Void {
        var uniforms:Dynamic = material.uniforms;
        if (uniforms && uniforms.resolution) {
            renderer.getViewport(_viewport);
            uniforms.resolution.value.set(_viewport.z, _viewport.w);
        }
    }
}

static var _start:Vector3 = new Vector3();
static var _end:Vector3 = new Vector3();
static var _viewport:Vector4 = new Vector4();