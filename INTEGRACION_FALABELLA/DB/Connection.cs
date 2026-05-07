using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.SqlClient;
using System.Configuration;

namespace INTEGRACION_FALABELLA.DB
{
    public class Connection
    {
        public static SqlConnection ObtenerConexion()
        {
            try
            {
                var connectionString = ConfigurationManager.ConnectionStrings["conexion"].ConnectionString;
                var connection = new SqlConnection(connectionString);
                /*Console.WriteLine(connectionString);*/
                return connection;
            }
            catch (Exception ex)
            {
                // Manejar la excepción apropiadamente (puedes registrarla o lanzarla nuevamente)
                Console.WriteLine("Error al obtener la conexión: " + ex.Message);
                throw;
            }
        }
    }
}
