-- Fix: format() de PostgreSQL no acepta especificadores tipo printf.
--
-- La versión original usaba '%.0f km, calif %.1f' y eso hace fallar la función
-- con: unrecognized format() type specifier ".". format() solo entiende %s, %I,
-- %L y %%; el redondeo va fuera, con round().
--
-- Efecto del bug: CUALQUIER `UPDATE viajes SET estado = 'completado'` abortaba,
-- porque el trigger trg_viaje_completado revienta antes de acreditar. El ciclo
-- completo de gamificación (viaje completado → puntos → notificación) nunca
-- llegó a ejecutarse.

CREATE OR REPLACE FUNCTION fn_calcular_puntos_viaje()
RETURNS TRIGGER AS $$
DECLARE
  v_km          DECIMAL;
  v_calific     DECIMAL;
  v_alertas     INT;
  v_incidencias INT;
  v_puntos      INT;
  v_desc        TEXT;
BEGIN
  -- Solo actuar cuando el viaje pasa a completado por primera vez
  IF NEW.estado <> 'completado' OR OLD.estado = 'completado' THEN
    RETURN NEW;
  END IF;

  -- Evitar doble acreditación
  IF EXISTS (
    SELECT 1 FROM movimientos_puntos
    WHERE viaje_id = NEW.id AND tipo = 'ganado_viaje'
  ) THEN
    RETURN NEW;
  END IF;

  v_km      := COALESCE(NEW.km_recorridos, 0);
  v_calific := COALESCE(NEW.calificacion, 3.0);

  SELECT COUNT(*) INTO v_alertas
  FROM alertas_seguridad WHERE viaje_id = NEW.id;

  SELECT COUNT(*) INTO v_incidencias
  FROM incidencias WHERE viaje_id = NEW.id;

  -- Fórmula simplificada:
  --   base = 1 pt/km * factor_calificacion (0.5–1.5)
  --   penalizaciones: -5 por alerta, -10 por incidencia
  --   mínimo 10 pts por viaje completado
  v_puntos := GREATEST(
    10,
    ROUND(
      v_km * (0.5 + (v_calific / 5.0))
      - (v_alertas * 5)
      - (v_incidencias * 10)
    )::INT
  );

  v_desc := format(
    'Viaje completado — %s km, calif %s, %s alertas, %s incidencias',
    ROUND(v_km), ROUND(v_calific, 1), v_alertas, v_incidencias
  );

  PERFORM fn_acreditar_puntos_viaje(NEW.id, v_puntos, v_desc);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
