import ChainMap;
import RenderList;

class RenderLists {

	var lists:ChainMap;

	public function new() {

		lists = new ChainMap();

	}

	public function get(scene:Dynamic, camera:Dynamic):RenderList {

		var keys:Array<Dynamic> = [scene, camera];

		var list:RenderList = lists.get(keys);

		if (list == null) {

			list = new RenderList();
			lists.set(keys, list);

		}

		return list;

	}

	public function dispose():Void {

		lists = new ChainMap();

	}

}