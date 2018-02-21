using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Net.Http
{
	extern(Android) internal class ForeignHttpHeaderBridge
	{
		public static Java.Object FromDictionaryToMap(IDictionary<string, IList<string>> dictionary)
		{
			var javaMap = new DictionaryToMap(dictionary);
			return javaMap.Get();
		}

		public static IDictionary<string, IEnumerable<string>> FromMapToDictionary(Java.Object map)
		{
			var a = new MapToDictionary(map);
			//_statusLine = a.GetStatus();
			return a.Get();
		}
		
		class DictionaryToMap
		{
			Java.Object _map;

			public DictionaryToMap(IDictionary<string, IList<string>> dictionary)
			{
				_map = CreateMap();
				foreach(var h in dictionary)
				{
					Add(_map, h.Key, h.Value.ToArray());
				}
			}
			
			[Foreign(Language.Java)]
			Java.Object CreateMap()
			@{
				return new java.util.HashMap<String, java.util.List<String>>();
			@}

			[Foreign(Language.Java)]
			void Add(Java.Object omap, string key, string[] values)
			@{
				java.util.Map<String, java.util.List<String>> m =  (java.util.Map<String, java.util.List<String>>)omap;
				m.put(key, java.util.Arrays.asList(values.copyArray()));
			@}

			public Java.Object Get()
			{
				return _map;
			}
		}

		class MapToDictionary
		{
			IDictionary<string, IEnumerable<string>> _dict;
			string _statusLine;

			public MapToDictionary(Java.Object map)
			{
				_dict = new Dictionary<string, IEnumerable<string>>();
				ForeignLoop(map, Add, SetStatus);
			}

			[Foreign(Language.Java)]
			void ForeignLoop(Java.Object omap, Action<string, string[]> add, Action<string> setStatus)
			@{
				java.util.Map<String, java.util.List<String>> m =  (java.util.Map<String, java.util.List<String>>)omap;
				for (java.util.Map.Entry<String, java.util.List<String>> k : m.entrySet()) {
					String key = k.getKey();
					if (key == null) {
						// NOTE: This is the start of a HTTP response message and not normally considered part of the headers, but Android includes it here
						setStatus.run(k.getValue().get(0));
					} else {
						add.run(key, new StringArray(k.getValue().toArray(new String[0])));
					}
				}
			@}

			void SetStatus(string key)
			{
				_statusLine = key;
			}

			void Add(string key, string[] values)
			{
				_dict.Add(key, values);
			}

			public string GetStatus()
			{
				return _statusLine;
			}

			public IDictionary<string, IEnumerable<string>> Get()
			{
				return _dict;
			}
		}
	}
}
