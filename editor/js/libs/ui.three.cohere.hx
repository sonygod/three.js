import js.three.WebGLRenderer;
import js.three.Texture;
import js.three.DataTexture;
import js.three.CompressedTexture;
import js.three.MeshBasicMaterial;
import js.three.RGBELoader;
import js.three.TGALoader;
import js.three.KTX2Loader;
import js.three.FullScreenQuad;
import js.three.File;
import js.three.FileReader;
import js.three.Blob;
import js.three.URL;

import js.Document;
import js.HTMLElement;
import js.HTMLInputElement;
import js.HTMLCanvasElement;
import js.HTMLImageElement;
import js.FileReader;
import js.Event;
import js.Image;

class UITexture extends UISpan {
    public function new(editor:Editor) {
        super();
        var scope = this;
        var form = Document.createElement('form');
        var input = Document.createElement('input');
        input.type = 'file';
        input.addEventListener('change', function(event) {
            loadFile(event.target.files[0]);
        });
        form.appendChild(input);
        var canvas = Document.createElement('canvas');
        canvas.width = 32;
        canvas.height = 16;
        canvas.style.cursor = 'pointer';
        canvas.style.marginRight = '5px';
        canvas.style.border = '1px solid #888';
        canvas.addEventListener('click', function() {
            input.click();
        });
        canvas.addEventListener('drop', function(event) {
            event.preventDefault();
            event.stopPropagation();
            loadFile(event.dataTransfer.files[0]);
        });
        this.dom.appendChild(canvas);
        function loadFile(file:File) {
            var extension = file.name.split('.').pop().toLowerCase();
            var reader = new FileReader();
            var hash = '${file.lastModified}_${file.size}_${file.name}';
            if (cache.exists(hash)) {
                var texture = cache.get(hash);
                scope.setValue(texture);
                if (scope.onChangeCallback != null) {
                    scope.onChangeCallback(texture);
                }
            } else if (extension == 'hdr' || extension == 'pic') {
                reader.addEventListener('load', function(event) {
                    var loader = new RGBELoader();
                    loader.load(event.target.result, function(hdrTexture) {
                        hdrTexture.sourceFile = file.name;
                        cache.set(hash, hdrTexture);
                        scope.setValue(hdrTexture);
                        if (scope.onChangeCallback != null) {
                            scope.onChangeCallback(hdrTexture);
                        }
                    });
                });
                reader.readAsDataURL(file);
            } else if (extension == 'tga') {
                reader.addEventListener('load', function(event) {
                    var loader = new TGALoader();
                    loader.load(event.target.result, function(texture) {
                        texture.colorSpace = js.three.SRGBColorSpace;
                        texture.sourceFile = file.name;
                        cache.set(hash, texture);
                        scope.setValue(texture);
                        if (scope.onChangeCallback != null) {
                            scope.onChangeCallback(texture);
                        }
                    });
                }, false);
                reader.readAsDataURL(file);
            } else if (extension == 'ktx2') {
                reader.addEventListener('load', function(event) {
                    var arrayBuffer = event.target.result;
                    var blobURL = URL.createObjectURL(new Blob([arrayBuffer]));
                    var ktx2Loader = new KTX2Loader();
                    editor.signals.rendererDetectKTX2Support.dispatch(ktx2Loader);
                    ktx2Loader.load(blobURL, function(texture) {
                        texture.colorSpace = js.three.SRGBColorSpace;
                        texture.sourceFile = file.name;
                        texture.needsUpdate = true;
                        cache.set(hash, texture);
                        scope.setValue(texture);
                        if (scope.onChangeCallback != null) {
                            scope.onChangeCallback(texture);
                        }
                        ktx2Loader.dispose();
                    });
                });
                reader.readAsArrayBuffer(file);
            } else if (file.type.match('image.*')) {
                reader.addEventListener('load', function(event) {
                    var image = new Image();
                    image.addEventListener('load', function() {
                        var texture = new Texture(this);
                        texture.sourceFile = file.name;
                        texture.needsUpdate = true;
                        cache.set(hash, texture);
                        scope.setValue(texture);
                        if (scope.onChangeCallback != null) {
                            scope.onChangeCallback(texture);
                        }
                    }, false);
                    image.src = event.target.result;
                }, false);
                reader.readAsDataURL(file);
            }
            form.reset();
        }
        this.texture = null;
        this.onChangeCallback = null;
    }
    public function getValue():Texture {
        return this.texture;
    }
    public function setValue(texture:Texture) {
        var canvas = this.dom.children[0] as HTMLCanvasElement;
        var context = canvas.getContext2d();
        if (context != null) {
            context.clearRect(0, 0, canvas.width, canvas.height);
        }
        if (texture != null) {
            var image = texture.image;
            if (image != null && image.width > 0) {
                canvas.title = texture.sourceFile;
                var scale = canvas.width / image.width;
                if (texture is DataTexture || texture is CompressedTexture) {
                    var canvas2 = renderToCanvas(texture);
                    context.drawImage(canvas2, 0, 0, image.width * scale, image.height * scale);
                } else {
                    context.drawImage(image, 0, 0, image.width * scale, image.height * scale);
                }
            } else {
                canvas.title = texture.sourceFile + ' (error)';
            }
        } else {
            canvas.title = 'empty';
        }
        this.texture = texture;
    }
    public function setColorSpace(colorSpace:Int) {
        var texture = this.getValue();
        if (texture != null) {
            texture.colorSpace = colorSpace;
        }
        return this;
    }
    public function onChange(callback:Texture -> Void) {
        this.onChangeCallback = callback;
        return this;
    }
}

