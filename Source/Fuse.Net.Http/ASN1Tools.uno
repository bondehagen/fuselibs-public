namespace Fuse.Security
{
	public class ASN1Tools
	{
		public void Decode(byte[] data)
		{
			debug_log "Cert length: " + data.Length;
			using (var stream = new Uno.IO.MemoryStream(data))
			using (var br = new Uno.IO.BinaryReader(stream))
			{
				br.LittleEndian = false;
				ReadTag(br);
			}
		}
		
		void ReadTag(Uno.IO.BinaryReader br)
		{
			var tag = br.ReadByte();

			var length = ReadLength(br);

			//debug_log "Length: " + length;

			const byte BOOLEAN = 0x01;
			const byte INTEGER = 0x02; 
			const byte BIT_STRING = 0x03;
			const byte OCTET_STRING = 0x04;
			const byte _NULL = 0x05;
			const byte OBJECT_ID = 0x06;
			const byte UTF8_STRING = 0x0C;
			const byte PRINTABLE_STRING = 0x13;
			const byte IA5_STRING = 0x16;
			const byte UNICODE_STRING = 0x1e;
			const byte SEQUENCE = 0x30;
			const byte SET = 0x31;

			/*const byte TeletexString = 0x14;
			const byte BMPString = 0x1E;
			const byte  = 0x;*/
			if (tag == SEQUENCE)
			{
				debug_log("SEQUENCE");
			}
			else if (tag == INTEGER)
			{
				var res = "";
				foreach(var b in br.ReadBytes(length))
				{
					res += Uno.String.Format("{0:X}", b);
				}

				debug_log("INTEGER " + res);
			}
			else if (tag == BOOLEAN)
			{
				debug_log("BOOLEAN ");
				return;
			}
			else if (tag == BIT_STRING)
			{
				debug_log("BIT_STRING ");
				return;
			}
			else if (tag == OCTET_STRING)
			{
				var bytes = br.ReadBytes(length);
				debug_log("OCTET_STRING ");
			}
			else if (tag == _NULL)
			{
				//var b = br.ReadByte();
				debug_log("NULL ");
			}
			else if (tag == OBJECT_ID)
			{
				var oid = DecodeOID(br.ReadBytes(length));

				debug_log("OBJECT_ID " + oid + " ");
			}
			else if (tag == UTF8_STRING)
			{
				debug_log("UTF8_STRING ");
				return;
			}
			else if (tag == PRINTABLE_STRING)
			{
				var bytes = br.ReadBytes(length);
				debug_log("PRINTABLE_STRING " + Uno.Text.Utf8.GetString(bytes));
			}
			else if (tag == IA5_STRING)
			{
				debug_log("IA5_STRING ");
				return;
			}
			else if (tag == SET)
			{
				debug_log("SET ");
			}
			else if (tag >> 6 == 0X02)
			{
				debug_log "context-defined";
				PrintTag(tag);
			}
			else if (tag >> 6 == 0X00)
			{
				debug_log "UNIVERSAL";
				PrintTag(tag);
				return;
			}
			else if (tag >> 6 == 0X01)
			{
				debug_log "APPLICATION";
				PrintTag(tag);
				return;
			}
			else if (tag >> 6 == 0X03)
			{
				debug_log "PRIVATE";
				PrintTag(tag);
				return;
			}
			else
			{
				debug_log "Unknown tag: " + Uno.String.Format("{0:X}", tag);
				return;
			}
			if (length != -1)
				ReadTag(br);
		}

		public void PrintTag(byte tag)
		{
			var isConstructed = tag & (1 >> 5);
			var tagNumber = tag & 0x1F;
			if (isConstructed == 1)
			{
				debug_log "\tconstructed " + tagNumber; 
			}
			else
			{
				debug_log "\tprimitive " + tagNumber;
			}
		}

		public int ReadLength(Uno.IO.BinaryReader br)
		{
			var a = br.ReadByte();
			var extendedLength = (a >> 7) & 1;
			int l = a & 0x7F;
			if (extendedLength == 1)
			{
				if (l == 1)
				{
					return br.ReadByte();
				}
				else if (l == 2)
				{
					return br.ReadUShort();
				} else {
					br.ReadBytes(l);
					debug_log "Unknown extended length " + l;
					return 127+l;
				}
			}
			else
			{
				return l;
			}
			debug_log "Unknown length";
			return -1;
		}
		
		private string DecodeOID(byte[] bytes)
		{
			// 1.2.840.113549.1.1.11 sha256WithRSAEncryption(PKCS #1)
			// 2A 86 48 86 F7 0D 01 01 0B
			var result = "";
			for(int i = 0; i < bytes.Length; i++)
			{
				var b = bytes[i];
				//debug_log b + " " + string.Format("{0:X}", b);
				if ((b & 0x80) == 0) 
				{
					if (b < 40)
						result += b;
					else
						result += (b / 40) + "." + (b % 40);
				}
				else
				{
					debug_log "---";

					// 86 48
					// (6 * 128^1) + (72 * 128^0) = 840

					// 86 F7 0D
					// (6 * 128^2) + (119 * 128^1) + (13 * 128^0) = 113549
					
					var shift = 31 - 7;
					int v = 0;
					while ((b & 0x80) != 0)
					{
						v |= (b & 0x7F) << shift;

						shift -= 7;
						//if (shift < 0) 
						b = bytes[++i];
					}
					v >>= shift;
					
					byte count = 0;
					int t = v;

//					for (var g = 0; g < list.Count; g++)
/*					{
						var val = list[g] & 0x7F;
						var shift = 7 * (list.Count-g);
						t |= val << shift;
					}
*/
					/*int count = 0;
					int t = 0;
					while (b > 127)
					{
						count = b ^ 128;
						t += count * 128;
						b = bytes[++i];
					}*/
					t += b;

					result += t;
				}
				if (i < bytes.Length - 1)
					result += ".";
			}
			debug_log("result: " + result);
			return result;
		}

		private Uno.Collections.Dictionary<string, string> OIDS = new Uno.Collections.Dictionary<string, string>()
    {
{ "2.5.4.0","objectClass" },
{ "2.5.4.1","aliasedEntryName" },
{ "2.5.4.10","organizationName" },
{ "2.5.4.10.1","collectiveOrganizationName" },
{ "2.5.4.11","organizationalUnitName" },
{ "2.5.4.11.1","collectiveOrganizationalUnitName" },
{ "2.5.4.12","title" },
{ "2.5.4.13","description" },
{ "2.5.4.14","searchGuide" },
{ "2.5.4.15","businessCategory" },
{ "2.5.4.16","postalAddress" },
{ "2.5.4.16.1","collectivePostalAddress" },
{ "2.5.4.17","postalCode" },
{ "2.5.4.17.1","collectivePostalCode" },
{ "2.5.4.18","postOfficeBox" },
{ "2.5.4.18.1","collectivePostOfficeBox" },
{ "2.5.4.19","physicalDeliveryOfficeName" },
{ "2.5.4.19.1","collectivePhysicalDeliveryOfficeName" },
{ "2.5.4.2","knowledgeInformation" },
{ "2.5.4.20","telephoneNumber" },
{ "2.5.4.20.1","collectiveTelephoneNumber" },
{ "2.5.4.21","telexNumber" },
{ "2.5.4.21.1","collectiveTelexNumber" },
{ "2.5.4.22.1","collectiveTeletexTerminalIdentifier" },
{ "2.5.4.23","facsimileTelephoneNumber" },
{ "2.5.4.23.1","collectiveFacsimileTelephoneNumber" },
{ "2.5.4.25","internationalISDNNumber" },
{ "2.5.4.25.1","collectiveInternationalISDNNumber" },
{ "2.5.4.26","registeredAddress" },
{ "2.5.4.27","destinationIndicator" },
{ "2.5.4.28","preferredDeliveryMehtod" },
{ "2.5.4.29","presentationAddress" },
{ "2.5.4.3","commonName" },
{ "2.5.4.31","member" },
{ "2.5.4.32","owner" },
{ "2.5.4.33","roleOccupant" },
{ "2.5.4.34","seeAlso" },
{ "2.5.4.35","userPassword" },
{ "2.5.4.36","userCertificate" },
{ "2.5.4.37","caCertificate" },
{ "2.5.4.38","authorityRevocationList" },
{ "2.5.4.39","certificateRevocationList" },
{ "2.5.4.4","surname" },
{ "2.5.4.40","crossCertificatePair" },
{ "2.5.4.41","name" },
{ "2.5.4.42","givenName" },
{ "2.5.4.43","initials" },
{ "2.5.4.44","generationQualifier" },
{ "2.5.4.45","uniqueIdentifier" },
{ "2.5.4.46","dnQualifier" },
{ "2.5.4.47","enhancedSearchGuide" },
{ "2.5.4.48","protocolInformation" },
{ "2.5.4.49","distinguishedName" },
{ "2.5.4.5","serialNumber" },
{ "2.5.4.50","uniqueMember" },
{ "2.5.4.51","houseIdentifier" },
{ "2.5.4.52","supportedAlgorithms" },
{ "2.5.4.53","deltaRevocationList" },
{ "2.5.4.55","clearance" },
{ "2.5.4.58","crossCertificatePair" },
{ "2.5.4.6","countryName" },
{ "2.5.4.7","localityName" },
{ "2.5.4.7.1","collectiveLocalityName" },
{ "2.5.4.8","stateOrProvinceName" },
{ "2.5.4.8.1","collectiveStateOrProvinceName" },
{ "2.5.4.9","streetAddress" },
{ "2.5.4.9.1","collectiveStreetAddress" },
{ "1.2.840.113549.1.1.11","sha256WithRSAEncryption" },
{ "1.2.840.113549.1.1.12","sha384WithRSAEncryption" },
{ "1.2.840.113549.1.1.13","sha512WithRSAEncryption" },
{ "1.2.840.113549.1.1.10","id-RSASSA-PSS" },
{ "1.2.840.10040.4.3","dsa-with-sha1X957" },
{ "1.2.840.10045.4.1","ecdsa-with-sha1" },
{ "1.2.840.10045.4.2","ecdsa-with-Recommended" },
{ "1.2.840.10045.4.3","ecdsa-with-Specified" },
{ "1.2.840.10045.4.3.1","ecdsa-with-SHA224" },
{ "1.2.840.10045.4.3.2","ecdsa-with-SHA256" },
{ "1.2.840.10045.4.3.3","ecdsa-with-SHA384" },
{ "1.2.840.10045.4.3.4","ecdsa-with-SHA512" },
{ "1.3.14.7.2.3.1","md2WithRsa" },
{ "1.3.14.3.2.2","md4WithRSA" },
{ "1.3.14.3.2.3","md5WithRSA" },
{ "1.3.14.3.2.4","md4WithRSAEncryption" },
{ "1.3.14.3.2.29","sha1WithRSASignature" },
{ "1.3.14.3.2.27","dsa-with-sha1" }
};
	}
}
