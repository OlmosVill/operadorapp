-- =============================================================================
-- OperadorApp — Datos de ejemplo para desarrollo local
-- Este archivo se aplica automáticamente con: supabase db reset
-- TODOS los datos aquí son DEMO — no usar en producción
-- =============================================================================

-- Niveles de operador
INSERT INTO niveles_operador (nombre, puntos_minimos, puntos_maximos, descripcion, color_hex, orden, beneficios) VALUES
    ('plata',     0,      4999,  '[DEMO] Nivel inicial. Todo operador comienza aquí.',                           '#C0C0C0', 1,
     '[{"texto": "Acceso a catálogo básico de premios"}]'),
    ('oro',       5000,   14999, '[DEMO] Buen historial. Pocas incidencias y buen rendimiento.',                 '#FFD700', 2,
     '[{"texto": "Acceso a premios de nivel Oro"}, {"texto": "Prioridad en asignación de rutas premium"}]'),
    ('platino',   15000,  29999, '[DEMO] Operador con excelente rendimiento consistente.',                       '#E5E4E2', 3,
     '[{"texto": "Acceso a experiencias"}, {"texto": "Bono trimestral adicional"}]'),
    ('esmeralda', 30000,  59999, '[DEMO] De los mejores en la flota. Referente para otros operadores.',          '#50C878', 4,
     '[{"texto": "Acceso a vehículos en catálogo"}, {"texto": "Reconocimiento público en empresa"}]'),
    ('diamante',  60000,  NULL,  '[DEMO] Elite. El máximo reconocimiento de la empresa.',                        '#B9F2FF', 5,
     '[{"texto": "Acceso a todos los premios"}, {"texto": "Asesor de nuevos operadores"}, {"texto": "Eventos exclusivos"}]');

-- Tractos de ejemplo
INSERT INTO tractos (numero_economico, marca, modelo, anio, placa, rendimiento_esperado) VALUES
    ('T-001', 'Kenworth', 'T680',     2022, 'ABC-123-A', 4.2),
    ('T-002', 'Peterbilt', '579',     2021, 'DEF-456-B', 4.0),
    ('T-003', 'Freightliner', 'Cascadia', 2023, 'GHI-789-C', 4.5),
    ('T-004', 'Volvo', 'VNL 860',    2020, 'JKL-012-D', 3.8),
    ('T-005', 'International', 'LT',  2022, 'MNO-345-E', 4.1);

-- Reglas de puntaje
INSERT INTO reglas_puntaje (nombre, descripcion, variable, formula, peso) VALUES
    (
        'Rendimiento de combustible',
        '[DEMO] Puntaje por km/litro real vs esperado. Mejor rendimiento = más puntos.',
        'rendimiento',
        '{"tipo": "ratio", "base": 100, "multiplicador": 50, "max": 200}',
        1.5
    ),
    (
        'Penalización por alertas de seguridad',
        '[DEMO] Cada freno brusco, aceleración o exceso de velocidad resta puntos.',
        'alertas_seguridad',
        '{"tipo": "penalizacion_por_evento", "puntos_por_evento": -5, "max_penalizacion": -100}',
        1.0
    ),
    (
        'Cumplimiento de tiempo de entrega',
        '[DEMO] Llegar en el tiempo estimado suma puntos. Retrasos penalizan.',
        'puntualidad',
        '{"tipo": "escalonado", "en_tiempo": 50, "tardanza_menor_1h": 25, "tardanza_1_2h": 10, "tardanza_mayor_2h": 0}',
        1.2
    ),
    (
        'Sin reportes de mantenimiento abiertos',
        '[DEMO] Bonificación por completar el viaje sin reportes de mantenimiento.',
        'sin_reportes_mantenimiento',
        '{"tipo": "bonificacion", "sin_reportes": 30, "con_reportes": 0}',
        1.0
    ),
    (
        'Incidencias en ruta',
        '[DEMO] Cada incidencia registrada resta puntos según su severidad.',
        'incidencias',
        '{"tipo": "penalizacion_por_severidad", "puntos_por_nivel": [-2, -5, -10, -20, -40]}',
        0.8
    );

