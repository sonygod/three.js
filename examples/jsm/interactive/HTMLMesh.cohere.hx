import js.html.CanvasTexture;
import js.html.LinearFilter;
import js.html.Mesh;
import js.html.MeshBasicMaterial;
import js.html.PlaneGeometry;
import js.html.SRGBColorSpace;
import js.html.Color;

class HTMLMesh extends Mesh {
    public function new(dom:Dynamic) {
        var texture = new HTMLTexture(dom);
        var geometry = new PlaneGeometry(texture.image.width * 0.001, texture.image.height * 0.001);
        var material = new MeshBasicMaterial(#map = texture, #toneMapped = false, #transparent = true);
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
            canvases.delete(dom);
            this.removeEventListener('mousedown', onEvent);
            this.removeEventListener('mousemove', onEvent);
            this.removeEventListener('mouseup', onEvent);
            this.removeEventListener('click', onEvent);
        };
    }
}

class HTMLTexture extends CanvasTexture {
    public function new(dom:Dynamic) {
        super(html2canvas(dom));
        this.dom = dom;
        this.anisotropy = 16;
        this.colorSpace = SRGBColorSpace;
        this.minFilter = LinearFilter;
        this.magFilter = LinearFilter;

        var observer = new MutationObserver(function() {
            if (!this.scheduleUpdate) {
                this.scheduleUpdate = Sys.setTimeout(function() this.update(), 16);
            }
        });

        var config = { attributes: true, childList: true, subtree: true, characterData: true };
        observer.observe(dom, config);
        this.observer = observer;
    }

    public function dispatchDOMEvent(event:Dynamic) {
        if (event.data) {
            htmlevent(this.dom, event.type, event.data.x, event.data.y);
        }
    }

    public function update() {
        this.image = html2canvas(this.dom);
        this.needsUpdate = true;
        this.scheduleUpdate = null;
    }

    public function dispose() {
        if (this.observer) {
            this.observer.disconnect();
        }
        this.scheduleUpdate = Sys.clearTimeout(this.scheduleUpdate);
        super.dispose();
    }
}

var canvases = new WeakMap<Dynamic,Dynamic>();