class UIOutliner extends UIDiv {
    public function new(editor:Editor) {
        super();
        this.dom.className = 'Outliner';
        this.dom.tabIndex = 0;
        var scope = this;
        this.scene = editor.scene;
        this.dom.addEventListener('keydown', function(event) {
            switch (event.code) {
                case 'ArrowUp':
                case 'ArrowDown':
                    event.preventDefault();
                    event.stopPropagation();
                    break;
            }
        });
        this.dom.addEventListener('keyup', function(event) {
            switch (event.code) {
                case 'ArrowUp':
                    scope.selectIndex(scope.selectedIndex - 1);
                    break;
                case 'ArrowDown':
                    scope.selectIndex(scope.selectedIndex + 1);
                    break;
            }
        });
        this.editor = editor;
        this.options = [];
        this.selectedIndex = -1;
        this.selectedValue = null;
    }
    public function selectIndex(index:Int) {
        if (index >= 0 && index < this.options.length) {
            this.setValue(this.options[index].value);
            var changeEvent = new Event('change', { bubbles: true, cancelable: true });
            this.dom.dispatchEvent(changeEvent);
        }
    }
    public function setOptions(options:Array<UIDiv>) {
        var scope = this;
        while (scope.dom.children.length > 0) {
            scope.dom.removeChild(scope.dom.firstChild);
        }
        function onClick() {
            scope.setValue(this.value);
            var changeEvent = new Event('change', { bubbles: true, cancelable: true });
            scope.dom.dispatchEvent(changeEvent);
        }
        var currentDrag:UIDiv = null;
        function onDrag() {
            currentDrag = this;
        }
        function onDragStart(event:Event) {
            event.dataTransfer.setData('text', 'foo');
        }
        function onDragOver(event:Event) {
            if (this == currentDrag) return;
            var area = event.offsetY / this.clientHeight;
            if (area < 0.25) {
                this.className = 'option dragTop';
            } else if (area > 0.75) {
                this.className = 'option dragBottom';
            } else {
                this.className = 'option drag';
            }
        }
        function onDragLeave() {
            if (this == currentDrag) return;
            this.className = 'option';
        }
        function onDrop(event:Event) {
            if (this == currentDrag || currentDrag == null) return;
            this.className = 'option';
            var scene = scope.scene;
            var object = scene.getObjectById(currentDrag.value);
            var area = event.offsetY / this.clientHeight;
            if (area < 0.25) {
                var nextObject = scene.getObjectById(this.value);
                moveObject(object, nextObject.parent, nextObject);
            } else if (area > 0.75) {
                var nextObject:Dynamic, parent:Dynamic;
                if (this.nextSibling != null) {
                    nextObject = scene.getObjectById(this.nextSibling.value);
                    parent = nextObject.parent;
                } else {
                    nextObject = null;
                    parent = scene.getObjectById(this.value).parent;
                }
                moveObject(object, parent, nextObject);
            } else {
                var parentObject = scene.getObjectById(this.value);
                moveObject(object, parentObject);
            }
        }
        function moveObject(object, newParent, nextObject:Dynamic = null) {
            if (nextObject == null) nextObject = null;
            var newParentIsChild = false;
            object.traverse(function(child) {
                if (child == newParent) newParentIsChild = true;
            });
            if (newParentIsChild) return;
            var editor = scope.editor;
            editor.execute(new MoveObjectCommand(editor, object, newParent, nextObject));
            var changeEvent = new Event('change', { bubbles: true, cancelable: true });
            scope.dom.dispatchEvent(changeEvent);
        }
        scope.options = [];
        for (i in 0...options.length) {
            var div = options[i];
            div.className = 'option';
            scope.dom.appendChild(div);
            scope.options.push(div);
            div.addEventListener('click', onClick);
            if (div.draggable) {
                div.addEventListener('drag', onDrag);
                div.addEventListener('dragstart', onDragStart);
                div.addEventListener('dragover', onDragOver);
                div.addEventListener('dragleave', onDragLeave);
                div.addEventListener('drop', onDrop);
            }
        }
        return scope;
    }
    public function getValue():Dynamic {
        return this.selectedValue;
    }
    public function setValue(value:Dynamic) {
        for (i in 0...this.options.length) {
            var element = this.options[i];
            if (element.value == value) {
                element.classList.add('active');
                var y = element.offsetTop - this.dom.offsetTop;
                var bottomY = y + element.offsetHeight;
                var minScroll = bottomY - this.dom.offsetHeight;
                if (this.dom.scrollTop > y) {
                    this.dom.scrollTop = y;
                } else if (this.dom.scrollTop < minScroll) {
                    this.dom.scrollTop = minScroll;
                }
                this.selectedIndex = i;
            } else {
                element.classList.remove('active');
            }
        }
        this.selectedValue = value;
        return this;
    }
}

