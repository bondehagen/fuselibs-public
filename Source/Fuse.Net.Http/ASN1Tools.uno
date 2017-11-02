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

	public class Asn1Node
	{
		public Tag Tag { get; set; }

		public int Length { get; set; }

		public int ContentsLength { get; set; }

		public List<Asn1Node> Children  { get; set; }

		public string Value { get; set; }

		public Asn1Node()
		{
			Children = new List<Asn1Node>();
		}

		public string ToString()
		{
			Asn1Node tree = this;
			var sb = new StringBuilder();
			List<Asn1Node> firstStack = new List<Asn1Node>();
			firstStack.Add(tree);

			List<List<Asn1Node>> childListStack = new List<List<Asn1Node>>();
			childListStack.Add(firstStack);

			while (childListStack.Count > 0)
			{
				List<Asn1Node> childStack = childListStack[childListStack.Count - 1];

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
						var l = new List<Asn1Node>();
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
			var tagName = (IdentifierClass == IdentifierClass.ContextSpecific) ? "[" +(int)Number+"]" : string.Format("{0}", Number);
			return string.Format("{2} {0} {1}", IdentifierClass, IsConstructed ? "constructed" : "primitive", tagName);
		}
	}

	public class ASN1Tools // TODO: rename Asn1Der 
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

		public Asn1Node Decode()
		{
			var node = ReadNext();
			debug_log "------------------------------";
			debug_log node.ToString();
			debug_log "------------------------------";
			return node;
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
		
		Asn1Node ReadChildren(Asn1Node node)
		{
			_depth++;
			var seqLength = 0;
			while (seqLength < node.ContentsLength)
			{
				var seqAsn1Node = ReadNext();
				seqLength += seqAsn1Node.Length;
				node.Children.Add(seqAsn1Node);
			}
			_depth--;
			return node;
		}

		Asn1Node ReadNext()
		{
			if (offset >= _length)
				return null;
			
			_currentOffset = offset;
			var currentOffset = offset;
			var node = new Asn1Node();
			var tag = node.Tag = ReadTag();
			node.ContentsLength = ReadLength();
			_currentContentsLength = node.ContentsLength;

			_currentHeaderLength = offset - currentOffset;

			node = ReadContents(node);

			node.Length = offset - currentOffset;
			var totalRead = _currentHeaderLength + node.ContentsLength;
			if (node.Length != totalRead)
				debug_log("WARNING: expected: " + totalRead + " but got: " + node.Length);

			return node;
		}

		Asn1Node ReadContents(Asn1Node node)
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
							Print(tag.ToString());
							node = ReadChildren(node);
							found = true;
						}
						else
						{
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
						Print(node.Value = v.ToString());
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
							Print(node.Value = res);
							found = true;
						}
						else
						{
							Print(node.Value = "" + ReadInteger(length));
							found = true;
						}
						break;

					case TagName._NULL:
						Print(node.Value = "NULL");
						found = true;
						break;

					case TagName.OBJECT_ID:
						var oid = DecodeOID(length);
						string oidv = "";
						if (!ObjectIdentifierTable.TryGetValue(oid, out oidv))
						{
							oidv = oid;
						}
						Print(node.Value = oidv);
						found = true;
						break;
				}
			}
			if (!found)
			switch(tag.Number)
			{
				case TagName.BIT_STRING:
					Print(tag.ToString());
					
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
					Print(tag.ToString());
					if (tag.IsConstructed)
						throw new Exception("DER encoding only support primitive OCTET_STRING");

					ReadBytes(length);
					//ReadNext(length);
					found = true;
					break;

				case TagName.UTC_TIME:
					var time = ReadUtcTime(length);
					Print(node.Value = time);
					found = true;
					break;

				case TagName.UTF8_STRING:
				case TagName.IA5_STRING:
				case TagName.PRINTABLE_STRING:
					Print(node.Value = Uno.Text.Utf8.GetString(ReadBytes(length)));
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
			var result = "";
			for(int i = 0; i < length; i++)
			{
				var b = ReadByte();
				if ((b & 0x80) == 0) 
				{
					if (b < 40)
						result += b;
					else
						result += (b / 40) + "." + (b % 40);
				}
				else
				{
					int v = b & 0x7F;
					var shift = 0;
					do
					{
						++i;
						b = ReadByte();
						v <<= 7;
						v |= b & 0x7F;
						shift += 7;
						if (shift > 24)
							throw new Exception("Too long tag");
							
					} while ((b & 0x80) != 0);
					result += v;
				}
				if (i < length - 1)
					result += ".";
			}

			return result;
		}
	}
}