-- Catálogo de premios (DEMO)
INSERT INTO premios_catalogo (nombre, descripcion, tipo, costo_puntos, nivel_minimo, orden) VALUES
    (
        'Tarjeta de regalo $500',
        '[DEMO] Tarjeta de regalo en tiendas de conveniencia. Para esa botana que se merece tu familia.',
        'tarjeta_regalo', 500, NULL, 10
    ),
    (
        'Tarjeta de regalo $1,000',
        '[DEMO] Para una comida especial en familia un domingo.',
        'tarjeta_regalo', 1000, NULL, 20
    ),
    (
        'Mochila escolar premium',
        '[DEMO] Para que tus hijos lleguen con estilo al colegio. Incluye útiles básicos.',
        'producto_fisico', 2500, NULL, 30
    ),
    (
        'Despensa familiar completa',
        '[DEMO] Canasta básica completa para un mes. Para que no falte nada en casa.',
        'producto_fisico', 5000, 'oro', 40
    ),
    (
        'Set de herramientas profesional',
        '[DEMO] Para el operador que también es manitas en casa. 120 piezas.',
        'producto_fisico', 8000, 'oro', 50
    ),
    (
        'Tablet educativa',
        '[DEMO] Para que tus hijos sigan aprendiendo. Con apps educativas preinstaladas.',
        'producto_fisico', 12000, 'oro', 60
    ),
    (
        'Smartphone de gama media',
        '[DEMO] Para estar conectado con la familia en cada ruta.',
        'producto_fisico', 18000, 'platino', 70
    ),
    (
        'Paquete de vacaciones familiar',
        '[DEMO] 4 días, 3 noches en destino de playa. Incluye transporte y hotel. Para la familia que lo merece.',
        'experiencia', 30000, 'platino', 80
    ),
    (
        'Motocicleta de trabajo',
        '[DEMO] Para moverse más fácil en el día a día. 150cc, económica en combustible.',
        'vehiculo', 60000, 'esmeralda', 90
    ),
    (
        'Auto compacto 0km',
        '[DEMO] El sueño de todo operador. Un auto para la familia. Para llegar a casa con orgullo.',
        'vehiculo', 150000, 'diamante', 100
    );

-- Nota: los operadores de prueba deben crearse via Supabase Auth
-- (no se pueden insertar directamente en auth.users desde seed.sql)
-- Usar la UI de Supabase Studio en localhost:54323 > Authentication
-- o el script de setup en docs/DATABASE.md para crear operadores de prueba.

-- =============================================================================
-- Ranking — operadores DEMO
-- Sin auth_user_id: no pueden iniciar sesión y RLS los mantiene invisibles en
-- consultas individuales. Solo aparecen a través de fn_ranking_operadores.
-- =============================================================================

INSERT INTO operadores (id, numero_empleado, nombre_completo, fecha_ingreso, base) VALUES
    ('a0000000-0000-4000-8000-000000000001', '90001', '[DEMO] Ricardo Salgado Mena',   '2018-02-12', 'Monterrey'),
    ('a0000000-0000-4000-8000-000000000002', '90002', '[DEMO] Martín Ochoa Valdés',    '2019-06-03', 'Monterrey'),
    ('a0000000-0000-4000-8000-000000000003', '90003', '[DEMO] Alonso Reyes Guzmán',    '2020-01-20', 'Querétaro'),
    ('a0000000-0000-4000-8000-000000000004', '90004', '[DEMO] Fernanda Ríos Camacho',  '2020-09-14', 'Querétaro'),
    ('a0000000-0000-4000-8000-000000000005', '90005', '[DEMO] Ismael Cordero Nava',    '2021-04-05', 'Guadalajara'),
    ('a0000000-0000-4000-8000-000000000006', '90006', '[DEMO] Ana Lucía Bermúdez',     '2022-07-18', 'Guadalajara');

