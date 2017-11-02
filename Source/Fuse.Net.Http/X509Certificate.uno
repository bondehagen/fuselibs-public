using Uno;
using Uno.Text;
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
			var asn1 = new ASN1Tools(der).Decode();
			Certificate = new CertificateToBeSigned(
				(int)asn1[0][0][0].AsUInt64()+1, asn1[0][1].AsHex(), asn1[0][2][0].AsOid(),
				new RelativeDistinguishedName(asn1[0][3]), new Validity(asn1[0][4][0].AsDateTime(), asn1[0][4][1].AsDateTime()),
				new RelativeDistinguishedName(asn1[0][5]),
				new SubjectPublicKeyInfo(new AlgorithmIdentifier(asn1[0][6][0][0].AsOid()), asn1[0][6][1].Data));

			Algorithm = asn1[1][0].AsOid().FriendlyName;
			Signature = asn1[2].Data;
			debug_log this.ToString();
		}

		public CertificateToBeSigned Certificate { get; private set; }
		public string Algorithm { get; private set; }
		public byte[] Signature { get; private set; }

		public override string ToString()
		{
			var sb = new StringBuilder();
			sb.AppendLine("Certificate:");
			sb.AppendLine("\tData:");
			sb.AppendLine("\t\tVersion: " + Certificate.Version);
			sb.AppendLine("\t\tSerial Number:");
			sb.AppendLine("\t\t\t" + Certificate.SerialNumber);
			sb.AppendLine("\tSignature Algorithm: " + Certificate.SignatureAlgorithm.FriendlyName);
			sb.AppendLine("\t\tIssuer: " + Certificate.Issuer.Name);

			sb.AppendLine("Public Key:");
			sb.AppendLine(Certificate.SubjectPublicKeyInfo.Algorithm.Algorithm.FriendlyName);
			sb.AppendLine(Certificate.SubjectPublicKeyInfo.SubjectPublicKey.Length + " bit");

			var o = "";
			foreach (var b in Certificate.SubjectPublicKeyInfo.SubjectPublicKey)
				o += string.Format("{0:X}:", b);

			sb.AppendLine(o);
			sb.AppendLine("Exponent: " + Certificate.SubjectPublicKeyInfo.Exponent);
			return sb.ToString();
		}
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
		public RelativeDistinguishedName(Asn1Node datacollection)
		{
			RawData = datacollection.Data;
			Name = "";
			for (var i = 0; i < datacollection.Count; i++)
			{
				var node = datacollection[i][0];
				var oid = node[0].AsOid();
				var v = node[1].AsString();
				Name += oid.FriendlyName + "=" + v;
				if (i < datacollection.Count)
					Name += ", ";
			}
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
			var asn1 = new ASN1Tools(subjectPublicKey).Decode();
			SubjectPublicKey = asn1[0].Data;
			Exponent = asn1[1].AsUInt64();
		}

		public AlgorithmIdentifier Algorithm { get; private set; }
		public byte[] SubjectPublicKey { get; private set; }
		public ulong Exponent { get; private set; }
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
		public Validity(Uno.Time.ZonedDateTime notBefore, Uno.Time.ZonedDateTime notAfter)
		{
			NotBefore = notBefore;
			NotAfter = notAfter;
		}

		public Uno.Time.ZonedDateTime NotBefore { get; private set; }
		public Uno.Time.ZonedDateTime NotAfter { get; private set; }
	}

	public class Oid
	{
		public Oid(string oid)
		{
			string friendlyName = "";
			if (!ObjectIdentifierTable.TryGetValue(oid, out friendlyName))
			{
				friendlyName = oid;
			}
			FriendlyName = friendlyName;
			Value = oid;
		}

		public string FriendlyName { get; set; }
		public string Value { get; set; }

		public override string ToString()
		{
			return Value + " " + FriendlyName;
		}
	}
}
