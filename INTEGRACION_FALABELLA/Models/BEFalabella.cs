using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace INTEGRACION_FALABELLA.Models
{
    /*public class BEDataFalabella
    { 
        public string
    }*/
    public  class BEFalabella
    {
        public string? numero { get; set; }
        public string? numeroExterno { get; set; }
        public string? idEstadoEnvio { get; set; }
        public string? estadoEnvio { get; set; }
        public string? idFormaEntrega { get; set; }
        public string? nombreFormaEntrega { get; set; }
        public string? idPoblacionOrigen { get; set; }
        public string? nombrePoblacionDestino { get; set; }
        public string? idPoblacionDestino { get; set; }
        public decimal pesoLiquidado { get; set; }
        public string? pesoVolumen { get; set; }
        public string? alto { get; set; }
        public string? largo { get; set; }
        public string? ancho { get; set; }
        public string? remitente { get; set; }
        public string? idTipoDocumentoRem { get; set; }
        public string? documentoRem { get; set; }
        public string? telefonoRem { get; set; }
        public string? direccionRem { get; set; }
        public string? complementoDirRem { get; set; }
        public string? emailRem { get; set; }
        public string? destinatario { get; set; }
        public string? idTipoDocumentoDest { get; set; }
        public string? documentoDest { get; set; }
        public string? telefonoDest { get; set; }
        public string? direccionDest { get; set; }
        public string? complementoDirDest { get; set; }
        public string? emailDest { get; set; }
        public string? fechaRegistroEnvio { get; set; }
        public string? totalPiezas { get; set; }
        public string? diceContener { get; set; }
        public string? dinamicouno { get; set; }
        public string? dinamicodos { get; set; }
        public string? dinamicotres { get; set; }
    }
    public class BEDinamicouno { 
        public List<BESkus>? skus { get; set; }
        public string? carrier { get; set; }              
        public string? skuDesc { get; set; }
        public string unidades { get; set; }
        public string? distritoRem { get; set; }
        public string? ordenCompra { get; set; }
        public string? distritoDest { get; set; }
        public string? numeroPedido { get; set; }
        public string? provinciaRem { get; set; }
        public string? unidadMedida { get; set; }
        public string? provinciaDest { get; set; }
        public string? codigoProducto { get; set; }
        public string? promesaEntrega { get; set; }
        public string? departamentoRem { get; set; }
        public string? fulFillmentType { get; set; }
        public string? departamentoDest { get; set; }
    }
    public class BESkus { 
        public string? unidad { get; set; }
        public string? skuDesc { get; set; }
        public string? codigoProducto { get; set; }

    }

}