function html2canvas(element:Dynamic):Dynamic {
    var range = document.createRange();
    var color = new Color();

    class Clipper {
        var clips:Array<Dynamic>;
        var isClipping:Bool;

        public function new(context:Dynamic) {
            clips = [];
            isClipping = false;
        }

        function doClip() {
            if (isClipping) {
                isClipping = false;
                context.restore();
            }

            if (clips.length == 0) {
                return;
            }

            var minX = -Infinity;
            var minY = -Infinity;
            var maxX = Infinity;
            var maxY = Infinity;

            for (i in 0...clips.length) {
                var clip = clips[i];
                minX = Math.max(minX, clip.x);
                minY = Math.max(minY, clip.y);
                maxX = Math.min(maxX, clip.x + clip.width);
                maxY = Math.min(maxY, clip.y + clip.height);
            }

            context.save();
            context.beginPath();
            context.rect(minX, minY, maxX - minX, maxY - minY);
            context.clip();
            isClipping = true;
        }

        public function add(clip:Dynamic) {
            clips.push(clip);
            doClip();
        }

        public function remove() {
            clips.pop();
            doClip();
        }
    }

    function drawText(style:Dynamic, x:Float, y:Float, string:String) {
        if (string != '') {
            if (style.textTransform == 'uppercase') {
                string = string.toUpperCase();
            }

            context.font = style.fontWeight + ' ' + style.fontSize + ' ' + style.fontFamily;
            context.textBaseline = 'top';
            context.fillStyle = style.color;
            context.fillText(string, x, y + Std.parseFloat(style.fontSize) * 0.1);
        }
    }

    function buildRectPath(x:Float, y:Float, w:Float, h:Float, r:Float) {
        if (w < 2 * r) {
            r = w / 2;
        }
        if (h < 2 * r) {
            r = h / 2;
        }

        context.beginPath();
        context.moveTo(x + r, y);
        context.arcTo(x + w, y, x + w, y + h, r);
        context.arcTo(x + w, y + h, x, y + h, r);
        context.arcTo(x, y + h, x, y, r);
        context.arcTo(x, y, x + w, y, r);
        context.closePath();
    }

    function drawBorder(style:Dynamic, which:String, x:Float, y:Float, width:Float, height:Float) {
        var borderWidth = style[which + 'Width'];
        var borderStyle = style[which + 'Style'];
        var borderColor = style[which + 'Color'];

        if (borderWidth != '0px' && borderStyle != 'none' && borderColor != 'transparent' && borderColor != 'rgba(0, 0, 0, 0)') {
            context.strokeStyle = borderColor;
            context.lineWidth = Std.parseFloat(borderWidth);
            context.beginPath();
            context.moveTo(x, y);
            context.lineTo(x + width, y + height);
            context.stroke();
        }
    }

    function drawElement(element:Dynamic, style:Dynamic) {
        if (element.nodeType == Node.COMMENT_NODE || element.nodeName == 'SCRIPT' || (element.style && element.style.display == 'none')) {
            return;
        }

        var x = 0.0;
        var y = 0.0;
        var width = 0.0;
        var height = 0.0;

        if (element.nodeType == Node.TEXT_NODE) {
            range.selectNode(element);
            var rect = range.getBoundingClientRect();
            x = rect.left - offset.left - 0.5;
            y = rect.top - offset.top - 0.5;
            width = rect.width;
            height = rect.height;
            drawText(style, x, y, element.nodeValue.trim());
        } else if (Type.enumIndex(element) == HTMLCanvasElement) {
            var rect = element.getBoundingClientRect();
            x = rect.left - offset.left - 0.5;
            y = rect.top - offset.top - 0.5;
            context.save();
            var dpr = window.devicePixelRatio;
            context.scale(1 / dpr, 1 / dpr);
            context.drawImage(element, x, y);
            context.restore();
        } else if (Type.enumIndex(element) == HTMLImageElement) {
            var rect = element.getBoundingClientRect();
            x = rect.left - offset.left - 0.5;
            y = rect.top - offset.top - 0.5;
            width = rect.width;
            height = rect.height;
            context.drawImage(element, x, y, width, height);
        } else {
            var rect = element.getBoundingClientRect();
            x = rect.left - offset.left - 0.5;
            y = rect.top - offset.top - 0.5;
            width = rect.width;
            height = rect.height;
            style = window.getComputedStyle(element);

            buildRectPath(x, y, width, height, Std.parseFloat(style.borderRadius));

            var backgroundColor = style.backgroundColor;
            if (backgroundColor != 'transparent' && backgroundColor != 'rgba(0, 0, 0, 0)') {
                context.fillStyle = backgroundColor;
                context.fill();
            }

            var borders = ['borderTop', 'borderLeft', 'borderBottom', 'borderRight'];
            var match = true;
            var prevBorder = null;

            for (border in borders) {
                if (prevBorder != null) {
                    match = (style[border + 'Width'] == style[prevBorder + 'Width']) &&
                        (style[border + 'Color'] == style[prevBorder + 'Color']) &&
                        (style[border + 'Style'] == style[prevBorder + 'Style']);
                }

                if (!match) {
                    break;
                }

                prevBorder = border;
            }

            if (match) {
                var width = Std.parseFloat(style.borderTopWidth);
                if (style.borderTopWidth != '0px' && style.borderTopStyle != 'none' && style.borderTopColor != 'transparent' && style.borderTopColor != 'rgba(0, 0, 0, 0)') {
                    context.strokeStyle = style.borderTopColor;
                    context.lineWidth = width;
                    context.stroke();
                }
            } else {
                drawBorder(style, 'borderTop', x, y, width, 0);
                drawBorder(style, 'borderLeft', x, y, 0, height);
                drawBorder(style, 'borderBottom', x, y + height, width, 0);
                drawBorder(style, 'borderRight', x + width, y, 0, height);
            }

            if (Type.enumIndex(element) == HTMLInputElement) {
                var accentColor = style.accentColor;
                if (accentColor == null || accentColor == 'auto') {
                    accentColor = style.color;
                }

                color.set(accentColor);
                var luminance = Math.sqrt(0.299 * (color.r ** 2) + 0.587 * (color.g ** 2) + 0.114 * (color.b ** 2));
                var accentTextColor = luminance < 0.5 ? 'white' : '#111111';

                if (element.type == 'radio') {
                    buildRectPath(x, y, width, height, height);
                    context.fillStyle = 'white';
                    context.strokeStyle = accentColor;
                    context.lineWidth = 1;
                    context.fill();
                    context.stroke();

                    if (element.checked) {
                        buildRectPath(x + 2, y + 2, width - 4, height - 4, height);
                        context.fillStyle = accentColor;
                        context.strokeStyle = accentTextColor;
                        context.lineWidth = 2;
                        context.fill();
                        context.stroke();
                    }
                }

                if (element.type == 'checkbox') {
                    buildRectPath(x, y, width, height, 2);
                    context.fillStyle = if (element.checked) accentColor else 'white';
                    context.strokeStyle = if (element.checked) accentTextColor else accentColor;
                    context.lineWidth = 1;
                    context.stroke();
                    context.fill();

                    if (element.checked) {
                        var currentTextAlign = context.textAlign;
                        context.textAlign = 'center';
                        var properties = {
                            color: accentTextColor,
                            fontFamily: style.fontFamily,
                            fontSize: height + 'px',
                            fontWeight: 'bold'
                        };
                        drawText(properties, x + (width / 2), y, '✔');
                        context.textAlign = currentTextAlign;
                    }
                }

                if (element.type == 'range') {
                    var min = Std.parseFloat(element.min);
                    var max = Std.parseFloat(element.max);
                    var value = Std.parseFloat(element.value);
                    var position = ((value - min) / (max - min)) * (width - height);

                    buildRectPath(x, y + (height / 4), width, height / 2, height / 4);
                    context.fillStyle = accentTextColor;
                    context.strokeStyle = accentColor;
                    context.lineWidth = 1;
                    context.fill();
                    context.stroke();

                    buildRectPath(x, y + (height / 4), position + (height / 2), height / 2, height / 4);
                    context.fillStyle = accentColor;
                    context.fill();

                    buildRectPath(x + position, y, height, height, height / 2);
                    context.fillStyle = accentColor;
                    context.fill();
                }

                if (element.type == 'color' || element.type == 'text' || element.type == 'number') {
                    clipper.add({ x: x, y: y, width: width, height: height });
                    drawText(style, x + Std.parseInt(style.paddingLeft), y + Std.parseInt(style.paddingTop), element.value);
                    clipper.remove();
                }
            }
        }

        var isClipping = style.overflow == 'auto' || style.overflow == 'hidden';
        if (isClipping) {
            clipper.add({ x: x, y: y, width: width, height: height });
        }

        for (i in 0...element.childNodes.length) {
            drawElement(element.childNodes[i], style);
        }

        if (isClipping) {
            clipper.remove();
        }
    }

    var offset = element.getBoundingClientRect();
    var canvas = canvases.get(element);
    if (canvas == null) {
        canvas = document.createElement('canvas');
        canvas.width = offset.width;
        canvas.height = offset.height;
        canvases.set(element, canvas);
    }

    var context = canvas.getContext('2d');
    var clipper = new Clipper(context);

    context.clearRect(0, 0, canvas.width, canvas.height);
    drawElement(element);

    return canvas;
}

