-- =============================================================================
-- Migración inicial — OperadorApp
-- Ver docs/DATABASE.md para la documentación completa del esquema
-- =============================================================================

-- Extensiones
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Tipos / Enums
CREATE TYPE nivel_operador_enum AS ENUM (
    'plata', 'oro', 'platino', 'esmeralda', 'diamante'
);
CREATE TYPE estado_viaje_enum AS ENUM (
    'asignado', 'en_curso', 'completado', 'cancelado', 'incidente'
);
CREATE TYPE tipo_reporte_enum AS ENUM (
    'mantenimiento', 'choque', 'incidencia', 'seguridad'
);
CREATE TYPE estado_reporte_enum AS ENUM (
    'abierto', 'en_proceso', 'cerrado'
);
CREATE TYPE tipo_premio_enum AS ENUM (
    'efectivo', 'tarjeta_regalo', 'producto_fisico', 'experiencia', 'vehiculo'
);
CREATE TYPE estado_canje_enum AS ENUM (
    'solicitado', 'aprobado', 'entregado', 'rechazado', 'cancelado'
);
CREATE TYPE tipo_movimiento_enum AS ENUM (
    'ganado_viaje', 'canjeado', 'ajuste_manual', 'bonificacion', 'penalizacion'
);

-- Tablas
CREATE TABLE niveles_operador (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre         nivel_operador_enum UNIQUE NOT NULL,
    puntos_minimos INTEGER NOT NULL,
    puntos_maximos INTEGER,
    descripcion    TEXT,
    color_hex      VARCHAR(7) NOT NULL DEFAULT '#C0C0C0',
    icono_url      TEXT,
    beneficios     JSONB DEFAULT '[]'::jsonb,
    orden          SMALLINT NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE operadores (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_user_id    UUID UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
    numero_empleado VARCHAR(20) UNIQUE NOT NULL,
    nombre_completo VARCHAR(255) NOT NULL,
    email           VARCHAR(255),
    telefono        VARCHAR(20),
    fecha_ingreso   DATE NOT NULL,
    base            VARCHAR(100),
    foto_perfil_url TEXT,
    nivel_actual    nivel_operador_enum NOT NULL DEFAULT 'plata',
    activo          BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_nivel FOREIGN KEY (nivel_actual) REFERENCES niveles_operador(nombre)
);

CREATE TABLE tractos (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    numero_economico     VARCHAR(50) UNIQUE NOT NULL,
    marca                VARCHAR(100),
    modelo               VARCHAR(100),
    anio                 SMALLINT,
    placa                VARCHAR(20),
    vin                  VARCHAR(50),
    rendimiento_esperado DECIMAL(5,2),
    activo               BOOLEAN NOT NULL DEFAULT true,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE viajes (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    operador_id      UUID NOT NULL REFERENCES operadores(id),
    tracto_id        UUID NOT NULL REFERENCES tractos(id),
    origen           VARCHAR(255) NOT NULL,
    destino          VARCHAR(255) NOT NULL,
    origen_coords    GEOGRAPHY(POINT, 4326),
    destino_coords   GEOGRAPHY(POINT, 4326),
    fecha_inicio     TIMESTAMPTZ,
    fecha_fin        TIMESTAMPTZ,
    km_esperados     DECIMAL(10,2),
    km_recorridos    DECIMAL(10,2),
    litros_diesel    DECIMAL(10,2),
    rendimiento_real DECIMAL(5,2),
    costo_diesel     DECIMAL(12,2),
    estado           estado_viaje_enum NOT NULL DEFAULT 'asignado',
    calificacion     DECIMAL(3,2) CHECK (calificacion BETWEEN 0 AND 10),
    puntos_obtenidos INTEGER,
    eta              TIMESTAMPTZ,
    notas            TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE viaje_puntos_gps (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    viaje_id      UUID NOT NULL REFERENCES viajes(id) ON DELETE CASCADE,
    coordenada    GEOGRAPHY(POINT, 4326) NOT NULL,
    velocidad_kmh DECIMAL(6,2),
    rumbo_grados  DECIMAL(5,2),
    altitud_m     DECIMAL(8,2),
    timestamp_gps TIMESTAMPTZ NOT NULL,
    proveedor_gps VARCHAR(100),
    raw_data      JSONB,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE historial_tractos_operador (
    id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    operador_id           UUID NOT NULL REFERENCES operadores(id),
    tracto_id             UUID NOT NULL REFERENCES tractos(id),
    fecha_inicio          DATE NOT NULL,
    fecha_fin             DATE,
    km_recorridos         DECIMAL(12,2) DEFAULT 0,
    viajes_realizados     INTEGER DEFAULT 0,
    calificacion_promedio DECIMAL(3,2),
    activo                BOOLEAN NOT NULL DEFAULT false,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE reportes (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    viaje_id      UUID REFERENCES viajes(id),
    operador_id   UUID NOT NULL REFERENCES operadores(id),
    tracto_id     UUID REFERENCES tractos(id),
    tipo          tipo_reporte_enum NOT NULL,
    estado        estado_reporte_enum NOT NULL DEFAULT 'abierto',
    descripcion   TEXT NOT NULL,
    fotos_urls    TEXT[] DEFAULT '{}',
    coordenada    GEOGRAPHY(POINT, 4326),
    fecha_reporte TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_cierre  TIMESTAMPTZ,
    resolucion    TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE incidencias (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    viaje_id             UUID NOT NULL REFERENCES viajes(id) ON DELETE CASCADE,
    operador_id          UUID NOT NULL REFERENCES operadores(id),
    tipo                 VARCHAR(100) NOT NULL,
    descripcion          TEXT,
    severidad            SMALLINT CHECK (severidad BETWEEN 1 AND 5),
    coordenada           GEOGRAPHY(POINT, 4326),
    timestamp_incidencia TIMESTAMPTZ NOT NULL,
    impacto_puntos       INTEGER NOT NULL DEFAULT 0,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE alertas_seguridad (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    viaje_id         UUID NOT NULL REFERENCES viajes(id) ON DELETE CASCADE,
    operador_id      UUID NOT NULL REFERENCES operadores(id),
    tipo             VARCHAR(100) NOT NULL,
    valor_medido     DECIMAL(10,2),
    umbral_permitido DECIMAL(10,2),
    coordenada       GEOGRAPHY(POINT, 4326),
    timestamp_alerta TIMESTAMPTZ NOT NULL,
    impacto_puntos   INTEGER NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE reglas_puntaje (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre      VARCHAR(255) NOT NULL,
    descripcion TEXT,
    variable    VARCHAR(100) NOT NULL UNIQUE,
    formula     JSONB NOT NULL,
    peso        DECIMAL(5,2) NOT NULL DEFAULT 1.0,
    activa      BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE premios_catalogo (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre       VARCHAR(255) NOT NULL,
    descripcion  TEXT,
    tipo         tipo_premio_enum NOT NULL,
    costo_puntos INTEGER NOT NULL CHECK (costo_puntos > 0),
    nivel_minimo nivel_operador_enum,
    imagen_url   TEXT,
    animacion_url TEXT,
    stock        INTEGER,
    activo       BOOLEAN NOT NULL DEFAULT true,
    metadata     JSONB DEFAULT '{}'::jsonb,
    orden        SMALLINT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE premios_canjeados (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    operador_id      UUID NOT NULL REFERENCES operadores(id),
    premio_id        UUID NOT NULL REFERENCES premios_catalogo(id),
    puntos_canjeados INTEGER NOT NULL,
    estado           estado_canje_enum NOT NULL DEFAULT 'solicitado',
    notas_operador   TEXT,
    notas_rh         TEXT,
    fecha_solicitud  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_aprobacion TIMESTAMPTZ,
    fecha_entrega    TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE puntos_operador (
    operador_id        UUID PRIMARY KEY REFERENCES operadores(id) ON DELETE CASCADE,
    puntos_ganados     INTEGER NOT NULL DEFAULT 0,
    puntos_canjeados   INTEGER NOT NULL DEFAULT 0,
    puntos_disponibles INTEGER NOT NULL DEFAULT 0,
    ultimo_calculo     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE movimientos_puntos (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    operador_id   UUID NOT NULL REFERENCES operadores(id),
    tipo          tipo_movimiento_enum NOT NULL,
    puntos        INTEGER NOT NULL,
    viaje_id      UUID REFERENCES viajes(id),
    canje_id      UUID REFERENCES premios_canjeados(id),
    descripcion   TEXT,
    saldo_despues INTEGER NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE operador_devices (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    operador_id          UUID NOT NULL REFERENCES operadores(id) ON DELETE CASCADE,
    fcm_token            TEXT NOT NULL,
    plataforma           VARCHAR(10) NOT NULL CHECK (plataforma IN ('android', 'ios')),
    activo               BOOLEAN NOT NULL DEFAULT true,
    ultima_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (operador_id, fcm_token)
);

CREATE TABLE configuracion_operador (
    operador_id           UUID PRIMARY KEY REFERENCES operadores(id) ON DELETE CASCADE,
    tema                  VARCHAR(10) NOT NULL DEFAULT 'system' CHECK (tema IN ('light', 'dark', 'system')),
    idioma                VARCHAR(5) NOT NULL DEFAULT 'es_MX',
    notificaciones_push   BOOLEAN NOT NULL DEFAULT true,
    notificaciones_in_app BOOLEAN NOT NULL DEFAULT true,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE notificaciones_in_app (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    operador_id UUID NOT NULL REFERENCES operadores(id) ON DELETE CASCADE,
    titulo      VARCHAR(255) NOT NULL,
    cuerpo      TEXT NOT NULL,
    tipo        VARCHAR(100),
    leida       BOOLEAN NOT NULL DEFAULT false,
    metadata    JSONB DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_operadores_auth_user_id ON operadores(auth_user_id);
CREATE INDEX idx_operadores_numero_empleado ON operadores(numero_empleado);
CREATE INDEX idx_viajes_operador_id ON viajes(operador_id);
CREATE INDEX idx_viajes_tracto_id ON viajes(tracto_id);
CREATE INDEX idx_viajes_estado ON viajes(estado);
CREATE INDEX idx_viajes_fecha_inicio ON viajes(fecha_inicio DESC);
CREATE INDEX idx_viajes_updated_at ON viajes(updated_at DESC);
CREATE INDEX idx_puntos_gps_viaje_id ON viaje_puntos_gps(viaje_id);
CREATE INDEX idx_puntos_gps_timestamp ON viaje_puntos_gps(viaje_id, timestamp_gps);
CREATE INDEX idx_reportes_operador_id ON reportes(operador_id);
CREATE INDEX idx_reportes_viaje_id ON reportes(viaje_id);
CREATE INDEX idx_reportes_estado ON reportes(estado);
CREATE INDEX idx_incidencias_viaje_id ON incidencias(viaje_id);
CREATE INDEX idx_alertas_viaje_id ON alertas_seguridad(viaje_id);
CREATE INDEX idx_alertas_operador_id ON alertas_seguridad(operador_id);
CREATE INDEX idx_canjes_operador_id ON premios_canjeados(operador_id);
CREATE INDEX idx_canjes_estado ON premios_canjeados(estado);
CREATE INDEX idx_movimientos_operador_id ON movimientos_puntos(operador_id);
CREATE INDEX idx_movimientos_viaje_id ON movimientos_puntos(viaje_id);
CREATE INDEX idx_movimientos_created_at ON movimientos_puntos(operador_id, created_at DESC);
CREATE INDEX idx_notif_operador_id ON notificaciones_in_app(operador_id);
CREATE INDEX idx_notif_no_leidas ON notificaciones_in_app(operador_id) WHERE leida = false;
CREATE INDEX idx_historial_operador_id ON historial_tractos_operador(operador_id);
CREATE INDEX idx_historial_tracto_id ON historial_tractos_operador(tracto_id);

-- Vista: progreso hacia premios por operador
CREATE VIEW progreso_premios AS
SELECT
    o.id                                                                                AS operador_id,
    pc.id                                                                               AS premio_id,
    pc.nombre,
    pc.costo_puntos,
    pc.tipo,
    pc.imagen_url,
    pc.orden,
    po.puntos_disponibles,
    LEAST(po.puntos_disponibles, pc.costo_puntos)                                       AS puntos_acumulados,
    ROUND(LEAST(po.puntos_disponibles::DECIMAL, pc.costo_puntos) / pc.costo_puntos * 100, 2) AS porcentaje_progreso,
    po.puntos_disponibles >= pc.costo_puntos                                            AS puede_canjear
FROM operadores o
JOIN puntos_operador po ON po.operador_id = o.id
CROSS JOIN premios_catalogo pc
WHERE pc.activo = true;

-- Función: updated_at automático
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Función: recalcular puntos del operador
CREATE OR REPLACE FUNCTION fn_actualizar_puntos_operador(p_operador_id UUID)
RETURNS VOID AS $$
DECLARE
    v_ganados     INTEGER;
    v_canjeados   INTEGER;
    v_disponibles INTEGER;
BEGIN
    SELECT
        COALESCE(SUM(puntos) FILTER (WHERE puntos > 0), 0),
        COALESCE(ABS(SUM(puntos)) FILTER (WHERE puntos < 0), 0),
        COALESCE(SUM(puntos), 0)
    INTO v_ganados, v_canjeados, v_disponibles
    FROM movimientos_puntos
    WHERE operador_id = p_operador_id;

    INSERT INTO puntos_operador (operador_id, puntos_ganados, puntos_canjeados, puntos_disponibles, ultimo_calculo)
    VALUES (p_operador_id, v_ganados, v_canjeados, v_disponibles, NOW())
    ON CONFLICT (operador_id) DO UPDATE SET
        puntos_ganados     = EXCLUDED.puntos_ganados,
        puntos_canjeados   = EXCLUDED.puntos_canjeados,
        puntos_disponibles = EXCLUDED.puntos_disponibles,
        ultimo_calculo     = NOW();

    UPDATE operadores
    SET nivel_actual = (
        SELECT nombre FROM niveles_operador
        WHERE puntos_minimos <= v_ganados
          AND (puntos_maximos IS NULL OR v_ganados <= puntos_maximos)
        ORDER BY puntos_minimos DESC
        LIMIT 1
    )
    WHERE id = p_operador_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función: acreditar puntos por viaje completado
CREATE OR REPLACE FUNCTION fn_acreditar_puntos_viaje(
    p_viaje_id    UUID,
    p_puntos      INTEGER,
    p_descripcion TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_operador_id UUID;
    v_saldo       INTEGER;
BEGIN
    SELECT operador_id INTO v_operador_id FROM viajes WHERE id = p_viaje_id;
    SELECT COALESCE(puntos_disponibles, 0) INTO v_saldo FROM puntos_operador WHERE operador_id = v_operador_id;

    INSERT INTO movimientos_puntos (operador_id, tipo, puntos, viaje_id, descripcion, saldo_despues)
    VALUES (v_operador_id, 'ganado_viaje', p_puntos, p_viaje_id,
            COALESCE(p_descripcion, 'Puntos por viaje completado'), v_saldo + p_puntos);

    PERFORM fn_actualizar_puntos_operador(v_operador_id);

    INSERT INTO notificaciones_in_app (operador_id, titulo, cuerpo, tipo, metadata)
    VALUES (v_operador_id, '¡Puntos acreditados!',
            format('Ganaste %s puntos por tu viaje completado.', p_puntos),
            'puntos_acreditados',
            jsonb_build_object('viaje_id', p_viaje_id, 'puntos', p_puntos));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función: descontar puntos al aprobar canje
CREATE OR REPLACE FUNCTION fn_descontar_puntos_canje(p_canje_id UUID)
RETURNS VOID AS $$
DECLARE
    v_operador_id UUID;
    v_puntos      INTEGER;
    v_saldo       INTEGER;
    v_nombre      TEXT;
BEGIN
    SELECT c.operador_id, c.puntos_canjeados, p.nombre
    INTO v_operador_id, v_puntos, v_nombre
    FROM premios_canjeados c JOIN premios_catalogo p ON p.id = c.premio_id
    WHERE c.id = p_canje_id;

    SELECT COALESCE(puntos_disponibles, 0) INTO v_saldo FROM puntos_operador WHERE operador_id = v_operador_id;

    INSERT INTO movimientos_puntos (operador_id, tipo, puntos, canje_id, descripcion, saldo_despues)
    VALUES (v_operador_id, 'canjeado', -v_puntos, p_canje_id,
            format('Canje: %s', v_nombre), v_saldo - v_puntos);

    PERFORM fn_actualizar_puntos_operador(v_operador_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers: updated_at
CREATE TRIGGER trg_operadores_updated_at BEFORE UPDATE ON operadores FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_tractos_updated_at BEFORE UPDATE ON tractos FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_viajes_updated_at BEFORE UPDATE ON viajes FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_reportes_updated_at BEFORE UPDATE ON reportes FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_premios_catalogo_updated_at BEFORE UPDATE ON premios_catalogo FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_premios_canjeados_updated_at BEFORE UPDATE ON premios_canjeados FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_configuracion_updated_at BEFORE UPDATE ON configuracion_operador FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_historial_tractos_updated_at BEFORE UPDATE ON historial_tractos_operador FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- Trigger: descontar puntos al aprobar canje
CREATE OR REPLACE FUNCTION fn_on_canje_aprobado()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'aprobado' AND OLD.estado = 'solicitado' THEN
        PERFORM fn_descontar_puntos_canje(NEW.id);
        INSERT INTO notificaciones_in_app (operador_id, titulo, cuerpo, tipo, metadata)
        VALUES (NEW.operador_id, '¡Premio aprobado!',
                'Tu solicitud fue aprobada. Pronto recibirás tu premio.',
                'canje_aprobado', jsonb_build_object('canje_id', NEW.id));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_canje_aprobado
    AFTER UPDATE ON premios_canjeados
    FOR EACH ROW EXECUTE FUNCTION fn_on_canje_aprobado();

-- Trigger: inicializar config y puntos al crear operador
CREATE OR REPLACE FUNCTION fn_on_new_operador()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO configuracion_operador (operador_id) VALUES (NEW.id) ON CONFLICT DO NOTHING;
    INSERT INTO puntos_operador (operador_id) VALUES (NEW.id) ON CONFLICT DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_new_operador
    AFTER INSERT ON operadores
    FOR EACH ROW EXECUTE FUNCTION fn_on_new_operador();

-- RLS
CREATE OR REPLACE FUNCTION auth_operador_id()
RETURNS UUID AS $$
    SELECT id FROM operadores WHERE auth_user_id = auth.uid() LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

ALTER TABLE operadores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "operador_select_own" ON operadores FOR SELECT USING (auth_user_id = auth.uid());
CREATE POLICY "operador_update_own" ON operadores FOR UPDATE USING (auth_user_id = auth.uid());

ALTER TABLE niveles_operador ENABLE ROW LEVEL SECURITY;
CREATE POLICY "niveles_select_all" ON niveles_operador FOR SELECT USING (auth.role() = 'authenticated');

ALTER TABLE tractos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tractos_select_assigned" ON tractos FOR SELECT USING (
    id IN (
        SELECT tracto_id FROM viajes WHERE operador_id = auth_operador_id()
        UNION
        SELECT tracto_id FROM historial_tractos_operador WHERE operador_id = auth_operador_id()
    )
);

ALTER TABLE viajes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "viajes_select_own" ON viajes FOR SELECT USING (operador_id = auth_operador_id());

ALTER TABLE viaje_puntos_gps ENABLE ROW LEVEL SECURITY;
CREATE POLICY "puntos_gps_select_own" ON viaje_puntos_gps FOR SELECT USING (
    viaje_id IN (SELECT id FROM viajes WHERE operador_id = auth_operador_id())
);

ALTER TABLE historial_tractos_operador ENABLE ROW LEVEL SECURITY;
CREATE POLICY "historial_tractos_select_own" ON historial_tractos_operador FOR SELECT USING (operador_id = auth_operador_id());

ALTER TABLE reportes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reportes_select_own" ON reportes FOR SELECT USING (operador_id = auth_operador_id());
CREATE POLICY "reportes_insert_own" ON reportes FOR INSERT WITH CHECK (operador_id = auth_operador_id());

ALTER TABLE incidencias ENABLE ROW LEVEL SECURITY;
CREATE POLICY "incidencias_select_own" ON incidencias FOR SELECT USING (operador_id = auth_operador_id());

ALTER TABLE alertas_seguridad ENABLE ROW LEVEL SECURITY;
CREATE POLICY "alertas_select_own" ON alertas_seguridad FOR SELECT USING (operador_id = auth_operador_id());

ALTER TABLE reglas_puntaje ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reglas_select_authenticated" ON reglas_puntaje FOR SELECT USING (auth.role() = 'authenticated');

ALTER TABLE premios_catalogo ENABLE ROW LEVEL SECURITY;
CREATE POLICY "premios_select_active" ON premios_catalogo FOR SELECT USING (auth.role() = 'authenticated' AND activo = true);

ALTER TABLE premios_canjeados ENABLE ROW LEVEL SECURITY;
CREATE POLICY "canjes_select_own" ON premios_canjeados FOR SELECT USING (operador_id = auth_operador_id());
CREATE POLICY "canjes_insert_own" ON premios_canjeados FOR INSERT WITH CHECK (operador_id = auth_operador_id());

ALTER TABLE puntos_operador ENABLE ROW LEVEL SECURITY;
CREATE POLICY "puntos_select_own" ON puntos_operador FOR SELECT USING (operador_id = auth_operador_id());

ALTER TABLE movimientos_puntos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "movimientos_select_own" ON movimientos_puntos FOR SELECT USING (operador_id = auth_operador_id());

ALTER TABLE operador_devices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "devices_select_own" ON operador_devices FOR SELECT USING (operador_id = auth_operador_id());
CREATE POLICY "devices_insert_own" ON operador_devices FOR INSERT WITH CHECK (operador_id = auth_operador_id());
CREATE POLICY "devices_update_own" ON operador_devices FOR UPDATE USING (operador_id = auth_operador_id());
CREATE POLICY "devices_delete_own" ON operador_devices FOR DELETE USING (operador_id = auth_operador_id());

ALTER TABLE configuracion_operador ENABLE ROW LEVEL SECURITY;
CREATE POLICY "config_select_own" ON configuracion_operador FOR SELECT USING (operador_id = auth_operador_id());
CREATE POLICY "config_update_own" ON configuracion_operador FOR UPDATE USING (operador_id = auth_operador_id());

ALTER TABLE notificaciones_in_app ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notif_select_own" ON notificaciones_in_app FOR SELECT USING (operador_id = auth_operador_id());
CREATE POLICY "notif_update_own" ON notificaciones_in_app FOR UPDATE USING (operador_id = auth_operador_id());

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE notificaciones_in_app;
ALTER PUBLICATION supabase_realtime ADD TABLE viajes;
ALTER PUBLICATION supabase_realtime ADD TABLE viaje_puntos_gps;
ALTER PUBLICATION supabase_realtime ADD TABLE premios_canjeados;
