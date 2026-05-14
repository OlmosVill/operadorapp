// Edge Function: calcular-puntos-viaje
// Calcula y acredita puntos al operador cuando un viaje se completa.
// Llamada via POST con { viaje_id: string } — requiere service_role key.
// La misma lógica existe como DB trigger (trg_viaje_completado) para
// ejecución automática; esta función se usa para invocación manual/admin.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

interface Regla {
  variable: string
  formula: Record<string, unknown>
  peso: number
}

interface Viaje {
  id: string
  estado: string
  km_recorridos: number | null
  calificacion: number | null
  rendimiento_real: number | null
  tracto: { rendimiento_esperado: number } | null
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  const { viaje_id } = await req.json() as { viaje_id?: string }
  if (!viaje_id) {
    return json({ error: 'viaje_id requerido' }, 400)
  }

  const { data: viaje, error: vErr } = await supabase
    .from('viajes')
    .select('id, estado, km_recorridos, calificacion, rendimiento_real, '
      + 'tracto:tractos(rendimiento_esperado)')
    .eq('id', viaje_id)
    .single<Viaje>()

  if (vErr || !viaje) return json({ error: 'Viaje no encontrado' }, 404)
  if (viaje.estado !== 'completado') {
    return json({ error: 'El viaje no está completado' }, 400)
  }

  // Evitar doble acreditación
  const { data: existente } = await supabase
    .from('movimientos_puntos')
    .select('id')
    .eq('viaje_id', viaje_id)
    .eq('tipo', 'ganado_viaje')
    .maybeSingle()

  if (existente) {
    return json({ message: 'Puntos ya acreditados' }, 200)
  }

  const { data: reglas } = await supabase
    .from('reglas_puntaje')
    .select('variable, formula, peso')
    .eq('activa', true)

  const { data: incidencias } = await supabase
    .from('incidencias')
    .select('severidad')
    .eq('viaje_id', viaje_id)

  const { data: alertas } = await supabase
    .from('alertas_seguridad')
    .select('tipo')
    .eq('viaje_id', viaje_id)

  const { data: reportes } = await supabase
    .from('reportes')
    .select('tipo')
    .eq('viaje_id', viaje_id)
    .eq('tipo', 'mantenimiento')

  let total = 0
  const desglose: Record<string, number> = {}

  for (const regla of (reglas ?? []) as Regla[]) {
    const f = regla.formula
    const p = regla.peso
    let pts = 0

    if (regla.variable === 'rendimiento') {
      const real = viaje.rendimiento_real ?? 0
      const esp = (viaje.tracto?.rendimiento_esperado ?? 4.0)
      if (esp > 0) {
        const ratio = real / esp
        const base = (f['base'] as number) ?? 100
        const mult = (f['multiplicador'] as number) ?? 50
        const max = (f['max'] as number) ?? 200
        pts = Math.round(Math.max(0, base + Math.min(
          (ratio - 1) * mult, max - base,
        )) * p)
      }
    } else if (regla.variable === 'alertas_seguridad') {
      const count = alertas?.length ?? 0
      const ppe = (f['puntos_por_evento'] as number) ?? -5
      const maxPen = (f['max_penalizacion'] as number) ?? -100
      pts = Math.round(Math.max(count * ppe * p, maxPen))
    } else if (regla.variable === 'puntualidad') {
      pts = Math.round(((f['en_tiempo'] as number) ?? 50) * p)
    } else if (regla.variable === 'sin_reportes_mantenimiento') {
      const has = (reportes?.length ?? 0) > 0
      const bonus = has
        ? (f['con_reportes'] as number) ?? 0
        : (f['sin_reportes'] as number) ?? 30
      pts = Math.round(bonus * p)
    } else if (regla.variable === 'incidencias') {
      const niveles = (f['puntos_por_nivel'] as number[]) ??
        [-2, -5, -10, -20, -40]
      for (const inc of incidencias ?? []) {
        const sev = ((inc as { severidad?: number }).severidad ?? 1) - 1
        pts += Math.round((niveles[Math.min(sev, 4)] ?? -2) * p)
      }
    }

    desglose[regla.variable] = pts
    total += pts
  }

  total = Math.max(10, total) // mínimo 10 pts por viaje completado

  const desc = 'Viaje completado. ' +
    Object.entries(desglose)
      .map(([k, v]) => `${k}: ${v >= 0 ? '+' : ''}${v}`)
      .join(', ')

  const { error: acErr } = await supabase.rpc('fn_acreditar_puntos_viaje', {
    p_viaje_id: viaje_id,
    p_puntos: total,
    p_descripcion: desc,
  })

  if (acErr) return json({ error: acErr.message }, 500)

  return json({ puntos: total, desglose }, 200)
})

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}
