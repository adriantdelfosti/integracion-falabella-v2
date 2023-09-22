using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace INTEGRACION_FALABELLA.Models
{
    public class BEBaseResponse
    {
        public int statusCode { get; set; }
        public string? razon { get; set; }
        public string? message { get; set; }

        public BECarga_falabella? carga_Falabella { get; set; }

        public List<Object>? dataEnviosFalabella { get; set; }
    }
}
