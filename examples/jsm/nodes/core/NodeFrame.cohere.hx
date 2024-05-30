import js.Browser.Performance;

class NodeUpdateType {
    static inline var FRAME:String = "frame";
    static inline var RENDER:String = "render";
    static inline var OBJECT:String = "object";
}

class NodeFrame {
    var time:Float;
    var deltaTime:Float;
    var frameId:Int;
    var renderId:Int;
    var startTime:Float;
    var updateMap:Map<Dynamic, { renderMap:WeakMap<Dynamic, Dynamic>, frameMap:WeakMap<Dynamic, Dynamic> }>;
    var updateBeforeMap:Map<Dynamic, { renderMap:WeakMap<Dynamic, Dynamic>, frameMap:WeakMap<Dynamic, Dynamic> }>;
    var renderer:Dynamic;
    var material:Dynamic;
    var camera:Dynamic;
    var object:Dynamic;
    var scene:Dynamic;

    public function new() {
        time = 0;
        deltaTime = 0;
        frameId = 0;
        renderId = 0;
        startTime = Perf.now();
        updateMap = Map_dyn();
        updateBeforeMap = Map_dyn();
        renderer = null;
        material = null;
        camera = null;
        object = null;
        scene = null;
    }

    function _getMaps(referenceMap:Map<Dynamic, { renderMap:WeakMap<Dynamic, Dynamic>, frameMap:WeakMap<Dynamic, Dynamic> }>, nodeRef:Dynamic):{ renderMap:WeakMap<Dynamic, Dynamic>, frameMap:WeakMap<Dynamic, Dynamic> } {
        var maps = referenceMap.get(nodeRef);
        if (maps == null) {
            maps = { renderMap: WeakMap_dyn(), frameMap: WeakMap_dyn() };
            referenceMap.set(nodeRef, maps);
        }
        return maps;
    }

    function updateBeforeNode(node) {
        var updateType = node.getUpdateBeforeType();
        var reference = node.updateReference($this);

        switch (updateType) {
            case NodeUpdateType.FRAME:
                var frameMap = _getMaps(updateBeforeMap, reference).frameMap;
                if (frameMap.get(reference) != frameId) {
                    if (node.updateBefore($this) != false) {
                        frameMap.set(reference, frameId);
                    }
                }
                break;
            case NodeUpdateType.RENDER:
                var renderMap = _getMaps(updateBeforeMap, reference).renderMap;
                if (renderMap.get(reference) != renderId) {
                    if (node.updateBefore($this) != false) {
                        renderMap.set(reference, renderId);
                    }
                }
                break;
            case NodeUpdateType.OBJECT:
                node.updateBefore($this);
                break;
        }
    }

    function updateNode(node) {
        var updateType = node.getUpdateType();
        var reference = node.updateReference($this);

        switch (updateType) {
            case NodeUpdateType.FRAME:
                var frameMap = _getMaps(updateMap, reference).frameMap;
                if (frameMap.get(reference) != frameId) {
                    if (node.update($this) != false) {
                        frameMap.set(reference, frameId);
                    }
                }
                break;
            case NodeUpdateType.RENDER:
                var renderMap = _getMaps(updateMap, reference).renderMap;
                if (renderMap.get(reference) != renderId) {
                    if (node.update($this) != false) {
                        renderMap.set(reference, renderId);
                    }
                }
                break;
            case NodeUpdateType.OBJECT:
                node.update($this);
                break;
        }
    }

    function update() {
        frameId++;
        var lastTime = if (lastTime == null) Perf.now() else lastTime;
        deltaTime = (Perf.now() - lastTime) / 1000.0;
        lastTime = Perf.now();
        time += deltaTime;
    }
}