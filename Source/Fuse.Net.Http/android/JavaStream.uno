using Uno;
using Uno.IO;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Net.Http
{
	[ForeignInclude(Language.Java, "java.net.HttpURLConnection", "java.io.*")]
	extern(Android) internal class JavaStream : Uno.IO.Stream
	{
		Java.Object _inputStream;
		Java.Object _outputStream;

		public JavaStream(Java.Object inputStream, Java.Object outputStream)
		{
			_inputStream = inputStream;
			_outputStream = outputStream;
		}

    	public override bool CanRead
        {
            get { return true; }
        }

        public override bool CanWrite
        {
            get { return true; }
        }

        public override bool CanSeek
        {
            get { return true; }
        }

		[Foreign(Language.Java)]
		int GetLength()
		@{
			try {
				InputStream inputstream = (InputStream)@{JavaStream:Of(_this)._inputStream:Get()};
				return inputstream.available();
			} catch(IOException e) {
				// TODO
			}
			return 0;
		@}

        public override long Length
        {
            get { return GetLength(); }
        }

        public override long Position
        {
            get { return 0; }
            set { }
        }

        public override void SetLength(long value)
        {

        }
		
		public override int Read(byte[] dst, int byteOffset, int byteCount)
		{
			var i = this.Read(ForeignDataView.Create(dst), dst.Length, 0, dst.Length);
			if(i < 0) return 0;
			return i;
		}

		[Foreign(Language.Java)]
        int Read(Java.Object dst, int arrLength, int byteOffset, int byteCount)
        @{
        	try {
        		com.uno.UnoBackedByteBuffer buf = (com.uno.UnoBackedByteBuffer)dst;
				InputStream inputstream = (InputStream)@{JavaStream:Of(_this)._inputStream:Get()};
				if(inputstream == null) return 0;
				// NOTE: For some reason this trows exception: int res = inputstream.read(buf.array(), byteOffset, byteCount);
				byte[] arr = new byte[arrLength];
				int res = inputstream.read(arr, byteOffset, byteCount);
				buf.put(arr);
				return res;
			} catch(IOException e) {}
			return 0;
		@}

        public override void Write(byte[] src, int byteOffset, int byteCount)
        {

        }

        public override long Seek(long byteOffset, SeekOrigin origin)
        {
        	return 0;
        }

        public override void Flush()
        {

        }
	}
}
