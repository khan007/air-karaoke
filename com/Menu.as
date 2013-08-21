package com {
	
	import flash.display.MovieClip;
	import com.SongManager;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import com.Config;
	
	public class Menu extends MovieClip {
		
		private var _songManager:SongManager;
		
		public function Menu(songManager:SongManager):void {
			// constructor code
			_songManager = songManager;
			location_txt.text = Config.get('folder');
			location_txt.mouseEnabled = false;
			
			// init buttons
			updateDatabase_btn.addEventListener(MouseEvent.CLICK, _onClick);
			reset_btn.addEventListener(MouseEvent.CLICK, _onClick);
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
					try {
						_songManager.fetchMP3(Config.get('folder'));
					}catch (err:Error) {
						Notify.show(err.message);
					}
					break;
					
				case reset_btn:
					_songManager.resetDatabase();
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
