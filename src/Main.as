package
{
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeDragManager;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.NativeWindowDisplayState;
	import flash.display.Screen;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.InvokeEvent;
	import flash.events.NativeDragEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.events.NativeWindowDisplayStateEvent;
	import flash.filesystem.File;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import flash.profiler.showRedrawRegions;
	import flash.system.LoaderContext;
	import project.Menu;
	import project.MenuEvent;
	import project.SWFData;
	
	public class Main extends Sprite 
	{
		private var file:File;
		private var swf:SWFData;
		
		private var sprite:Sprite;
		private var bitmap:Bitmap;
		private var buffer:BitmapData;
		
		private var clipRect:Rectangle = new Rectangle();
		
		private var menu:Menu;
		private var focusRect:Sprite;
		private var color:ColorTransform;
		
		public function Main() 
		{
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
		}
		
		private function onInvoke(e:InvokeEvent):void
		{
			focusRect = new Sprite();
			focusRect.graphics.beginFill(0);
			focusRect.graphics.drawRect(0, 0, 1000, 1000);
			
			color = new ColorTransform(0, 0, 0, 1, 255, 255, 255, 0);
			
			menu = new Menu(stage.nativeWindow, this);
			menu.bounds = new Rectangle(0, 0, 550, 400);
			menu.addEventListener(MenuEvent.CHANGE_SCALE, onChangeScale);
			menu.addEventListener(MenuEvent.CHANGE_SPEED, onChangeSpeed);
			menu.addEventListener(MenuEvent.RENDERING_STATE_CHANGE, onRenderingStateChange);
			menu.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZING, onResizing);
			stage.nativeWindow.addEventListener(NativeWindowDisplayStateEvent.DISPLAY_STATE_CHANGING, onDisplayStateChanging);
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
			
			buffer = new BitmapData(Screen.mainScreen.bounds.width, Screen.mainScreen.bounds.height, false, 0);
			bitmap = new Bitmap(buffer);
			
			sprite = new Sprite();
			sprite.addEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed);
			
			addChild(focusRect);
			addChild(bitmap);
			addChild(sprite);
			
			menu.antiAliasing = true;
			menu.legacyZoom = false;
			
			setWindowScale(1);
			
			if(e.arguments.length != 0)
			{
				file = new File(e.arguments[0]);
				file.addEventListener(Event.COMPLETE, onComplete);
				file.load();
				return;
			}
			
			var onDragEnter:Function = function(e:NativeDragEvent):void { NativeDragManager.acceptDragDrop(focusRect); };
			
			focusRect.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragEnter);
			focusRect.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, function(e:NativeDragEvent):void
			{
				if(e.clipboard.formats[0] == ClipboardFormats.FILE_LIST_FORMAT)
				{
					focusRect.removeEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragEnter);
					focusRect.removeEventListener(NativeDragEvent.NATIVE_DRAG_DROP, arguments.callee);
					
					file = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT)[0];
					file.addEventListener(Event.COMPLETE, onComplete);
					file.load();
				}
			});
		}
		
		private function onComplete(e:Event):void
		{
			swf = new SWFData(file.data);
			menu.bounds = swf.frameSize;
			
			stage.frameRate = swf.frameRate;
			color.color = swf.backgroundColor;
			focusRect.transform.colorTransform = color;
			
			setWindowScale(1);
			
			var loader:Loader = new Loader();
			var loaderContext:LoaderContext = new LoaderContext();
			
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void
			{
				sprite.addChild(loader);
			});
			
			loaderContext.allowCodeImport = true;
			loader.loadBytes(file.data, loaderContext);
		}
		
		private function onFrameConstructed(e:Event):void
		{
			if (menu.antiAliasing == true && menu.legacyZoom == false) { return; }
			
			clipRect.width = Math.ceil(menu.bounds.width * sprite.scaleX + sprite.x * 2)
			clipRect.height = Math.ceil(menu.bounds.height * sprite.scaleY + sprite.y * 2);
			
			buffer.lock();
			buffer.fillRect(clipRect, focusRect.transform.colorTransform.color);
			if(menu.antiAliasing == false) {
				buffer.drawWithQuality(sprite, sprite.transform.matrix, sprite.transform.colorTransform, null, clipRect, false, StageQuality.LOW);
			}
			else {
				buffer.drawWithQuality(sprite, sprite.transform.matrix, sprite.transform.colorTransform, null, clipRect, false, StageQuality.BEST);
			}
			buffer.unlock();
		}
		
		private function onRenderingStateChange(e:MenuEvent):void
		{
			fitScreen();
			
			sprite.visible = menu.antiAliasing && !menu.legacyZoom;
			bitmap.visible = !sprite.visible;
			
			showRedrawRegions(menu.redrawRegions);
			sprite.alpha = menu.transparent ? 0.7 : 1.0;
			
			if (menu.outsiderMode == false)
			{
				sprite.scrollRect = new Rectangle(0, 0, menu.bounds.width, menu.bounds.height);
				focusRect.transform.colorTransform = color;
			}
			else
			{
				sprite.scrollRect = null;
				focusRect.transform.colorTransform = color;
			}
		}
		
		private function onChangeScale(e:MenuEvent):void 
		{
			stage.displayState = StageDisplayState.NORMAL;
			setWindowScale(e.item.data as Number);
		}
		
		private function onChangeSpeed(e:MenuEvent):void 
		{
			stage.frameRate = 30 * Number(e.item.name);
		}
		
		private function onDisplayStateChanging(e:NativeWindowDisplayStateEvent):void 
		{
			// 最大化の代わりにフルスクリーンにする
			if (e.afterDisplayState == NativeWindowDisplayState.MAXIMIZED)
			{
				stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
				e.preventDefault();
			}
		}
		
		private function get contentWidth():int
		{
			return Math.round(menu.bounds.width / stage.contentsScaleFactor);
		}
		
		private function get contentHeight():int
		{
			return Math.round(menu.bounds.height / stage.contentsScaleFactor);
		}
		
		private function onResizing(e:NativeWindowBoundsEvent):void
		{
			stage.nativeWindow.bounds = e.afterBounds;
			fitScreen();
			
			e.preventDefault();
		}
		
		private function onFullScreen(e:FullScreenEvent):void 
		{
			if(e.fullScreen == true) {
				stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			}
			else {
				stage.displayState = StageDisplayState.NORMAL;
			}
			
			fitScreen();
		}
		
		private function setWindowScale(value:Number):void
		{
			stage.stageWidth = contentWidth * value;
			stage.stageHeight = contentHeight * value;
			
			fitScreen();
		}
		
		private function fitScreen():void
		{
			var scale:Number = 1;
			
			if (menu.outsiderMode == false) {
				scale = Math.min(stage.stageWidth / contentWidth, stage.stageHeight / contentHeight);
			}
			
			if(menu.legacyZoom == true)
			{
				sprite.scaleX = 1;
				sprite.scaleY = 1;
				bitmap.scaleX = scale / stage.contentsScaleFactor;
				bitmap.scaleY = scale / stage.contentsScaleFactor;
				sprite.x = (stage.stageWidth * stage.contentsScaleFactor / scale - menu.bounds.width) / 2;
				sprite.y = (stage.stageHeight * stage.contentsScaleFactor / scale - menu.bounds.height) / 2;
			}
			else
			{
				if(menu.antiAliasing == false)
				{
					sprite.scaleX = scale;
					sprite.scaleY = scale;
					sprite.x = (stage.stageWidth * stage.contentsScaleFactor - menu.bounds.width * scale) / 2;
					sprite.y = (stage.stageHeight * stage.contentsScaleFactor - menu.bounds.height * scale) / 2;
				}
				else
				{
					sprite.scaleX = scale / stage.contentsScaleFactor;
					sprite.scaleY = scale / stage.contentsScaleFactor;
					sprite.x = (stage.stageWidth - contentWidth * scale) / 2;
					sprite.y = (stage.stageHeight - contentHeight * scale) / 2;
				}
				bitmap.scaleX = 1 / stage.contentsScaleFactor;
				bitmap.scaleY = 1 / stage.contentsScaleFactor;
			}
			
			focusRect.width = stage.stageWidth;
			focusRect.height = stage.stageHeight;
		}
	}
}