-- =====================================================
-- SP_GENERATE_GUIA_FALABELLA2 — v2 (Trujillo carrier)
-- Cambios:
--   1. + @C_OFI_ORIGEN INT = NULL (opcional)
--   2. Si @C_OFI_ORIGEN != NULL → overridea oficina, ciudad y ubigeo
--   3. NULL → comportamiento actual Lima (sin cambio)
-- =====================================================

ALTER PROC [dbo].[SP_GENERATE_GUIA_FALABELLA2] @C_COD_MASIVO_DETALLE INT
    ,
    -- @FORMA_ENTREGA VARCHAR(),
    --REMITENTE
    @UBIGEO_ORIGEN VARCHAR(8)
    ,
    -----------------------
    @UBIGEO_DESTINO VARCHAR(8)
    , @N_PESO NUMERIC(8, 2)
    ,
    --REMITENTE
    @CLIENTE_REMITENTE VARCHAR(255)
    , @NRO_TELF_REM VARCHAR(50)
    , @TIPO_DOC_REM VARCHAR(4)
    , @NRO_DOC_REM VARCHAR(50)
    , @S_DIR_REM VARCHAR(500)
    , @S_REF_REM VARCHAR(500)
    ,
    -------------------------
    @NOM_DEST VARCHAR(255)
    , @TIPO_DOC_DEST VARCHAR(4)
    , @NRO_DOC_DEST VARCHAR(50)
    , @NRO_TELEFONO_DEST VARCHAR(50)
    , @DIR_DEST VARCHAR(500)
    , @REF_DEST VARCHAR(500)
    , @FECHA_ESTIMADA VARCHAR(100)
    , @NRO_PEDIDO VARCHAR(30)
    , @DESCRIPCION VARCHAR(MAX)
    , @N_PAQUETES NUMERIC(8, 0)
    , @FECHA_RECOJO VARCHAR(100)
    , @TIPO_SERVICIO VARCHAR(200)
    , @ORDEN_COMPRA VARCHAR(100)
    , @C_SUBESTADO_CLI VARCHAR(50)
    , @C_ACTIVO VARCHAR(1)
    , @C_USU_ALTA VARCHAR(20)
    , @C_OFI_ORIGEN INT = NULL
AS --REMITENTE
SET @UBIGEO_ORIGEN = '150142'
SET @CLIENTE_REMITENTE = 'FALABELLA.COM S.A.C.'
SET @NRO_TELF_REM = ''
SET @TIPO_DOC_REM = 'RUC'
SET @NRO_DOC_REM = '20547836473'
SET @S_DIR_REM = 'AV ARRIBA PERU CRUCE CON C. VICUNA ALDEAS GLOBAL 6 - VES'
SET @S_REF_REM = ''

PRINT 'que da aca?' + @UBIGEO_ORIGEN

DECLARE @C_CLI_FACT VARCHAR(8) = '2663078'
    , @C_DPTO_REM VARCHAR(6)
    , @C_PROV_REM VARCHAR(6)
    , @C_DIST_REM VARCHAR(6)
    , @C_CLI_REM VARCHAR(8)
    , @C_OFI_REM INT
    , @S_DPTO_REM VARCHAR(64)
    , @S_PROV_REM VARCHAR(64)
    , @S_DIST_REM VARCHAR(64)
    , @C_CIU_REM VARCHAR(8)
    , @S_CIU_REM VARCHAR(32)
    , @C_TIPO_CLIENTE_REM VARCHAR(10) = CASE 
        WHEN @TIPO_DOC_REM = 'RUC'
            THEN 'PJ'
        ELSE 'PN'
        END
    , @S_TELF_REM VARCHAR(12) = @NRO_TELF_REM
    , @c_oficina_OUT INT
    , @c_cliente_OUT VARCHAR(8)
    , @S_RESPONSE_OUT VARCHAR(350) = ''
    ,
    --DESTINATARIO
    @C_DPTO_DEST VARCHAR(6)
    , @C_PROV_DEST VARCHAR(6)
    , @C_DIST_DEST VARCHAR(6)
    , @C_CLI_DEST VARCHAR(8)
    , @C_OFI_DEST INT
    , @S_DPTO_DEST VARCHAR(64)
    , @S_PROV_DEST VARCHAR(64)
    , @S_DIST_DEST VARCHAR(64)
    , @C_CIU_DEST VARCHAR(8)
    , @S_CIU_DEST VARCHAR(32)
    , @C_TIPO_CLIENTE_DEST VARCHAR(10) = CASE 
        WHEN @TIPO_DOC_DEST = 'RUC'
            THEN 'PJ'
        ELSE 'PN'
        END
    , @C_CIU_DESTINO_BASE VARCHAR(8)
    , @MESSAGE_ERROR VARCHAR(MAX) = ''
    , @C_FORMA_FACTURAR VARCHAR(2) = 'AT'
    , @C_TRANSPORTE VARCHAR(2) = 'TT'
    , @C_SERVICIO_CAL VARCHAR(2)
    ,
    -- @S_SERVICIO   VARCHAR(32)  = 'LOGISTICA INVERSA',--prueba
    -- @C_CLI_FACT VARCHAR(8) ='2663078', -- prod 2663078
    @C_OFI_FACT INT = 1
    , @S_SERVICIO_CAL VARCHAR(32)
    , @C_SUBESTADO VARCHAR(3)
    , @C_ESTADO_TRACKING VARCHAR(2)
    , @C_GUIA_ANDES VARCHAR(8)
    , @C_TIPO_GUIA VARCHAR(2) = 'NR'
    , @C_PRIORIDAD VARCHAR(2) = '02'
    , @C_TIPO_SERVICIO VARCHAR(2) = 'EN'
    , @C_ESTADO_GUIA VARCHAR(2) = 'RE'
    , @C_TIPO_EMBALAJE VARCHAR(2) = 'CP'
    , @C_FORMA_ENTREGA VARCHAR(2) = 'CS'
    , @C_TIPO_DOCUMENTO_PLANTILLA VARCHAR(4) = 'CN'
    , @QUERY_GUIA VARCHAR(max) = ''
