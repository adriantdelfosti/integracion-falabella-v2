using INTEGRACION_FALABELLA.Falabella;
using INTEGRACION_FALABELLA.Models;
using INTEGRACION_FALABELLA.Repository;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;

namespace Integracion_falabella
{
    class Program
    {
        static CargaMasivaRepository repository;
        static async Task Main(string[] args)
        {
            Console.WriteLine("Integración Falabella");
            repository = new CargaMasivaRepository();
            await  InsertarCargaMasivo();
        }
        private static  async Task InsertarCargaMasivo() 
        {
            //genera modelo en carga masiva para falabella
            BECarga_falabella carga= new BECarga_falabella();
            BACKFalabella falabella = new BACKFalabella();
            BEBaseResponse response_falabella = await falabella.PlanillasEnvios();
            if (response_falabella.statusCode == 200)
            {
                carga.c_cod_plantilla_reparto = response_falabella.carga_Falabella.c_cod_plantilla_reparto;
                carga.c_cod_carrier = response_falabella.carga_Falabella.c_cod_carrier;
                carga.c_activo = "S";
                carga.c_usu_alta = "System";
                carga.c_estado = response_falabella.carga_Falabella.c_estado;
                _ = new BECarga_response();
                BECarga_response response = repository.InsertCargaMasivaFalabella(carga);

                if (response.codigo == "OK")
                {
                    int idCarga = response.c_cod_carga_masivo_falabella;
                    var insertCargaDetalle = InsertCargaMasivoDetalle(idCarga, response_falabella.dataEnviosFalabella);
                }
                Console.WriteLine(response);
            } 

        }

        private static async Task InsertCargaMasivoDetalle(int id, List<Object> carga_Falabella_envios) 
        {
            try
            {
                int row = 1;
                List<string> jsonStrings = new List<string>();
                foreach (var obj in carga_Falabella_envios)
                {
                    string jsonString = JsonConvert.SerializeObject(obj);
                    jsonStrings.Add(jsonString);
                }   
                if (jsonStrings.Count > 0)
                {
                    foreach (var item in jsonStrings)
                    {
                        dynamic jsonData = JsonConvert.DeserializeObject(item);
                        string nro_pedido_valid= jsonData.numeroExterno;
                        string idEstadoEnvio = jsonData.idEstadoEnvio;
                        if (idEstadoEnvio == "50")
                        {
                            BECarga_response_detalle response = repository.InsertCargaMasivaDetalleFalabella(id, row, item, nro_pedido_valid);

                            /*if (response.codigo == "OK" && response.c_cod_carga_masivo_falabella_detalle != 0)
                            {*/
                                BEEnvios envios = new BEEnvios();
                                BEPedidos descripcionPedido = new BEPedidos();
                                var data = JsonConvert.DeserializeObject<BEFalabella>(item);
                                if (data.idEstadoEnvio == "50")
                                {
                                    envios.forma_entrega = data.nombreFormaEntrega;
                                    envios.ubigeo_origen = data.idPoblacionOrigen;
                                    envios.ubigeo_destino = data.idPoblacionDestino;
                                    envios.n_peso = data.pesoLiquidado;
                                    //datos del remitente
                                    envios.cliente_remitente = data.remitente;
                                    //envios.tipo_doc_rem = data.idTipoDocumentoRem;
                                    if (data.idTipoDocumentoRem == "NI")
                                    {
                                        envios.tipo_doc_rem = "RUC";
                                    }
                                    else if (data.idTipoDocumentoRem == "CC")
                                    {
                                        envios.tipo_doc_rem = "DNI";
                                    }
                                    else {
                                        envios.tipo_doc_rem = data.idTipoDocumentoRem;
                                    }
                                    
                                    envios.nro_telefono_rem = data.telefonoRem;
                                    envios.nro_doc_rem = data.documentoRem;
                                    envios.oficina_dir_rem = data.direccionRem;
                                    envios.referencia_rem = data.complementoDirRem;
                                    //datos del destinatario
                                    envios.nom_destinatario = data.destinatario;
                                    envios.tipo_doc_dest = data.idTipoDocumentoDest;
                                    if (data.idTipoDocumentoDest == "NI")
                                    {
                                        envios.tipo_doc_dest = "DNI";
                                    }
                                    else if (data.idTipoDocumentoDest == "CC")
                                    {
                                        envios.tipo_doc_dest = "CE";
                                    }
                                    envios.nro_doc_dest = data.documentoDest;
                                    envios.nro_telefono = data.telefonoDest;
                                    envios.direccion_dest = data.direccionDest;
                                    envios.referencia_dest = data.complementoDirDest;
                                    envios.c_subestado_cli = data.idEstadoEnvio;
                                    //de ahi ver si añado el correo electronico del cliente destinatario
                                    envios.fecha_compromiso_estimada = data.fechaRegistroEnvio;
                                    if (data.nombreFormaEntrega == "Home Delivery")
                                    {
                                        envios.tipo_servicio = "SERVICIO DE PAQUETERIA CD";
                                    }


                                    var dataDinamicUno = JsonConvert.DeserializeObject<BEDinamicouno>(data.dinamicouno);
                                    if (dataDinamicUno.skus.Count() > 0) {
                                        foreach (BESkus item1 in dataDinamicUno.skus)
                                        {
                                            var responseDet = repository.InsertCargaMasivaDetalleSkuFalabella(item1, response.c_cod_carga_masivo_falabella_detalle, data.numero);
                                        }
                                    }
                                    descripcionPedido.nro_paquetes = dataDinamicUno.skus.Count();
                                    Console.WriteLine(dataDinamicUno.skus.Count().ToString());
                                    if (dataDinamicUno.skuDesc == null || dataDinamicUno.skuDesc == "")
                                    {
                                        descripcionPedido.descripcion = "";
                                    }
                                    else {
                                        descripcionPedido.descripcion = dataDinamicUno.skuDesc;
                                    }
                                    
                                    descripcionPedido.nro_pedido = data.numero;
                                    descripcionPedido.fecha_recojo = dataDinamicUno.promesaEntrega;
                                    descripcionPedido.orden_compra = data.numeroExterno;
                                    envios.pedidos = descripcionPedido;
                                    var responseImportWeb = repository.InsertImportWebFalabella(response.c_cod_carga_masivo_falabella_detalle, envios);
                                    if (responseImportWeb.codigo == "OK")
                                    {
                                        Console.WriteLine(responseImportWeb.mensaje);
                                    }
                                    else
                                    {
                                        Console.WriteLine("ERROR: " + responseImportWeb.mensaje);
                                    }
/*
                                }*/

                            }
                            else
                            {
                                Console.WriteLine("no existe valores");
                            }

                            row++;
                    }

                }
                }
                Console.WriteLine("terminado");
            }
            catch (Exception ex) {
                Console.WriteLine(ex.Message);
            }
             
        }
        
    }
}