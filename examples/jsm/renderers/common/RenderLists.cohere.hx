import ChainMap from './ChainMap.hx';
import RenderList from './RenderList.hx';

class RenderLists {

	public var lists:ChainMap;

	public function new() {
		lists = ChainMap._new();
	}

	public function get(scene:Dynamic, camera:Dynamic):RenderList {
		var lists = this.lists;
		var keys = [ scene, camera ];

		var list = lists.get(keys);

		if (list == null) {
			list = RenderList._new();
			lists.set(keys, list);
		}

		return list;
	}

	public function dispose():Void {
		lists = ChainMap._new();
	}

}