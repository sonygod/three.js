import ChainMap from './ChainMap.hx';
import RenderList from './RenderList.hx';

class RenderLists {

	public var lists:ChainMap<Dynamic>;

	public function new() {
		this.lists = new ChainMap<Dynamic>();
	}

	public function get(scene:Dynamic, camera:Dynamic):RenderList {
		var lists = this.lists;
		var keys = [scene, camera];

		var list = lists.get(keys);

		if (list == null) {
			list = new RenderList();
			lists.set(keys, list);
		}

		return list;
	}

	public function dispose() {
		this.lists = new ChainMap<Dynamic>();
	}

}

export default RenderLists;