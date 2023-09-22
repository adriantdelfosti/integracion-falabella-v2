using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using INTEGRACION_FALABELLA.DB;
using System.Data.SqlClient;
using INTEGRACION_FALABELLA.Models;
using System.Data;

namespace INTEGRACION_FALABELLA.Repository
{
    public class CargaMasivaRepository
    {
        

        public BECarga_response InsertCargaMasivaFalabella(BECarga_falabella carga) {
            BECarga_response response = new BECarga_response();
            try {
                using var conn = Connection.ObtenerConexion();
                conn.Open();
                using (SqlCommand sqlCmd = new SqlCommand("SP_INSERT_CARGA_FALABELLA", conn))
                {
                    sqlCmd.CommandType = CommandType.StoredProcedure;
                    sqlCmd.Parameters.AddWithValue("@C_ACTIVO", carga.c_activo);
                    sqlCmd.Parameters.AddWithValue("@C_USU_ALTA", carga.c_usu_alta);
                    sqlCmd.Parameters.AddWithValue("@C_COD_PLANTILLA_REPARTO", carga.c_cod_plantilla_reparto);
                    sqlCmd.Parameters.AddWithValue("@C_COD_CARRIER", carga.c_cod_carrier);
                    sqlCmd.Parameters.AddWithValue("@C_ESTADO", carga.c_estado);

                    SqlDataReader reader = sqlCmd.ExecuteReader();
                    if (reader.HasRows)
                    {
                        if (reader.Read())
                        {

                            response.codigo = reader.IsDBNull(reader.GetOrdinal("codigo")) ? "" : reader.GetString(reader.GetOrdinal("codigo"));
                            response.c_cod_carga_masivo_falabella = reader.GetInt32("id");
                            response.mensaje = reader.IsDBNull(reader.GetOrdinal("mensaje")) ? "" : reader.GetString(reader.GetOrdinal("mensaje"));

                        }
                    }
                    reader.Close();
                }
                conn.Close();

                return response;

            }
            catch (Exception ex)
            {
               
                response.mensaje=ex.Message;
                response.c_cod_carga_masivo_falabella = 0;
                response.codigo = "400";
                return response;
            }
        }

        public BECarga_response_detalle InsertCargaMasivaDetalleFalabella(int id,int row,string carga)
        {
            BECarga_response_detalle response = new BECarga_response_detalle();
            try
            {
                using var conn = Connection.ObtenerConexion();
                conn.Open();
                using (SqlCommand sqlCmd = new SqlCommand("SP_INSERT_CARGA_FALABELLA_DETALLE", conn))
                {
                    sqlCmd.CommandType = CommandType.StoredProcedure;
                    sqlCmd.Parameters.AddWithValue("@C_ACTIVO", "S");
                    sqlCmd.Parameters.AddWithValue("@C_USU_ALTA", "System");
                    sqlCmd.Parameters.AddWithValue("@C_COD_PLANTILLA", id);
                    sqlCmd.Parameters.AddWithValue("@S_VALORES", carga);
                    sqlCmd.Parameters.AddWithValue("@ROW", row);

                    SqlDataReader reader = sqlCmd.ExecuteReader();
                    if (reader.HasRows)
                    {
                        if (reader.Read())
                        {

                            response.codigo = reader.IsDBNull(reader.GetOrdinal("codigo")) ? "" : reader.GetString(reader.GetOrdinal("codigo"));
                            response.c_cod_carga_masivo_falabella_detalle = reader.GetInt32("id");
                            response.mensaje = reader.IsDBNull(reader.GetOrdinal("mensaje")) ? "" : reader.GetString(reader.GetOrdinal("mensaje"));

                        }
                    }
                    reader.Close();
                }
                conn.Close();

                return response;

            }
            catch (Exception ex)
            {

                response.mensaje = ex.Message;
                response.c_cod_carga_masivo_falabella_detalle = 0;
                response.codigo = "400";
                return response;
            }
        }

