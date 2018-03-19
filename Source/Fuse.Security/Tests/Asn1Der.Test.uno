using Uno;
using Uno.Testing;
using Uno.IO;
using Fuse.Security;

namespace Fuse.Motion.Simulation.Test
{
	public class Asn1DerTest
	{
		[Test]
		public void MakeCert()
		{
			/*
			self signed v2 cert
			*/
			var bytes = Uno.Text.Base64.GetBytes("MIIDmDCCAYACAQEwDQYJKoZIhvcNAQELBQAwDzENMAsGA1UEAxMEdGVzdDAeFw0xNzExMTkxNzM3NTZaFw0xODExMTkxNzM3NTZaMBUxEzARBgNVBAMTCnRlc3RzZXJ2ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDOaDxPO66iXjRm51/ErsABQaTPiGj9ntlnPHHyvWmjRpohEr1KS+DCV9hf2+nxMXfGrcbwLQtJxUw2CRtThge1OI1RsnwfKvSttfWZX2rEjItO3qbdkqIp7d32eSkGOYhH4GQwdUXYUF9ixYQwSeqWt4DPEPBzPlLHw08sfgwjROSW8KYKJe+23hyJI2ookREF+uXZaPmDNwMe4/hH/fAzA02vw+vCY2xV2QZPGsj3Qc4G8jBUjvCaeQ8g3R82dUJKfANf6bD+x22Ghrgjc3FA8/lpi/xMjux+reWt5oFyHbDo5mIKPJ3LaMlvrjx20cmyxKevLJRO26VEWkjRyhpfAgMBAAEwDQYJKoZIhvcNAQELBQADggIBABY4Zf68hxFDplqkjpXiiziKwr4uXYi5hvtTND9vl763GJgemPHzeQqAWletI1sQml2QGw/qZPaVLlc3xshIAu3BrH7iQT0kuANih0bzDji9uRcHQPchHWv9arG1SXocxx4hXHQueS8peoYPgDq0NB9saBNj9tKMjhmapTbqXoOULxVl2CzqcFVKPYQHPhUmlPl2QD+IC56PhARM3O9+Lh3Ij9nD0S3ryiv8BzglwWGI0or6JXRGJzPi1wapZ1iiAaLxXqsRf3pBAD9r8a5PhIiZNClaTb6hHMS6PzgldzCpEWDSZGbGDLczWjl4yksEDJMZLigpqz+i4b2s2F7jKH+SlXbwO9V8ldsWeGmH6y5KWWc3hCl9QEMSms2aZi5SeBkeqgl69VCVg/aFHUCfLe7uNMNleIQjjIm7pWATXaz9XoxxbjXQhixreFYZtnJ/mXwgISE+rhNwA/Vs8luPNwHUVawGbI8rTdvqxooEta1h984UFgfgRH/2VgBThZPF5tA896+QkFEbwBNoD3PIlsyuWaWVy2czQzsY2fmTzVko+y7HqEvYYrmQyUHxVSwN9/iQPtiOLah0sLtbkOImLfJ1WG10FfjLoPIisio11GgXyjFpAH6lw1pILyOA8MK9wDwi6gV3ez0wxK7MajEd48Ov3GsCDPtBpNNiYUdT3Utd");
			var a = new X509Certificate(bytes);
		}

		[Test]
		public void Decode()
		{

			/*var bytes = File.ReadAllBytes("c:/azurecert.der");
			var a = new X509Certificate(bytes);
			var asn = new ASN1Tools(bytes);
			asn.Decode();
			Assert.IsTrue(true);*/
		}

		[Test]
		public void ReadTag()
		{
			var bytes = new byte[] { 0x30, 0xA0, 0x02, 0x7F, 0x84, 0x02, 0xA3 }; 
			var asn = new Asn1Der(bytes);
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
			var asn = new Asn1Der(bytes);
			Assert.AreEqual(1719, asn.ReadLength());
			Assert.AreEqual(3, asn.ReadLength());
			Assert.AreEqual(513, asn.ReadLength());
		}

		[Test]
		public void ReadInteger()
		{
			var asn = new Asn1Der(new byte[] { 0x02, 0x01, 0x02 });
			Assert.AreEqual(2, asn.Decode().AsUInt64());

			asn = new Asn1Der(new byte[] { 0x02, 0x03, 0x01, 0x00, 0x01 });
			Assert.AreEqual(65537, asn.Decode().AsUInt64());
			
			asn = new Asn1Der(new byte[] { 0x02, 0x04, 0x13, 0x54, 0xCB, 0x8B });
			Assert.AreEqual(324324235, asn.Decode().AsUInt64());

			asn = new Asn1Der(new byte[] { 0x02, 0x13, 0x5A, 0x00, 0x04, 0x98, 0xAF, 0x9A, 0x64, 0x12, 0xB7, 0x63, 0x25, 0x17, 0x04, 0x00, 0x01, 0x00, 0x04, 0x98, 0xAF });
			Assert.AreEqual("5A000498AF9A6412B7632517040001000498AF", asn.Decode().AsHex());
		}
		
		[Test]
		public void ReadUTCTime()
		{
			var asn = new Asn1Der(new byte[] { 0x17, 0x0D, 0x31, 0x36, 0x30, 0x39, 0x32, 0x38, 0x32, 0x31, 0x34, 0x35, 0x32, 0x33, 0x5A });
			Assert.AreEqual("2016-09-28T21:45:23UTC+00:00:00", asn.Decode().AsDateTime().ToString());

			asn = new Asn1Der(new byte[] { 0x17, 0x0D, 0x31, 0x38, 0x30, 0x35, 0x30, 0x37, 0x31, 0x37, 0x30, 0x33, 0x33, 0x30, 0x5A });
			Assert.AreEqual("2018-05-07T17:03:30UTC+00:00:00", asn.Decode().AsDateTime().ToString());
		}

		[Test]
		public void ReadObjectIdentifier()
		{
			// 1.2.840.113549.1.1.11 sha256WithRSAEncryption(PKCS #1)
			// 2A 86 48 86 F7 0D 01 01 0B
								// 86 48
					// (6 * 128^1) + (72 * 128^0) = 840

					// 86 F7 0D
					// (6 * 128^2) + (119 * 128^1) + (13 * 128^0) = 113549
					
		}
	}
}
