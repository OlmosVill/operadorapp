-- Función auxiliar para el admin: devuelve los puntos GPS de un viaje como lat/lng numéricos
CREATE OR REPLACE FUNCTION get_viaje_gps_points(p_viaje_id uuid)
RETURNS TABLE(
  lat  float8,
  lng  float8,
  velocidad_kmh numeric,
  timestamp_gps timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  -- La tabla se alias como g y se califica cada columna: los nombres de las
  -- columnas de salida (velocidad_kmh, timestamp_gps) coinciden con los de la
  -- tabla, y sin alias PostgreSQL los reporta como referencia ambigua.
  SELECT
    ST_Y(g.coordenada::geometry) AS lat,
    ST_X(g.coordenada::geometry) AS lng,
    g.velocidad_kmh,
    g.timestamp_gps
  FROM viaje_puntos_gps g
  WHERE g.viaje_id = p_viaje_id
  ORDER BY g.timestamp_gps;
$$;
