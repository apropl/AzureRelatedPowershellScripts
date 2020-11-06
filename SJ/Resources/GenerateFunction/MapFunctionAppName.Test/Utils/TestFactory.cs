using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.Internal;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Primitives;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace Function_App_Name_NS.Test
{
  public class TestFactory
  {
    public static IEnumerable<object[]> Data()
    {
      return new List<object[]>
            {
                new object[] { "name", "Bill" },
                new object[] { "name", "Paul" },
                new object[] { "name", "Steve" }

            };
    }

    private static Dictionary<string, StringValues> CreateDictionary(string key, string value)
    {
      var qs = new Dictionary<string, StringValues>
            {
                { key, value }
            };
      return qs;
    }

    public static DefaultHttpRequest CreateHttpRequest(string queryStringKey, string queryStringValue)
    {
      var request = new DefaultHttpRequest(new DefaultHttpContext())
      {
        Query = new QueryCollection(CreateDictionary(queryStringKey, queryStringValue))
      };
      return request;
    }

    public static DefaultHttpRequest CreateHttpRequest(string bodyFilePath)
    {
      var request = new DefaultHttpRequest(new DefaultHttpContext())
      {
        Body = System.IO.File.OpenRead(bodyFilePath)
      };
      return request;
    }

    public static DefaultHttpRequest CreateHttpRequest(string queryStringKey, string queryStringValue, string body)
    {
      var request = new DefaultHttpRequest(new DefaultHttpContext())
      {
        Query = new QueryCollection(CreateDictionary(queryStringKey, queryStringValue)),
        Body = new MemoryStream(Encoding.UTF8.GetBytes(body))
      };
      return request;
    }

    public static DefaultHttpRequest CreateHttpRequest(Dictionary<string,string> headers, string body)
    {
      var request = new DefaultHttpRequest(new DefaultHttpContext());
      if (!string.IsNullOrEmpty(body))
      {
        request.Body = new MemoryStream(Encoding.UTF8.GetBytes(body));
      }

      foreach (var header in headers)
      {
        request.Headers.Add(header.Key, new StringValues(header.Value));
      }
      
      return request;
    }

    public static DefaultHttpRequest CreateHttpRequest(Dictionary<string, StringValues> queryparams)
    {
            var request = new DefaultHttpRequest(new DefaultHttpContext())
            {
                Query = new QueryCollection(queryparams)
            };        

        return request;
    }

        public static ILogger CreateLogger(LoggerTypes type = LoggerTypes.Null)
    {
      ILogger logger;

      if (type == LoggerTypes.List)
      {
        logger = new ListLogger();
      }
      else
      {
        logger = NullLoggerFactory.Instance.CreateLogger("Null Logger");
      }

      return logger;
    }
  }
}
