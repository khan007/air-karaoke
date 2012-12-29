package com {
	
	import flash.display.MovieClip;
	import com.SongManager;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import com.Config;
	
	public class Menu extends MovieClip {
		
		private var _songManager:SongManager;
		
		public static const REFRESH:String = "Refresh";
		
		public function Menu(songManager:SongManager):void {
			// constructor code
			_songManager = songManager;
			location_txt.text = Config.get('folder');
			
			// init buttons
			updateDatabase_btn.addEventListener(MouseEvent.CLICK, _onClick);
			browse_btn.addEventListener(MouseEvent.CLICK, _onClick);
		}
		
		private function _onClick(e:MouseEvent):void {
			switch (e.target) {
				case browse_btn:
					var folder:File = new File();
					folder.addEventListener(Event.SELECT, _onFolderSelected);
					folder.browseForDirectory("Choose a directory");
					break;
				case updateDatabase_btn:
					var mp3List:Array = _songManager.fetchMP3(Config.get('folder'));
					_songManager.readMP3TagAsync(mp3List);
					dispatchEvent(new Event(REFRESH));
					break;
			}
		}
		
		private function _onFolderSelected(e:Event):void {
			var folder:File = e.target as File;
			Config.set('folder', folder.nativePath);
			location_txt.text = folder.nativePath;
			folder.removeEventListener(Event.SELECT, _onFolderSelected);
			folder = null;
		}
	}
	
}
