import ChainMap from './ChainMap';
import RenderList from './RenderList';

class RenderLists {

    public var lists:ChainMap<Array<Dynamic>, RenderList> = new ChainMap();

    public function new() {
    }

    public function get(scene:Dynamic, camera:Dynamic):RenderList {
        var keys:Array<Dynamic> = [scene, camera];

        var list:RenderList = this.lists.get(keys);

        if (list == null) {
            list = new RenderList();
            this.lists.set(keys, list);
        }

        return list;
    }

    public function dispose():Void {
        this.lists = new ChainMap();
    }
}