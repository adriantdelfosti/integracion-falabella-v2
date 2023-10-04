using INTEGRACION_FALABELLA.Models;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using RestSharp;
using System.Configuration;
using System.Net;

namespace INTEGRACION_FALABELLA.Falabella
{
    public class BACKFalabella
    {
        string url_falabella = ConfigurationManager.AppSettings["UrlFalabella"];
        string cod_carrier = ConfigurationManager.AppSettings["CodCarrier"];
        string token = ConfigurationManager.AppSettings["Token"];
        string fecha = ConfigurationManager.AppSettings["Fecha"];
        /*static DateTime fechaActual = DateTime.Now;*/
/*        static DateTime fechaDeseada = fechaActual.AddDays(-1);*/
        /*string fecha = fechaActual.ToString("yyyy-MM-dd");*/
        public async Task<BEBaseResponse> PlanillasEnvios() 
        {
            BEBaseResponse responseFalabella = new BEBaseResponse();
            string apiPlanillasEnvios = url_falabella + "/Server.Web/dominio/envios/ENThirdPartyLogistic/v2/planillas-envios"+
                                        "?codigoCarrier=" + cod_carrier + "&fecha=" + fecha;
            string? contentResponse = "";
            try {
                RestClient client = new RestClient(apiPlanillasEnvios);
                RestRequest request = new RestRequest();
                request.Method = Method.Get;
                request.AddHeader("Authorization-User", cod_carrier);
                request.AddHeader("Authorization-Token", token);
                RestResponse response = client.Execute(request);
                contentResponse = response.Content;
                JObject contentFalabella=null;
                if (contentResponse != null ) {
                    if (contentResponse.Contains("[") && contentResponse.Contains("]"))
                    {
                        contentResponse = contentResponse.Trim('[', ']');
                        if (contentResponse == "" || contentResponse == null) 
                        {
                            responseFalabella.message = "no contiene valores";
                            responseFalabella.statusCode = 500;
                            responseFalabella.razon = "";
                            responseFalabella.carga_Falabella = null;
                            return responseFalabella;
                        }
                        
                        contentFalabella = JObject.Parse(contentResponse);  
                        
                    }
                    else {
                        contentFalabella = JObject.Parse(contentResponse);
                    }
                   
                }

               
                if (response.StatusCode == HttpStatusCode.InternalServerError) {
                    responseFalabella.message = (string?)contentFalabella["Mensaje"];
                    responseFalabella.statusCode = 500;
                    responseFalabella.razon = (string?)contentFalabella["Razon"];
                    responseFalabella.carga_Falabella = null;
                    return responseFalabella;
                }

                if (response.StatusCode == HttpStatusCode.OK) {


                    BECarga_falabella schemaResponse = new BECarga_falabella();
                    schemaResponse.c_cod_plantilla_reparto = (int)contentFalabella["idPlanillaReparto"];
                    schemaResponse.c_estado = (string)contentFalabella["estado"];
                    schemaResponse.c_cod_carrier = (string)contentFalabella["codigoCarrier"];

                    List<Object> listEnvios = new List<Object>();
                  
                        foreach (var envio in contentFalabella["envios"])
                        {
                   
                            listEnvios.Add(envio);
                        }
                   


                    responseFalabella.message = "Respuesta satisfactoriamente.";
                    responseFalabella.statusCode = 200;
                    responseFalabella.razon = "";
                    responseFalabella.carga_Falabella = schemaResponse;
                    responseFalabella.dataEnviosFalabella = listEnvios;
                    return responseFalabella;
                }

                

                return responseFalabella;
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                responseFalabella.message = ex.Message;
                responseFalabella.statusCode = 500;
                responseFalabella.razon = "";
                responseFalabella.carga_Falabella = null;

                return responseFalabella;
            }
        }

        
    }
}