class UIPoints extends UISpan {
    public var pointsList:UIDiv;
    public var pointsUI:Array<Dynamic>;
    public var lastPointIdx:Int;
    public var onChangeCallback:Void -> Void;
    public function new() {
        super();
        this.dom.style.display = 'inline-block';
        this.pointsList = new UIDiv();
        this.add(this.pointsList);
        this.pointsUI = [];
        this.lastPointIdx = 0;
        this.onChangeCallback = null;
        this.update = this.update.bind(this);
    }
    public function onChange(callback:Void -> Void) {
        this.onChangeCallback = callback;
        return this;
    }
    public function clear() {
        for (i in 0...this.pointsUI.length) {
            if (this.pointsUI[i] != null) {
                this.deletePointRow(i, true);
            }
        }
        this.lastPointIdx = 0;
    }
    public function deletePointRow(idx:Int, dontUpdate:Bool = false) {
        if (this.pointsUI[idx] == null) return;
        this.pointsList.remove(this.pointsUI[idx].row);
        this.pointsUI.splice(idx, 1);
        if (!dontUpdate) {
            this.update();
        }
        this.lastPointIdx--;
    }
}

class UIPoints2 extends UIPoints {
    public function new() {
        super();
        var row = new UIRow();
        this.add(row);
        var addPointButton = new UIButton('+');
        addPointButton.onClick(function() {
            if (this.pointsUI.length == 0) {
                this.pointsList.add(this.createPointRow(0, 0));
            } else {
                var point = this.pointsUI[this.pointsUI.length - 1];
                this.pointsList.add(this.createPointRow(point.x.getValue(), point.y.getValue()));
            }
            this.update();
        }.bind(this));
        row.add(addPointButton);
    }
    public function getValue():Array<js.three.Vector2> {
        var points = [];
        var count = 0;
        for (i in 0...this.pointsUI.length) {
            var pointUI = this.pointsUI[i];
            if (pointUI != null) {
                points.push(new js.three.Vector2(pointUI.x.getValue(), pointUI.y.getValue()));
                count++;
                pointUI.lbl.setValue(count);
            }
        }
        return points;
    }
    public function setValue(points:Array<js.three.Vector2>) {
        this.clear();
        for (i in 0...points.length) {
            var point = points[i];
            this.pointsList.add(this.createPointRow(point.x, point.y));
        }
        this.update();
        return this;
    }
    public function createPointRow(x:Float, y:Float) {
        var pointRow = new UIDiv();
        var lbl = new UIText(this.lastPointIdx + 1).setWidth('20px');
        var txtX = new UINumber(x).setWidth('30px').onChange(this.update);
        var txtY = new UINumber(y).setWidth('30px').onChange(this.update);
        var scope = this;
        var btn = new UIButton('-').onClick(function() {
            if (scope.isEditing) return;
            var idx = scope.pointsList.getIndexOfChild(pointRow);
            scope.deletePointRow(idx);
        });
        this.pointsUI.push({ row: pointRow, lbl: lbl, x: txtX, y: txtY });
        this.lastPointIdx++;
        pointRow.add(lbl, txtX, txtY, btn);
        return pointRow;
    }
}

