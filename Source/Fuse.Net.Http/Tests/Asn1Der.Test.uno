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
			var asn = new ASN1Tools(bytes);
			asn.Decode();
			Assert.IsTrue(true);
		}

		[Test]
		public void ReadTag()
		{
			var bytes = new byte[] { 0x30, 0xA0, 0x02, 0x7F, 0x84, 0x02, 0xA3 }; 
			var asn = new ASN1Tools(bytes);
			Assert.AreEqual(new Tag(IdentifierClass.Universal, true, 0x10), asn.ReadTag());
			Assert.AreEqual(new Tag(IdentifierClass.ContextSpecific, true, 0x0), asn.ReadTag());
			Assert.AreEqual(new Tag(IdentifierClass.Universal, false, 0x02), asn.ReadTag());
			Assert.AreEqual(new Tag(IdentifierClass.Application, true, 0x202).ToString(), asn.ReadTag().ToString());
			Assert.AreEqual(new Tag(IdentifierClass.ContextSpecific, true, 0x03), asn.ReadTag());
		}

		[Test]
		public void ReadLength()
		{
			var bytes = new byte[] { 0x82, 0x06, 0xB7, 0x03, 0x82, 0x02, 0x01 };
			var asn = new ASN1Tools(bytes);
			Assert.AreEqual(1719, asn.ReadLength());
			Assert.AreEqual(3, asn.ReadLength());
			Assert.AreEqual(513, asn.ReadLength());
		}

		[Test]
		public void ReadInteger()
		{
			var asn = new ASN1Tools(new byte[] { 0x02 });
			Assert.AreEqual(2, asn.ReadInteger(1));

			asn = new ASN1Tools(new byte[] { 0x01, 0x00, 0x01 });
			Assert.AreEqual(65537, asn.ReadInteger(3));
			
			asn = new ASN1Tools(new byte[] { 0x13, 0x54, 0xCB, 0x8B });
			Assert.AreEqual(324324235, asn.ReadInteger(4));

			asn = new ASN1Tools(new byte[] { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff });
			//var bytes4 = new byte[] { 0x5A, 0x00, 0x04, 0x98, 0xAF, 0x9A, 0x64, 0x12, 0xB7, 0x63, 0x25, 0x17, 0x04, 0x00, 0x01, 0x00, 0x04, 0x98, 0xAF };
			ulong lol = 0xffffffffffffffff;
			Assert.AreEqual(lol, asn.ReadInteger(8));
		}
		
		[Test]
		public void ReadUTCTime()
		{
			var bytes = new byte[] { 0x31, 0x36, 0x30, 0x39, 0x32, 0x38, 0x32, 0x31, 0x34, 0x35, 0x32, 0x33, 0x5A };
			var asn = new ASN1Tools(bytes);
			Assert.AreEqual("2016-09-28T21:45:23UTC+00:00:00", asn.ReadUtcTime(13));

			asn = new ASN1Tools(new byte[] { 0x31, 0x38, 0x30, 0x35, 0x30, 0x37, 0x31, 0x37, 0x30, 0x33, 0x33, 0x30, 0x5A });
			Assert.AreEqual("2018-05-07T17:03:30UTC+00:00:00", asn.ReadUtcTime(13));
		}

		[Test]
		public void ReadObjectIdentifier()
		{

		}
	}
}
