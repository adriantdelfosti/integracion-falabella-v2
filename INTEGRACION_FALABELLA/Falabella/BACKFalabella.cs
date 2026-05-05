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
        string cod_carrier_trujillo = ConfigurationManager.AppSettings["CodCarrierTrujillo"];
        string auth_user = ConfigurationManager.AppSettings["AuthorizationUser"];
        string token = ConfigurationManager.AppSettings["Token"];

        string ObtenerFecha()
        {
            string fechaConfig = ConfigurationManager.AppSettings["Fecha"];
            return string.IsNullOrEmpty(fechaConfig)
                ? DateTime.Now.ToString("yyyy-MM-dd")
                : fechaConfig;
        }
        public async Task<List<BEBaseResponse>> PlanillasEnvios() 
        {
            List<BEBaseResponse> responseFalabelList = new List<BEBaseResponse>();
            
            string apiPlanillasEnvios = url_falabella + "/Server.Web/dominio/envios/ENThirdPartyLogistic/v2/planillas-envios"+
                                        "?codigoCarrier=" + cod_carrier + "&fecha=" + ObtenerFecha();
            string? contentResponse = "";
            try {
                RestClient client = new RestClient(apiPlanillasEnvios);
                RestRequest request = new RestRequest();
                request.Method = Method.Get;
                request.AddHeader("Authorization-User", string.IsNullOrEmpty(auth_user) ? cod_carrier : auth_user);
                request.AddHeader("Authorization-Token", token);
                RestResponse response = client.Execute(request);
                contentResponse = response.Content;
                dynamic[] dataResponseFalabella = JsonConvert.DeserializeObject<dynamic[]>(contentResponse);
                int cant = dataResponseFalabella.Length;
                if (cant > 0)
                {
                    foreach (var item in dataResponseFalabella)
                    {
                        JObject contentFalabella = null;
                        BEBaseResponse responseFalabella = new BEBaseResponse();
                        if (item == null) {
                            responseFalabella.message = "no contiene valores";
                            responseFalabella.statusCode = 500;
                            responseFalabella.razon = "";
                            responseFalabella.carga_Falabella = null;
                            responseFalabelList.Add(responseFalabella);
                        }

                        contentFalabella = item;

                        if (response.StatusCode == HttpStatusCode.InternalServerError)
                        {
                            responseFalabella.message = (string?)contentFalabella["Mensaje"];
                            responseFalabella.statusCode = 500;
                            responseFalabella.razon = (string?)contentFalabella["Razon"];
                            responseFalabella.carga_Falabella = null;
                            responseFalabelList.Add(responseFalabella);
                        }

                        if (response.StatusCode == HttpStatusCode.OK)
                        {


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

                           
                        }


                        responseFalabelList.Add(responseFalabella);


                    }
                }
                else
                {
                    BEBaseResponse responseFalabella = new BEBaseResponse();
                    responseFalabella.message = "no contiene valores";
                    responseFalabella.statusCode = 500;
                    responseFalabella.razon = "";
                    responseFalabella.carga_Falabella = null;

                    responseFalabelList.Add(responseFalabella);
                    return responseFalabelList;
                }
                /*JObject contentFalabella = null;
                if (contentResponse != null)
                {
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
                    else
                    {
                        contentFalabella = JObject.Parse(contentResponse);
                    }

                }
*/
/*
                if (response.StatusCode == HttpStatusCode.InternalServerError)
                {
                    responseFalabella.message = (string?)contentFalabella["Mensaje"];
                    responseFalabella.statusCode = 500;
                    responseFalabella.razon = (string?)contentFalabella["Razon"];
                    responseFalabella.carga_Falabella = null;
                    return responseFalabella;
                }

                if (response.StatusCode == HttpStatusCode.OK)
                {


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
*/


                return responseFalabelList;
            }
            catch (Exception ex)
            {
                BEBaseResponse responseFalabella = new BEBaseResponse();
                Console.WriteLine(ex.Message);
                responseFalabella.message = ex.Message;
                responseFalabella.statusCode = 500;
                responseFalabella.razon = "";
                responseFalabella.carga_Falabella = null;
                responseFalabelList.Add(responseFalabella);
                return responseFalabelList;
            }
        }

        public async Task<List<BEBaseResponse>> PlanillasEnviosTrujillo()
        {
            List<BEBaseResponse> responseFalabelList = new List<BEBaseResponse>();

            string apiPlanillasEnvios = url_falabella + "/Server.Web/dominio/envios/ENThirdPartyLogistic/v2/planillas-envios" +
                                        "?codigoCarrier=" + cod_carrier_trujillo + "&fecha=" + ObtenerFecha();
            string? contentResponse = "";
            try
            {
                RestClient client = new RestClient(apiPlanillasEnvios);
                RestRequest request = new RestRequest();
                request.Method = Method.Get;
                request.AddHeader("Authorization-User", string.IsNullOrEmpty(auth_user) ? cod_carrier_trujillo : auth_user);
                request.AddHeader("Authorization-Token", token);
                RestResponse response = client.Execute(request);
                contentResponse = response.Content;
                dynamic[] dataResponseFalabella = JsonConvert.DeserializeObject<dynamic[]>(contentResponse);
                int cant = dataResponseFalabella.Length;
                if (cant > 0)
                {
                    foreach (var item in dataResponseFalabella)
                    {
                        JObject contentFalabella = null;
                        BEBaseResponse responseFalabella = new BEBaseResponse();
                        if (item == null)
                        {
                            responseFalabella.message = "no contiene valores";
                            responseFalabella.statusCode = 500;
                            responseFalabella.razon = "";
                            responseFalabella.carga_Falabella = null;
                            responseFalabelList.Add(responseFalabella);
                        }

                        contentFalabella = item;

                        if (response.StatusCode == HttpStatusCode.InternalServerError)
                        {
                            responseFalabella.message = (string?)contentFalabella["Mensaje"];
                            responseFalabella.statusCode = 500;
                            responseFalabella.razon = (string?)contentFalabella["Razon"];
                            responseFalabella.carga_Falabella = null;
                            responseFalabelList.Add(responseFalabella);
                        }

                        if (response.StatusCode == HttpStatusCode.OK)
                        {
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
                        }

                        responseFalabelList.Add(responseFalabella);
                    }
                }
                else
                {
                    BEBaseResponse responseFalabella = new BEBaseResponse();
                    responseFalabella.message = "no contiene valores";
                    responseFalabella.statusCode = 500;
                    responseFalabella.razon = "";
                    responseFalabella.carga_Falabella = null;

                    responseFalabelList.Add(responseFalabella);
                    return responseFalabelList;
                }

                return responseFalabelList;
            }
            catch (Exception ex)
            {
                BEBaseResponse responseFalabella = new BEBaseResponse();
                Console.WriteLine(ex.Message);
                responseFalabella.message = ex.Message;
                responseFalabella.statusCode = 500;
                responseFalabella.razon = "";
                responseFalabella.carga_Falabella = null;
                responseFalabelList.Add(responseFalabella);
                return responseFalabelList;
            }
        }

        
    }
}
