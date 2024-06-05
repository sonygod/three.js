import NodeUpdateType from "./constants.hx";

class NodeFrame {

  public var time:Float;
  public var deltaTime:Float;

  public var frameId:Int;
  public var renderId:Int;

  public var startTime:Null<Float>;

  public var updateMap:WeakMap<Dynamic, { renderMap:WeakMap<Dynamic, Int>, frameMap:WeakMap<Dynamic, Int> }>;
  public var updateBeforeMap:WeakMap<Dynamic, { renderMap:WeakMap<Dynamic, Int>, frameMap:WeakMap<Dynamic, Int> }>;

  public var renderer:Dynamic;
  public var material:Dynamic;
  public var camera:Dynamic;
  public var object:Dynamic;
  public var scene:Dynamic;

  public function new() {
    this.time = 0;
    this.deltaTime = 0;

    this.frameId = 0;
    this.renderId = 0;

    this.startTime = null;

    this.updateMap = new WeakMap();
    this.updateBeforeMap = new WeakMap();

    this.renderer = null;
    this.material = null;
    this.camera = null;
    this.object = null;
    this.scene = null;
  }

  private function _getMaps(referenceMap:WeakMap<Dynamic, { renderMap:WeakMap<Dynamic, Int>, frameMap:WeakMap<Dynamic, Int> }>, nodeRef:Dynamic):{ renderMap:WeakMap<Dynamic, Int>, frameMap:WeakMap<Dynamic, Int> } {
    var maps = referenceMap.get(nodeRef);
    if (maps == null) {
      maps = {
        renderMap: new WeakMap(),
        frameMap: new WeakMap()
      };
      referenceMap.set(nodeRef, maps);
    }
    return maps;
  }

  public function updateBeforeNode(node:Dynamic) {
    var updateType = node.getUpdateBeforeType();
    var reference = node.updateReference(this);
    if (updateType == NodeUpdateType.FRAME) {
      var { frameMap } = this._getMaps(this.updateBeforeMap, reference);
      if (frameMap.get(reference) != this.frameId) {
        if (node.updateBefore(this) != false) {
          frameMap.set(reference, this.frameId);
        }
      }
    } else if (updateType == NodeUpdateType.RENDER) {
      var { renderMap } = this._getMaps(this.updateBeforeMap, reference);
      if (renderMap.get(reference) != this.renderId) {
        if (node.updateBefore(this) != false) {
          renderMap.set(reference, this.renderId);
        }
      }
    } else if (updateType == NodeUpdateType.OBJECT) {
      node.updateBefore(this);
    }
  }

  public function updateNode(node:Dynamic) {
    var updateType = node.getUpdateType();
    var reference = node.updateReference(this);
    if (updateType == NodeUpdateType.FRAME) {
      var { frameMap } = this._getMaps(this.updateMap, reference);
      if (frameMap.get(reference) != this.frameId) {
        if (node.update(this) != false) {
          frameMap.set(reference, this.frameId);
        }
      }
    } else if (updateType == NodeUpdateType.RENDER) {
      var { renderMap } = this._getMaps(this.updateMap, reference);
      if (renderMap.get(reference) != this.renderId) {
        if (node.update(this) != false) {
          renderMap.set(reference, this.renderId);
        }
      }
    } else if (updateType == NodeUpdateType.OBJECT) {
      node.update(this);
    }
  }

  public function update() {
    this.frameId++;
    if (this.lastTime == null) this.lastTime = Date.now();
    this.deltaTime = (Date.now() - this.lastTime) / 1000;
    this.lastTime = Date.now();
    this.time += this.deltaTime;
  }

  private var lastTime:Null<Float>;

}