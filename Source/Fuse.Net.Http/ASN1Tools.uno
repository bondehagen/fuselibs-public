using Uno;
using Uno.Text;
using Uno.Collections;

namespace Fuse.Security
{
	public enum IdentifierClass : byte
	{
		Universal = 0X00,
		Application = 0X01,
		ContextSpecific = 0X02,
		Private = 0X03
	}

	public enum TagName : byte
	{
		EOC = 0,
		BOOLEAN = 0x01,
		INTEGER = 0x02,
		BIT_STRING = 0x03,
		OCTET_STRING = 0x04,
		_NULL = 0x05,
		OBJECT_ID = 0x06,
		Object_Descriptor = 0x07,
		EXTERNAL = 0x08,
		REAL = 0x09,
		ENUMERATED = 0x0A,
		EMBEDDED_PDV = 0x0B,
		UTF8_STRING = 0x0C,
		SEQUENCE = 0x10,
		SET = 0x11,
		NumericString = 0x12,
		PRINTABLE_STRING = 0x13,
		T61String = 0x14, // TeletexStrin,
		VideotexString = 0x15,
		IA5_STRING = 0x16,
		UTC_TIME = 0x17,
		GeneralizedTime = 0x18,
		GraphicString = 0x19,
		VisibleString = 0x1A,
		GeneralString = 0x1B,
		UniversalString = 0x1C,
		CHARACTER = 0x1D,
		BMPString = 0x1E
	}

	class Node
	{
		public Tag Tag { get; set; }

		public int Length { get; set; }

		public int ContentsLength { get; set; }

		public List<Node> Children  { get; set; }

		public string Value { get; set; }

		public Node()
		{
			Children = new List<Node>();
		}

		public string ToString()
		{
			Node tree = this;
			var sb = new StringBuilder();
			List<Node> firstStack = new List<Node>();
			firstStack.Add(tree);

			List<List<Node>> childListStack = new List<List<Node>>();
			childListStack.Add(firstStack);

			while (childListStack.Count > 0)
			{
				List<Node> childStack = childListStack[childListStack.Count - 1];

				if (childStack.Count == 0)
				{
					childListStack.RemoveAt(childListStack.Count - 1);
				}
				else
				{
					tree = childStack[0];
					childStack.RemoveAt(0);

					string indent = "";
					for (int i = 0; i < childListStack.Count - 1; i++)
					{
						indent += (childListStack[i].Count > 0) ? "|  " : "   ";
					}
					var v = (tree.Value != null) ? " " + tree.Value : "";
					sb.AppendLine(indent + "+- " + tree.Tag.ToString() + v);

					if (tree.Children.Count > 0)
					{
						var l = new List<Node>();
						l.AddRange(tree.Children);
						childListStack.Add(l);
					}
				}
			}
			return sb.ToString();
		}
	}
	
	public struct Tag
	{
		public IdentifierClass IdentifierClass { get; set; }
		public bool IsConstructed { get; set; }
		public bool IsPrimitive { get { return !IsConstructed; } }
		public TagName Number { get; set; }

		public Tag(IdentifierClass identifierClass, bool isConstructed, int number)
		{
			IdentifierClass = identifierClass;
			IsConstructed = isConstructed;
			Number = (TagName)number;
		}

		public string ToString()
		{
			return string.Format("{2} {0} {1}", IdentifierClass, IsConstructed ? "constructed" : "primitive", Number);
		}
	}

	public class ASN1Tools
	{
		byte[] buffer;
		int offset;
		int _depth;
		int _length;

		public ASN1Tools(byte[] data)
		{
			// NOTE: This implementation is supposed to only conform to DER (subset of BER) encoding although some rules for CER and BER also exist for future development. 
			buffer = data;
			offset = 0;
			_depth = 0;
			_length = data.Length;
		}

		public void Decode()
		{
			var node = ReadNext();
			debug_log "------------------------------";
			debug_log node.ToString();
			debug_log "------------------------------";
		}
		