DECLARE @F_GUIA DATETIME = GETDATE()
DECLARE @F_GUIA_UPDATE DATETIME
DECLARE @C_IND_CAMBIO_FECHA_GUIA VARCHAR(1) = 'N'

BEGIN TRY
    PRINT 'COLOCAR TIPO DE TRANSPORTE'

    SELECT @C_TRANSPORTE = ISNULL(C_TIPO_TRANSPORTE, '')
    FROM CS_TRANSPORTE_AEREO_PROVINCIA WITH (NOLOCK)
    WHERE C_UBIGEO = ISNULL(@UBIGEO_DESTINO, '')

    IF (ISNULL(@C_TRANSPORTE, '') = '')
    BEGIN
        SET @C_TRANSPORTE = 'TT'
    END

    PRINT 'PASO VERIFICA SI ESTE NRO PEDIDO ESTA REGISTRADO ANTERIORMENTE'

    DECLARE @CANT INT = (
            SELECT COUNT(nro_pedido)
            FROM carga_masivo_falabella_detalle
            WHERE nro_pedido = @NRO_PEDIDO
                AND s_observacion = 'SE GENERO LA GUIA CORRECTAMENTE'
                AND c_activo = 'S'
            )

    IF (@CANT > 0)
    BEGIN
        SET @MESSAGE_ERROR = 'EL PEDIDO ' + ISNULL(@NRO_PEDIDO, '') + ' YA SE ENCUENTRA INGRESADO EN UNA GUIA'

        GOTO PROCESO_CON_ERROR;
    END

    PRINT 'PASO 1: OBTENER EL SERVICIO'

    IF @TIPO_SERVICIO IS NOT NULL
        AND @C_CLI_FACT IS NOT NULL
    BEGIN
        SELECT @S_SERVICIO_CAL = ISNULL(S_NOMBRE, 'NR')
            , @C_SERVICIO_CAL = ISNULL(C_SERVICIO, 'NR')
        FROM CS_CLIENTE_SERVICIO
        WHERE C_CLIENTE = @C_CLI_FACT
            AND S_NOMBRE = @TIPO_SERVICIO;
    END
    ELSE
    BEGIN
        SET @MESSAGE_ERROR = 'Error al obtener servicio'

        GOTO PROCESO_CON_ERROR;
    END

    PRINT 'PASO 2: ENCONTRAR EL UBIGEO TANTO DESTINO COMO REMITENTE'

    SELECT @C_DIST_REM = D.C_DISTRITO
        , @S_DIST_REM = D.S_NOMBRE
        , @C_PROV_REM = D.C_PROVINCIA
        , @C_DPTO_REM = D.C_DEPARTAMENTO
        , @S_PROV_REM = P.S_NOMBRE
        , @S_DPTO_REM = DP.S_NOMBRE
    FROM CS_DISTRITO D
    INNER JOIN CS_PROVINCIA P
        ON P.C_PROVINCIA = D.C_PROVINCIA
    INNER JOIN CS_DEPARTAMENTO DP
        ON DP.C_DEPARTAMENTO = D.C_DEPARTAMENTO
    WHERE D.C_DISTRITO = @UBIGEO_ORIGEN
        AND D.C_ACTIVO = 'S'

    IF (
            @C_DIST_REM IS NULL
            AND @C_DIST_REM = ''
            )
    BEGIN
        SET @MESSAGE_ERROR = 'NO EXISTE EL UBIGEO ORIGEN'

        GOTO PROCESO_CON_ERROR;
    END

    SELECT @C_DIST_DEST = M.C_DISTRITO
        , @S_DIST_DEST = M.S_NOMBRE
        , @C_PROV_DEST = P.C_PROVINCIA
        , @C_DPTO_DEST = DP.C_DEPARTAMENTO
        , @S_PROV_DEST = P.S_NOMBRE
        , @S_DPTO_DEST = DP.S_NOMBRE
    FROM CS_DISTRITO M
    INNER JOIN CS_PROVINCIA P
        ON P.C_PROVINCIA = M.C_PROVINCIA
    INNER JOIN CS_DEPARTAMENTO DP
        ON DP.C_DEPARTAMENTO = M.C_DEPARTAMENTO
    WHERE M.C_DISTRITO = @UBIGEO_DESTINO
        AND M.C_ACTIVO = 'S'

    IF (
            @C_DIST_DEST IS NULL
            OR @C_DIST_DEST = ''
            )
    BEGIN
        SET @MESSAGE_ERROR = 'NO EXISTE EL UBIGEO DESTINO'

        GOTO PROCESO_CON_ERROR;
    END

    PRINT 'PASO 3 BUSCAR LA CIUDAD ORIGEN Y DESTINO'

    SELECT TOP 1 @S_CIU_REM = S_CIU_AND_ORIG
    FROM CS_CIUDADES_MULTISELLER_V2 CM WITH (NOLOCK)
    WHERE CM.C_ACTIVO = 'S'
        AND ltrim(rtrim(CM.S_DISTRITO)) = @S_DIST_REM
        AND ltrim(rtrim(CM.S_DEPARTAMENTO)) = @S_DPTO_REM
        AND ltrim(rtrim(CM.S_PROVINCIA)) = @S_PROV_REM

    PRINT '@S_CIU_REM: ' + @S_CIU_REM

    SELECT TOP 1 @C_CIU_REM = C.C_CIUDAD
    FROM CS_CIUDAD C WITH (NOLOCK)
    WHERE C.C_ACTIVO = 'S'
        AND ltrim(rtrim(C.S_NOMBRE)) = ltrim(rtrim(@S_CIU_REM))

    IF ISNULL(@C_CIU_REM, '') = ''
    BEGIN
        DECLARE @C_DPTO_R VARCHAR(6) = (
                SELECT TOP 1 C_DEPARTAMENTO
                FROM CS_DEPARTAMENTO WITH (NOLOCK)
                WHERE S_NOMBRE = @S_DPTO_REM
                    AND C_ACTIVO = 'S'
                )

        SELECT TOP 1 @S_CIU_REM = S_CIU_AND_ORIG
        FROM CS_CIUDADES_MULTISELLER_V2 CM WITH (NOLOCK)
        WHERE CM.C_ACTIVO = 'S'
            AND ltrim(rtrim(CM.S_PROVINCIA)) = @S_PROV_REM

        --- BUSCA EL NOMBRE DEL DISTRITO COMO NOMBRE DE CIUDAD 
        SELECT TOP 1 @C_CIU_REM = C_CIUDAD
        FROM CS_CIUDAD WITH (NOLOCK)
        WHERE S_NOMBRE = @S_DIST_REM
            AND C_ACTIVO = 'S'
            AND C_DEPARTAMENTO = @C_DPTO_R

        IF ISNULL(@C_CIU_REM, '') = ''
        BEGIN
            SELECT TOP 1 @C_CIU_REM = C_CIUDAD
            FROM CS_CIUDAD WITH (NOLOCK)
            WHERE S_NOMBRE = @S_PROV_REM
                AND C_ACTIVO = 'S'
                AND C_DEPARTAMENTO = @C_DPTO_R
        END

        IF ISNULL(@C_CIU_REM, '') = ''
        BEGIN
            INSERT INTO CS_CIUDAD (
                C_CIUDAD
                , S_NOMBRE
                , S_NOMBRE_CORTO
                , C_DEPARTAMENTO
                , C_IND_FAU
                , C_CIUDAD_BASE
                , C_USU_ALTA
                , F_ALTA
                , C_ACTIVO
                )
            VALUES (
                LEFT(@S_DIST_REM, 3) + '101'
                , @S_DIST_REM
                , @S_DIST_REM
                , @C_DPTO_R
                , 'S'
                , @S_DIST_REM
                , 'FALABELLA'
                , GETDATE()
                , 'S'
                )

            IF (
                    SELECT COUNT(C_CIUDAD)
                    FROM CS_CIUDAD
                    WHERE C_CIUDAD = @S_DIST_REM
                    ) <> 0
            BEGIN
                SET @C_CIU_REM = (
                        SELECT TOP 1 C_CIUDAD
                        FROM CS_CIUDAD WITH (NOLOCK)
                        WHERE C_CIUDAD = @S_DIST_REM
                            AND C_ACTIVO = 'S'
                        )
            END
        END
    END

    SELECT TOP 1 @S_CIU_DEST = ltrim(rtrim(S_CIU_AND_DEST))
    FROM CS_CIUDADES_MULTISELLER_V2 CM WITH (NOLOCK)
    WHERE CM.C_ACTIVO = 'S'
        AND CM.S_DISTRITO = @S_DIST_DEST
        AND ltrim(rtrim(CM.S_DEPARTAMENTO)) = @S_DPTO_DEST
        AND ltrim(rtrim(CM.S_PROVINCIA)) = @S_PROV_DEST

    SELECT TOP 1 @C_CIU_DEST = C.C_CIUDAD
        , @C_CIU_DESTINO_BASE = C_CIUDAD_BASE
    FROM CS_CIUDAD C WITH (NOLOCK)
    WHERE C.C_ACTIVO = 'S'
        AND ltrim(rtrim(C.S_NOMBRE)) = @S_CIU_DEST

    PRINT 'imprime la ciudad destino' + isnull(@C_CIU_DEST, 'no hay')

    IF ISNULL(@C_CIU_DEST, '') = ''
    BEGIN
        DECLARE @C_DPTO_D VARCHAR(6) = (
                SELECT TOP 1 C_DEPARTAMENTO
                FROM CS_DEPARTAMENTO WITH (NOLOCK)
                WHERE S_NOMBRE = @S_DPTO_DEST
                    AND C_ACTIVO = 'S'
                )

        SELECT TOP 1 @S_CIU_DEST = ltrim(rtrim(S_CIU_AND_DEST))
        FROM CS_CIUDADES_MULTISELLER_V2 CM WITH (NOLOCK)
        WHERE CM.C_ACTIVO = 'S'
            AND ltrim(rtrim(CM.S_PROVINCIA)) = @S_PROV_DEST

        SELECT TOP 1 @C_CIU_DEST = C.C_CIUDAD
            , @C_CIU_DESTINO_BASE = C_CIUDAD_BASE
        FROM CS_CIUDAD C WITH (NOLOCK)
        WHERE C.C_ACTIVO = 'S'
            AND ltrim(rtrim(C.S_NOMBRE)) = @S_CIU_DEST

        SELECT TOP 1 @C_CIU_DEST = C_CIUDAD
        FROM CS_CIUDAD WITH (NOLOCK)
        WHERE S_NOMBRE = @S_DIST_DEST
            AND C_ACTIVO = 'S'
            AND C_DEPARTAMENTO = @C_DPTO_D

        IF ISNULL(@C_CIU_DEST, '') = ''
        BEGIN
            SELECT TOP 1 @C_CIU_DEST = C_CIUDAD
            FROM CS_CIUDAD WITH (NOLOCK)
            WHERE S_NOMBRE = @S_PROV_DEST
                AND C_ACTIVO = 'S'
                AND C_DEPARTAMENTO = @C_DPTO_D
        END

        IF ISNULL(@C_CIU_DEST, '') = ''
        BEGIN
            PRINT 'LLEGA ACA? ' + @C_DPTO_DEST

            IF EXISTS (
                    SELECT TOP 1 1
                    FROM CS_CIUDAD
                    WHERE C_CIUDAD = LEFT(@S_DIST_DEST, 3) + '100'
                    )
            BEGIN
                SET @C_CIU_DEST = LEFT(@S_DIST_DEST, 3) + '100'
            END
            ELSE
            BEGIN
                INSERT INTO CS_CIUDAD (
                    C_CIUDAD
                    , S_NOMBRE
                    , S_NOMBRE_CORTO
                    , C_DEPARTAMENTO
                    , C_IND_FAU
                    , C_CIUDAD_BASE
                    , C_USU_ALTA
                    , F_ALTA
                    , C_USU_ACTUALIZA
                    , F_ACTUALIZA
                    , C_ACTIVO
                    )
                VALUES (
                    LEFT(@S_DIST_DEST, 3) + '100'
                    , @S_DIST_DEST
                    , SUBSTRING(@S_DIST_DEST, 1, 4)
                    , @C_DPTO_D
                    , 'S'
                    , (
                        SELECT TOP 1 C_CIUDAD
                        FROM CS_CIUDAD WITH (NOLOCK)
                        WHERE C_DEPARTAMENTO = @C_DPTO_DEST
                        )
                    , 'FALABELLA'
                    , GETDATE()
                    , 'FALABELLA'
                    , GETDATE()
                    , 'S'
                    )

                PRINT 'LLEGA ACAX2? ' + @S_DIST_DEST

                IF (
                        SELECT COUNT(C_CIUDAD)
                        FROM CS_CIUDAD
                        WHERE C_CIUDAD = @S_DIST_DEST
                        ) <> 0
                BEGIN
                    SET @C_CIU_DEST = (
                            SELECT TOP 1 C_CIUDAD
                            FROM CS_CIUDAD WITH (NOLOCK)
                            WHERE C_CIUDAD = @S_DIST_DEST
                                AND C_ACTIVO = 'S'
                            )
                END
            END
        END
    END

    PRINT 'PASO 4 OBTENER CLIENTE Y OFICINA REMITENTE Y ORIGEN'
    PRINT 'entra aqui'

    EXEC SP_GENERA_CLIENTE_OFICINA_WEBV2 @S_NRO_DOC = @NRO_DOC_REM
        , @S_DIR = @S_DIR_REM
        , @C_TIPO_CLIENTE = @C_TIPO_CLIENTE_REM
        , @C_TIPO_DOCUMENTO = @TIPO_DOC_REM
        , @S_DESTINATARIO = @CLIENTE_REMITENTE
        , @S_REFERENCIA = @S_REF_REM
        , @S_TELEFONO = @S_TELF_REM
        , @S_CORREO = ''
        , @S_DPTO = @S_DPTO_REM
        , @S_PROV = @S_PROV_REM
        , @S_DIST = @S_DIST_REM
        , @C_CIUDAD = @C_CIU_REM
        , @Usuario = @C_USU_ALTA
        , @C_CLIENTE_OUT = @C_CLIENTE_OUT OUT
        , @C_OFICINA_OUT = @C_OFICINA_OUT OUT
        , @S_RESPONSE_OUT = @S_RESPONSE_OUT OUT

    PRINT 'termina aqui primero '

    SELECT @C_CLI_REM = @C_CLIENTE_OUT
        , @C_OFI_REM = @C_OFICINA_OUT

    -- =====================================================
    -- OVERRIDE: Si @C_OFI_ORIGEN != NULL, usar oficina especifica
    -- y derivar ciudad/ubigeo desde CS_CLIENTE_OFICINA
    -- =====================================================
    IF @C_OFI_ORIGEN IS NOT NULL
    BEGIN
        SET @C_OFI_REM = @C_OFI_ORIGEN;

        SELECT @C_CIU_REM = CO.C_CIUDAD
            , @S_CIU_REM = ISNULL(C.S_NOMBRE, CO.C_CIUDAD)
            , @C_DPTO_REM = CO.C_DEPARTAMENTO
            , @C_PROV_REM = CO.C_PROVINCIA
            , @C_DIST_REM = CO.C_DISTRITO
        FROM CS_CLIENTE_OFICINA CO
        LEFT JOIN CS_CIUDAD C ON CO.C_CIUDAD = C.C_CIUDAD
        WHERE CO.C_OFICINA = @C_OFI_ORIGEN
            AND CO.C_CLIENTE = @C_CLI_FACT
            AND CO.C_ACTIVO = 'S';

        -- Obtener nombres de dpto/prov/dist
        SELECT @S_DPTO_REM = ISNULL(S_NOMBRE, '')
        FROM CS_DEPARTAMENTO
        WHERE C_DEPARTAMENTO = @C_DPTO_REM AND C_ACTIVO = 'S';

        SELECT @S_PROV_REM = ISNULL(S_NOMBRE, '')
        FROM CS_PROVINCIA
        WHERE C_PROVINCIA = @C_PROV_REM AND C_ACTIVO = 'S';

        SELECT @S_DIST_REM = ISNULL(S_NOMBRE, '')
        FROM CS_DISTRITO
        WHERE C_DISTRITO = @C_DIST_REM AND C_ACTIVO = 'S';
    END

    PRINT 'linea 345 que sale aca? ' + CONVERT(VARCHAR(10), isnull(@C_OFI_REM, 0))

    IF @S_RESPONSE_OUT <> 'OK'
    BEGIN
        SET @MESSAGE_ERROR = 'ERROR  ' + @S_RESPONSE_OUT + '  REMITENTE'

        GOTO PROCESO_CON_ERROR;
    END

    PRINT 'termina aqui'
    PRINT '  @S_NRO_DOC      =      ' + isnull(@NRO_DOC_DEST, 'no hay')
    PRINT '    @S_DIR          =  ' + isnull(@DIR_DEST, 'no hay')
    PRINT '    @C_TIPO_CLIENTE =  ' + isnull(@C_TIPO_CLIENTE_DEST, 'no hay')
    PRINT '    @C_TIPO_DOCUMENTO = ' + isnull(@TIPO_DOC_DEST, 'no hay')
    PRINT '    @S_DESTINATARIO   = ' + isnull(@NOM_DEST, 'no hay')
    PRINT '    @S_REFERENCIA     = ' + isnull(@REF_DEST, 'no hay')
    PRINT '    @S_TELEFONO       = ' + isnull(@NRO_TELEFONO_DEST, 'no hay')
    PRINT '    @S_CORREO         = ' + isnull('no hay', 'no hay')
    PRINT '    @S_DPTO           = ' + isnull(@S_DPTO_DEST, 'no hay')
    PRINT '    @S_PROV           = ' + isnull(@S_PROV_DEST, 'no hay')
    PRINT '    @S_DIST           = ' + isnull(@S_DIST_DEST, 'no hay')
    PRINT '    @C_CIUDAD         = ' + isnull(@C_CIU_DEST, 'no hay')
    PRINT '    @Usuario          = ' + isnull(@C_USU_ALTA, 'no hay')
    PRINT '    @C_CLIENTE_OUT    = ' + isnull(@C_CLIENTE_OUT, 'no hay')
    PRINT '    @C_OFICINA_OUT    = ' + isnull(cast(@C_OFICINA_OUT AS VARCHAR(2)), 'no hay')
    PRINT '    @S_RESPONSE_OUT   = ' + isnull(@S_RESPONSE_OUT, 'no hay')

    EXEC SP_GENERA_CLIENTE_OFICINA_WEBV2 @S_NRO_DOC = @NRO_DOC_DEST
        , @S_DIR = @DIR_DEST
        , @C_TIPO_CLIENTE = @C_TIPO_CLIENTE_DEST
        , @C_TIPO_DOCUMENTO = @TIPO_DOC_DEST
        , @S_DESTINATARIO = @NOM_DEST
        , @S_REFERENCIA = @REF_DEST
        , @S_TELEFONO = @NRO_TELEFONO_DEST
        , @S_CORREO = ''
        , @S_DPTO = @S_DPTO_DEST
        , @S_PROV = @S_PROV_DEST
        , @S_DIST = @S_DIST_DEST
        , @C_CIUDAD = @C_CIU_DEST
        , @Usuario = @C_USU_ALTA
        , @C_CLIENTE_OUT = @C_CLIENTE_OUT OUT
        , @C_OFICINA_OUT = @C_OFICINA_OUT OUT
        , @S_RESPONSE_OUT = @S_RESPONSE_OUT OUT

    PRINT 'termina aqui x2'

    SELECT @C_CLI_DEST = @C_CLIENTE_OUT
        , @C_OFI_DEST = @C_OFICINA_OUT

    IF @S_RESPONSE_OUT <> 'OK'
    BEGIN
        SET @MESSAGE_ERROR = 'ERROR  ' + @S_RESPONSE_OUT + '  DESTINATARIO'

        GOTO PROCESO_CON_ERROR;
    END

    PRINT 'PASO 5 SETEANDO EL CLIENTE SABER A QUIEN FACTURARA'

    DECLARE @C_CLI_FACT_SERV INT
        , @C_OFI_FACT_SERV INT;

    SET @C_CLI_FACT_SERV = @C_CLI_REM
    SET @C_OFI_FACT_SERV = @C_OFI_REM

    PRINT 'PASO 6 '

    SELECT @C_TRANSPORTE = CASE 
            WHEN C_TRANSPORTE IS NOT NULL
                AND C_TRANSPORTE <> @C_TRANSPORTE
                THEN C_TRANSPORTE
            ELSE @C_TRANSPORTE
            END
    FROM CS_CLIENTE_CIUDAD_VIA WITH (NOLOCK)
    WHERE C_CLIENTE = @C_CLI_FACT_SERV
        AND C_CIUDAD = @C_CIU_DESTINO_BASE

    PRINT 'PASO 7 DETERMINACION DE LA TARIFA Y SERVICIO'

    SELECT TOP 1 @C_SERVICIO_CAL = C_SERVICIO
    FROM CS_CLIENTE_SERVICIO WITH (NOLOCK)
    WHERE C_CLIENTE = @C_CLI_FACT_SERV
        AND S_NOMBRE LIKE @S_SERVICIO_CAL + '%'
    ORDER BY S_NOMBRE

    PRINT 'PASO 8 CONTIENE DATOS DEL RECOJO'

    SELECT TOP 1 @C_SUBESTADO = 'GRE'
        , @C_ESTADO_TRACKING = 'IS'
    FROM CS_TRACKING WITH (NOLOCK)
    WHERE CS_TRACKING.C_ACTIVO = 'S'
        AND CS_TRACKING.C_ETAPA = 'RL'
        AND CS_TRACKING.C_ESTADO_ETAPA = 'RE'

    PRINT 'PASO 9 GENERANDO EL CODIGO DE GUIA'

    DECLARE @C_CORRELATIVO INT
    DECLARE @S_SERIE VARCHAR(2)

    UPDATE cs_control_guias_api
    SET @c_correlativo = n_correlativo = n_correlativo + 1
        , @S_SERIE = S_SERIE
    WHERE S_SERIE = 'AI'

    SET @C_GUIA_ANDES = (
            SELECT (
                    'AI' + (
                        SELECT CASE 
                                WHEN LEN(cast(@C_CORRELATIVO AS VARCHAR(8))) = 5
                                    THEN '0' + cast(@C_CORRELATIVO AS VARCHAR(8))
                                ELSE cast(@C_CORRELATIVO AS VARCHAR(8))
                                END
                        )
                    )
            )

    PRINT 'PASO 10 INSERTAR EN LA TABLA GUIA '

    EXEC SP_ASIGNACION_FECHA_GUIA @F_GUIA
        , @F_GUIA_UPDATE OUTPUT

    IF (CAST(@F_GUIA AS DATE) <> CAST(@F_GUIA_UPDATE AS DATE))
    BEGIN
        SET @F_GUIA = @F_GUIA_UPDATE
        SET @C_IND_CAMBIO_FECHA_GUIA = 'S'
    END

    SET @QUERY_GUIA = 'INSERT INTO CS_GUIA' + '(C_GUIA,' + 'F_GUIA,' + 'C_ESTADO_GUIA,' + 'C_TIPO_GUIA,' + 'C_PRIORIDAD,' + 'C_CIU_ORIGEN,' + 'C_CIU_DESTINO,' + 'C_CLI_ORIGEN,' + 'C_OFI_ORIGEN,' + 'C_CLI_DESTINO,' + 'C_OFI_DESTINO,' + 'C_TIPO_SERVICIO,  ' + 'C_TIPO_EMBALAJE, ' + 'C_FORMA_ENTREGA, ' + 'C_FORMA_FACTURAR, ' + 'N_PAQUETES,    ' + 'N_PESO,      ' + 'C_TIPO_DOCUMENTO,  ' + 'N_MONTO_TOTAL,    ' + 'C_IND_MANIFIESTO,  ' + 'C_USU_ALTA,    ' + 'F_ALTA,      ' + 'C_USU_ACTUALIZA, ' + 'F_ACTUALIZA,   ' + 'C_ACTIVO,      ' + 'S_OBS,        ' + 'S_CLIENTE,      ' + 'S_DIRECCION,    ' + 'S_DESCRIPCION,    ' + 'N_PESO_REAL,   ' + 'S_DIR2,      ' + 'S_ZONA,      ' + 'S_CAMPANA,      ' + 'C_TRANSPORTE,    ' + 'S_GUIA_AVON,   ' + 'F_VMTO_LICITACION, ' + 'S_CUENTA,      ' + 'S_SECTOR,      ' + 'C_SERVICIO,   ' + 'C_CLI_FACT,    ' + 'S_NRO_PEDIDO,   ' +
        'C_OFI_FACT,    ' + 'S_COD_BAR_1,    ' + 'S_COD_BAR_2,    ' + 'S_TELEFONO_DEST, ' + 'C_DPTO_DEST,    ' + 'C_PROV_DEST,    ' + 'C_DIST_DEST,    ' + 'C_DPTO_ORIG,    ' + 'C_PROV_ORIG,    ' + 'C_DIST_ORIG,    ' + 'F_COMPROMISO_E, ' + 'C_SUBESTADO,    ' + 'C_ESTADO_TRACKING,  ' + 'N_VALOR_COBRO    ' + ')          ' + ' VALUES (' + '''' + @C_GUIA_ANDES + ''',' + 'GETDATE(),' + '''' + @C_ESTADO_GUIA + ''',' + '''' + @C_TIPO_GUIA + ''',' + '''' + @C_PRIORIDAD + ''',' + '''' + @C_CIU_REM + ''',' + '''' + @C_CIU_DEST + ''',' + '''' + @C_CLI_REM + ''',' + '''' + cast(@C_OFI_REM AS VARCHAR(4)) + ''',' + '''' + @C_CLI_DEST + ''',' + '''' + cast(@C_OFI_DEST AS VARCHAR(4)) + ''',' + '''' + @C_TIPO_SERVICIO + ''',' + '''' + @C_TIPO_EMBALAJE + ''',' + '''' + @C_FORMA_ENTREGA + ''',' + '''' + @C_FORMA_FACTURAR + ''',' + '''' + cast(@N_PAQUETES AS VARCHAR(20)) + ''',' + '''' + cast(@N_PESO AS VARCHAR) + ''',' + '''' + @C_TIPO_DOCUMENTO_PLANTILLA + ''',' + '0,' + '''N'',' + '''FALABELLA'',' + 'convert(smalldatetime, GETDATE())    ,' + '''FALABELLA'',' + 'convert(smalldatetime, GETDATE()),' + '''S'',' + ''''',' + '''' + @NOM_DEST + ''',' + '''' + @DIR_DEST + ''',' + 'LEFT(''' + @DESCRIPCION + 
        ''',64),' + cast(@N_PESO AS VARCHAR(20)) + ',''' + @REF_DEST + ''',' + 'NULL ,' + 'NULL,' + '''' + @C_TRANSPORTE + ''',' + 'LEFT(''' + @NRO_PEDIDO + ''',24),' +
        'NULL,' + '''' + @NRO_DOC_DEST + ''',' + 'NULL,' + '''' + @C_SERVICIO_CAL + ''',' + '''' + cast(@C_CLI_FACT AS VARCHAR(10)) + ''',' + '''' + @NRO_PEDIDO + ''',' +
        '''' + cast(@C_OFI_FACT AS VARCHAR(2)) + ''',' + '''' + @NRO_PEDIDO + ''',' + '''' + @NRO_PEDIDO + ''',' + '''' + @NRO_TELEFONO_DEST + ''',' + 'isnull(''' + @C_DPTO_DEST + ''', ''' + '''),' + 'isnull(''' + @C_PROV_DEST + ''', ''' + '''),' + 'isnull(''' + @C_DIST_DEST + ''', ''' + '''),' + 'isnull(''' + @C_DPTO_REM + ''', ''' + '''),' + 'isnull(''' + @C_PROV_REM + ''', ''' + '''),' + 'isnull(''' + @C_DIST_REM + ''', ''' + '''),' + 'convert(datetime,''' + @FECHA_ESTIMADA + ''',120),' + '''' + @C_SUBESTADO + ''',' + '''' + @C_ESTADO_TRACKING + ''',' + 'NULL' + ') '

    PRINT isnull(@QUERY_GUIA, 'N')
    insert into prueba values (@QUERY_GUIA)

    EXEC sp_sqlexec @QUERY_GUIA

    PRINT 'PASO 11 AGREGAR A LA GUIA DETALLE'

    INSERT INTO CourierService.dbo.CS_GUIA_DET (
        C_GUIA
        , C_ITEM
        , S_DESC_ITEM
        , N_CANT
        , S_COD_BAR1
        , S_COD_BAR2
        , C_ACTIVO
        , C_USU_ALTA
        , F_ALTA
        )
    SELECT @C_GUIA_ANDES
        , C_ITEM
        , S_DESC_ITEM
        , N_CANT
        , S_COD_BAR_1
        , S_COD_BAR_2
        , 'S'
        , 'FALABELLA'
        , GETDATE()
    FROM CS_CARGAR_MASIVO_DET_FALABELLA
    WHERE C_GUIA_MASIVO_FALABELLA = @C_COD_MASIVO_DETALLE
        AND S_NRO_PEDIDO = @NRO_PEDIDO;

    PRINT 'PASO FINAL ACTUALIZAR CARGA MASIVO DETALLE'

    UPDATE carga_masivo_falabella_detalle
    SET s_observacion = 'SE GENERO LA GUIA CORRECTAMENTE' + (CASE WHEN @C_IND_CAMBIO_FECHA_GUIA='S' THEN ', SE MODIFICO LA FECHA GUIA A '+(CONVERT(VARCHAR,@F_GUIA,103))+',MOTIVO: FECHA ACTUAL ES UN DIA NO LABORABLE.' ELSE '' END)
        , S_QUERY = @QUERY_GUIA
        , c_guia_andes = @C_GUIA_ANDES
        , nro_pedido = @NRO_PEDIDO
        , C_SUBESTADO_UPDATE = @C_SUBESTADO_CLI
    WHERE c_cod_carga_masivo_falabella_detalle = @C_COD_MASIVO_DETALLE

    SELECT 0 AS 'id'
        , 'OK' AS 'codigo'
        , 'PROCESO CON EXITO' AS 'mensaje'
END TRY

BEGIN CATCH
    DECLARE @MENSAJE VARCHAR(MAX) = ERROR_MESSAGE()

    EXEC [dbo].[SP_LOG_ERROR_CARGA_FALABELLA] @MENSAJE
        , @QUERY_GUIA
        , 'CS_GUIA'
        , 'SYSTEM'

    PRINT '@MENSAJE: ' + @MENSAJE

    SELECT 0 AS 'id'
        , 'ERROR' AS 'codigo'
        , 'NO SE PUDO INSERTAR A LA TABLA GUIA' AS 'mensaje'

    GOTO PROCESO_CON_ERROR
END CATCH

PROCESO_CON_ERROR:

IF (
        @MESSAGE_ERROR IS NOT NULL
        AND @MESSAGE_ERROR <> ''
        )
BEGIN
    UPDATE carga_masivo_falabella_detalle
    SET s_observacion = @MESSAGE_ERROR
        , S_QUERY = @QUERY_GUIA
    WHERE c_cod_carga_masivo_falabella_detalle = @C_COD_MASIVO_DETALLE
END
