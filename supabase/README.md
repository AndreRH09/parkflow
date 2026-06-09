# Supabase Migrations — ParkFlow

Guía para gestionar cambios de esquema en Supabase.

## 📁 Estructura

```
supabase/
  migrations/          # SQL migrations versionadas
    001_init_schema.sql
    002_*.sql
  schema.sql          # Referencia del schema actual (no ejecutar)
  README.md           # Este archivo
```

## 🔄 Cómo usar migraciones

### 1. **Crear una nueva migración**

Crea un archivo SQL con formato de versión:

```bash
# Ejemplo: agregar tabla de transacciones
supabase/migrations/002_add_transactions_table.sql
```

**Convención de nombres:**
- `NNN_` — número secuencial (001, 002, 003...)
- Descripción clara en snake_case
- Sufijo `.sql`

### 2. **Ejecutar migraciones en Supabase**

#### Opción A: Desde el Dashboard (recomendado para desarrollo)
1. Ve a **Supabase Dashboard** → **SQL Editor**
2. Copia el contenido del archivo `.sql`
3. Pégalo y ejecuta

#### Opción B: Usar CLI de Supabase (cuando esté disponible)
```bash
# Requiere supabase CLI instalado
supabase db push
```

### 3. **Agregar migraciones al repo**

Después de ejecutar en Supabase:

```bash
git add supabase/migrations/NNN_*.sql
git commit -m "Add migration: NNN_description"
git push
```

## ✅ Buenas prácticas

- **Versionado secuencial:** Nunca renumeres migraciones existentes
- **Idempotencia:** Usa `CREATE IF NOT EXISTS`, `DROP IF EXISTS`
- **RLS:** Siempre habilita `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`
- **Documentación:** Añade comentarios en SQL explicando qué hace
- **Testing:** Prueba en una rama development antes de mergear
- **Schema.sql:** Actualiza `schema.sql` después de cambios mayores (referencia)

## 📋 Ejemplo de buena migración

```sql
-- ============================================================
-- Migración: Agregar tabla de transacciones
-- Descripción: Nueva tabla para rastrear pagos (HU-15)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  booking_id UUID NOT NULL REFERENCES public.bookings(id),
  amount NUMERIC(10,2) NOT NULL,
  status TEXT CHECK (status IN ('pending','completed','failed')) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_view_own_transactions" ON public.transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = transactions.booking_id
        AND (auth.uid() = b.driver_id OR auth.uid() = b.host_id)
    )
  );
```

## 🔗 Referencias

- [Supabase SQL Editor](https://supabase.com/docs/guides/database)
- [PostgreSQL DDL](https://www.postgresql.org/docs/current/ddl.html)
- [PostGIS Docs](https://postgis.net/documentation/)

## 📝 Changelog actual

| Ver | Descripción | Archivo |
|-----|-------------|---------|
| 001 | Schema inicial (profiles, spots, bids, bookings, reviews) | `001_init_schema.sql` |
