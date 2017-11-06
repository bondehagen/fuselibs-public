
using Uno;
using Uno.Collections;
using Uno.Text;
using Fuse.Security.X509;

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


	public class Asn1Node : IList<Asn1Node>
	{
		List<Asn1Node> _internalList = new List<Asn1Node>();
		public void Insert(int index, Asn1Node item)
		{
			_internalList.Insert(index, item);
		}
        public void RemoveAt(int index)
        {
        	_internalList.RemoveAt(index);
        }

        public Asn1Node this[int index]
        {
            get { return _internalList[index]; }
        }
        public void Clear()
        {
        	_internalList.Clear();
        }
        public bool Remove(Asn1Node item)
        {
        	return _internalList.Remove(item);
        }
        public bool Contains(Asn1Node item)
        {
        	return _internalList.Contains(item);
        }
		public void Add(Asn1Node item)
		{
			_internalList.Add(item);
		}
		public IEnumerator<Asn1Node> GetEnumerator()
		{
			return _internalList.GetEnumerator();
		}
		public int Count { get { return _internalList.Count; } }
		public Tag Tag { get; set; }

		public int Length { get; set; }
		public int ContentsLength { get; set; }
		public byte[] Data { get; internal set; }

		public Asn1Node(Tag tag, int contentsLength)
		{
			Data = new byte[contentsLength];
			Tag = tag;
			ContentsLength = contentsLength;
		}

		public ulong AsUInt64()
		{
			var length = ContentsLength- 1;
			ulong v = 0;
			for (var i = 0; i < length; i++)
			{
				v |= (ulong)Data[i] << (length - i) * 8;
			}
			return v | Data[length];
		}

		public string AsHex()
		{
			var res = "";
			for (var i = 0; i < ContentsLength; i++)
			{
				res += string.Format("{0:X2}", Data[i]);
			}
			return res;
		}

		public bool AsBool()
		{
			if (Tag.Number != TagName.BOOLEAN)
				throw new Exception("Wrong tag");

			if (Data != null)
				return Data[0] != 0x0;

			return false;
		}

		public string AsString()
		{
			return Uno.Text.Utf8.GetString(Data);
		}

		public Uno.Time.ZonedDateTime AsDateTime()
		{
			// TODO: Add support for GeneralizedTime
			// "YYMMDD000000Z"
			string date = Uno.Text.Utf8.GetString(Data);
			var year = int.Parse("" + date[0] + date[1]);
			var month = int.Parse("" + date[2] + date[3]);
			var day = int.Parse("" + date[4] + date[5]);
			var hour = int.Parse("" + date[6] + date[7]);
			var minutes = int.Parse("" + date[8] + date[9]);
			var seconds = int.Parse("" + date[10] + date[11]);
			var t = new Uno.Time.ZonedDateTime(new Uno.Time.LocalDateTime(2000 + year, month, day, hour, minutes, seconds), Uno.Time.DateTimeZone.Utc);

			return t;
		}

		public Oid AsOid()
		{
			var result = "";
			for (int i = 0; i < ContentsLength; i++)
			{
				var b = Data[i];
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
						b = Data[++i];
						v <<= 7;
						v |= b & 0x7F;
						shift += 7;
						if (shift > 24)
							throw new Exception("Too long tag");

					} while ((b & 0x80) != 0);
					result += v;
				}
				if (i < ContentsLength - 1)
					result += ".";
			}

			return new Oid(result);
		}

		public override string ToString()
		{
			var tree = this;
			var sb = new StringBuilder();
			var firstStack = new List<Asn1Node> { tree };

			var childListStack = new List<List<Asn1Node>> { firstStack };

			while (childListStack.Count > 0)
			{
				var childStack = childListStack[childListStack.Count - 1];

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
					var v = tree.GetSimpleValue();
					sb.AppendLine(indent + "+- " + tree.Tag.ToString() + " " + v);

					if (tree.Count > 0)
					{
						var l = new List<Asn1Node>();
						foreach(var i in tree)
							l.Add(i);

						childListStack.Add(l);
					}
				}
			}
			return sb.ToString();
		}

		private string GetSimpleValue()
		{
			switch (Tag.Number)
			{
				case TagName.OBJECT_ID:
					return AsOid().ToString();
				case TagName.BOOLEAN:
					return AsBool().ToString();
				case TagName.INTEGER:
					return ContentsLength > 8 ? AsHex() : AsUInt64().ToString();
				case TagName._NULL:
					return "NULL";
				case TagName.UTF8_STRING:
				case TagName.IA5_STRING:
				case TagName.PRINTABLE_STRING:
					return AsString();
				case TagName.UTC_TIME:
					return AsDateTime().ToString();
			}
			return "Data [" + ContentsLength + "]";
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

		public override string ToString()
		{
			var tagName = (IdentifierClass == IdentifierClass.ContextSpecific) ? "[" + (int)Number + "]" : string.Format("{0}", Number);
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
			return ReadNext();
		}

		void Print(string str)
		{
			var tabs = "";
			for (var i = 0; i < _depth; i++)
				tabs += "  ";

		//	debug_log _currentOffset +":d=" + _depth + "  hl=" + _currentHeaderLength + " l=" + _currentContentsLength + " " + tabs + str;
		}

		/*int _currentOffset = 0;
		int _currentHeaderLength = 0;
		int _currentContentsLength = 0;
		int _currentDepth = 0;*/

		Asn1Node ReadChildren(Asn1Node node)
		{
			_depth++;
			var aggregatedLength = 0;
			while (aggregatedLength < node.ContentsLength)
			{
				var seqAsn1Node = ReadNext();
				aggregatedLength += seqAsn1Node.Length;
				node.Add(seqAsn1Node);
			}
			_depth--;
			return node;
		}

		Asn1Node ReadNext()
		{
			if (offset >= _length)
				return null;

			var startOffset = offset;
			var node = new Asn1Node(ReadTag(), ReadLength());
			var headerLength = offset - startOffset;

			node = ReadContents(node);

			node.Length = offset - startOffset;
			var totalRead = headerLength + node.ContentsLength;
			if (node.Length != totalRead)
				debug_log("WARNING: expected: " + totalRead + " but got: " + node.Length);

			return node;
		}

		Asn1Node ReadContents(Asn1Node node)
		{
			var tag = node.Tag;
			var length = node.ContentsLength;
			if (tag.IsConstructed)
			{
				switch (tag.Number)
				{
					case TagName.SEQUENCE:
					case TagName.SET:
						//Print(tag.ToString());
						return ReadChildren(node);

					default:
						if (tag.IdentifierClass == IdentifierClass.ContextSpecific)
						{
							//Print(tag.ToString());
							return ReadChildren(node);
						}
						else
							throw new Exception("Unknown tag");

						break;
				}
			}
			switch (tag.Number)
			{
				case TagName.EOC:
					throw new Exception("The end of content, not supported by DER encoding");
					
				case TagName._NULL:
					return node;

				case TagName.OBJECT_ID:
				case TagName.BOOLEAN:
				case TagName.INTEGER:
				case TagName.UTF8_STRING:
				case TagName.IA5_STRING:
				case TagName.PRINTABLE_STRING:
				case TagName.UTC_TIME:
					for (var i = 0; i < length; i++)
						node.Data[i] = ReadByte();

					return node;

				case TagName.BIT_STRING:
					if (tag.IsConstructed)
						throw new Exception("DER encoding only support primitive BIT_STRING");

					int unusedBits = (int)(uint)ReadByte();
					node.Data = new byte[(length - 1) - unusedBits];
					for (var i = 0; i < (length - 1) - unusedBits; i++)
						node.Data[i] = ReadByte();

					for (var i = 0; i < unusedBits; i++)
						ReadByte();

					return node;

				case TagName.OCTET_STRING:
					if (tag.IsConstructed)
						throw new Exception("DER encoding only support primitive OCTET_STRING");

					for (var i = 0; i < length; i++)
						node.Data[i] = ReadByte();

					return node;
			}

			throw new Exception("Could not parse contents on offset " + offset);
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

		byte ReadByte()
		{
			return buffer[offset++];
		}
	}
}
