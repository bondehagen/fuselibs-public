using Uno;
using Fuse.Security.X509;

namespace Fuse.Security
{
	public class X509Certificate
	{
		public string Subject { get; private set; }
		public string Issuer { get; private set; }
		public byte[] DerEncodedData { get; private set; } 

		public X509Certificate(string subject, string issuer, byte[] der) {}
		public X509Certificate(byte[] der)
		{
			DerEncodedData = der;
			var lol = new ASN1Tools(der);
			var asn1 = lol.Decode();
			Certificate = new CertificateToBeSigned(asn1.Children[0].Children[0].Children[0].Value, asn1.Children[0].Children[1].Value, new Oid("", ""), new RelativeDistinguishedName("", new Oid("", ""), new byte[0]),
				new Validity(default(DateTime), default(DateTime)), new RelativeDistinguishedName("", new Oid("", ""), new byte[0]),
				new SubjectPublicKeyInfo(new AlgorithmIdentifier(new Oid("", "")), new byte[0]));
			debug_log Certificate.SerialNumber;
		}

		public CertificateToBeSigned Certificate { get; private set; }
		public string Algorithm { get; private set; }
		public byte[] Signature { get; private set; }
	}

	public class X509Chain
	{

	}

	public enum SslPolicyErrors
	{
		None = 0,
		RemoteCertificateNotAvailable = 1,
		RemoteCertificateNameMismatch = 2,
		RemoteCertificateChainErrors = 4,
	}
}
namespace Fuse.Security.X509
{
	public class CertificateToBeSigned
	{
		public CertificateToBeSigned(int version, string serialNumber, Oid signatureAlgorithm,
			RelativeDistinguishedName issuer, Validity validity, RelativeDistinguishedName subject,
			SubjectPublicKeyInfo subjectPublicKeyInfo)
		{
			Version = version;
			SerialNumber = serialNumber;
			SignatureAlgorithm = signatureAlgorithm;
			Issuer = issuer;
			Validity = validity;
			Subject = subject;
			SubjectPublicKeyInfo = subjectPublicKeyInfo;
		}

		public int Version { get; private set; }
		public string SerialNumber { get; private set; }
		public Oid SignatureAlgorithm { get; private set; }
		public RelativeDistinguishedName Issuer { get; private set; }
		public Validity Validity { get; private set; }
		public RelativeDistinguishedName Subject { get; private set; }
		public SubjectPublicKeyInfo SubjectPublicKeyInfo { get; private set; }
	}

	public class RelativeDistinguishedName
	{
		public RelativeDistinguishedName(string name, Oid oid, byte[] rawData)
		{
			Name = name;
			Oid = oid;
			RawData = rawData;
		}

		public string Name { get; private set; }
		public Oid Oid { get; private set; }
		public byte[] RawData { get; private set; }
	}

	public class SubjectPublicKeyInfo
	{
		public SubjectPublicKeyInfo(AlgorithmIdentifier algorithm, byte[] subjectPublicKey)
		{
			Algorithm = algorithm;
			SubjectPublicKey = subjectPublicKey;
		}

		public AlgorithmIdentifier Algorithm { get; private set; }
		public byte[] SubjectPublicKey { get; private set; }
	}

	public class AlgorithmIdentifier
	{
		public AlgorithmIdentifier(Oid algorithm)
		{
			Algorithm = algorithm;
		}

		public Oid Algorithm { get; private set; }
		public Object parameters { get; private set; }
	}

	public class Validity
	{
		public Validity(DateTime notBefore, DateTime notAfter)
		{
			NotBefore = notBefore;
			NotAfter = notAfter;
		}

		public DateTime NotBefore { get; private set; }
		public DateTime NotAfter { get; private set; }
	}

	public class Oid
	{
		public Oid(string friendlyName, string value)
		{
			FriendlyName = friendlyName;
			Value = value;
		}

		public string FriendlyName { get; set; }
		public string Value { get; set; }
	}
}