        public BECarga_response_detalle InsertImportWebFalabella(int id, BEEnvios envios)
        {
            BECarga_response_detalle response = new BECarga_response_detalle();
            try
            {
                using var conn = Connection.ObtenerConexion();
                conn.Open();
                using (SqlCommand sqlCmd = new SqlCommand("SP_GENERATE_GUIA_FALABELLA", conn))
                {
                    sqlCmd.CommandType = CommandType.StoredProcedure;
                    sqlCmd.Parameters.AddWithValue("@C_ACTIVO", "S");
                    sqlCmd.Parameters.AddWithValue("@C_USU_ALTA", "FALABELLA");
                    sqlCmd.Parameters.AddWithValue("@C_COD_MASIVO_DETALLE", id);
                    sqlCmd.Parameters.AddWithValue("@UBIGEO_ORIGEN", envios.ubigeo_origen);
                    sqlCmd.Parameters.AddWithValue("@UBIGEO_DESTINO", envios.ubigeo_destino);
                    sqlCmd.Parameters.AddWithValue("@N_PESO", envios.n_peso);
                    sqlCmd.Parameters.AddWithValue("@CLIENTE_REMITENTE", envios.cliente_remitente);
                    sqlCmd.Parameters.AddWithValue("@TIPO_DOC_REM", envios.tipo_doc_rem);
                    sqlCmd.Parameters.AddWithValue("@NRO_DOC_REM", envios.nro_doc_rem);
                    sqlCmd.Parameters.AddWithValue("@S_DIR_REM", envios.oficina_dir_rem);
                    sqlCmd.Parameters.AddWithValue("@S_REF_REM", envios.referencia_rem);
                    sqlCmd.Parameters.AddWithValue("@NOM_DEST", envios.nom_destinatario);
                    sqlCmd.Parameters.AddWithValue("@TIPO_DOC_DEST", envios.tipo_doc_dest);
                    sqlCmd.Parameters.AddWithValue("@NRO_DOC_DEST", envios.nro_doc_dest);
                    sqlCmd.Parameters.AddWithValue("@NRO_TELEFONO_DEST", envios.nro_telefono);
                    sqlCmd.Parameters.AddWithValue("@DIR_DEST", envios.direccion_dest);
                    sqlCmd.Parameters.AddWithValue("@REF_DEST", envios.referencia_dest);
                    sqlCmd.Parameters.AddWithValue("@FECHA_ESTIMADA", envios.fecha_compromiso_estimada);
                    sqlCmd.Parameters.AddWithValue("@NRO_PEDIDO", envios.pedidos.nro_pedido);
                    sqlCmd.Parameters.AddWithValue("@DESCRIPCION", envios.pedidos.descripcion);
                    sqlCmd.Parameters.AddWithValue("@N_PAQUETES", envios.pedidos.nro_paquetes);
                    sqlCmd.Parameters.AddWithValue("@FECHA_RECOJO", envios.pedidos.fecha_recojo);


                    SqlDataReader reader = sqlCmd.ExecuteReader();
                    if (reader.HasRows)
                    {
                        if (reader.Read())
                        {

                            response.codigo = reader.IsDBNull(reader.GetOrdinal("codigo")) ? "" : reader.GetString(reader.GetOrdinal("codigo"));
                            response.c_cod_carga_masivo_falabella_detalle = reader.GetInt32("id");
                            response.mensaje = reader.IsDBNull(reader.GetOrdinal("mensaje")) ? "" : reader.GetString(reader.GetOrdinal("mensaje"));

                        }
                    }
                    reader.Close();
                }
                conn.Close();

                return response;

            }
            catch (Exception ex)
            {

                response.mensaje = ex.Message;
                response.c_cod_carga_masivo_falabella_detalle = 0;
                response.codigo = "400";
                return response;
            }
        }

    }
}
