package
{
	import flash.desktop.NativeApplication;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.InvokeEvent;
	import flash.filesystem.File;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class Main extends Sprite 
	{
		private var file:File;
		
		public function Main() 
		{
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
		}
		
		private function onInvoke(e:InvokeEvent):void
		{
			if(e.arguments.length != 0)
			{
				file = new File(e.arguments[0]);
				file.addEventListener(Event.COMPLETE, onComplete);
				file.load();
			}
		}
		
		private function readBits(bytes:Array, readLengthList:Array):Array
		{
			var results:Array = new Array();
			var bitIndex:int = 0;
			
			for(var i:int = 0; i < readLengthList.length; i++)
			{
				results.push(0);
				for(var remain:int = readLengthList[i]; remain > 0; remain--)
				{
					results[i] = (results[i] << 1) + (bytes[Math.floor(bitIndex / 8)] & 128 >> (bitIndex % 8) ? 1 : 0);
					bitIndex++;
				}
			}
			
			return results;
		}
		
		private function onComplete(e:Event):void
		{
			var bytes:ByteArray = file.data;
			var format:String = bytes.readMultiByte(3, "us-ascii");
			bytes.position += 5;
			
			var contentBytes:ByteArray = new ByteArray()
			contentBytes.endian = Endian.LITTLE_ENDIAN;
			bytes.readBytes(contentBytes);
			
			if(format == "CWS")
			{
				contentBytes.uncompress();
			}
			
			var bitLength:uint = contentBytes.readUnsignedByte() >> 3;
			contentBytes.position--;
			var screenSizeByteLength:uint = Math.ceil((5 + bitLength * 4) / 8);
			var screenSizeBytes:Array = new Array();
			for(var i:int = 0; i < screenSizeByteLength; i++)
			{
				screenSizeBytes.push(contentBytes.readUnsignedByte());
			}
			
			var screenInfo:Array = readBits(screenSizeBytes, [5, bitLength, bitLength, bitLength, bitLength]);
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.stageWidth = screenInfo[2] / 20;
			stage.stageHeight = screenInfo[4] / 20;
			
			contentBytes.position++;
			stage.frameRate = contentBytes.readUnsignedByte();
			
			contentBytes.position += 2;
			
			while(contentBytes.bytesAvailable > 0)
			{
				var recordHeader:uint = contentBytes.readUnsignedShort();
				var tagCode:uint = recordHeader >> 6;
				var bodyLength:uint = recordHeader & 0x3F;
				
				//SetBackgroundColor
				if(tagCode == 9)
				{
					var r:uint = contentBytes.readUnsignedByte();
					var g:uint = contentBytes.readUnsignedByte();
					var b:uint = contentBytes.readUnsignedByte();
					stage.color = (r << 16) + (g << 8) + b;
					break;
				}
				
				contentBytes.position += bodyLength;
			}
			
			var loader:Loader = new Loader();
			var loaderContext:LoaderContext = new LoaderContext();
			
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void
			{
				addChild(loader);
			});
			
			loaderContext.allowCodeImport = true;
			loader.loadBytes(file.data, loaderContext);
		}
	}
}