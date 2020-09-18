using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Xml.Linq;

namespace Function_App_Name_NS
{
    public static class Function_Name
    {
        [FunctionName("Function_Name")]
        public static async Task<HttpResponseMessage> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
            ILogger log, ExecutionContext context)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            //Get query parameters
            string name = req.Query["name"];

            //Deserialize xml stream into class
            //**********************************************************************************
            var serializer = new System.Xml.Serialization.XmlSerializer(typeof(ClassName.Type));
            ClassName.Type ClassVariableName = (ClassName.Type)serializer.Deserialize(req.Body);

            //Deserialize json stream into class
            //**********************************************************************************
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            ClassName.Type ClassVariableName = JsonConvert.DeserializeObject<ClassName.Type>(requestBody);

            //Deserialize json stream into dynamic json object
            //**********************************************************************************
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            var jsonObj = JObject.Parse(requestBody);

            //Transform
            //**********************************************************************************
            string output = MapToClass(ClassVariableName).ToString();

            //Return json
            //**********************************************************************************
            //Convert JSON object to string
            string jsonOutput = JsonConvert.SerializeObject(output);
            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(jsonOutput, Encoding.UTF8, "application/json")
            };

            //Return XML
            //**********************************************************************************
            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(output, Encoding.UTF8, "text/xml")
            };
        }

        private static XElement MapToXML(inputobject objectname)
        {
        }

        private static ClassName MapToClass(inputobject objectname)
        {
        }
    }
}