function htmlevent(element:Dynamic, event:String, x:Float, y:Float) {
    var mouseEventInit = {
        clientX: (x * element.offsetWidth) + element.offsetLeft,
        clientY: (y * element.offsetHeight) + element.offsetTop,
        view: element.ownerDocument.defaultView
    };

    window.dispatchEvent(new MouseEvent(event, mouseEventInit));

    var rect = element.getBoundingClientRect();
    x = x * rect.width + rect.left;
    y = y * rect.height + rect.top;

    function traverse(element:Dynamic) {
        if (element.nodeType != Node.TEXT_NODE && element.nodeType != Node.COMMENT_NODE) {
            var rect = element.getBoundingClientRect();
            if (x > rect.left && x < rect.right && y > rect.top && y < rect.bottom) {
                element.dispatchEvent(new MouseEvent(event, mouseEventInit));

                if (Type.enumIndex(element) == HTMLInputElement && element.type == 'range' && (event == 'mousedown' || event == 'click')) {
                    var min = Std.parseFloat(element.min);
                    var max = Std.parseFloat(element.max);
                    var width = rect.width;
                    var offsetX = x - rect.x;
                    var proportion = offsetX / width;
                    element.value = min + (max - min) * proportion;
                    element.dispatchEvent(new InputEvent('input', { bubbles: true }));
                }
            }

            for (i in 0...element.childNodes.length) {
                traverse(element.childNodes[i]);
            }
        }
    }

    traverse(element);
}

@:jsRequire("three")
class HTMLMesh {}