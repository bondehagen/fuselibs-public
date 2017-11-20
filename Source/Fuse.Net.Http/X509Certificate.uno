using Uno;
using Uno.Text;
using Uno.Collections;
using Fuse.Security.X509;

namespace Fuse.Security
{
	public class X509Certificate
	{
		public byte[] DerEncodedData { get; private set; }
		
		public object ImplHandle { get; private set; }
		public byte[] RawBytes { get; private set; }
		public string Password { get; private set; }
		
		public X509Certificate(string data) : this(Uno.Text.Base64.GetBytes(LoadPem(data)))
		{}

		static string LoadPem(string data)
		{
			// https://tls.mbed.org/kb/cryptography/asn1-key-structures-in-der-and-pem
			var begin = "-----BEGIN CERTIFICATE-----";
			var end = "-----END CERTIFICATE-----";
			return data.Replace(begin, "").Replace(end, "").Replace("\n", "").Replace("\r", "");
		}
		
		public X509Certificate(byte[] der) : this(der, null) {}

		public X509Certificate(byte[] der, string password)
		{
			if (der == null || der.Length == 0)
				throw new Exception("Could not load certificate, bytes was null or empty");

			RawBytes = der;
			Password = password;
			
			if (password != null)
			{
				ImplHandle = LoadCertificateFromBytes.Load(der, password);
				return;
			}
			else
				ImplHandle = LoadCertificateFromBytes.Load(der);

			DerEncodedData = LoadCertificateFromBytes.GetBytes(ImplHandle);
			
			var asn1 = new Asn1Der(DerEncodedData).Decode();
			if (asn1 == null)
				throw new Exception("Could not load certificate, asn1 decoding unsuccessful");

			try
			{
				if (asn1[0][0].Tag.IsPrimitive)
				{
					var version = (int)asn1[0][0].AsUInt64()+1;
					var signatureAlgorithm = asn1[0][1][0].AsOid();
					var issuer = new RelativeDistinguishedName(asn1[0][2]);
					var validity = new Validity(asn1[0][3][0].AsDateTime(), asn1[0][3][1].AsDateTime());
					var subject = new RelativeDistinguishedName(asn1[0][4]);
					var subjectPublicKeyInfo = new SubjectPublicKeyInfo(new AlgorithmIdentifier(asn1[0][5][0][0].AsOid()), asn1[0][5][1].Data);

					Certificate = new CertificateToBeSigned(version, "", signatureAlgorithm, issuer, validity, subject, subjectPublicKeyInfo);
					Algorithm = asn1[1][0].AsOid().FriendlyName;
					Signature = asn1[2].Data;
				}
				else
				{
					var version = (int)asn1[0][0][0].AsUInt64()+1;
					var serialNumber = asn1[0][1].AsHex();
					var signatureAlgorithm = asn1[0][2][0].AsOid();
					var issuer = new RelativeDistinguishedName(asn1[0][3]);
					var validity = new Validity(asn1[0][4][0].AsDateTime(), asn1[0][4][1].AsDateTime());
					var subject = new RelativeDistinguishedName(asn1[0][5]);
					var subjectPublicKeyInfo = new SubjectPublicKeyInfo(new AlgorithmIdentifier(asn1[0][6][0][0].AsOid()), asn1[0][6][1].Data);

					Certificate = new CertificateToBeSigned(version, serialNumber, signatureAlgorithm, issuer, validity, subject, subjectPublicKeyInfo);

					Algorithm = asn1[1][0].AsOid().FriendlyName;
					Signature = asn1[2].Data;
					Extensions = new List<X509v3Extension>();
					foreach (var extension in asn1[0][7][0])
					{
						Extensions.Add(new X509v3Extension(extension[0].AsOid(), true, extension[1].AsString()));
					}
				}
			}
			catch(Exception e)
			{
				throw new Exception("Could not load certificate, error extracting asn1 data. " + e.ToString());
			}
		}

		public CertificateToBeSigned Certificate { get; private set; }
		public string Algorithm { get; private set; }
		public byte[] Signature { get; private set; }
		public IList<X509v3Extension> Extensions { get; private set; }
		
