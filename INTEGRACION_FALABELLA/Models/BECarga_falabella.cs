using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace INTEGRACION_FALABELLA.Models
{
    public class BECarga_falabella
    {
        public int c_cod_plantilla_reparto { get; set; }
        public string c_estado { get; set; }
        public string c_cod_carrier { get; set; }
        public string c_activo { get; set; }
        public string c_usu_alta { get; set; }
        public List<BEEnvios>? envios { get; set;}

    }
    public class BEEnvios
    { 
        public string forma_entrega { get; set; }
        public string ubigeo_origen { get; set; }
        public string ubigeo_destino { get; set; }
        public decimal n_peso { get; set; }
        public string cliente_remitente { get; set; }
        public string tipo_doc_rem { get; set; }
        public string nro_doc_rem { get; set; }
        public string nro_telefono_rem { get; set; }
        public string oficina_dir_rem { get; set; }
        public string referencia_rem { get; set; }
        public string nom_destinatario { get; set; }
        public string tipo_doc_dest { get; set; }
        public string nro_doc_dest { get; set; }
        public string nro_telefono { get; set; }
        public string direccion_dest { get; set; }
        public string referencia_dest { get; set; }
        public string fecha_compromiso_estimada { get; set; }
        public string tipo_servicio { get; set; }
        public string c_subestado_cli { get; set; }
        public BEPedidos pedidos { get; set; }

    }
    public class BEPedidos
    { 
        public string descripcion { get; set; }
        public decimal nro_paquetes { get; set; }
        public string nro_pedido { get; set; }
        public string orden_compra { get; set; }
        public string fecha_recojo { get; set; }

    }
    public class BECarga_response
    {
        public int c_cod_carga_masivo_falabella { get; set; }
        public string codigo { get; set; }
        public string mensaje { get; set; }
    }

    public class BECarga_response_detalle
    {
        public int c_cod_carga_masivo_falabella_detalle { get; set; }
        public string codigo { get; set; }
        public string mensaje { get; set; }
    }

}
