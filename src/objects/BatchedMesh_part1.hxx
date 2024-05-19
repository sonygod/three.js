class MultiDrawRenderList {

	var index:Int;
	var pool:Array<{start:Int, count:Int, z:Float}>;
	var list:Array<{start:Int, count:Int, z:Float}>;

	public function new() {

		index = 0;
		pool = [];
		list = [];

	}

	public function push(drawRange:{start:Int, count:Int}, z:Float) {

		if (index >= pool.length) {

			pool.push({

				start: - 1,
				count: - 1,
				z: - 1,

			});

		}

		var item = pool[index];
		list.push(item);
		index ++;

		item.start = drawRange.start;
		item.count = drawRange.count;
		item.z = z;

	}

	public function reset() {

		list.length = 0;
		index = 0;

	}

}