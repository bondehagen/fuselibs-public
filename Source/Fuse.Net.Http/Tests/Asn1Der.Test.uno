using Uno;
using Uno.Testing;
using Uno.IO;
using Fuse.Security;

namespace Fuse.Motion.Simulation.Test
{
	public class Asn1DerTest
	{
		[Test]
		public void Decode()
		{
			var bytes = File.ReadAllBytes("c:/azurecert.der");
			var asn = new ASN1Tools();
			asn.Decode(bytes);
		}
	}
}
