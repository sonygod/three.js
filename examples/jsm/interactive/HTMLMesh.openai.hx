package three.js.examples.jsm.interactive;

import three.js.CanvasTexture;
import three.js.LinearFilter;
import three.js.Mesh;
import three.js.MeshBasicMaterial;
import three.js.PlaneGeometry;
import three.js.SRGBColorSpace;
import three.js.Color;

class HTMLMesh extends Mesh {

    public function new(dom:Dynamic) {
        var texture:CanvasTexture = new HTMLTexture(dom);
        var geometry:PlaneGeometry = new PlaneGeometry(texture.image.width * 0.001, texture.image.height * 0.001);
        var material:MeshBasicMaterial = new MeshBasicMaterial({map: texture, toneMapped: false, transparent: true});

        super(geometry, material);

        function onEvent(event:Dynamic) {
            material.map.dispatchDOMEvent(event);
        }

        this.addEventListener('mousedown', onEvent);
        this.addEventListener('mousemove', onEvent);
        this.addEventListener('mouseup', onEvent);
        this.addEventListener('click', onEvent);

        this.dispose = function() {
            geometry.dispose();
            material.dispose();

            material.map.dispose();

            canvases.remove(dom);

            this.removeEventListener('mousedown', onEvent);
            this.removeEventListener('mousemove', onEvent);
            this.removeEventListener('mouseup', onEvent);
            this.removeEventListener('click', onEvent);
        };
    }
}

class HTMLTexture extends CanvasTexture {

    public var dom:Dynamic;
    public var observer:MutationObserver;

    public function new(dom:Dynamic) {
        super(html2canvas(dom));

        this.dom = dom;

        this.anisotropy = 16;
        this.colorSpace = SRGBColorSpace;
        this.minFilter = LinearFilter;
        this.magFilter = LinearFilter;

        observer = new MutationObserver(function() {
            if (!this.scheduleUpdate) {
                this.scheduleUpdate = setTimeout(() => this.update(), 16);
            }
        });

        var config = { attributes: true, childList: true, subtree: true, characterData: true };
        observer.observe(dom, config);
    }

    public function dispatchDOMEvent(event:Dynamic) {
        if (event.data) {
            htmlevent(dom, event.type, event.data.x, event.data.y);
        }
    }

    public function update() {
        this.image = html2canvas(dom);
        this.needsUpdate = true;

        this.scheduleUpdate = null;
    }

    public function dispose() {
        if (observer != null) {
            observer.disconnect();
        }

        this.scheduleUpdate = clearTimeout(this.scheduleUpdate);

        super.dispose();
    }
}

// ...

var canvases:WeakMap<Dynamic, Dynamic> = new WeakMap<Dynamic, Dynamic>();

function html2canvas(element:Dynamic) {
    // implementation of html2canvas function
}

// ...