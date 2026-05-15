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
AS $$
  SELECT
    ST_Y(coordenadas::geometry) AS lat,
    ST_X(coordenadas::geometry) AS lng,
    velocidad_kmh,
    timestamp_gps
  FROM viaje_puntos_gps
  WHERE viaje_id = p_viaje_id
  ORDER BY timestamp_gps;
$$;