		public override string ToString()
		{
			var sb = new StringBuilder();
			sb.Append(Certificate.ToString());
			sb.AppendLine("\tX509v3 extensions:");
			foreach (var e in Extensions)
				sb.AppendLine(e.ToString());
			
			sb.AppendLine("Signature Algorithm: " + Algorithm);
			for (var i = 0; i < Signature.Length; i++)
			{
				if (i == 0 || i % 18 == 0)
					sb.Append("\t");

				sb.Append(string.Format("{0:X2}", Signature[i]));
				if (i != Signature.Length - 1)
					sb.Append(':');
				else
					sb.AppendLine("");

				if ((i + 1) % 18 == 0)
					sb.AppendLine("");
			}
			sb.AppendLine("-----BEGIN CERTIFICATE-----");
			sb.AppendLine(Base64.GetString(DerEncodedData));
			sb.AppendLine("-----END CERTIFICATE-----");
			return  sb.ToString();
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
	public class X509v3Extension
	{
		public X509v3Extension(Oid id, bool isCritical, string v)
		{
			Id = id;
			IsCritical = isCritical;
			Value = v;
		}
		public Oid Id { get; private set; }
		public bool IsCritical { get; private set; }
		public string Value { get; private set; }
		public override string ToString()
		{
			return Id.FriendlyName + " " + Value;
		}
	}
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

		public override string ToString()
		{
			var sb = new StringBuilder();
			sb.AppendLine("Certificate:");
			sb.AppendLine("\tData:");
			sb.AppendLine("\t\tVersion: " + Version);
			sb.AppendLine("\t\tSerial Number:");
			sb.AppendLine("\t\t\t" + SerialNumber);
			sb.AppendLine("\tSignature Algorithm: " + SignatureAlgorithm.FriendlyName);
			sb.AppendLine("\t\tIssuer: " + Issuer.Name);
			sb.AppendLine("\t\tValidity");
			sb.AppendLine("\t\t\tNot Before: " + Validity.NotBefore.ToString());
			sb.AppendLine("\t\t\tNot After : " + Validity.NotAfter.ToString());
			sb.AppendLine("\t\tSubject : " + Subject.Name);
			sb.AppendLine("\t\tSubject Public Key Info:");
			sb.AppendLine("\t\t\tPublic Key Algorithm: " + SubjectPublicKeyInfo.Algorithm.Algorithm.FriendlyName);
			sb.AppendLine("\t\t\t\tPublic-Key: (" + ((SubjectPublicKeyInfo.SubjectPublicKey.Length - 1) * 8) + " bit)");
			sb.AppendLine("\t\t\t\tModulus:");
			for (var i = 0; i < SubjectPublicKeyInfo.SubjectPublicKey.Length; i++)
			{
				if (i == 0 || i % 15 == 0)
					sb.Append("\t\t\t\t\t");

				sb.Append(string.Format("{0:X2}", SubjectPublicKeyInfo.SubjectPublicKey[i]));
				if (i != SubjectPublicKeyInfo.SubjectPublicKey.Length - 1)
					sb.Append(':');
				else
					sb.AppendLine("");

				if ((i + 1) % 15 == 0)
					sb.AppendLine("");
			}
			sb.AppendLine("\t\t\t\tExponent: " + SubjectPublicKeyInfo.Exponent);
			return sb.ToString();
		}
	}

	public class RelativeDistinguishedName
	{
		static IDictionary<string, string> DistinguishedNames = new Dictionary<string, string>
		{
			{ "2.5.4.3", "cn" },
			{ "2.5.4.4", "sn" },
			{ "2.5.4.5", "serialNumber" },
			{ "2.5.4.6", "c" },
			{ "2.5.4.7", "l" },
			{ "2.5.4.8", "st" },
			{ "2.5.4.9", "street" },
			{ "2.5.4.10", "o" },
			{ "2.5.4.11", "ou" },
			{ "2.5.4.12", "title" },
			{ "2.5.4.13", "description" },
			{ "2.5.4.14", "searchGuide" },
			{ "2.5.4.15", "businessCategory" },
			{ "2.5.4.16", "postalAddress" },
			{ "2.5.4.17", "postalCode" },
			{ "2.5.4.18", "postOfficeBox" },
			{ "2.5.4.19", "physicalDeliveryOfficeName" },
			{ "2.5.4.20", "telephoneNumber" },
			{ "2.5.4.27", "destinationIndicator" },
			{ "2.5.4.31", "member" },
			{ "2.5.4.32", "owner" },
			{ "2.5.4.41", "name" },
			{ "2.5.4.42", "givenName" },
			{ "2.5.4.43", "initials" },
			{ "2.5.4.44", "generationQualifier" },
			{ "2.5.4.49", "distinguishedName" },
			{ "2.5.4.46", "dnQualifier" }
		};

		public RelativeDistinguishedName(Asn1Node datacollection)
		{
			RawData = datacollection.Data;
			Name = "";
			for (var i = 0; i < datacollection.Count; i++)
			{
				var node = datacollection[i][0];
				var oid = node[0].AsOid();
				var v = node[1].AsString();
				var key = "";
				if (!DistinguishedNames.TryGetValue(oid.Value, out key))
					key = oid.FriendlyName;

				Name += key.ToUpper() + "=" + v;
				if (i < datacollection.Count-1)
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
			var asn1 = new Asn1Der(subjectPublicKey).Decode();
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
