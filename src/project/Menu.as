package project 
{
	import flash.desktop.NativeApplication;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.NativeWindow;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.FullScreenEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.geom.Rectangle;
	import flash.profiler.showRedrawRegions;
	import flash.ui.Keyboard;

	public class Menu extends EventDispatcher
	{
		private var nativeWindow:NativeWindow;
		private var frameSize:Rectangle;
		
		private var menu:NativeMenu = new NativeMenu();
		private var fileMenu:NativeMenu = new NativeMenu();
		private var displayMenu:NativeMenu = new NativeMenu();
		
		private var initScaleItem:NativeMenuItem;
		private var fullScreenItem:NativeMenuItem;
		private var redrawRegionItem:NativeMenuItem;
		
		private function createMenuItem(label:String, mnemonic:String = ""):NativeMenuItem
		{
			var item:NativeMenuItem = new NativeMenuItem(label);
			
			if (mnemonic != "")
			{
				item.label += "(" + mnemonic + ")";
				item.mnemonicIndex = item.label.length - 2;
			}
			
			return item;
		}
		
		private function createSeparator():NativeMenuItem
		{
			return new NativeMenuItem("", true);
		}
		
		private function addSubMenu(submenu:NativeMenu, label:String, mnemonic:String = ""):NativeMenuItem
		{
			var item:NativeMenuItem = menu.addSubmenu(submenu, label);
			
			if (mnemonic != "")
			{
				item.label += "(" + mnemonic + ")";
				item.mnemonicIndex = item.label.length - 2;
			}
			
			return item;
		}
		
		public function Menu(nativeWindow:NativeWindow, frameSize:Rectangle, root:Sprite)
		{
			this.nativeWindow = nativeWindow;
			this.frameSize = frameSize;
			
			// ファイル
			fileMenu.addItem(createMenuItem("終了", "X")).addEventListener(Event.SELECT, function(e:Event):void {
				NativeApplication.nativeApplication.exit();
			});
			
			// 表示
			initScaleItem = displayMenu.addItem(createMenuItem("100%"))
			initScaleItem.addEventListener(Event.SELECT, function(e:Event):void
			{
				if (fullScreenItem.checked == true) {
					nativeWindow.stage.dispatchEvent(new FullScreenEvent(FullScreenEvent.FULL_SCREEN, false, false, false, true));
				}
				
				nativeWindow.dispatchEvent(new NativeWindowBoundsEvent(NativeWindowBoundsEvent.RESIZING, false, false,
					new Rectangle(nativeWindow.x, nativeWindow.y, frameSize.width / nativeWindow.stage.contentsScaleFactor, frameSize.height / nativeWindow.stage.contentsScaleFactor),
					new Rectangle(nativeWindow.x, nativeWindow.y, frameSize.width / nativeWindow.stage.contentsScaleFactor, frameSize.height / nativeWindow.stage.contentsScaleFactor)
				));
			});
			
			fullScreenItem = displayMenu.addItem(createMenuItem("フルスクリーン", "S"))
			fullScreenItem.keyEquivalent = "\renter";
			fullScreenItem.keyEquivalentModifiers = [Keyboard.ALTERNATE];
			fullScreenItem.addEventListener(Event.SELECT, toggleFullScreen);
			
			displayMenu.addItem(createSeparator());
			redrawRegionItem = displayMenu.addItem(createMenuItem("再描画領域を表示"));
			redrawRegionItem.addEventListener(Event.SELECT, toggleRedrawRegions);
			
			addSubMenu(fileMenu, "ファイル", "F");
			addSubMenu(displayMenu, "表示", "V");
			
			nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZE, onResize);
			nativeWindow.stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
			nativeWindow.menu = menu;
			root.contextMenu = displayMenu;
		}
		
		public function onResize(e:NativeWindowBoundsEvent):void
		{
			initScaleItem.checked = Math.round(nativeWindow.stage.stageWidth * nativeWindow.stage.contentsScaleFactor) == frameSize.width;
		}
		
		private function onFullScreen(e:FullScreenEvent):void 
		{
			fullScreenItem.checked = e.fullScreen;
		}
		
		private function toggleFullScreen(e:Event):void
		{
			if (fullScreenItem.checked == false) {
				nativeWindow.stage.dispatchEvent(new FullScreenEvent(FullScreenEvent.FULL_SCREEN, false, false, true, true));
			}
			else {
				nativeWindow.stage.dispatchEvent(new FullScreenEvent(FullScreenEvent.FULL_SCREEN, false, false, false, true));
			}
		}
		
		private function toggleRedrawRegions(e:Event):void
		{
			if (redrawRegionItem.checked == false)
			{
				redrawRegionItem.checked = true;
				showRedrawRegions(true);
			}
			else
			{
				redrawRegionItem.checked = false;
				showRedrawRegions(false);
			}
		}
	}
}