		void Print(string str)
		{
			var tabs = "";
			for (var i = 0; i < _depth; i++)
				tabs += "  ";

			debug_log _currentOffset + ":d=" + _depth + "  hl=" + _currentHeaderLength + " l=" + _currentContentsLength + " " + tabs + str;
		}

		int _currentOffset = 0;
		int _currentHeaderLength = 0;
		int _currentContentsLength = 0;
		int _currentDepth = 0;
		
		Node ReadChildren(Node node)
		{
			var length = node.ContentsLength;
			_depth++;
			var seqLength = 0;
			while (seqLength < length)
			{
				debug_log offset + " " + seqLength + " " + length;
				var seqNode = ReadNext();
				seqLength += seqNode.Length;
				node.Children.Add(seqNode);
				debug_log offset + " " + seqLength + " " + seqNode.Length + " " + length;
			}
			debug_log "end";
			_depth--;
			return node;
		}

		Node ReadNext()
		{
			if (offset >= _length)
				return null;
			
			_currentOffset = offset;
			var currentOffset = offset;
			var node = new Node();
			var tag = node.Tag = ReadTag();
			node.ContentsLength = ReadLength();
			_currentContentsLength = node.ContentsLength;

			_currentHeaderLength = offset - currentOffset;

			node = ReadContents(node);

			node.Length = offset - currentOffset;
			var totalRead = _currentHeaderLength + node.ContentsLength;
			if (node.Length != totalRead)
				debug_log("WARNING: expected: " + totalRead + " but got: " + node.Length);

			Print(tag.Number + " " + node.Length + " CLOSE ");
			return node;
		}

		Node ReadContents(Node node)
		{
			var found = false;
			var tag = node.Tag;
			var length = node.ContentsLength;
			if (tag.IsConstructed)
			{
				switch(tag.Number)
				{
					case TagName.SEQUENCE:
					case TagName.SET:
						Print(tag.ToString());
						node = ReadChildren(node);
						found = true;
						break;

					default:
						if (tag.IdentifierClass == IdentifierClass.ContextSpecific)
						{
							Print("[" + tag.Number + "] " + tag.ToString());
							node = ReadChildren(node);
							found = true;
						}
						else{
							throw new Exception("Unknown tag");
							Print("Unknown " + tag.ToString());
							ReadBytes(node.ContentsLength);
						}

						break;
				}
			}
			else if (tag.IsPrimitive)
			{
				switch(tag.Number)
				{
					case TagName.EOC:
						throw new Exception("The end of content, not supported by DER encoding");

					case TagName.BOOLEAN:
						bool v = ReadByte() != 0x0;
						Print(node.Value = "BOOLEAN " + v);
						found = true;
						break;

					case TagName.INTEGER:
						if (length > 8)
						{
							var res = "";
							for (var i = 0; i < length; i++)
							{
								res += Uno.String.Format("{0:X}", ReadByte());
							}
							Print(node.Value = "INTEGER " + res);
							found = true;
						}
						else
						{
							Print(node.Value = "INTEGER " + ReadInteger(length));
							found = true;
						}
						break;

					case TagName._NULL:
						Print(node.Value = "NULL ");
						found = true;
						break;

					case TagName.OBJECT_ID:
						var oid = DecodeOID(length);
						string oidv = "";
						if (!OIDS.TryGetValue(oid, out oidv))
						{
							oidv = "Unknown";
						}
						Print(node.Value = "OBJECT_ID " + oid + " " + oidv);
						found = true;
						break;
				}
			}
			if (!found)
			switch(tag.Number)
			{
				case TagName.BIT_STRING:
					Print("BIT_STRING "  + tag.ToString());
					
					if (tag.IsPrimitive)
					{
						int unusedBits = (int)(uint)ReadByte();
						/*if (unusedBits > 0)
						{
							ReadNext(length - unusedBits);
							ReadBytes(unusedBits);
						}
						else
							ReadNext(length);*/
					}/*else  {
						throw new Exception("DER encoding only support primitive BIT_STRING");
					}*/
					ReadBytes(length -1);
					found = true;
					break;
				case TagName.OCTET_STRING:
					Print("OCTET_STRING " + tag.ToString());
					if (tag.IsConstructed)
						throw new Exception("DER encoding only support primitive OCTET_STRING");

					ReadBytes(length);
					//ReadNext(length);
					found = true;
					break;

				case TagName.UTC_TIME:
					var time = ReadUtcTime(length);
					Print(node.Value = "UTC_TIME " + time);
					found = true;
					break;

				case TagName.UTF8_STRING:
				case TagName.IA5_STRING:
				case TagName.PRINTABLE_STRING:
					Print(node.Value = "STRING: " + Uno.Text.Utf8.GetString(ReadBytes(length)));
					found = true;
					break;
			}

			return node;
		}

