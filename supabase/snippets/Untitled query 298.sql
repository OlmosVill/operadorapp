select o.numero_empleado, o.nombre_completo, u.email
  from operadores o
  join auth.users u on u.id = o.auth_user_id
  order by o.numero_empleado;