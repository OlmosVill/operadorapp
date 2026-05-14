import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const LEVEL_RANK: Record<string, number> = {
  plata: 0,
  oro: 1,
  platino: 2,
  esmeralda: 3,
  diamante: 4,
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;

    // Verify JWT
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse({ error: 'Unauthorized' }, 401);
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return jsonResponse({ error: 'Unauthorized' }, 401);
    }

    const { premio_id, operador_id } = await req.json();

    if (!premio_id || !operador_id) {
      return jsonResponse(
        { error: 'Faltan parámetros: premio_id y operador_id requeridos' },
        400,
      );
    }

    const admin = createClient(supabaseUrl, serviceRoleKey);

    // Fetch the prize
    const { data: premio, error: premioError } = await admin
      .from('premios_catalogo')
      .select('*')
      .eq('id', premio_id)
      .eq('activo', true)
      .single();

    if (premioError || !premio) {
      return jsonResponse({ error: 'Premio no encontrado o inactivo' }, 404);
    }

    // Check stock
    if (premio.stock !== null && premio.stock <= 0) {
      return jsonResponse({ error: 'Premio sin stock disponible' }, 409);
    }

    // Fetch operator points
    const { data: puntosData, error: puntosError } = await admin
      .from('puntos_operador')
      .select('puntos_disponibles')
      .eq('operador_id', operador_id)
      .single();

    if (puntosError || !puntosData) {
      return jsonResponse(
        { error: 'No se encontró saldo del operador' },
        404,
      );
    }

    // Fetch operator level
    const { data: operadorData, error: operadorError } = await admin
      .from('operadores')
      .select('nivel_actual')
      .eq('id', operador_id)
      .single();

    if (operadorError || !operadorData) {
      return jsonResponse({ error: 'Operador no encontrado' }, 404);
    }

    // Validate level
    const operadorRank = LEVEL_RANK[operadorData.nivel_actual] ?? 0;
    const requiredRank =
      premio.nivel_minimo ? (LEVEL_RANK[premio.nivel_minimo] ?? 0) : 0;

    if (operadorRank < requiredRank) {
      return jsonResponse(
        {
          error: `Nivel insuficiente. Se requiere nivel ${premio.nivel_minimo}`,
        },
        403,
      );
    }

    // Validate points
    if (puntosData.puntos_disponibles < premio.costo_puntos) {
      return jsonResponse(
        {
          error: `Puntos insuficientes. Disponibles: ${puntosData.puntos_disponibles}, requeridos: ${premio.costo_puntos}`,
        },
        402,
      );
    }

    // Create canje
    const { data: canje, error: canjeError } = await admin
      .from('premios_canjeados')
      .insert({
        operador_id,
        premio_id,
        puntos_canjeados: premio.costo_puntos,
        estado: 'solicitado',
        fecha_solicitud: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (canjeError || !canje) {
      return jsonResponse({ error: 'Error al crear el canje' }, 500);
    }

    // Decrement stock if limited
    if (premio.stock !== null) {
      await admin
        .from('premios_catalogo')
        .update({ stock: premio.stock - 1 })
        .eq('id', premio_id);
    }

    return jsonResponse(canje, 200);
  } catch (error) {
    return jsonResponse({ error: String(error) }, 500);
  }
});

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
