package com {
	
	public class Song {

		private var _name:String;
		private var _artist:String;
		private var _path:String;
		private var _count:uint;

		public function Song(data:Object) {
			// constructor code
			_name = data['name'];
			_artist = data['artist'];
			_path = data['path'];
			_count = data['count'];
		}
		
		public function get name():String {
			return _name;
		}
		
		public function get artist():String {
			return _artist;
		}
		
		public function get url():String {
			return _path;
		}
		
		public function get count():uint {
			return _count;
		}

	}
	
}