		public Tag ReadTag()
		{
			var tagByte = ReadByte();

			int tagNumber = tagByte & 0x1F;
			if (tagNumber == 0x1F)
			{
				tagNumber = 0;
				byte sb = 0;
				int bits = 0;
				do
				{
					sb = ReadByte();
					tagNumber <<= 7;
					tagNumber |= sb & 0x7F;
					bits += 7;
					if (bits > 31)
						throw new Exception("Too long tag");
				}
				while ((sb & 0x80) != 0);
			}

			return new Tag((IdentifierClass)(tagByte >> 6), (tagByte >> 5 & 1) == 1, tagNumber);
		}

		public int ReadLength()
		{
			var a = ReadByte();
			var indefiniteLength = a == 0x80;
			if (indefiniteLength)
			{
				throw new Exception("indefinite length (not allowed for DER encoding, so skipped here)");
			}
			var extendedLength = (a & 0x80) == 0x80;
			int l = a & 0x7F;
			if (extendedLength)
			{
				if (l == 1)
				{
					return ReadByte();
				}
				else if (l == 2)
				{ 
					return ReadByte() << 8 | ReadByte();
				}
				else
				{
					int el = 0;
					for (var i = 0; i < l; i++)
					{
						el += ReadByte();
					}
					debug_log "Unknown extended length " + l;
					return el;
				}
			}
			return l;
		}
		
		public ulong ReadInteger(int length)
		{
			length--;
			ulong v = 0;
			for (var i = 0; i < length; i++)
			{
				v |=(ulong)ReadByte() << (length - i) * 8;
			}
			return v | (ulong)ReadByte();
		}
		
		byte ReadByte()
		{
			try
			{ 
				return buffer[offset++];
			}
			catch(Exception e)
			{
				debug_log offset;
				throw e;
			}
		}

		byte[] ReadBytes(int length)
		{
			var result = new byte[length];
			for (int i = 0; i < length; i++)
				result[i] = ReadByte();
			
			return result;
		}

		public string ReadUtcTime(int length)
		{
			// "YYMMDD000000Z"
			string date = Uno.Text.Utf8.GetString(ReadBytes(length));
			var year = int.Parse("" + date[0] + date[1]);
			var month = int.Parse("" + date[2] + date[3]);
			var day = int.Parse("" + date[4] + date[5]);
			var hour = int.Parse("" + date[6] + date[7]);
			var minutes = int.Parse("" + date[8] + date[9]);
			var seconds = int.Parse("" + date[10] + date[11]);
			var t = new Uno.Time.ZonedDateTime(new Uno.Time.LocalDateTime(2000 + year, month, day, hour, minutes, seconds), Uno.Time.DateTimeZone.Utc);

			return t.ToString();
		}

		public string DecodeOID(int length)
		{
			// 1.2.840.113549.1.1.11 sha256WithRSAEncryption(PKCS #1)
			// 2A 86 48 86 F7 0D 01 01 0B
			var result = "";
			for(int i = 0; i < length; i++)
			{
				var b = ReadByte();
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
						++i;
						b = ReadByte();
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
				if (i < length - 1)
					result += ".";
			}

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
{ "2.5.29.32","certificatePolicies" },
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
