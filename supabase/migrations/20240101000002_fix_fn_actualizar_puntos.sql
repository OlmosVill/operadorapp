-- Fix: FILTER clause must be applied directly to aggregate function, not to ABS()
CREATE OR REPLACE FUNCTION fn_actualizar_puntos_operador(p_operador_id UUID)
RETURNS VOID AS $$
DECLARE
    v_ganados     INTEGER;
    v_canjeados   INTEGER;
    v_disponibles INTEGER;
BEGIN
    SELECT
        COALESCE(SUM(puntos) FILTER (WHERE puntos > 0), 0),
        COALESCE(ABS(SUM(puntos) FILTER (WHERE puntos < 0)), 0),
        COALESCE(SUM(puntos), 0)
    INTO v_ganados, v_canjeados, v_disponibles
    FROM movimientos_puntos
    WHERE operador_id = p_operador_id;

    INSERT INTO puntos_operador (
        operador_id, puntos_ganados, puntos_canjeados, puntos_disponibles, ultimo_calculo
    )
    VALUES (p_operador_id, v_ganados, v_canjeados, v_disponibles, NOW())
    ON CONFLICT (operador_id) DO UPDATE SET
        puntos_ganados     = EXCLUDED.puntos_ganados,
        puntos_canjeados   = EXCLUDED.puntos_canjeados,
        puntos_disponibles = EXCLUDED.puntos_disponibles,
        ultimo_calculo     = NOW();

    -- Recalcular nivel según puntos ganados totales acumulados
    UPDATE operadores
    SET nivel_actual = (
        SELECT nombre
        FROM niveles_operador
        WHERE puntos_minimos <= v_ganados
          AND (puntos_maximos IS NULL OR v_ganados <= puntos_maximos)
        ORDER BY puntos_minimos DESC
        LIMIT 1
    )
    WHERE id = p_operador_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
