-- Ranking de operadores
--
-- El cálculo de posiciones vive SOLO en el servidor: el cliente consume la RPC
-- `fn_ranking_operadores` y nunca deriva puntos ni posiciones por su cuenta.
--
-- El movimiento de lugares (flecha arriba/abajo) se calcula contra el último
-- snapshot guardado en `ranking_snapshots`, no contra lo que el dispositivo
-- tenga en caché: así todos los operadores ven el mismo delta.

-- ─── Snapshots ───────────────────────────────────────────────────────────────

CREATE TABLE ranking_snapshots (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    periodo      VARCHAR(10) NOT NULL CHECK (periodo IN ('global', 'mensual')),
    operador_id  UUID NOT NULL REFERENCES operadores(id) ON DELETE CASCADE,
    posicion     INTEGER NOT NULL,
    puntos       INTEGER NOT NULL DEFAULT 0,
    capturado_el DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (periodo, operador_id, capturado_el)
);

CREATE INDEX idx_ranking_snapshots_periodo
    ON ranking_snapshots (periodo, capturado_el DESC);

-- ─── Ranking actual ──────────────────────────────────────────────────────────

-- p_periodo:
--   'global'  → puntos acumulados de toda la historia
--   'mensual' → puntos ganados desde el inicio del mes calendario en curso
--
-- SECURITY DEFINER porque RLS restringe `operadores` / `puntos_operador` a la
-- fila propia. La función expone solo las columnas públicas del leaderboard.
CREATE OR REPLACE FUNCTION fn_ranking_operadores(
    p_periodo VARCHAR DEFAULT 'global'
)
RETURNS TABLE (
    operador_id        UUID,
    numero_empleado    VARCHAR,
    nombre_completo    VARCHAR,
    foto_perfil_url    TEXT,
    nivel              TEXT,
    puntos             INTEGER,
    calificacion       NUMERIC,
    viajes_completados INTEGER,
    posicion           INTEGER,
    posicion_anterior  INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    WITH rango AS (
        SELECT CASE
            WHEN p_periodo = 'mensual' THEN date_trunc('month', NOW())
            ELSE NULL
        END AS desde
    ),
    base AS (
        SELECT
            o.id,
            o.numero_empleado,
            o.nombre_completo,
            o.foto_perfil_url,
            -- enum → text: PostgreSQL no permite el cast directo a varchar
            o.nivel_actual::TEXT AS nivel,
            COALESCE((
                SELECT SUM(mp.puntos)::INTEGER
                FROM movimientos_puntos mp
                WHERE mp.operador_id = o.id
                  AND mp.puntos > 0
                  AND (r.desde IS NULL OR mp.created_at >= r.desde)
            ), 0) AS puntos,
            (
                SELECT ROUND(AVG(v.calificacion), 2)
                FROM viajes v
                WHERE v.operador_id = o.id
                  AND v.estado = 'completado'
                  AND v.calificacion IS NOT NULL
                  AND (r.desde IS NULL OR v.fecha_fin >= r.desde)
            ) AS calificacion,
            COALESCE((
                SELECT COUNT(*)::INTEGER
                FROM viajes v
                WHERE v.operador_id = o.id
                  AND v.estado = 'completado'
                  AND (r.desde IS NULL OR v.fecha_fin >= r.desde)
            ), 0) AS viajes_completados
        FROM operadores o
        CROSS JOIN rango r
        WHERE o.activo = true
    ),
    ordenado AS (
        SELECT
            b.*,
            ROW_NUMBER() OVER (
                ORDER BY b.puntos DESC,
                         b.calificacion DESC NULLS LAST,
                         b.viajes_completados DESC,
                         b.nombre_completo ASC
            )::INTEGER AS posicion
        FROM base b
    ),
    -- Fecha del snapshot más reciente anterior a hoy: todos los deltas se
    -- comparan contra el mismo corte para que las posiciones sean coherentes.
    corte AS (
        SELECT MAX(rs.capturado_el) AS fecha
        FROM ranking_snapshots rs
        WHERE rs.periodo = p_periodo
          AND rs.capturado_el < CURRENT_DATE
    ),
    previo AS (
        SELECT rs.operador_id, rs.posicion
        FROM ranking_snapshots rs
        CROSS JOIN corte c
        WHERE rs.periodo = p_periodo
          AND c.fecha IS NOT NULL
          AND rs.capturado_el = c.fecha
    )
    SELECT
        o.id,
        o.numero_empleado,
        o.nombre_completo,
        o.foto_perfil_url,
        o.nivel,
        o.puntos,
        o.calificacion,
        o.viajes_completados,
        o.posicion,
        p.posicion AS posicion_anterior
    FROM ordenado o
    LEFT JOIN previo p ON p.operador_id = o.id
    ORDER BY o.posicion;
$$;

-- ─── Captura de snapshot ─────────────────────────────────────────────────────

-- Ejecutar una vez al día (pg_cron o job externo con la service key):
--   SELECT fn_capturar_snapshot_ranking('global');
--   SELECT fn_capturar_snapshot_ranking('mensual');
CREATE OR REPLACE FUNCTION fn_capturar_snapshot_ranking(
    p_periodo VARCHAR DEFAULT 'global'
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_filas INTEGER;
BEGIN
    INSERT INTO ranking_snapshots (periodo, operador_id, posicion, puntos)
    SELECT p_periodo, r.operador_id, r.posicion, r.puntos
    FROM fn_ranking_operadores(p_periodo) r
    ON CONFLICT (periodo, operador_id, capturado_el)
    DO UPDATE SET posicion = EXCLUDED.posicion,
                  puntos   = EXCLUDED.puntos;

    GET DIAGNOSTICS v_filas = ROW_COUNT;
    RETURN v_filas;
END;
$$;

-- ─── RLS y permisos ──────────────────────────────────────────────────────────

ALTER TABLE ranking_snapshots ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ranking_snapshots_select_own" ON ranking_snapshots
    FOR SELECT USING (operador_id = auth_operador_id());

-- El leaderboard es para operadores autenticados; nunca para anon.
REVOKE ALL ON FUNCTION fn_ranking_operadores(VARCHAR) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION fn_ranking_operadores(VARCHAR) TO authenticated;

-- La captura de snapshots es tarea de backend, no del cliente.
REVOKE ALL ON FUNCTION fn_capturar_snapshot_ranking(VARCHAR) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION fn_capturar_snapshot_ranking(VARCHAR) TO service_role;
