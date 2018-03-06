using Uno;
using Uno.IO;
using Uno.Compiler.ExportTargetInterop;
using Foundation;

namespace Fuse.Net.Http
{
    extern(DOTNET && HOST_MAC) internal class MacStream : Uno.IO.Stream
    {
        NSInputStream _inputStream;
        NSOutputStream _outputStream;

        public MacStream(NSInputStream inputStream, NSOutputStream outputStream)
        {
            if (inputStream == null)
                throw new ArgumentNullException("inputStream");

            if (outputStream == null)
                throw new ArgumentNullException("outputStream");

            _inputStream = inputStream;
            _outputStream = outputStream;

            if (_inputStream.Status == NSStreamStatus.NotOpen)
                _inputStream.Open();
        }

        public override long Length
        {
            get { return 0; }
        }

        public override void SetLength(long value) { }

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
            get { return false; }
        }

        public override void Write(byte[] src, int byteOffset, int byteCount)
        {
            throw new NotImplementedException();
        }

        public override long Seek(long byteOffset, SeekOrigin origin)
        {
            return 0;
        }

        public override void Flush() { }
        
        public override long Position
        {
            get { return _inputStream.FileCurrentOffset.Int64Value; }
            set { }
        }

        public override int Read(byte[] dst, int byteOffset, int byteCount)
        {   var ret = _inputStream.Read(dst, byteOffset, byteCount);
            if(ret == -1)
                throw new Exception(_inputStream.Error.ToString());

            return ret;
        }

        public virtual bool DataAvailable
        {
            get { return _inputStream.HasBytesAvailable(); }
        }
    }
}
