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
