package com{

	import flash.display.MovieClip;
	import com.Song;
	import flash.events.MouseEvent;
	import flash.text.TextFormat;


	public class SongListItem extends MovieClip {

		public static const SONG_NORMAL:String = "Normal";
		public static const SONG_SHUFFLE:String = "Shuffle";
		public static const HEADING:String = "Heading";
		public static const PADDING:uint = 5;

		private var _song:Song;
		private var _type:String;

		public function SongListItem(data:Object, type = SONG_NORMAL) {
			// constructor code
			_type = type;
			
			switch (type) {
				case SONG_NORMAL:
				case SONG_SHUFFLE:
					_song = data as Song;
					name_txt.text = _song.name;
					artist_txt.text = _song.artist;
					bar_mc.stop();
					bar_mc.height = name_txt.height + PADDING * 2;
					artist_txt.y = name_txt.x = name_txt.y = PADDING;
					artist_txt.x = name_txt.x + name_txt.width + PADDING;
					
					this.useHandCursor = true;
					this.buttonMode = true;
			
					this.addEventListener(MouseEvent.MOUSE_OVER, _onOver);
					this.addEventListener(MouseEvent.MOUSE_OUT, _onOut);
					break;
				case HEADING:
					var str:String = data as String;
					bar_mc.gotoAndStop("heading");
					var tf:TextFormat = new TextFormat();
					tf.color = 0xffffff;
					
					name_txt.defaultTextFormat = tf;
					name_txt.text = str;
					removeChild(artist_txt);
					
					bar_mc.height = name_txt.height + PADDING * 2;
					artist_txt.y = name_txt.x = name_txt.y = PADDING;
					break;
			}
			
			// events
			this.mouseChildren = false;
		}
		
		public function get song():Song {
			return _song;
		}
		
		public function setSize(w:uint):void {
			bar_mc.width = w;
			
			switch (_type) {
				case SONG_NORMAL:
				case SONG_SHUFFLE:
					name_txt.width = w * 0.65;
					artist_txt.width = w * 0.25;
					artist_txt.y = name_txt.x = name_txt.y = PADDING;
					artist_txt.x = name_txt.x + name_txt.width + PADDING;
					break;
				case HEADING:
					name_txt.width = w;
					break;
			}
		}
		
		public function unbind():void {
			if (this.hasEventListener(MouseEvent.MOUSE_OVER)) {
				this.removeEventListener(MouseEvent.MOUSE_OVER, _onOver);
				this.removeEventListener(MouseEvent.MOUSE_OUT, _onOut);
			}
		}
		
		private function _onOver(e:MouseEvent):void {
			bar_mc.gotoAndStop("over");
		}
		
		private function _onOut(e:MouseEvent):void {
			bar_mc.gotoAndStop("out");
		}
	}

}