-- Puntos acumulados (fn_actualizar_puntos_operador deriva nivel y saldos).
--
-- Las fechas se anclan al INICIO DEL MES en curso, no a NOW() - n días: con
-- offsets relativos a hoy, un reset corrido el día 3 del mes empujaba los
-- movimientos "del mes" al mes anterior y el ranking mensual salía en ceros.
-- dias negativos = meses anteriores. El LEAST evita fechas futuras.
INSERT INTO movimientos_puntos (operador_id, tipo, puntos, descripcion, saldo_despues, created_at)
SELECT
    m.operador_id, 'ganado_viaje'::tipo_movimiento_enum, m.puntos, m.descripcion, m.saldo,
    LEAST(
        date_trunc('month', NOW()) + (m.dias || ' days')::INTERVAL,
        NOW() - INTERVAL '2 hours'
    )
FROM (VALUES
    ('a0000000-0000-4000-8000-000000000001'::UUID, 41200, '[DEMO] Acumulado histórico', 41200, -170),
    ('a0000000-0000-4000-8000-000000000001'::UUID,  3800, '[DEMO] Viajes del mes',      45000,    2),
    ('a0000000-0000-4000-8000-000000000002'::UUID, 26500, '[DEMO] Acumulado histórico', 26500, -160),
    ('a0000000-0000-4000-8000-000000000002'::UUID,  5100, '[DEMO] Viajes del mes',      31600,    3),
    ('a0000000-0000-4000-8000-000000000003'::UUID, 17800, '[DEMO] Acumulado histórico', 17800, -150),
    ('a0000000-0000-4000-8000-000000000003'::UUID,  1200, '[DEMO] Viajes del mes',      19000,    1),
    ('a0000000-0000-4000-8000-000000000004'::UUID, 11400, '[DEMO] Acumulado histórico', 11400, -140),
    ('a0000000-0000-4000-8000-000000000004'::UUID,  4300, '[DEMO] Viajes del mes',      15700,    3),
    ('a0000000-0000-4000-8000-000000000005'::UUID,  7900, '[DEMO] Acumulado histórico',  7900, -130),
    ('a0000000-0000-4000-8000-000000000005'::UUID,   600, '[DEMO] Viajes del mes',       8500,    0),
    ('a0000000-0000-4000-8000-000000000006'::UUID,  3100, '[DEMO] Acumulado histórico',  3100, -120),
    ('a0000000-0000-4000-8000-000000000006'::UUID,  2400, '[DEMO] Viajes del mes',       5500,    1)
) AS m(operador_id, puntos, descripcion, saldo, dias);

-- Viajes completados: alimentan la calificación promedio del ranking.
-- Se insertan ya en estado 'completado'; trg_viaje_completado es AFTER UPDATE,
-- así que no se duplican los puntos de arriba.
-- Mismo anclaje al inicio del mes: cada operador tiene un viaje dentro del mes
-- en curso para que el periodo 'mensual' muestre calificación.
INSERT INTO viajes (operador_id, tracto_id, origen, destino, estado, km_recorridos, calificacion, fecha_inicio, fecha_fin)
SELECT
    v.operador_id,
    (SELECT id FROM tractos WHERE numero_economico = v.tracto),
    v.origen, v.destino, 'completado', v.km, v.calif,
    v.fin - INTERVAL '11 hours',
    v.fin