class UIPoints3 extends UIPoints {
    public function new() {
        super();
        var row = new UIRow();
        this.add(row);
        var addPointButton = new UIButton('+');
        addPointButton.onClick(function() {
            if (this.pointsUI.length == 0) {
                this.pointsList.add(this.createPointRow(0, 0, 0));
            } else {
                var point = this.pointsUI[this.pointsUI.length - 1];
                this.pointsList.add(this.createPointRow(point.x.getValue(), point.y.getValue(), point.z.getValue()));
            }
            this.update();
        }.bind(this));
        row.add(addPointButton);
    }
    public function getValue():Array<js.three.Vector3> {
        var points = [];
        var count = 0;
        for (i in 0...this.pointsUI.length) {
            var pointUI = this.pointsUI[i];
            if (pointUI != null) {
                points.push(new js.three.Vector3(pointUI.x.getValue(), pointUI.y.getValue(), pointUI.z.getValue()));
                count++;
                pointUI.lbl.setValue(count);
            }
        }
        return points;
    }
    public function setValue(points:Array<js.three.Vector3>) {
        this.clear();
        for (i in 0...points.length) {
            var point = points[i];
            this.pointsList.add(this.createPointRow(point.x, point.y, point.z));
        }
        this.update();
        return this;
    }
    public function createPointRow(x:Float, y:Float, z:Float) {
        var pointRow = new UIDiv();
        var lbl = new UIText(this.lastPointIdx +
1).setWidth('20px');
var txtX = new UINumber(x).setWidth('30px').onChange(this.update);
var txtY = new UINumber(y).setWidth('30px').onChange(this.update);
var txtZ = new UINumber(z).setWidth('30px').onChange(this.update);
var scope = this;
var btn = new UIButton('-').onClick(function() {
    if (scope.isEditing) return;
    var idx = scope.pointsList.getIndexOfChild(pointRow);
    scope.deletePointRow(idx);
});
this.pointsUI.push({ row: pointRow, lbl: lbl, x: txtX, y: txtY, z: txtZ });
this.lastPointIdx++;
pointRow.add(lbl, txtX, txtY, txtZ, btn);
return pointRow;
}
}

class UIBoolean extends UISpan {
    public function new(boolean:Bool, text:String) {
        super();
        this.setMarginRight('4px');
        this.checkbox = new UICheckbox(boolean);
        this.text = new UIText(text).setMarginLeft('3px');
        this.add(this.checkbox);
        this.add(this.text);
    }
    public function getValue():Bool {
        return this.checkbox.getValue();
    }
    public function setValue(value:Bool) {
        return this.checkbox.setValue(value);
    }
}

var renderer:WebGLRenderer = null;
var fsQuad:FullScreenQuad = null;
function renderToCanvas(texture:Texture) {
    if (renderer == null) {
        renderer = new WebGLRenderer();
    }
    if (fsQuad == null) {
        fsQuad = new FullScreenQuad(new MeshBasicMaterial());
    }
    var image = texture.image;
    renderer.setSize(image.width, image.height, false);
    fsQuad.material.map = texture;
    fsQuad.render(renderer);
    return renderer.domElement;
}

class Editor {
    public var scene:Dynamic;
    public var signals:Dynamic;
}

class Command {
}

class MoveObjectCommand extends Command {
    public function new(editor:Editor, object:Dynamic, newParent:Dynamic, nextObject:Dynamic) {
    }
}

export { UITexture, UIOutliner, UIPoints, UIPoints2, UIPoints3, UIBoolean };