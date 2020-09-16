using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using Xunit;
using Xunit.Abstractions;
using Microsoft.Extensions.Primitives;
using System.Globalization;
using System.Threading.Tasks;
using System.Xml.Serialization;
using System.IO;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Xml;
using System.Linq;
using Microsoft.AspNetCore.Mvc.Internal;

namespace Function_App_Name_NS.Test
{
    public class UnitTest
    {
        private readonly ITestOutputHelper output;

        public UnitTest(ITestOutputHelper output)
        {
            this.output = output;
        }

        private readonly ILogger logger = TestFactory.CreateLogger();


        //private bool ValidateAgainstSchema(string xml)
        //{
        //    XmlSchemaSet schemas = new XmlSchemaSet();
        //    schemas.Add("http://www.funkwerk-itk.com/Siri/KARI-TrainFormation-Import", "./Banenor/KARI_TrainFormationImport_V1.7.xsd");

        //    XDocument doc = XDocument.Parse(xml);
        //    string msg = "";
        //    doc.Validate(schemas, (o, e) =>
        //    {
        //        msg += e.Message + Environment.NewLine;
        //    });

        //    output.WriteLine(string.IsNullOrEmpty(msg) ? "Document is valid" : "Document invalid: " + msg);

        //    return string.IsNullOrEmpty(msg);
        //}

        private async Task<string> HTTP_TestMap(string inputfile, string destinationFile)
        {
            string input = await File.ReadAllTextAsync(inputfile);

            string source = input;
            string tempInputFile = Path.GetTempFileName();
            System.IO.File.WriteAllText(tempInputFile, source);
            output.WriteLine("Result stored temporarily in " + tempInputFile);

            var request = TestFactory.CreateHttpRequest("tmkKey", "tmpVal", source);
            Microsoft.Azure.WebJobs.ExecutionContext context = new Microsoft.Azure.WebJobs.ExecutionContext()
            {
                FunctionName = "Test",
                FunctionAppDirectory = "TestAppDirectory",
                FunctionDirectory = "TestDirectory",
                InvocationId = Guid.NewGuid()
            };
			
			//Run the transformation by calling "Transform" which in this case is the function name
            var response = await Transform.Run(request, logger, context);

            if (response == null)
            {
                return null;
            }

            string responseContent = await response.Content.ReadAsStringAsync();

            if (responseContent != null)
            {
                System.IO.File.WriteAllText(destinationFile, responseContent);
                return responseContent;
            }

            return null;
        }

        [Fact]
        public async void TestSampleEventJSON()
        {
            var TestMapOutput = await HTTP_TestMap("../../../SampleFiles/SampleEvent.json",
              "../../../SampleFiles/SampleEvent_tmpOutput.json");

            var jsonObj = JObject.Parse(TestMapOutput);

            Assert.True(jsonObj != null);

        }
		
		        [Fact]
        public async void TestSampleEventXML()
        {
            var TestMapOutput = await HTTP_TestMap("../../../SampleFiles/SampleEvent.xml",
              "../../../SampleFiles/SampleEvent_tmpOutput.xml");


            XmlDocument doc = new XmlDocument();
            doc.LoadXml(TestMapOutput);
            string json = JsonConvert.SerializeXmlNode(doc);
            var jsonObj = JObject.Parse(TestMapOutput);

            var dt = (DateTime)jsonObj.SelectToken("Siri.ServiceDelivery.ResponseTimestamp");

            Assert.True(jsonObj != null);

        }
    }
}