FROM (
    SELECT
        t.operador_id, t.tracto, t.origen, t.destino, t.km, t.calif,
        LEAST(
            date_trunc('month', NOW()) + (t.dias || ' days')::INTERVAL,
            NOW() - INTERVAL '2 hours'
        ) AS fin
    FROM (VALUES
        ('a0000000-0000-4000-8000-000000000001'::UUID, 'T-001', 'Monterrey',   'CDMX',        920.0, 9.6,   3),
        ('a0000000-0000-4000-8000-000000000001'::UUID, 'T-001', 'CDMX',        'Monterrey',   915.0, 9.4, -25),
        ('a0000000-0000-4000-8000-000000000002'::UUID, 'T-002', 'Monterrey',   'Saltillo',    290.0, 9.1,   2),
        ('a0000000-0000-4000-8000-000000000002'::UUID, 'T-002', 'Saltillo',    'Torreón',     320.0, 8.8, -20),
        ('a0000000-0000-4000-8000-000000000003'::UUID, 'T-003', 'Querétaro',   'Guadalajara', 380.0, 8.5,   1),
        ('a0000000-0000-4000-8000-000000000003'::UUID, 'T-003', 'Guadalajara', 'Querétaro',   378.0, 8.2, -30),
        ('a0000000-0000-4000-8000-000000000004'::UUID, 'T-004', 'Querétaro',   'CDMX',        215.0, 8.9,   3),
        ('a0000000-0000-4000-8000-000000000004'::UUID, 'T-004', 'CDMX',        'Puebla',      135.0, 9.2, -18),
        ('a0000000-0000-4000-8000-000000000005'::UUID, 'T-005', 'Guadalajara', 'Colima',      215.0, 7.6,   0),
        ('a0000000-0000-4000-8000-000000000005'::UUID, 'T-005', 'Colima',      'Guadalajara', 218.0, 7.9, -22),
        ('a0000000-0000-4000-8000-000000000006'::UUID, 'T-005', 'Guadalajara', 'León',        210.0, 8.0,   1),
        ('a0000000-0000-4000-8000-000000000006'::UUID, 'T-005', 'León',        'Guadalajara', 212.0, 8.3, -15)
    ) AS t(operador_id, tracto, origen, destino, km, calif, dias)
) AS v;

-- =============================================================================
-- Operador de prueba CON LOGIN — solo desarrollo local
--
-- Credenciales:  número de empleado 12345  /  contraseña 123456
--
-- `supabase db reset` también vacía auth.users, así que sin este bloque cada
-- reset dejaba la app con sesión cacheada apuntando a un operador inexistente
-- (syncProfile → PGRST116 "0 rows"). Las columnas de token van en cadena vacía
-- a propósito: GoTrue las escanea en `string` de Go y con NULL el login
-- devuelve "Database error querying schema".
-- =============================================================================

INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    confirmation_token, recovery_token, email_change,
    email_change_token_new, email_change_token_current,
    phone_change, phone_change_token, reauthentication_token
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    'b0000000-0000-4000-8000-000000000001',
    'authenticated', 'authenticated',
    '12345@operadorapp.internal',
    extensions.crypt('123456', extensions.gen_salt('bf')),
    NOW(), NOW(), NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    '', '', '', '', '', '', '', ''
);

INSERT INTO auth.identities (
    provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
) VALUES (
    'b0000000-0000-4000-8000-000000000001',
    'b0000000-0000-4000-8000-000000000001',
    jsonb_build_object(
        'sub', 'b0000000-0000-4000-8000-000000000001',
        'email', '12345@operadorapp.internal',
        'email_verified', true,
        'phone_verified', false
    ),
    'email', NOW(), NOW(), NOW()
);

-- trg_new_operador crea automáticamente puntos_operador y configuracion_operador
INSERT INTO operadores (id, auth_user_id, numero_empleado, nombre_completo, fecha_ingreso, base) VALUES (
    'a0000000-0000-4000-8000-0000000000ff',
    'b0000000-0000-4000-8000-000000000001',
    '12345', '[DEMO] Juan Demo', '2022-01-15', 'Monterrey'
);

INSERT INTO movimientos_puntos (operador_id, tipo, puntos, descripcion, saldo_despues, created_at)
SELECT
    'a0000000-0000-4000-8000-0000000000ff', 'ganado_viaje'::tipo_movimiento_enum,
    m.puntos, m.descripcion, m.saldo,
    LEAST(
        date_trunc('month', NOW()) + (m.dias || ' days')::INTERVAL,
        NOW() - INTERVAL '2 hours'
    )
FROM (VALUES
    (16900, '[DEMO] Acumulado histórico', 16900, -145),
    ( 2600, '[DEMO] Viajes del mes',      19500,    2)
) AS m(puntos, descripcion, saldo, dias);

INSERT INTO viajes (operador_id, tracto_id, origen, destino, estado, km_recorridos, km_esperados, litros_diesel, rendimiento_real, calificacion, fecha_inicio, fecha_fin)
SELECT
    'a0000000-0000-4000-8000-0000000000ff',
    (SELECT id FROM tractos WHERE numero_economico = 'T-003'),
    v.origen, v.destino, 'completado', v.km, v.km, v.litros,
    ROUND(v.km / v.litros, 2), v.calif,
    v.fin - INTERVAL '10 hours',
    v.fin
FROM (
    SELECT
        t.origen, t.destino, t.km, t.litros, t.calif,
        LEAST(
            date_trunc('month', NOW()) + (t.dias || ' days')::INTERVAL,
            NOW() - INTERVAL '2 hours'
        ) AS fin
    FROM (VALUES
        ('Monterrey',   'Guadalajara', 720.0, 165.0, 8.7,   2),
        ('Guadalajara', 'CDMX',        540.0, 128.0, 9.0, -12),
        ('CDMX',        'Monterrey',   910.0, 210.0, 8.4, -24)
    ) AS t(origen, destino, km, litros, calif, dias)
) AS v;

INSERT INTO historial_tractos_operador (operador_id, tracto_id, fecha_inicio, km_recorridos, viajes_realizados, calificacion_promedio, activo)
VALUES (
    'a0000000-0000-4000-8000-0000000000ff',
    (SELECT id FROM tractos WHERE numero_economico = 'T-003'),
    CURRENT_DATE - 120, 2170.0, 3, 8.70, true
);

-- Recalcular saldos y nivel de cada operador DEMO
DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT DISTINCT operador_id FROM movimientos_puntos LOOP
        PERFORM fn_actualizar_puntos_operador(r.operador_id);
    END LOOP;
END $$;

-- Snapshot "de ayer": da contenido a las flechas de subida/bajada del ranking.
-- Las posiciones aquí son intencionalmente distintas a las actuales.
INSERT INTO ranking_snapshots (periodo, operador_id, posicion, puntos, capturado_el) VALUES
    ('global',  'a0000000-0000-4000-8000-000000000001', 1, 41200, CURRENT_DATE - 1),
    ('global',  'a0000000-0000-4000-8000-000000000002', 4, 26500, CURRENT_DATE - 1),
    ('global',  'a0000000-0000-4000-8000-000000000003', 2, 17800, CURRENT_DATE - 1),
    ('global',  'a0000000-0000-4000-8000-000000000004', 6, 11400, CURRENT_DATE - 1),
    ('global',  'a0000000-0000-4000-8000-000000000005', 5,  7900, CURRENT_DATE - 1),
    ('global',  'a0000000-0000-4000-8000-000000000006', 7,  3100, CURRENT_DATE - 1),
    ('mensual', 'a0000000-0000-4000-8000-000000000001', 3,  3800, CURRENT_DATE - 1),
    ('mensual', 'a0000000-0000-4000-8000-000000000002', 1,  5100, CURRENT_DATE - 1),
    ('mensual', 'a0000000-0000-4000-8000-000000000003', 4,  1200, CURRENT_DATE - 1),
    ('mensual', 'a0000000-0000-4000-8000-000000000004', 2,  4300, CURRENT_DATE - 1),
    ('mensual', 'a0000000-0000-4000-8000-000000000005', 5,   600, CURRENT_DATE - 1),
    ('mensual', 'a0000000-0000-4000-8000-000000000006', 6,  2400, CURRENT_DATE - 1),
    ('global',  'a0000000-0000-4000-8000-0000000000ff', 5, 16900, CURRENT_DATE - 1),
    ('mensual', 'a0000000-0000-4000-8000-0000000000ff', 7,  2600, CURRENT_DATE - 1);
